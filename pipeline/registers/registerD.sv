`ifndef __REGISTERD_SV
`define __REGISTERD_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif 

module registerD
    import common::*;
    import pipes::*;(
       input logic clk, reset,
       input u1 reset_D,
       input u1 stall_D,
       input decode_data_t dataD_nxt,
       output decode_data_t dataD
    );

    always_ff @(posedge clk ) begin 
		if(reset) begin
			dataD<=0;
		end
      else if(reset_D)begin 
         dataD<=0;
      end 
      else if(stall_D)begin 
         dataD<=dataD;
      end
      else begin
			dataD<=dataD_nxt;
		end
	end
    
endmodule

`endif 