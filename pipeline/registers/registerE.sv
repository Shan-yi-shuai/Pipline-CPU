`ifndef __REGISTERE_SV
`define __REGISTERE_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif 

module registerE
    import common::*;
    import pipes::*;(
       input logic clk, reset,
       input u1 reset_E,
       input u1 stall_E,
       input execute_data_t dataE_nxt,
       output execute_data_t dataE
    );

    always_ff @(posedge clk ) begin 
		if(reset) begin
			dataE<=0;
		end 
      else if(reset_E)begin
         dataE<=0;
      end
      else if(stall_E)begin 
         dataE<=dataE;
      end
      else begin
			dataE<=dataE_nxt;
		end
	end
    
endmodule

`endif 