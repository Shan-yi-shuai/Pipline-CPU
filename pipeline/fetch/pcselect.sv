`ifndef _PCSELECT_SV
`define _PCSELECT_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else
`endif

module pcselect
  import common::*;
  import pipes::*;
(
    input u64 pc,
    output u64 pc_selected,
    input execute_data_t dataE,
    input memory_data_t dataM,
    input u64 mepc,mtvec,
    input u1 make_interrupt
);
    always_comb begin
        if(dataM.ctl.csr!=0)begin
            pc_selected=dataM.pc+4;
        end
        else if(dataM.ctl.mret)begin
            pc_selected=mepc;
        end
        else if(dataM.ctl.is_exception)begin
            pc_selected=mtvec;
        end
        else if(make_interrupt)begin
            pc_selected=mtvec;
        end
        else if(dataE.ctl.branch)begin
            pc_selected=dataE.j_pc;
        end
        else begin
            pc_selected=pc+4;
        end

    end

//   assign pc_selected = (dataE.ctl.branch) ? dataE.j_pc : pcplus4;
endmodule

`endif
