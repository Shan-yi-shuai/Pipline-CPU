`ifndef __ALU_SV
`define __ALU_SV

`ifdef VERILATOR
`include "include/common.sv"
`include "include/pipes.sv"
`include "pipeline/execute/divider.sv"
`include "pipeline/execute/multiplier.sv"
`else

`endif

module alu
	import common::*;
	import pipes::*;(
	input clk,
	input u64 a, b,
	input alufunc_t alufunc,
	output u64 c,
	output u1 done
);	

	u64 d;
	u32 e;
	u128 f;
	u6 shamt;
	u128 divide;
	u128 multy;
	u1 divide_done;
	u1 multy_done;
	u1 divide_resetn;
	u1 multy_resetn;
	u64 unsigned_a;
	u64 unsigned_b;

	assign shamt=b[5:0];
	//针对有符号乘除法，将负数转为正数
	assign unsigned_a=(alufunc==ALU_DIVW || alufunc==ALU_REMW )?(a[31]?~a+1:a):(alufunc==ALU_DIV|| alufunc==ALU_REM)?(a[63]?~a+1:a):a;
	assign unsigned_b=(alufunc==ALU_DIVW || alufunc==ALU_REMW )?(b[31]?~b+1:b):(alufunc==ALU_DIV|| alufunc==ALU_REM)?(b[63]?~b+1:b):b;

	always_comb begin
		if(alufunc==ALU_REMW||alufunc==ALU_REMUW||alufunc==ALU_DIVU||alufunc==ALU_DIV||alufunc==ALU_DIVW||alufunc==ALU_DIVUW||alufunc==ALU_REMU||alufunc==ALU_REM)begin
			done=divide_done;
			divide_resetn=1'b1;
		end
		else if(alufunc==ALU_MUL||alufunc==ALU_MULW)begin
			done=multy_done;
			multy_resetn=1'b1;
		end
		else begin
			done=1'b1;
			multy_resetn=1'b0;
			divide_resetn=1'b0;
		end
	end

	multiplier_multicycle_from_single multiplier(
		.clk,
		.resetn(multy_resetn),
		.valid(1'b1),
		.a(a),
		.b(b),
		.done(multy_done),
		.c(multy)
	);

	divider_multicycle_from_single divider(
		.clk,
		.resetn(divide_resetn),
		.valid(unsigned_b!=0),
		.a(unsigned_a),
		.b(unsigned_b),
		.done(divide_done),
		.c(divide)
	);

	always_comb begin
		c = '0;
		unique case(alufunc)
			ALU_ADD: c = a + b;
			ALU_SUB: c = a - b;
			ALU_XOR:c=a^b;
			ALU_OR:c=a|b;
			ALU_AND:c=a&b;
			ALU_SRL:c=a>>shamt;//
			ALU_ADDIW:begin
				d=a+b;
				c={{32{d[31]}},d[31:0]};
			end
			ALU_SLLW:begin
				d=a<<b[4:0];
				c={{32{d[31]}},d[31:0]};
			end
			ALU_SUBW:begin
				d=a-b;
				c={{32{d[31]}},d[31:0]};
			end
			ALU_SRAI:begin
				c=$signed(a)>>>shamt;
			end
			ALU_SLT:begin
				c=$signed(a) < $signed(b)?1:0;
			end
			ALU_SLTU:c=(a<b)?1:0;
			ALU_SLTI:c=($signed(a)<$signed(b))?1:0;
			ALU_SRAW:begin
				e=$signed(a[31:0])>>>b[4:0];
				c={{32{e[31]}},e[31:0]};
			end
			ALU_SLLI:begin
				c=a<<shamt;
			end
			ALU_SLLIW:begin
				d=a<<shamt;
				c={{32{d[31]}},d[31:0]};
			end
			ALU_SRAIW:begin
				e=$signed(a[31:0])>>>shamt;
				c={{32{e[31]}},e};
			end
			ALU_SLL:begin
				c=a<<shamt;//
			end
			ALU_ADDW:begin
				d=a+b;
				c={{32{d[31]}},d[31:0]};
			end
			ALU_SRLW:begin
				e=a[31:0]>>b[4:0];
				c={{32{e[31]}},e[31:0]};
			end
			ALU_SLTIU:begin
				c=a<b?1:0;
			end
			ALU_SRA:begin
				c=$signed(a)>>>b[5:0];
			end
			ALU_SRLIW:begin
				e=a[31:0]>>shamt;
				c={{32{e[31]}},e};
			end
			ALU_SRLI:begin
				c=a>>shamt;
			end
			ALU_REMW:begin
				if(a[31])begin
					d=~divide[127:64]+1;
				end
				else begin
					d=divide[127:64];
				end
				c={{32{d[31]}},d[31:0]};
			end
			ALU_REMUW:begin
				d=divide[127:64];
				c={{32{d[31]}},d[31:0]};
			end
			ALU_DIVU:begin
				c=divide[63:0];
			end
			ALU_DIV:begin
				if(unsigned_b==0)begin
					f=divide;
				end
				else if(a[63]&&!b[63] || !a[63]&&b[63])begin
					f=~divide+1;
				end
				else begin
					f=divide;
				end
				c=f[63:0];
			end
			ALU_MUL:begin
				c=multy[63:0];
			end
			ALU_MULW:begin
				// if(a[31]&&!b[31] || !a[31]&&b[31])begin
				// 	f=~multy+1;
				// end
				// c={{32{f[31]}},f[31:0]};
				c={{32{multy[31]}},multy[31:0]};
			end
			ALU_DIVW:begin
				if(unsigned_b==0)begin
					f=divide;
				end
				else if(a[31]&&!b[31] || !a[31]&&b[31])begin
					f=~divide+1;
				end
				else begin
					f=divide;
				end
				c={{32{f[31]}},f[31:0]};
			end
			ALU_DIVUW:begin
				c={{32{divide[31]}},divide[31:0]};
			end
			ALU_REMU:begin
				c=divide[127:64];
			end
			ALU_REM:begin
				if(a[63])begin
					d=~divide[127:64]+1;
				end
				else begin
					d=divide[127:64];
				end
				c=d;
			end
			ALU_CSRRC:begin
				c=b&~a;
			end
			ALU_CSRRW:begin
				c=a;
			end
			ALU_CSRRCI:begin
				c=a&~b;
			end
			ALU_CSRRWI:begin
				c=a;
			end
			ALU_NONE:begin
				
			end
			default: begin
			
			end
		endcase
	end
	
endmodule

`endif
