`ifndef __PIPES_SV
`define __PIPES_SV

`ifdef VERILATOR
`include "include/common.sv"
`endif 
package pipes;
	import common::*;
/* Define instrucion decoding rules here */

// parameter F7_RI = 7'bxxxxxxx;
parameter F7_ADDI =7'b0010011;//F7_XORI
parameter F7_XORI =7'b0010011;
parameter F7_LUI = 7'b0110111;
parameter F7_ADD = 7'b0110011;
parameter F7_SD = 7'b0100011;
parameter F7_LD = 7'b0000011;
parameter F7_BEQ = 7'b1100011;
parameter F7_JAL = 7'b1101111;
parameter F7_JALR = 7'b1100111;
parameter F7_AUIPC = 7'b0010111;
parameter F7_OR =7'b0110011;
parameter F7_SUB =7'b0110011;
parameter F7_AND =7'b0110011;
parameter F7_XOR =7'b0110011;

//LAB2
parameter F7_SRL =7'b0110011;
parameter F7_SH =7'b0100011;
parameter F7_ADDIW =7'b0011011;
parameter F7_SLLW =7'b0111011;
parameter F7_SUBW =7'b0111011;
parameter F7_SRAI =7'b0010011;
parameter F7_SLT =7'b0110011;
parameter F7_SRAW =7'b0111011;
parameter F7_SLTU =7'b0110011;
parameter F7_SLLI =7'b0010011;
parameter F7_SLLIW =7'b0011011;
parameter F7_BNE =7'b1100011;
parameter F7_LWU =7'b0000011;
parameter F7_SB =7'b0100011;
parameter F7_ADDW =7'b0111011;
parameter F7_SRLW =7'b0111011;
parameter F7_SLTIU =7'b0010011;
parameter F7_SW =7'b0100011;
parameter F7_SRA =7'b0110011;
parameter F7_SRLIW =7'b0011011;
parameter F7_BGEU =7'b1100011;
parameter F7_BLTU =7'b1100011;
parameter F7_LHU =7'b0000011;
parameter F7_SLTI =7'b0010011;
parameter F7_LH =7'b0000011;
parameter F7_SLL =7'b0110011;
parameter F7_LB =7'b0000011;
parameter F7_LBU =7'b0000011;
parameter F7_BGE =7'b1100011;
parameter F7_BLT =7'b1100011;
parameter F7_SRAIW =7'b0011011;
parameter F7_LW =7'b0000011;
parameter F7_SRLI =7'b0010011;

//LAB3
parameter F7_REMW =7'b0111011;
parameter F7_DIVU =7'b0110011;
parameter F7_REMUW =7'b0111011;
parameter F7_MUL =7'b0110011;
parameter F7_MULW =7'b0111011;
parameter F7_DIV =7'b0110011;
parameter F7_DIVW =7'b0111011;
parameter F7_DIVUW =7'b0111011;
parameter F7_REMU =7'b0110011;
parameter F7_REM =7'b0110011;

//LAB4
parameter F7_CSRRS =7'b1110011;
parameter F7_CSRRC =7'b1110011;
parameter F7_CSRRW =7'b1110011;
parameter F7_CSRRSi =7'b1110011;
parameter F7_CSRRCi =7'b1110011;
parameter F7_CSRRWi =7'b1110011;
parameter F7_MRET =7'b1110011;
parameter F7_ECALL =7'b1110011;

parameter F3_ADDI =3'b000;//F3_ADD
parameter F3_ADD =3'b000;
parameter F3_XORI =3'b100;
parameter F3_ORI =3'b110;
parameter F3_ANDI =3'b111;
parameter F3_SD =3'b011;
parameter F3_LD =3'b011;
parameter F3_BEQ =3'b000;
parameter F3_OR =3'b110;
parameter F3_SUB =3'b000;
parameter F3_AND =3'b111;
parameter F3_XOR =3'b100;
//LAB2
parameter F3_SRL =3'b101;
parameter F3_SH =3'b001;
parameter F3_ADDIW =3'b000;
parameter F3_SLLW =3'b001;
parameter F3_SUBW =3'b000;
parameter F3_SRAI =3'b101;
parameter F3_SLT =3'b010;
parameter F3_SRAW =3'b101;
parameter F3_SLTU =3'b011;
parameter F3_SLLI =3'b001;
parameter F3_SLLIW =3'b001;
parameter F3_BNE =3'b001;
parameter F3_LWU =3'b110;
parameter F3_SB =3'b000;
parameter F3_ADDW =3'b000;
parameter F3_SRLW =3'b101;
parameter F3_SLTIU =3'b011;
parameter F3_SW =3'b010;
parameter F3_SRA =3'b101;
parameter F3_SRLIW =3'b101;
parameter F3_BGEU =3'b111;
parameter F3_BLTU =3'b110;
parameter F3_LHU =3'b101;
parameter F3_SLTI =3'b010;
parameter F3_LH =3'b001;
parameter F3_SLL =3'b001;
parameter F3_LB =3'b000;
parameter F3_LBU =3'b100;
parameter F3_BGE =3'b101;
parameter F3_BLT =3'b100;
parameter F3_SRAIW =3'b101;
parameter F3_LW =3'b010;
parameter F3_SRLI =3'b101;

//LAB3
parameter F3_REMW =3'b110;
parameter F3_DIVU =3'b101;
parameter F3_REMUW =3'b111;
parameter F3_MUL =3'b000;
parameter F3_MULW =3'b000;
parameter F3_DIV =3'b100;
parameter F3_DIVW =3'b100;
parameter F3_DIVUW =3'b101;
parameter F3_REMU =3'b111;
parameter F3_REM =3'b110;

//LAB4
parameter F3_CSRRS =3'b010;
parameter F3_CSRRC =3'b011;
parameter F3_CSRRW =3'b001;
parameter F3_CSRRSI =3'b110;
parameter F3_CSRRCI =3'b111;
parameter F3_CSRRWI =3'b101;
parameter F3_MRET =3'b000;
parameter F3_ECALL =3'b000;

parameter F7_R_SUB =7'b0100000;
parameter F7_R_ADD =7'b0000000;
parameter F7_R_OR =7'b0000000;
parameter F7_R_AND =7'b0000000;
parameter F7_R_XOR =7'b0000000;
parameter F7_R_SRL =7'b0000000;
parameter F7_R_SLT =7'b0000000;
parameter F7_R_SLTU =7'b0000000;
parameter F7_R_SLLW =7'b0000000;
parameter F7_R_SUBW =7'b0100000;
parameter F7_R_SRAW =7'b0100000;
parameter F7_R_ADDW =7'b0000000;
parameter F7_R_SRLW =7'b0000000;
parameter F7_R_SRA =7'b0100000;
parameter F7_R_SLL =7'b0000000;

//LAB3
parameter F7_R_REMW =7'b0000001;
parameter F7_R_DIVU =7'b0000001;
parameter F7_R_REMUW =7'b0000001;
parameter F7_R_MUL =7'b0000001;
parameter F7_R_MULW =7'b0000001;
parameter F7_R_DIV =7'b0000001;
parameter F7_R_DIVW =7'b0000001;
parameter F7_R_DIVUW =7'b0000001;
parameter F7_R_REMU =7'b0000001;
parameter F7_R_REM =7'b0000001;

//LAB4
parameter F7_R_MRET =7'b0011000;
parameter F7_R_ECALL =7'b0000000;

parameter F6_I_ADDIW=6'b000000;
parameter F6_I_SLLIW=6'b000000;
parameter F6_I_SRLIW=6'b000000;
parameter F6_I_SRAIW=6'b010000;
parameter F6_I_SRLI=6'b000000;
parameter F6_I_SRAI=6'b010000;

/* Define pipeline structures here */



typedef enum logic [6:0] { 
	UNKNOWN,ADDI,LUI,XORI,ADD,SD,ORI,ANDI,LD,
	BEQ,JAL,AUIPC,OR,SUB,AND,XOR,JALR,SRL,SH,
	ADDIW,SLLW,SUBW,SRAI,SLT,SRAW,SLTU,SLLI,
	SLLIW,BNE,LWU,SB,ADDW,SRLW,SLTIU,SW,SRA,
	SRLIW,BGEU,BLTU,LHU,SLTI,LH,SLL,LB,LBU,BGE,
	BLT,SRAIW,LW,SRLI,REMW,DIVU,REMUW,MUL,MULW,
	DIV,DIVW,DIVUW,REMU,REM,CSRRS,CSRRC,CSRRW,
	CSRRSI,CSRRCI,CSRRWI,MRET,ECALL
} decode_op_t;

typedef enum logic [6:0] {
	ALU_NONE,ALU_ADD,ALU_XOR,ALU_OR,ALU_AND,ALU_SUB,ALU_SRL,
	ALU_ADDIW,ALU_SLLW,ALU_SUBW,ALU_SRAI,ALU_SLT,ALU_SRAW,
	ALU_SLTU,ALU_SLLI,ALU_SLLIW,ALU_ADDW,ALU_SRLW,ALU_SLTIU,
	ALU_SRA,ALU_SRLIW,ALU_SLTI,ALU_SLL,ALU_SRAIW,ALU_SRLI,
	ALU_REMW,ALU_DIVU,ALU_REMUW,ALU_MUL,ALU_MULW,ALU_DIV,
	ALU_DIVW,ALU_DIVUW,ALU_REMU,ALU_REM,ALU_CSRRC,ALU_CSRRW,
	ALU_CSRRCI,ALU_CSRRWI
} alufunc_t;
typedef enum logic [2:0]{
	I_TYPE,R_TYPE,U_TYPE,S_TYPE,B_TYPE,J_TYPE
} type_t;

typedef enum logic [2:0]{
	NONE,ENVIRONMENT_CALL,INSTRUCTION_MISALIGNED,LOAD_MISALIGNED,STORE_MISALIGNED,ILLEGAL_INSTRUCTION
} exception_t;

typedef enum logic [1:0]{
	TRINT,SWINT,EXINT
} interrupt_t;

typedef struct packed{
	decode_op_t op;
	alufunc_t alufunc;
	type_t typ;
	u1 regwrite;
	u1 memwrite;
	u1 memread;
	u1 alusrc;
	u1 branch;
	msize_t msize;
	u1 mem_unsigned;
	u12 csr;
	u1 mret;
	u1 is_exception;
	exception_t exception;
}control_t;

typedef struct packed {
	u32 raw_instr;
	u64 pc;
	u1 valid;
	u1 is_exception;
	exception_t exception;
} fetch_data_t;

typedef struct packed{
	word_t srca,srcb;
	control_t ctl;
	creg_addr_t dst;
	u64 pc;
	u32 raw_instr;
	u1 valid;
	u64 csr_data;
}decode_data_t;

typedef struct packed{
	control_t ctl;
	word_t result;
	creg_addr_t dst;
	u64 pc;
	u64 j_pc;
	word_t memwrite_data;
	u1 valid;
	u1 done;
	u64 csr_data;
}execute_data_t;

typedef struct packed{
	control_t ctl;
	word_t wd;
	creg_addr_t dst;
	u64 pc;
	u1 valid;
	u1 skip;
	u64 csr_data;
}memory_data_t;

typedef struct packed{
	control_t ctl;
	word_t wd;
	creg_addr_t dst;
	u64 pc;
	u1 valid;
	u1 skip;
	u64 csr_data; 
}write_data_t;

endpackage

`endif
