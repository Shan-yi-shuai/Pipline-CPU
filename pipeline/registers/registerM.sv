`ifndef __REGISTERM_SV
`define __REGISTERM_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif 

module registerM
    import common::*;
    import pipes::*;(
       input logic clk, reset,
       input u1 reset_M,
       input u1 stall_M,
       input memory_data_t dataM_nxt,
       output memory_data_t dataM
    );

    always_ff @(posedge clk ) begin 
		if(reset) begin
			dataM<=0;
		end 
      else if(reset_M)begin 
         dataM<=0;
      end 
      else if(stall_M)begin 
         dataM<=dataM;
      end
      else begin
			dataM<=dataM_nxt;
		end
	end
    
endmodule

`endif 