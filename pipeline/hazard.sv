`ifndef __HAZARD_SV
`define __HAZARD_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "include/csr_pkg.sv"
`else

`endif 

module hazard
    import common::*;
    import pipes::*;
	import csr_pkg::*;(
       input decode_data_t dataD,
       input execute_data_t dataE,dataE_nxt,
       input memory_data_t dataM,
       input write_data_t dataW,
       input creg_addr_t ra1,ra2,
       input u64 pc,pc_nxt,

       output u1 stall_pc,stall_D,stall_E,stall_F,stall_M,stall_W,stall_csr,reset_F,reset_D,reset_E,reset_M,reset_W,
	   input  ibus_resp_t iresp,
	   input  dbus_resp_t dresp,
	   input  ibus_req_t  ireq,
	   input  dbus_req_t  dreq,
	   output u1 is_stall,
	   input logic trint,exint,swint,
	   input csr_regs_t csr_reg
    );

    always_comb begin
		stall_pc=1'b0;
		stall_F=1'b0;
		stall_D=1'b0;
		stall_E=1'b0;
		stall_M=1'b0;
		stall_W=1'b0;
		stall_csr=1'b0;

		reset_F=1'b0;
		reset_D=1'b0;
		reset_E=1'b0;
		reset_M=1'b0;
		reset_W=1'b0;

		if(~iresp.data_ok&&ireq.valid)begin
			stall_pc=1'b1;
			stall_F=1'b1;

			reset_F=1'b1;
		end

		if(((dataD.dst==ra1||(dataD.dst==ra2))&&dataD.valid))begin
			stall_pc=1'b1;
			stall_F=1'b1;
			stall_D=1'b1;
			// stall_E=1'b0;
			// stall_M=1'b0;
			// stall_W=1'b0;
			//产生气泡
			reset_F=1'b0;
			reset_D=1'b1;
		end

		if(((dataE.dst==ra1||(dataE.dst==ra2))&&dataE.valid))begin
			stall_pc=1'b1;
			stall_F=1'b1;
			stall_D=1'b1;
			// stall_E=1'b0;
			// stall_M=1'b0;
			// stall_W=1'b0;

			reset_F=1'b0;
			reset_D=1'b1;
		end

		if(((dataM.dst==ra1||(dataM.dst==ra2))&&dataM.valid))begin
			stall_pc=1'b1;
			stall_F=1'b1;
			stall_D=1'b1;
			// stall_E=1'b0;
			// stall_M=1'b0;
			// stall_W=1'b0;

			reset_F=1'b0;
			reset_D=1'b1;
		end

		if(((dataW.dst==ra1||(dataW.dst==ra2))&&dataW.valid))begin
			stall_pc=1'b1;
			stall_F=1'b1;
			stall_D=1'b1;
			// stall_E=1'b0;
			// stall_M=1'b0;
			// stall_W=1'b0;

			reset_F=1'b0;
			reset_D=1'b1;
		end

		//乘法器和除法器的阻塞
		if(dataE_nxt.done==0)begin
			reset_F=1'b0;
			reset_D=1'b0;
			reset_E=1'b1;

			stall_pc=1'b1;
			stall_F=1'b1;
			stall_D=1'b1;
			stall_E=1'b1;
		end

		if(dataE.ctl.branch&&~iresp.data_ok&&ireq.valid)begin
			reset_F=1'b0;
			reset_D=1'b0;
			reset_E=1'b0;
			reset_M=1'b1;

			stall_pc=1'b1;
			stall_F=1'b1;
			stall_D=1'b1;
			stall_E=1'b1;
			stall_M=1'b1;
			// stall_W=1'b0;
		end

		//因为如果要跳转，本来数据冲突产生的阻塞，产生阻塞的指令是要被跳过的，所以没必要继续保持阻塞，直接清空就可以！
		if(dataE.ctl.branch&&iresp.data_ok&&ireq.valid)begin
			reset_F=1'b1;
			reset_D=1'b1;
			reset_E=1'b1;

			stall_pc=1'b0;
			stall_F=1'b0;
			stall_D=1'b0;
			stall_E=1'b0;
			stall_M=1'b0;
			stall_W=1'b0;
		end

		

		if(pc_nxt!=pc+4&&~iresp.data_ok&&ireq.valid)begin
			reset_F=1'b0;
			reset_D=1'b0;
			reset_E=1'b0;
			reset_M=1'b1;

			stall_pc=1'b1;
			stall_F=1'b1;
			stall_D=1'b1;
			stall_E=1'b1;
			stall_M=1'b1;
			// stall_W=1'b0;
		end

		if(pc_nxt!=pc+4&&iresp.data_ok&&ireq.valid)begin
			reset_F=1'b1;
			reset_D=1'b1;
			reset_E=1'b1;

			stall_pc=1'b0;
			stall_F=1'b0;
			stall_D=1'b0;
			stall_E=1'b0;
			stall_M=1'b0;
			stall_W=1'b0;
		end


		if(~dresp.data_ok&&dreq.valid)begin
			stall_pc=1'b1;
			stall_F=1'b1;
			stall_D=1'b1;
			stall_E=1'b1;
			stall_M=1'b1;
			
			//dbus阻塞的范围最大，所以M产生气泡，注意，流水线上只能有一个地方产生气泡！
			reset_M=1'b1;
			reset_E=1'b0;
			reset_D=1'b0;
			reset_F=1'b0;

		end


		if(iresp.data_ok&&ireq.valid&&(dataM.ctl.csr!=0 || dataM.ctl.mret || dataM.ctl.is_exception))begin
			reset_F=1'b1;
			reset_D=1'b1;
			reset_E=1'b1;
			reset_M=1'b1;

		end

		if(~iresp.data_ok&&ireq.valid&&(dataM.ctl.csr!=0 || dataM.ctl.mret || dataM.ctl.is_exception))begin
			reset_F=1'b0;
			reset_D=1'b0;
			reset_E=1'b0;
			reset_M=1'b0;
			reset_W=1'b1;

			stall_pc=1'b1;
			stall_F=1'b1;
			stall_D=1'b1;
			stall_E=1'b1;
			stall_M=1'b1;
			stall_W=1'b1;
			stall_csr=1'b1;
		end

		if(((iresp.data_ok&&ireq.valid)||(!ireq.valid))&&((dresp.data_ok&&dreq.valid)||(!dreq.valid))&&csr_reg.mstatus.mie&&((trint && csr_reg.mie[7]) || exint || (swint && csr_reg.mie[3])))begin
			reset_F=1'b1;
			reset_D=1'b1;
			reset_E=1'b1;
			reset_M=1'b1;

		end

		if(((~iresp.data_ok&&ireq.valid)||(~dresp.data_ok&&dreq.valid))&&csr_reg.mstatus.mie&&((trint && csr_reg.mie[7]) || exint || (swint && csr_reg.mie[3])))begin
			reset_F=1'b0;
			reset_D=1'b0;
			reset_E=1'b0;
			reset_M=1'b0;
			reset_W=1'b1;

			stall_pc=1'b1;
			stall_F=1'b1;
			stall_D=1'b1;
			stall_E=1'b1;
			stall_M=1'b1;
			stall_W=1'b1;
			stall_csr=1'b1;
		end
	end

	

	assign is_stall=stall_csr || stall_D || stall_E || stall_F || stall_M || stall_W || stall_pc;
endmodule

`endif 