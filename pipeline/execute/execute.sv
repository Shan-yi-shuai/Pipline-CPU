`ifndef __EXECUTE_SV
`define __EXECUTE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/execute/alu.sv"
`include "pipeline/execute/sext.sv"
`else

`endif

module execute
	import common::*;
	import pipes::*;(
    input logic clk,
	input decode_data_t dataD,
	output execute_data_t dataE

);  
    word_t a,b;//什么时候用word_t，什么时候用u64
    alufunc_t alufunc;
    word_t c;
    u6 shamt;
    u1 done;
    u5 zimm;
    assign zimm=dataD.raw_instr[19:15];
	alu alu(
        .clk(clk),
        .a(a),
        .b(b),
        .alufunc(alufunc),
        .c(c),
        .done(done)
    );
    word_t imm64;
    sext sext(
        .raw_instr(dataD.raw_instr),
        .typ(dataD.ctl.typ),
        .imm64(imm64)
    );

    // assign dataE.result=(dataD.ctl.op==JAL||dataD.ctl.op==JALR)?(dataD.pc+4):c;
    always_comb begin
        if(dataD.ctl.op==JAL||dataD.ctl.op==JALR)begin
            dataE.result=dataD.pc+4;
        end
        else if(dataD.ctl.op==CSRRS||dataD.ctl.op==CSRRC||dataD.ctl.op==CSRRW||dataD.ctl.op==CSRRSI||dataD.ctl.op==CSRRCI||dataD.ctl.op==CSRRWI)begin
            dataE.result=dataD.csr_data;
        end
        else begin
            dataE.result=c;
        end
    end
    assign dataE.dst=dataD.dst;
    assign dataE.pc=dataD.pc;
    assign dataE.valid=dataD.valid;
    assign dataE.memwrite_data=dataD.srcb;
    assign dataE.done=done;
    assign dataE.csr_data=c;

    assign shamt=dataD.raw_instr[25:20];
    assign alufunc=dataD.ctl.alufunc;

    always_comb begin
        if(dataD.ctl.op==SRAI)begin
            b={{58{1'b0}},shamt};
        end
        else if(dataD.ctl.op==REMW)begin
            b={{32{dataD.srcb[31]}},dataD.srcb[31:0]};
        end
        else if(dataD.ctl.op==REMUW)begin
            b={{32{1'b0}},dataD.srcb[31:0]};
        end
        else if(dataD.ctl.op==DIVW)begin
            b={{32{dataD.srcb[31]}},dataD.srcb[31:0]};
        end
        else if(dataD.ctl.op==DIVUW)begin
            b={{32{1'b0}},dataD.srcb[31:0]};
        end
        else if(dataD.ctl.op==CSRRS||dataD.ctl.op==CSRRC||dataD.ctl.op==CSRRW)begin
            b=dataD.csr_data;
        end
        else if(dataD.ctl.op==CSRRSI||dataD.ctl.op==CSRRCI||dataD.ctl.op==CSRRWI)begin
            b={{59{1'b0}},zimm};
        end
        else if(dataD.ctl.alusrc)begin
            b=imm64;
        end
        else begin
            b=dataD.srcb;
        end
    end


    always_comb begin
        if(dataD.ctl.op==JALR)begin
            dataE.j_pc={c[63:1],1'b0};
        end
        else begin
            dataE.j_pc=c;
        end
    end
    
    always_comb begin
        if(dataD.srca==dataD.srcb&&dataD.ctl.op==BEQ)begin
            dataE.ctl=dataD.ctl;
            dataE.ctl.branch=1'b1;
        end
        else if(dataD.srca!=dataD.srcb&&dataD.ctl.op==BNE)begin
            dataE.ctl=dataD.ctl;
            dataE.ctl.branch=1'b1;
        end
        else if(dataD.srca>=dataD.srcb&&dataD.ctl.op==BGEU)begin
            dataE.ctl=dataD.ctl;
            dataE.ctl.branch=1'b1;
        end
        else if(dataD.srca<dataD.srcb&&dataD.ctl.op==BLTU)begin
            dataE.ctl=dataD.ctl;
            dataE.ctl.branch=1'b1;
        end
        else if($signed(dataD.srca)>=$signed(dataD.srcb)&&dataD.ctl.op==BGE)begin
            dataE.ctl=dataD.ctl;
            dataE.ctl.branch=1'b1;
        end
        else if($signed(dataD.srca)<$signed(dataD.srcb)&&dataD.ctl.op==BLT)begin
            dataE.ctl=dataD.ctl;
            dataE.ctl.branch=1'b1;
        end
        else begin
            dataE.ctl=dataD.ctl;
        end
    end

    always_comb begin
        unique case(dataD.ctl.op)
            ADDI:begin
                a=dataD.srca;
            end
            LUI:begin 
                a=0;
            end
            XORI:begin
                a=dataD.srca;
            end
            ORI:begin
                a=dataD.srca;
            end
            ANDI:begin
                a=dataD.srca;
            end
            ADD:begin
                a=dataD.srca;
            end
            SUB:begin
                a=dataD.srca;
            end
            AND:begin
                a=dataD.srca;
            end
            OR:begin
                a=dataD.srca;
            end
            XOR:begin
                a=dataD.srca;
            end
            SRL:begin
                a=dataD.srca;
            end
            SD:begin
                a=dataD.srca;
            end
            SH:begin
                a=dataD.srca;
            end
            SB:begin
                a=dataD.srca;
            end
            SW:begin
                a=dataD.srca;
            end
            LD:begin
                a=dataD.srca;
            end
            LB:begin
                a=dataD.srca;
            end
            LWU:begin
                a=dataD.srca;
            end
            LW:begin
                a=dataD.srca;
            end
            LHU:begin
                a=dataD.srca;
            end
            LH:begin
                a=dataD.srca;
            end
            LBU:begin
                a=dataD.srca;
            end
            BEQ:begin
                a=dataD.pc;
            end
            BNE:begin
                a=dataD.pc;
            end
            BGEU:begin
                a=dataD.pc;
            end
            BLTU:begin
                a=dataD.pc;
            end
            BGE:begin
                a=dataD.pc;
            end
            BLT:begin
                a=dataD.pc;
            end
            JAL:begin
                a=dataD.pc;
            end
            JALR:begin
                a=dataD.srca;
            end
            AUIPC:begin
                a=dataD.pc;
            end
            ADDIW:begin
                a=dataD.srca;
            end
            SRAIW:begin
                a=dataD.srca;
            end
            SLLW:begin
                a=dataD.srca;
            end
            SUBW:begin
                a=dataD.srca;
            end
            SRAI:begin
                a=dataD.srca;
            end
            SLT:begin
                a=dataD.srca;
            end
            SLTU:begin
                a=dataD.srca;
            end
            SRAW:begin
                a=dataD.srca;
            end
            SLLI:begin
                a=dataD.srca;
            end
            SLLIW:begin
                a=dataD.srca;
            end
            ADDW:begin
                a=dataD.srca;
            end
            SRLW:begin
                a=dataD.srca;
            end
            SLTIU:begin
                a=dataD.srca;
            end
            SLL:begin
                a=dataD.srca;
            end
            SLTI:begin
                a=dataD.srca;
            end
            SRLI:begin
                a=dataD.srca;
            end
            SRA:begin
                a=dataD.srca;
            end
            SRLIW:begin
                a=dataD.srca;
            end
            REMW:begin
                a={{32{dataD.srca[31]}},dataD.srca[31:0]};
            end
            REMUW:begin
                a={{32{1'b0}},dataD.srca[31:0]};
            end
            DIVU:begin
                a=dataD.srca;
            end
            DIV:begin
                a=dataD.srca;
            end
            MUL:begin
                a=dataD.srca;
            end
            MULW:begin
                a=dataD.srca;
            end
            DIVW:begin
                a={{32{dataD.srca[31]}},dataD.srca[31:0]};
            end
            DIVUW:begin
                a={{32{1'b0}},dataD.srca[31:0]};
            end
            REMU:begin
                a=dataD.srca;
            end
            REM:begin
                a=dataD.srca;
            end
            CSRRS:begin
                a=dataD.srca;
            end
            CSRRC:begin
                a=dataD.srca;
            end
            CSRRW:begin
                a=dataD.srca;
            end
            CSRRSI:begin
                a=dataD.csr_data;
            end
            CSRRCI:begin
                a=dataD.csr_data;
            end
            CSRRWI:begin
                a=dataD.csr_data;
            end
            MRET:begin
                a=dataD.srca;
            end
            ECALL:begin
                a=dataD.srca;
            end
            default:begin
                a=dataD.srca;
            end
        endcase

    end
    
   
	
endmodule

`endif