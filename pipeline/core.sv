`ifndef __CORE_SV
`define __CORE_SV
`ifdef VERILATOR
`include "include/pipes.sv"
`include "include/common.sv"
`include "include/csr_pkg.sv"
`include "pipeline/regfile/regfile.sv"
`include "pipeline/decode/decode.sv"
`include "pipeline/fetch/fetch.sv"
`include "pipeline/fetch/pcselect.sv"
`include "pipeline/execute/execute.sv"
`include "pipeline/memory/memory.sv"
`include "pipeline/write/write.sv"
`include "pipeline/registers/registerF.sv"
`include "pipeline/registers/registerD.sv"
`include "pipeline/registers/registerE.sv"
`include "pipeline/registers/registerM.sv"
`include "pipeline/registers/registerW.sv"
`include "pipeline/hazard.sv"
`include "pipeline/csr.sv"

`else

`endif

module core 
	import common::*;
	import pipes::*;
	import csr_pkg::*;(
	input logic clk, reset,
	output ibus_req_t  ireq,
	input  ibus_resp_t iresp,
	output dbus_req_t  dreq,
	input  dbus_resp_t dresp,
	input logic trint, swint, exint
);
	/* TODO: Add your pipeline here. */
	u64 pc;
	u64 pc_nxt;
	u1 stall_pc;
	u1 stall_D;
	u1 stall_E;
	u1 stall_F;
	u1 stall_M;
	u1 stall_W;
	u1 stall_csr;

	u1 reset_F;
	u1 reset_D;
	u1 reset_E;
	u1 reset_M;
	u1 reset_W;
	always_ff @(posedge clk ) begin 
		if(reset) begin
			pc<=64'h8000_0000;
		end 
		else if(stall_pc)begin 
         	pc<=pc;
      	end 
	  	else begin
			pc<=pc_nxt;
		end
	end
	
	

	// u32 raw_instr;
	// assign raw_instr=iresp.data;

	fetch_data_t dataF;
	decode_data_t dataD;
	execute_data_t dataE;
	memory_data_t dataM;
	write_data_t dataW;

	fetch_data_t dataF_nxt;
	decode_data_t dataD_nxt;
	execute_data_t dataE_nxt;
	memory_data_t dataM_nxt;
	write_data_t dataW_nxt;

	creg_addr_t ra1,ra2;
	word_t rd1,rd2;

	csr_input_t csr_input;
	csr_output_t csr_output;
	u64 mepc;
	u64 mtvec;

	csr_regs_t csr_reg,csr_reg_before;
	csr_input_t csr_input_rd;
	csr_input_t csr_input_wd;
	u2 mode;
	u1 is_stall;
	u1 make_interrupt;

	csr csr(
		.clk,
		.reset,
		.stall_csr,
		.stall_pc,
		.csr_input_rd,
		.csr_input_wd,
		.csr_output,
		.pcselect_mepc(mepc),
		.pcselect_mtvec(mtvec),
		.csr_reg,
		.csr_reg_before,
		.csr_mode(mode),
		.is_stall,
		.make_interrupt,
		.dataF_nxt,
		.dataD_nxt,
		.dataE_nxt,
		.dataM_nxt,
		.dataW_nxt
	);

	hazard hazard(
		.dataD,
		.dataE,
		.dataE_nxt,
		.dataM,
		.dataW,
		.ra1,
		.ra2,
		.pc,
		.pc_nxt,
		.stall_pc,
		.stall_D,
		.stall_E,
		.stall_F,
		.stall_M,
		.stall_W,
		.stall_csr,
		.reset_F,
		.reset_D,
		.reset_E,
		.reset_M,
		.reset_W,
		.iresp,
		.dresp,
		.ireq,
		.dreq,
		.is_stall,
		.trint,
		.exint,
		.swint,
		.csr_reg(csr_reg_before)
	);

	pcselect pcselect(
		.pc(pc),
		.pc_selected(pc_nxt),
		.dataE,
		.dataM,
		.mepc,
		.mtvec,
		.make_interrupt
	);

	fetch fetch(
		.dataF(dataF_nxt),
		.pc(pc),
		.iresp,
		.ireq
	);

	registerF registerF(
		.clk,
		.reset,
		.reset_F,
		.stall_F,
		.dataF_nxt,
		.dataF
	);

	decode decode(
		.dataF,
		.dataD(dataD_nxt),
		.ra1,
		.ra2,
		.rd1,
		.rd2,
		.csr_input(csr_input_rd),
		.csr_output
	);
	
	registerD registerD(
		.clk,
		.reset,
		.reset_D,
		.stall_D,
		.dataD_nxt,
		.dataD
	);

	execute execute(
		.clk,
		.dataD,
		.dataE(dataE_nxt)
	);
	// word_t result;
	// assign result=rd1+{{52{raw_instr[31]}},raw_instr[31:20]};
	
	registerE registerE(
		.clk,
		.reset,
		.reset_E,
		.stall_E,
		.dataE_nxt,
		.dataE
	);

	memory memory(
		.dataE,
		.dataM(dataM_nxt),
		.dreq,
		.dresp
	);
	
	registerM registerM(
		.clk,
		.reset,
		.reset_M,
		.stall_M,
		.dataM_nxt,
		.dataM
	);

	write write(
		.dataM,
		.dataW(dataW_nxt),
		.csr_input(csr_input_wd),
		.exint,
		.trint,
		.swint
	);

	registerW registerW(
		.clk,
		.reset,
		.reset_W,
		.stall_W,
		.dataW_nxt,
		.dataW
	);

	regfile regfile(
		.clk, .reset,
		.ra1,
		.ra2,
		.rd1,
		.rd2,
		.wvalid(dataW.ctl.regwrite),
		.wa(dataW.dst),
		.wd(dataW.wd)
	);

