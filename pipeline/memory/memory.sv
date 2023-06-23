`ifndef __MEMORY_SV
`define __MEMORY_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/memory/writedata.sv"
`include "pipeline/memory/readdata.sv"
`else

`endif 

module memory
    import common::*;
    import pipes::*;(
       input execute_data_t dataE,
       output memory_data_t dataM,
       
       output dbus_req_t dreq,
       input  dbus_resp_t dresp
    );

    u64 rd;
    u8 strobe;
    control_t ctl;

    always_comb begin
        ctl=dataE.ctl;
        unique case(dataE.ctl.msize)
        MSIZE1:begin
            dreq.valid=dataE.ctl.memwrite||dataE.ctl.memread;
        end
        MSIZE2:begin
            if(dataE.result[0]==1'b1)begin
                ctl.is_exception=1'b1;
                ctl.exception=dataE.ctl.memwrite?STORE_MISALIGNED:dataE.ctl.memread?LOAD_MISALIGNED:NONE;
                dreq.valid=0;
            end
            else begin
                dreq.valid=dataE.ctl.memwrite||dataE.ctl.memread;
            end
        end
        MSIZE4:begin
            if(dataE.result[1:0]!=0)begin
                ctl.is_exception=1'b1;
                ctl.exception=dataE.ctl.memwrite?STORE_MISALIGNED:dataE.ctl.memread?LOAD_MISALIGNED:NONE;
                dreq.valid=0;
            end
            else begin
                dreq.valid=dataE.ctl.memwrite||dataE.ctl.memread;
            end
        end
        MSIZE8:begin
            if(dataE.result[2:0]!=0)begin
                ctl.is_exception=1'b1;
                ctl.exception=dataE.ctl.memwrite?STORE_MISALIGNED:dataE.ctl.memread?LOAD_MISALIGNED:NONE;
                dreq.valid=0;
            end
            else begin
                dreq.valid=dataE.ctl.memwrite||dataE.ctl.memread;
            end
        end
        default begin
            dreq.valid=0;
        end
        endcase
    end

    // assign dreq.valid=dataE.ctl.memwrite||dataE.ctl.memread;
    assign dreq.addr=dataE.result;
    assign dreq.size=dataE.ctl.msize;
    assign dreq.strobe=dataE.ctl.memread?0:strobe;
    // assign dreq.data=dataE.memwrite_data;

    writedata writedata(
        .addr(dataE.result[2:0]),
        ._wd(dataE.memwrite_data),
        .msize(dataE.ctl.msize),
        .wd(dreq.data),
        .strobe(strobe)
    );
    
    readdata readdata(
        ._rd(dresp.data),
        .rd(rd),
        .addr(dataE.result[2:0]),
        .msize(dataE.ctl.msize),
        .mem_unsigned(dataE.ctl.mem_unsigned)
    );
    
    //dataM
    assign dataM.ctl=ctl;
    assign dataM.dst=dataE.dst;
    assign dataM.pc=dataE.pc;
    assign dataM.valid=dataE.valid;
    assign dataM.skip=((dataE.ctl.memwrite||dataE.ctl.memread)&&(dataE.result[31]==0))?1'b1:1'b0;
    assign dataM.csr_data=dataE.csr_data;

    always_comb begin
        if(dataE.ctl.memwrite)begin
            dataM.wd=0;
        end
        else if(dataE.ctl.memread&&dataE.ctl.regwrite)begin
            dataM.wd=rd;
        end
        else begin
            dataM.wd=dataE.result;
        end
    end




    
endmodule

`endif 