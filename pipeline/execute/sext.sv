`ifndef _SEXT_SV
`define _SEXT_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else
`else

`endif 

module sext
    import common::*;
    import pipes::*;(
        input u32 raw_instr,
        input type_t typ,
        output u64 imm64
    );

    always_comb begin
        unique case(typ)
            I_TYPE:begin
                imm64={{52{raw_instr[31]}},raw_instr[31:20]};
            end
            U_TYPE:begin
                imm64={{32{raw_instr[31]}},raw_instr[31:12],{12{1'b0}}};    
            end
            S_TYPE:begin
                imm64={{52{raw_instr[31]}},raw_instr[31:25],raw_instr[11:7]};
            end
            B_TYPE:begin
                imm64={{51{raw_instr[31]}},raw_instr[31],raw_instr[7],raw_instr[30:25],raw_instr[11:8],1'b0};
            end
            J_TYPE:begin
                imm64={{43{raw_instr[31]}},raw_instr[31],raw_instr[19:12],raw_instr[20],raw_instr[30:21],1'b0};
            end
            default:begin
                imm64=0;
            end
        endcase 
    end
    
    
endmodule

`endif 