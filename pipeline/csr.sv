`ifndef __CSR_SV
`define __CSR_SV


`ifdef VERILATOR
`include "include/csr_pkg.sv"
`include "include/common.sv"
`include "include/pipes.sv"
`else
`endif

module csr
	import common::*;
	import pipes::*;
	import csr_pkg::*;(
	input logic clk, reset,stall_csr,stall_pc,
    input csr_input_t csr_input_rd,
    input csr_input_t csr_input_wd,
    output csr_output_t csr_output,
	output u64 pcselect_mepc,pcselect_mtvec,
    output csr_regs_t csr_reg,csr_reg_before,
    output u2 csr_mode,
    input u1 is_stall,
    output u1 make_interrupt,
    input fetch_data_t dataF_nxt,
	input decode_data_t dataD_nxt,
	input execute_data_t dataE_nxt,
	input memory_data_t dataM_nxt,
	input write_data_t dataW_nxt
);
	csr_regs_t regs, regs_nxt;
    csr_input_t csr_input;

    u2 mode;
    u2 mode_nxt;
    u64 mpec;

    // assign csr_input=csr_input_wd.valid?csr_input_wd:csr_input_rd;

	always_ff @(posedge clk) begin
		if (reset) begin
			regs <= '0;
			regs.mcause[1] <= 1'b1;
			regs.mepc[31] <= 1'b1;
            mode <= 2'b11;
		end else if(stall_csr)begin
            regs <= regs;
            mode <= mode;
        end
        else begin
			regs <= regs_nxt;
            mode <= mode_nxt;
		end
	end

	// read
	always_comb begin
		csr_output.rd = '0;
		unique case(csr_input_rd.ra)
			CSR_MIE: csr_output.rd = regs.mie;
			CSR_MIP: csr_output.rd = regs.mip;
			CSR_MTVEC: csr_output.rd = regs.mtvec;
			CSR_MSTATUS: csr_output.rd = regs.mstatus;
			CSR_MSCRATCH: csr_output.rd = regs.mscratch;
			CSR_MEPC: csr_output.rd = regs.mepc;
			CSR_MCAUSE: csr_output.rd = regs.mcause;
			CSR_MCYCLE: csr_output.rd = regs.mcycle;
			CSR_MTVAL: csr_output.rd = regs.mtval;
			default: begin
				csr_output.rd = '0;
			end
		endcase
	end

	// write
	always_comb begin
        mode_nxt = mode;
		regs_nxt = regs;
        make_interrupt=1'b0;
		regs_nxt.mcycle = regs.mcycle + 1;
		// Writeback: W stage
		if (csr_input_wd.w_valid) begin
			unique case(csr_input_wd.wa)
				CSR_MIE: regs_nxt.mie = csr_input_wd.wd;
				CSR_MIP:  regs_nxt.mip = csr_input_wd.wd;
				CSR_MTVEC: regs_nxt.mtvec = csr_input_wd.wd;
				CSR_MSTATUS: regs_nxt.mstatus = csr_input_wd.wd;
				CSR_MSCRATCH: regs_nxt.mscratch = csr_input_wd.wd;
				CSR_MEPC: regs_nxt.mepc = csr_input_wd.wd;
				CSR_MCAUSE: regs_nxt.mcause = csr_input_wd.wd;
				CSR_MCYCLE: regs_nxt.mcycle = csr_input_wd.wd;
				CSR_MTVAL: regs_nxt.mtval = csr_input_wd.wd;
				default: begin
					
				end
				
			endcase
			regs_nxt.mstatus.sd = regs_nxt.mstatus.fs != 0;
		end else if (csr_input_wd.is_mret) begin
            pcselect_mepc = regs.mepc;

			regs_nxt.mstatus.mie = regs_nxt.mstatus.mpie;
			regs_nxt.mstatus.mpie = 1'b1;
			regs_nxt.mstatus.mpp = 2'b0;
			regs_nxt.mstatus.xs = 0;
            mode_nxt=regs_nxt.mstatus.mpp;

            
		end else if (csr_input_wd.is_exception) begin
            mode_nxt=2'b11;
            pcselect_mtvec = regs.mtvec;
            regs_nxt.mepc = csr_input_wd.pc;
            regs_nxt.mstatus.mpie = regs.mstatus.mie;
            regs_nxt.mstatus.mie = 0;
            regs_nxt.mstatus.mpp = mode;
			regs_nxt.mcause[63] = 1'b0;
            unique case(csr_input_wd.exception)
                ENVIRONMENT_CALL:begin
                    // $display(mode);
                    unique case(mode)
                        2'b00:begin
                            regs_nxt.mcause[62:0]=63'd8;
                        end
                        2'b11:begin
                            regs_nxt.mcause[62:0]=63'd11;
                        end
                        default:begin
                        end
                    endcase
                end
                INSTRUCTION_MISALIGNED:begin
                    regs_nxt.mcause[62:0]=63'd0;
                end
                LOAD_MISALIGNED:begin
                    regs_nxt.mcause[62:0]=63'd4;
                end
                STORE_MISALIGNED:begin
                    regs_nxt.mcause[62:0]=63'd6;
                end
                ILLEGAL_INSTRUCTION:begin
                    regs_nxt.mcause[62:0]=63'd2;
                end
                default:begin
                end
            endcase
		end
        else if(csr_input_wd.is_interrupt && regs_nxt.mstatus.mie && stall_csr==0)begin
            if(dataW_nxt.pc!=0)begin
                mpec=dataW_nxt.pc;
            end
            else if(dataM_nxt.pc!=0)begin
                mpec=dataM_nxt.pc;
            end
            else if(dataE_nxt.pc!=0)begin
                mpec=dataE_nxt.pc;
            end
            else if(dataD_nxt.pc!=0)begin
                mpec=dataD_nxt.pc;
            end
            else if(dataF_nxt.pc!=0)begin
                mpec=dataF_nxt.pc;
            end
            unique case(csr_input_wd.m_interrupt)
                EXINT:begin
                    make_interrupt=1'b1;
                    regs_nxt.mcause[62:0]=63'd11;

                    mode_nxt=2'b11;
                    pcselect_mtvec = regs.mtvec;
                    regs_nxt.mepc = mpec;
                    regs_nxt.mstatus.mpie = regs.mstatus.mie;
                    regs_nxt.mstatus.mie = 0;
                    regs_nxt.mstatus.mpp = mode;
                    regs_nxt.mcause[63] = 1'b1;
                end
                TRINT:begin
                    if(regs_nxt.mie[7])begin
                        make_interrupt=1'b1;
                        regs_nxt.mcause[62:0]=63'd7;

                        mode_nxt=2'b11;
                        pcselect_mtvec = regs.mtvec;
                        regs_nxt.mepc = mpec;
                        regs_nxt.mstatus.mpie = regs.mstatus.mie;
                        regs_nxt.mstatus.mie = 0;
                        regs_nxt.mstatus.mpp = mode;
                        regs_nxt.mcause[63] = 1'b1;
                    end
                end
                SWINT:begin
                    if(regs_nxt.mie[3])begin
                        make_interrupt=1'b1;
                        regs_nxt.mcause[62:0]=63'd3;

                        mode_nxt=2'b11;
                        pcselect_mtvec = regs.mtvec;
                        regs_nxt.mepc = mpec;
                        regs_nxt.mstatus.mpie = regs.mstatus.mie;
                        regs_nxt.mstatus.mie = 0;
                        regs_nxt.mstatus.mpp = mode;
                        regs_nxt.mcause[63] = 1'b1;
                    end
                end
                default:begin
                end
            endcase
        end
		else begin end
	end

	assign csr_reg = regs_nxt;
    assign csr_reg_before = regs;
    assign csr_mode = mode_nxt;
	
endmodule

`endif