`ifdef VERILATOR
	DifftestInstrCommit DifftestInstrCommit(
		.clock              (clk),
		.coreid             (0),
		.index              (0),
		.valid              (dataW.valid),//有指令执行完成
		.pc                 (dataW.pc),//
		.instr              (0),
		.skip               (dataW.skip),
		.isRVC              (0),
		.scFailed           (0),
		.wen                (dataW.ctl.regwrite),//
		.wdest              ({3'b0,dataW.dst}),
		.wdata              (dataW.wd)
	);
	      
	DifftestArchIntRegState DifftestArchIntRegState (
		.clock              (clk),
		.coreid             (0),
		.gpr_0              (regfile.regs_nxt[0]),
		.gpr_1              (regfile.regs_nxt[1]),
		.gpr_2              (regfile.regs_nxt[2]),
		.gpr_3              (regfile.regs_nxt[3]),
		.gpr_4              (regfile.regs_nxt[4]),
		.gpr_5              (regfile.regs_nxt[5]),
		.gpr_6              (regfile.regs_nxt[6]),
		.gpr_7              (regfile.regs_nxt[7]),
		.gpr_8              (regfile.regs_nxt[8]),
		.gpr_9              (regfile.regs_nxt[9]),
		.gpr_10             (regfile.regs_nxt[10]),
		.gpr_11             (regfile.regs_nxt[11]),
		.gpr_12             (regfile.regs_nxt[12]),
		.gpr_13             (regfile.regs_nxt[13]),
		.gpr_14             (regfile.regs_nxt[14]),
		.gpr_15             (regfile.regs_nxt[15]),
		.gpr_16             (regfile.regs_nxt[16]),
		.gpr_17             (regfile.regs_nxt[17]),
		.gpr_18             (regfile.regs_nxt[18]),
		.gpr_19             (regfile.regs_nxt[19]),
		.gpr_20             (regfile.regs_nxt[20]),
		.gpr_21             (regfile.regs_nxt[21]),
		.gpr_22             (regfile.regs_nxt[22]),
		.gpr_23             (regfile.regs_nxt[23]),
		.gpr_24             (regfile.regs_nxt[24]),
		.gpr_25             (regfile.regs_nxt[25]),
		.gpr_26             (regfile.regs_nxt[26]),
		.gpr_27             (regfile.regs_nxt[27]),
		.gpr_28             (regfile.regs_nxt[28]),
		.gpr_29             (regfile.regs_nxt[29]),
		.gpr_30             (regfile.regs_nxt[30]),
		.gpr_31             (regfile.regs_nxt[31])
	);
	      
	DifftestTrapEvent DifftestTrapEvent(
		.clock              (clk),
		.coreid             (0),
		.valid              (0),
		.code               (0),
		.pc                 (0),
		.cycleCnt           (0),
		.instrCnt           (0)
	);
	      
	DifftestCSRState DifftestCSRState(
		.clock              (clk),
		.coreid             (0),
		.priviledgeMode     (mode),
		.mstatus            (csr_reg.mstatus),
		.sstatus            (csr_reg.mstatus & 64'h800000030001e000 /* mstatus & 64'h800000030001e000 */),
		.mepc               (csr_reg.mepc),
		.sepc               (0),
		.mtval              (csr_reg.mtval),
		.stval              (0),
		.mtvec              (csr_reg.mtvec),
		.stvec              (0),
		.mcause             (csr_reg.mcause),
		.scause             (0),
		.satp               (0),
		.mip                (csr_reg.mip),
		.mie                (csr_reg.mie),
		.mscratch           (csr_reg.mscratch),
		.sscratch           (0),
		.mideleg            (0),
		.medeleg            (0)
	      );
	      
	DifftestArchFpRegState DifftestArchFpRegState(
		.clock              (clk),
		.coreid             (0),
		.fpr_0              (0),
		.fpr_1              (0),
		.fpr_2              (0),
		.fpr_3              (0),
		.fpr_4              (0),
		.fpr_5              (0),
		.fpr_6              (0),
		.fpr_7              (0),
		.fpr_8              (0),
		.fpr_9              (0),
		.fpr_10             (0),
		.fpr_11             (0),
		.fpr_12             (0),
		.fpr_13             (0),
		.fpr_14             (0),
		.fpr_15             (0),
		.fpr_16             (0),
		.fpr_17             (0),
		.fpr_18             (0),
		.fpr_19             (0),
		.fpr_20             (0),
		.fpr_21             (0),
		.fpr_22             (0),
		.fpr_23             (0),
		.fpr_24             (0),
		.fpr_25             (0),
		.fpr_26             (0),
		.fpr_27             (0),
		.fpr_28             (0),
		.fpr_29             (0),
		.fpr_30             (0),
		.fpr_31             (0)
	);
	
`endif
endmodule
`endif