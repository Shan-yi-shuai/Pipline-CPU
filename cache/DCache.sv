`ifndef __DCACHE_SV
`define __DCACHE_SV

`ifdef VERILATOR
`include "include/common.sv"
/* You should not add any additional includes in this file */
`endif

module DCache 
	import common::*; #(
		/* You can modify this part to support more parameters */
		/* e.g. OFFSET_BITS, INDEX_BITS, TAG_BITS */
		parameter X = 1
	)(
	input logic clk, reset,

	input  dbus_req_t  dreq,
    output dbus_resp_t dresp,
    output cbus_req_t  creq,
    input  cbus_resp_t cresp
);

`ifndef REFERENCE_CACHE

	/* TODO: Lab3 Cache */
    //参数化、写取位函数
    localparam WORDS_PER_LINE = 16; //块的大小
    localparam ASSOCIATIVITY = 2; //一组中的cache line数量
    localparam SET_NUM = 8; //组数

    localparam OFFSET_BITS = $clog2(WORDS_PER_LINE); 
    localparam INDEX_BITS = $clog2(SET_NUM); 
    localparam TAG_BITS = 64 - INDEX_BITS - OFFSET_BITS - 3;
    localparam type offset_t = logic [OFFSET_BITS-1:0]; //块内地址
    localparam type index_t = logic [INDEX_BITS-1:0];//组编号 
    localparam type tag_t = logic [TAG_BITS-1:0]; //tag
    function offset_t get_offset(addr_t addr); 
        return addr[3+OFFSET_BITS-1:3]; 
    endfunction 
    function index_t get_index(addr_t addr); 
        return addr[3+INDEX_BITS+OFFSET_BITS-1:OFFSET_BITS+3]; 
    endfunction
    function tag_t get_tag(addr_t addr); 
        return addr[3+INDEX_BITS+OFFSET_BITS+TAG_BITS- 1:3+INDEX_BITS+OFFSET_BITS]; 
    endfunction 
    localparam type state_t = enum logic[2:0] { INIT, FETCH, WRITEBACK,IDLE,READY };
    localparam type hit_t = enum logic[1:0] { MISS,HIT};
    // localparam type get_t = enum logic[1:0] { NONE,GET };
    localparam type dirty_t = enum logic[0:0] { CLEAN,DIRTY };
    localparam type valid_t = enum logic[0:0] { INVALID,VALID };


    typedef struct packed {
         u8 age;
         valid_t valid; 
         dirty_t dirty; 
         tag_t tag; 
    } meta_t;

    typedef struct packed {
         meta_t meta1;
         meta_t meta2;
    } two_meta_t;

     // the RAM
    struct packed {
        logic    en;
        u4 addr;
        u2 strobe;//不确定是否正确()
        two_meta_t   wdata;
        two_meta_t rdata;
    } meta_ram /* verilator split_var */;

    struct packed {
        logic    en;
        u8 addr;
        strobe_t strobe;//读的时候应该和dreq.strobe一样
        word_t   wdata;
        word_t rdata;
    } data_ram /* verilator split_var */;


    //
    state_t state;
    state_t state_nxt;
    u4 meta_counter;
    u4 fetch_counter;
    u4 writeback_counter;
    u1 hit_counter;
    // u4 age_array [SET_NUM*ASSOCIATIVITY-1:0];//因为一组里面是两个cache line
    // u4 age_array_nxt [SET_NUM*ASSOCIATIVITY-1:0];
    hit_t hit;
    hit_t hit_nxt;
    dirty_t dirty;
    dirty_t dirty_nxt;
    valid_t valid;
    valid_t valid_nxt;
    tag_t Tag;
    u4 age_counter;


    //meta
    RAM_SinglePort #(
		.ADDR_WIDTH($clog2(SET_NUM*ASSOCIATIVITY)),
		.DATA_WIDTH(($bits(meta_t) * ASSOCIATIVITY)),
		.BYTE_WIDTH($bits(meta_t)),
		.READ_LATENCY(0)
    ) ram_meta (
        .clk(clk), .en(meta_ram.en),
        .addr(meta_ram.addr),
        .strobe(meta_ram.strobe),
        .wdata(meta_ram.wdata),
        .rdata(meta_ram.rdata)
    );
    //data
    RAM_SinglePort #(
		.ADDR_WIDTH($clog2(WORDS_PER_LINE*SET_NUM*ASSOCIATIVITY)),
		.DATA_WIDTH(64),
		.BYTE_WIDTH(8),
		.READ_LATENCY(0)
	) ram_data (
        .clk(clk), .en(data_ram.en),
        .addr(data_ram.addr),
        .strobe(data_ram.strobe),
        .wdata(data_ram.wdata),
        .rdata(data_ram.rdata)
    );

    u4 meta_addr1;
    u4 meta_addr2;
    meta_t meta1;
    meta_t meta2;
    meta_t meta_choice;
    u1 line;//0就是meta1,1就是meta2
    
    
    //判断对应的meta是否存在，获取要替换的meta的地址 
    //替换策略：hit,age置为0，其他meta age++;miss,age置为0,其他meta age++
    // assign meta_addr1=get_index(dreq.addr)*ASSOCIATIVITY-1;//数组是从下标为0开始的？
    // assign meta_addr2=get_index(dreq.addr)*ASSOCIATIVITY;
    // assign meta1=meta_ram.rdata.meta1;
    // assign meta2=meta_ram.rdata.meta2;

    always_comb begin
        if(dreq.valid&&state==READY)begin//获取了meta数据
            meta_addr1={get_index(dreq.addr),1'b0};//数组是从下标为0开始的？
            meta_addr2={get_index(dreq.addr),1'b1};
            meta1=meta_ram.rdata.meta1;
            meta2=meta_ram.rdata.meta2;
            line=0;
            dirty_nxt=CLEAN;
            hit_nxt=MISS;
            valid_nxt=INVALID;
            Tag=0;
            if(meta1.valid==VALID&&meta1.tag==get_tag(dreq.addr))begin
                // meta_ram.addr=meta_addr1;
                // meta_choice=meta1;
                line=0;
                dirty_nxt=meta1.dirty;
                hit_nxt=HIT;
                valid_nxt=VALID;
                Tag=get_tag(dreq.addr);
            end
            else if(meta2.valid==VALID&&meta2.tag==get_tag(dreq.addr))begin
                // meta_ram.addr=meta_addr2;
                // meta_choice=meta2;
                line=1;
                dirty_nxt=meta2.dirty;
                hit_nxt=HIT;
                valid_nxt=VALID;
                Tag=get_tag(dreq.addr);
            end
            else begin
                hit_nxt=MISS;
                //替换策略
                if(meta1.age>meta2.age)begin 
                    line=0;
                    if(meta1.valid==VALID)begin
                        dirty_nxt=meta1.dirty;
                        valid_nxt=VALID;
                        Tag=meta1.tag;
                    end
                    else begin
                        valid_nxt=INVALID;
                        dirty_nxt=CLEAN;
                    end
                end
                else begin 
                    line=1;
                    if(meta2.valid==VALID)begin
                        dirty_nxt=meta2.dirty;
                        valid_nxt=VALID;
                        Tag=meta2.tag;
                    end
                    else begin
                        valid_nxt=INVALID;
                        dirty_nxt=CLEAN;
                    end
                end         
            end
        end
        else if(cresp.last==1&&fetch_counter==15&&state==FETCH)begin
                hit_nxt=HIT;
            end
        else  begin
            dirty_nxt=CLEAN;
        end
    end


    //状态机：驱动state
    always_comb begin
        unique case(state)
        IDLE:begin
            //恢复初始状态
            if(cresp.last)begin
                state_nxt=INIT;
            end
            else begin
                state_nxt=IDLE;
            end
        end
        READY:begin
            if(dreq.valid)begin
                if(dreq.addr[31]==0)begin
                    state_nxt=IDLE;
                end
                else begin
                    state_nxt=INIT;
                end
            end
            else begin
                state_nxt=READY;
            end
        end
        INIT:begin
            if(dreq.valid)begin
                if(dresp.data_ok)begin
                    state_nxt=READY;
                end
                else if(hit==MISS&&valid==INVALID)begin
                    state_nxt=FETCH;
                end
                else if(hit==MISS&&valid==VALID&&dirty==CLEAN)begin
                    state_nxt=FETCH;
                end
                else if(hit==MISS&&valid==VALID&&dirty==DIRTY)begin
                    state_nxt=WRITEBACK;
                end
                else begin
                    state_nxt=INIT;
                end
            end
            else begin
                state_nxt=INIT;
            end
        end
        FETCH:begin
            if(cresp.last==1&&fetch_counter==15)begin
                state_nxt=INIT;
            end
            else begin
                state_nxt=FETCH;
            end
        end
        WRITEBACK:begin
            if(cresp.last==1)begin
                // dirty_nxt=CLEAN;
                state_nxt=FETCH;
            end
            else begin
                state_nxt=WRITEBACK;
            end
        end
        default:begin
            state_nxt=READY;
        end
        endcase
    end

    always_ff @(posedge clk)
    if (~reset) begin
        unique case (state)
        IDLE:begin

        end
        READY:begin
            state  <= state_nxt;
            dirty<=dirty_nxt;
            hit<=hit_nxt;
            valid<=valid_nxt;
            fetch_counter<=0;
            hit_counter<=0;
            writeback_counter<=0;
            meta_counter<=0;
        end
        INIT: if (dreq.valid) begin
            dirty<=dirty_nxt;
            state  <= state_nxt;
            valid<=valid_nxt;
            if(cresp.last)begin
                hit_counter<=0;
                hit<=hit_nxt;
            end
            else if(hit==MISS)begin
                hit_counter<=0;
                hit<=hit_nxt;
            end
            else if(hit==HIT)begin
                hit_counter<=hit_counter+1;
            end
            if(hit_counter==1)begin
                hit<=MISS;
            end
        end

        FETCH: if (cresp.ready) begin
            state  <= state_nxt;
            hit<=hit_nxt;
            if(fetch_counter==15)begin//也就意味着counter达到15
                fetch_counter<=0;
            end
            else begin
                fetch_counter<=fetch_counter+1;
            end
        end

        WRITEBACK: if (cresp.ready)begin
            state  <= state_nxt;
            if(cresp.last)begin
                writeback_counter<=0;
                dirty<=dirty_nxt;
            end
            else begin
                writeback_counter<=writeback_counter+1;
            end
        end
        default:begin end

        endcase
    end else begin
        //初始化(未写完)age 将meta_ram所有的valid置为1
        state <= READY;
        hit<=MISS;
        dirty<=CLEAN;
        valid<=INVALID;
        // meta_ram<=0;
        // data_ram<=0;
        meta_counter<=meta_counter+1;
    end

    //当meta hit，并且又过了一个周期，此时dresp已经准备好了
    assign dresp.data_ok=(state==IDLE&&cresp.last)?1:hit_counter==1&&hit==HIT?1:0;
    assign dresp.addr_ok=(state==IDLE&&cresp.last)?1:hit_counter==1&&hit==HIT?1:0;
    assign dresp.data=(state==IDLE&&cresp.last)?cresp.data:data_ram.rdata;

    // CBus driver
    assign creq.valid    = dreq.valid&&(state==IDLE)||(state == WRITEBACK)||(state == FETCH);
    assign creq.is_write = (state==IDLE&&dreq.strobe!=0)||state == WRITEBACK;
    assign creq.size     = state==IDLE?dreq.size:MSIZE8;
    assign creq.addr     = state==IDLE?dreq.addr: state==FETCH?{dreq.addr[63:OFFSET_BITS+3],{OFFSET_BITS{1'b0}},{3{1'b0}}} : state == WRITEBACK ?{ Tag,get_index(dreq.addr),{OFFSET_BITS{1'b0}},{3{1'b0}}} : 0;
    assign creq.strobe   = state==IDLE?dreq.strobe:state == WRITEBACK? 8'b11111111:0;
    assign creq.data     = state==IDLE?dreq.data:state == WRITEBACK?data_ram.rdata:0;//{meta1.tag[27:0],meta_ram.addr,/**/meta2.tag[31:0]==32'h00200002,meta1.tag[31:0]==32'h00200002,meta1.valid==VALID,line,/**/meta2.valid==VALID, meta1.dirty==DIRTY , meta2.dirty==DIRTY, dirty==DIRTY, /**/dirty_nxt==DIRTY,meta_ram.strobe, meta_choice.dirty==DIRTY,/**/data_ram.strobe,/**/data_ram.addr,/**/state==READY,state==FETCH,state==INIT,hit==MISS};//{{53{1'b0}},data_ram.strobe,state};
    assign creq.len      = state==IDLE?MLEN1:MLEN16;
	assign creq.burst	 = (state == WRITEBACK)||(state == FETCH)||(state==WRITEBACK)?AXI_BURST_INCR:AXI_BURST_FIXED;

    assign meta_ram.en=reset?1:(state==INIT&&dreq.valid)||(state==FETCH&&cresp.last)||(state==READY&&dreq.valid)?1:0;
    assign meta_ram.addr=reset?meta_counter:{get_index(dreq.addr),1'b0};
    assign meta_ram.strobe=reset?2'b11:(state==INIT&&hit==HIT&&dreq.valid&&dreq.strobe!=0)||(state==FETCH&&cresp.last)?(!line?2'b10:2'b01):2'b00;
    // assign meta_ram.strobe=reset?2'b11:(state==FETCH&&cresp.last&&dreq.strobe!=0)?(!line?2'b10:2'b01):((state==INIT&&dreq.valid)?2'b00:(!line?2'b10:2'b01));//(state==INIT&&dreq.valid&&hit==HIT)?(line?2'b10:2'b01):2'b00;//((state==INIT&&dreq.valid)?2'b00:(line?2'b10:2'b01));
    assign meta_ram.wdata={meta_choice,meta_choice};

    assign data_ram.en=(state==FETCH||state==WRITEBACK)?cresp.ready:(state==INIT&&hit==HIT&&dreq.valid?1:0);
    assign data_ram.addr=(state==INIT&&hit==HIT&&dreq.valid)?{get_index(dreq.addr),line,get_offset(dreq.addr)}:(state==FETCH?{get_index(dreq.addr),line,fetch_counter}:(state==WRITEBACK?{meta_ram.addr[3:1],line,writeback_counter}:0));
    assign data_ram.strobe=(state==INIT&&hit==HIT&&dreq.valid)?dreq.strobe:(state==FETCH?8'b11111111:(state==WRITEBACK?0:0));
    assign data_ram.wdata=(state==INIT&&hit==HIT&&dreq.valid)?dreq.data:(state==FETCH?cresp.data:0);

    assign meta_choice.tag=get_tag(dreq.addr);
    assign meta_choice.valid=reset?INVALID:VALID;//只要是非reset阶段，meta一定是valid
    assign meta_choice.dirty=(state==INIT&&hit==HIT&&dreq.valid&&dreq.strobe!=0)||(state==FETCH&&cresp.last&&dreq.strobe!=0)?DIRTY:CLEAN;
    assign meta_choice.age=reset?8'hff:(state==INIT&&hit==HIT&&dreq.valid&&dreq.strobe!=0)||(state==FETCH&&cresp.last)?(line?meta2.age-1:meta1.age-1):8'hff;
    //assign meta_choice.valid=reset?0:(state==FETCH&&dirty==CLEAN&&cresp.last)?1:(line==0?meta1.valid:meta2.valid);
    // assign meta_choice.dirty=reset?CLEAN:(state==FETCH&&cresp.last&&dreq.strobe!=0)?DIRTY:(line==0?meta1.dirty:meta2.dirty);//只要是写请求，meta一定为脏
    // assign meta_choice.dirty=(state==FETCH&&dirty==CLEAN&&cresp.last)?CLEAN:(line==0?meta1.dirty:meta2.dirty);

    




`else

	typedef enum u2 {
		IDLE,
		FETCH,
		READY,
		FLUSH
	} state_t /* verilator public */;

	// typedefs
    typedef union packed {
        word_t data;
        u8 [7:0] lanes;
    } view_t;

    typedef u4 offset_t;

    // registers
    state_t    state /* verilator public_flat_rd */;
    dbus_req_t req;  // dreq is saved once addr_ok is asserted.
    offset_t   offset;

    // wires
    offset_t start;
    assign start = dreq.addr[6:3];

    // the RAM
    struct packed {
        logic    en;
        strobe_t strobe;
        word_t   wdata;
    } ram;
    word_t ram_rdata;

    always_comb
    unique case (state)
    FETCH: begin
        ram.en     = 1;
        ram.strobe = 8'b11111111;
        ram.wdata  = cresp.data;
    end

    READY: begin
        ram.en     = 1;
        ram.strobe = req.strobe;
        ram.wdata  = req.data;
    end

    default: ram = '0;
    endcase

    RAM_SinglePort #(
		.ADDR_WIDTH(4),
		.DATA_WIDTH(64),
		.BYTE_WIDTH(8),
		.READ_LATENCY(0)
	) ram_inst (
        .clk(clk), .en(ram.en),
        .addr(offset),
        .strobe(ram.strobe),
        .wdata(ram.wdata),
        .rdata(ram_rdata)
    );

    // DBus driver
    assign dresp.addr_ok = state == IDLE;
    assign dresp.data_ok = state == READY;
    assign dresp.data    = ram_rdata;

    // CBus driver
    assign creq.valid    = state == FETCH || state == FLUSH;
    assign creq.is_write = state == FLUSH;
    assign creq.size     = MSIZE8;
    assign creq.addr     = req.addr;
    assign creq.strobe   = 8'b11111111;
    assign creq.data     = ram_rdata;
    assign creq.len      = MLEN16;
	assign creq.burst	 = AXI_BURST_INCR;

    // the FSM
    always_ff @(posedge clk)
    if (~reset) begin
        unique case (state)
        IDLE: if (dreq.valid) begin
            state  <= FETCH;
            req    <= dreq;
            offset <= start;
        end

        FETCH: if (cresp.ready) begin
            state  <= cresp.last ? READY : FETCH;
            offset <= offset + 1;
        end

        READY: begin
            state  <= (|req.strobe) ? FLUSH : IDLE;
        end

        FLUSH: if (cresp.ready) begin
            state  <= cresp.last ? IDLE : FLUSH;
            offset <= offset + 1;
        end

        endcase
    end else begin
        state <= IDLE;
        {req, offset} <= '0;
    end

`endif

endmodule

`endif
