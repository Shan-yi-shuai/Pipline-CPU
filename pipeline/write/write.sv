`ifndef __WRITE_SV
`define __WRITE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/csr_pkg.sv"
`else

`endif 

module write
    import common::*;
    import pipes::*;
    import csr_pkg::*;(
       input memory_data_t dataM,
       output write_data_t dataW,
       output csr_input_t csr_input,
       input logic trint, swint, exint
    );

    assign dataW.wd=dataM.wd;
    assign dataW.ctl=dataM.ctl;
    assign dataW.dst=dataM.dst;
    assign dataW.pc=dataM.pc;
    assign dataW.valid=dataM.valid;
    assign dataW.skip=dataM.skip;
    assign dataW.csr_data=dataM.csr_data;

    always_comb begin
        csr_input.w_valid=1'b0;
        csr_input.valid=1'b0;
        csr_input.is_exception=1'b0;
        csr_input.is_mret=1'b0;
        csr_input.is_interrupt=1'b0;
        csr_input.exception=NONE;
        if(dataM.ctl.csr!=0)begin
            csr_input.w_valid=1'b1;
            csr_input.valid=1'b1;
            csr_input.wa=dataM.ctl.csr;
            csr_input.wd=dataM.csr_data;
        end
        else if(dataM.ctl.mret)begin
            csr_input.valid=1'b1;
            csr_input.is_mret=1'b1;
        end
        else if(dataM.ctl.is_exception)begin
            csr_input.valid=1'b1;
            csr_input.is_exception=1'b1;
            csr_input.exception=dataM.ctl.exception;
            csr_input.pc=dataM.pc;
        end
        else if(trint)begin
            csr_input.valid=1'b1;
            csr_input.is_interrupt=1'b1;
            csr_input.m_interrupt=TRINT;
            csr_input.pc=dataM.pc;
        end
        else if(swint)begin
            csr_input.valid=1'b1;
            csr_input.is_interrupt=1'b1;
            csr_input.m_interrupt=SWINT;
            csr_input.pc=dataM.pc;
        end
        else if(exint)begin
            csr_input.valid=1'b1;
            csr_input.is_interrupt=1'b1;
            csr_input.m_interrupt=EXINT;
            csr_input.pc=dataM.pc;
        end
        else begin
        end
    end
    
endmodule

`endif 