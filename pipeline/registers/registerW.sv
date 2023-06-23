`ifndef __REGISTERW_SV
`define __REGISTERW_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif 

module registerW
    import common::*;
    import pipes::*;(
       input logic clk, reset,
       input u1 reset_W,
       input u1 stall_W,
       input write_data_t dataW_nxt,
       output write_data_t dataW
    );

    always_ff @(posedge clk ) begin 
		if(reset) begin
			dataW<=0;
		end 
      else if(reset_W)begin 
         dataW<=0;
      end 
      else if(stall_W)begin 
         dataW<=dataW;
      end
      else begin
			dataW<=dataW_nxt;
		end
	end
    
endmodule

`endif 