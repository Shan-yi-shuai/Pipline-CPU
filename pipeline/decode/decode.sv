`ifndef __DECODE_SV
`define __DECODE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/csr_pkg.sv"
`include "pipeline/decode/decoder.sv"
`else

`endif 

module decode
    import common::*;
    import pipes::*;
    import csr_pkg::*;(
    input fetch_data_t dataF,
    output decode_data_t dataD,

    output creg_addr_t ra1,ra2,
    input word_t rd1,rd2,

    output csr_input_t csr_input,
    input csr_output_t csr_output
    );
    control_t ctl;
    u1 is_exception;

    decoder decoder(
        .raw_instr(dataF.raw_instr),
        .ctl(ctl),
        .is_exception
    );
    
    always_comb begin

        if(dataF.is_exception)begin
            ctl.is_exception=dataF.is_exception;
            ctl.exception=dataF.exception;
        end
        if(is_exception && dataF.raw_instr!=0)begin
            ctl.is_exception=1'b1;
            ctl.exception=ILLEGAL_INSTRUCTION;
        end
        dataD.ctl=ctl;
    end
    assign ra1=dataF.raw_instr[19:15];
    assign ra2=dataF.raw_instr[24:20];
    assign dataD.srca=rd1;
    assign dataD.srcb=rd2;
    // assign dataD.ctl=ctl;
    assign dataD.dst=dataF.raw_instr[11:7];
    assign dataD.pc=dataF.pc;
    assign dataD.raw_instr=dataF.raw_instr;
    assign dataD.valid=dataF.valid;
    assign dataD.csr_data=csr_output.rd;

    assign csr_input.valid=ctl.csr==0?0:1'b1;
    assign csr_input.w_valid=0;
    assign csr_input.ra=ctl.csr;

endmodule

`endif 