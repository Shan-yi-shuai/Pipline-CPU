`ifndef _FETCH_SV
`define _FETCH_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else
`endif 

module fetch
    import common::*;
    import pipes::*;(
        output fetch_data_t dataF,
        input u64 pc,
        input ibus_resp_t iresp,
        output ibus_req_t  ireq
    );


    assign dataF.raw_instr=iresp.data;
    assign dataF.pc=pc;
    assign dataF.valid=1'b1;
    assign dataF.is_exception=pc[1:0]!=0?1'b1:0;
    assign dataF.exception=pc[1:0]!=0?INSTRUCTION_MISALIGNED:NONE;


    assign ireq.addr=pc;
	assign ireq.valid=1'b1;

endmodule

`endif 