`ifndef __REGISTERF_SV
`define __REGISTERF_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`else

`endif 

module registerF
    import common::*;
    import pipes::*;(
       input logic clk, reset,
       input u1 reset_F,
       input u1 stall_F,
       input fetch_data_t dataF_nxt,
       output fetch_data_t dataF
    );

    always_ff @(posedge clk ) begin 
		if(reset) begin
			dataF<=0;
		end 
      else if(reset_F)begin
         dataF<=0;
      end
      else if(stall_F)begin 
         dataF<=dataF;
      end 
      else begin
			dataF<=dataF_nxt;
		end
	end
    
endmodule

`endif 