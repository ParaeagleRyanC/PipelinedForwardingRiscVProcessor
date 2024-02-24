`timescale 1ns / 1ps
/***************************************************************************
* 
* File: riscv_final.sv
*
* Author: Ryan Chiang
* Class: ECEN 323, Winter Semester 2023
* Date: 03/27/2023
*
* Module: riscv_final
*
* Description:
*    This .sv file implements a pipelined version of the processor,
*	 with forwarding in place and takes care of various hazards.
*    regfile and alu modules are used in this top module.
*	 This version of the processor is modified to support
*	 a few more instructions. They are LUI, BNE, BLT, BGE, JAL, JALR.
*
****************************************************************************/


module riscv_final #(parameter INITIAL_PC = 32'h00400000)
             (clk, rst, PC, iMemRead, instruction, ALUResult, dAddress,
             dWriteData, dReadData, MemRead, MemWrite, WriteBackData);

    `include "riscv_datapath_constants.sv"
    `include "riscv_alu_constants.sv"
    
    ///////////////////////////////////////////////////////////////
    // Inputs and Outputs
    ///////////////////////////////////////////////////////////////
    
    // 1-bit input signals for Global Clock and Synchronous Reset
    input wire logic clk, rst;
	// 32-bit input for Instruction received from instruction memory
	input wire logic [31:0] instruction;
    // 32-bit input for Value of the read data in the WB stage
	input wire logic [31:0] dReadData;
	
	// 32-bit output signal for Program Counter in IF stage
	output logic [31:0] PC;
	// 32-bit output signal for Output of (EX stage)
	output logic [31:0] ALUResult;
	// 32-bit output for the Value of the data address in the MEM stage
	output logic [31:0] dAddress;
	// 32-bit output for the Value of the write data in the MEM stage
	output logic [31:0] dWriteData;
	// 32-bit output for Data to be written to register (WB stage)
	output logic [31:0] WriteBackData;
	// 1-bit output Control signal indicating memory read and write
	output logic MemRead, MemWrite;
	// 1-bit output Control signal indicating the enabling of instruction memory reading
	output logic iMemRead;
	
	
	///////////////////////////////////////////////////////////////
    // IF: Instruction Fetch
    ///////////////////////////////////////////////////////////////
    
	// 32-bit signal for Program Counter in IF, ID, EX stages
	logic [31:0] if_PC, id_PC, ex_PC;
    
    localparam NEXT_INSTRUCTION_OFFSET = 4;
    
    // 32-bit value of branch target (computed in the MEM stage)
    logic [31:0] ex_branchTarget, mem_branchTarget;
	// 1-bit logic indicating either a PC+4 or a branch target
	logic mem_PCSrc, wb_PCSrc;
	
	///////////////////////////////////////////////////////////////
    // ID: Instruction Decode
    ///////////////////////////////////////////////////////////////
	
	// The following control signals are determined in the ID stage 
	// and pipelined for use in later pipeline stages
	logic [3:0] id_ALUCtrl, ex_ALUCtrl;
	logic id_ALUSrc, ex_ALUSrc;
	logic id_MemWrite, ex_MemWrite, mem_MemWrite;
	logic id_MemRead, ex_MemRead, mem_MemRead;
	logic id_branch, ex_branch, mem_branch, wb_branch;
	logic id_jalr, ex_jalr; // added for lab11
	logic id_jump, ex_jump, mem_jump; // added for lab11
	logic id_RegWrite, ex_RegWrite, mem_RegWrite, wb_RegWrite;
	logic id_MemtoReg, ex_MemtoReg, mem_MemtoReg, wb_MemtoReg;
	
	////////////////////////
	// 1. Decode Instruction
	
	// funct3
    logic [2:0] func_three;
    assign func_three = instruction[RISB_FUN_THREE_MSB:RISB_FUN_THREE_LSB];
    // funct7
    logic func_seven;
    assign func_seven = instruction[FUNC_SEVEN_SINGLE_BIT];
	// id stage opcode
    logic [6:0] id_opcode;
    assign id_opcode = instruction[OPCODE_MSB:OPCODE_LSB];
    // logic to keep track of branch types
    logic [2:0] id_branch_type, ex_branch_type, mem_branch_type;
    assign id_branch_type = instruction[RISB_FUN_THREE_MSB:RISB_FUN_THREE_LSB];
    
    localparam FUNCT_ADD = 1'b0;
    localparam FUNCT_SUB = 1'b1;
    localparam FUNCT_SRL = 1'b0;
    localparam FUNCT_SRA = 1'b1;
	
	// This always_comb sets various control signals based on the decoded opcode
	// that will be used in later stages
	always_comb begin
	   // Go to the appropriate case based on the opcode
	   case(id_opcode)
	       R_TYPE_INSTRUCTION: 
	           begin
	               id_MemtoReg = 0;
                   id_ALUSrc = 0;
                   id_branch = 0;
                   id_jalr = 0;
                   id_jump = 0; 
                   id_MemWrite = 0;
                   id_MemRead = 0;
                   id_RegWrite = 1;
	               // Assign ALUCtrl based on funct 3 and funct 7
	               case(func_three)
	                   FUNCT_3_ADD_SUB:
                           begin
                               case(func_seven)
                                   FUNCT_ADD: id_ALUCtrl = ALUOP_ADDITION;
                                   FUNCT_SUB: id_ALUCtrl = ALUOP_SUBTRACTION;
                                   default: id_ALUCtrl = ALUOP_ADDITION;
                               endcase
                           end
                       FUNCT_3_SLT: id_ALUCtrl = ALUOP_LESS_THAN;
                       FUNCT_3_SLTU: id_ALUCtrl = ALUOP_LESS_THAN;
                       FUNCT_3_XOR: id_ALUCtrl = ALUOP_XOR;
                       FUNCT_3_OR: id_ALUCtrl = ALUOP_OR;
                       FUNCT_3_AND: id_ALUCtrl = ALUOP_AND;
                       FUNCT_3_SLL: id_ALUCtrl = ALUOP_SLL;
                       FUNCT_3_SRL_SRA:
                           begin
                               case(func_seven)
                                   FUNCT_SRL: id_ALUCtrl = ALUOP_SRL;
                                   FUNCT_SRA: id_ALUCtrl = ALUOP_SRA;
                                   default: id_ALUCtrl = ALUOP_SRL;
                               endcase
                           end
	                   default: id_ALUCtrl = ALUOP_ADDITION;
	               endcase
	           end
	       I_TYPE_INSTRUCTION: 
	           begin
                   id_ALUSrc = 1;
                   id_MemtoReg = 0;
                   id_branch = 0;
                   id_jalr = 0; 
                   id_jump = 0; 
                   id_MemWrite = 0;
                   id_MemRead = 0;
                   id_RegWrite = 1;
                   // Assign ALUCtrl based on funct 3 and funct 7
	               case(func_three)
	                   FUNCT_3_ADD_SUB: id_ALUCtrl = ALUOP_ADDITION;
                       FUNCT_3_SLT: id_ALUCtrl = ALUOP_LESS_THAN;
                       FUNCT_3_SLTU: id_ALUCtrl = ALUOP_LESS_THAN;
                       FUNCT_3_XOR: id_ALUCtrl = ALUOP_XOR;
                       FUNCT_3_OR: id_ALUCtrl = ALUOP_OR;
                       FUNCT_3_AND: id_ALUCtrl = ALUOP_AND;
                       FUNCT_3_SLL: id_ALUCtrl = ALUOP_SLL;
                       FUNCT_3_SRL_SRA:
                           begin
                               case(func_seven)
                                   FUNCT_SRL: id_ALUCtrl = ALUOP_SRL;
                                   FUNCT_SRA: id_ALUCtrl = ALUOP_SRA;
                                   default: id_ALUCtrl = ALUOP_SRL;
                               endcase
                           end
	                   default: id_ALUCtrl = ALUOP_ADDITION;
	               endcase
	           end
	       LW_TYPE_INSTRUCTION:
	           begin
                   id_ALUSrc = 1;
                   id_ALUCtrl = ALUOP_ADDITION;
                   id_MemtoReg = 1;
                   id_branch = 0;
                   id_jalr = 0;
                   id_jump = 0;
                   id_MemWrite = 0;
                   id_MemRead = 1;
                   id_RegWrite = 1;
	           end
	       S_TYPE_INSTRUCTION:
	           begin
                   id_ALUSrc = 1;
                   id_ALUCtrl = ALUOP_ADDITION;
                   id_MemtoReg = 0;
                   id_branch = 0;
                   id_jalr = 0; 
                   id_jump = 0;
                   id_MemWrite = 1;
                   id_MemRead = 0;
                   id_RegWrite = 0;
	           end
	       B_TYPE_INSTRUCTION:
	           begin
                   id_ALUSrc = 0;
                   id_ALUCtrl = ALUOP_SUBTRACTION;
                   id_MemtoReg = 0;
                   id_branch = 1;
                   id_jalr = 0;
                   id_jump = 0;
                   id_MemWrite = 0;
                   id_MemRead = 0;
                   id_RegWrite = 0;
	           end
	       LUI_INSTRUCTION:
	           begin
	               id_ALUSrc = 1;
                   id_ALUCtrl = ALUOP_ADDITION;
                   id_MemtoReg = 0;
                   id_branch = 0;
                   id_jalr = 0; 
                   id_jump = 0;
                   id_MemWrite = 0;
                   id_MemRead = 0;
                   id_RegWrite = 1;
	           end
	       JAL_INSTRUCTION: 
	           begin
	               id_ALUSrc = 0;
                   id_ALUCtrl = ALUOP_ADDITION;
                   id_MemtoReg = 0;
                   id_branch = 0;
                   id_jalr = 0;
                   id_jump = 1; 
                   id_MemWrite = 0;
                   id_MemRead = 0;
                   id_RegWrite = 1;
	           end
	       JALR_INSTRUCTION:
	           begin
	               id_ALUSrc = 0;
                   id_ALUCtrl = ALUOP_ADDITION;
                   id_MemtoReg = 0;
                   id_branch = 0;
                   id_jalr = 1;
                   id_jump = 1; 
                   id_MemWrite = 0;
                   id_MemRead = 0;
                   id_RegWrite = 1;
	           end
	       default: 
	           begin
	               id_ALUSrc = 0;
	               id_MemtoReg = 0;
	               id_ALUCtrl = ALUOP_AND;
                   id_branch = 0;
                   id_jalr = 0;
                   id_jump = 0;
                   id_MemWrite = 0;
                   id_MemRead = 0;
                   id_RegWrite = 0;
	           end
	   endcase
	end
	
	//////////////////////////
	// 2. Immediate Generation
	
    // I-type
	logic [31:0] i_imm;
    assign i_imm = $signed(instruction[I_IMM_MSB:I_IMM_LSB]);
    // S-type
    logic [31:0] s_imm;
    assign s_imm = $signed({{instruction[S_UPR_IMM_MSB:S_UPR_IMM_LSB]}
                        ,{instruction[S_LWR_IMM_MSB:S_LWR_IMM_LSB]}});
    // B-type
    logic [31:0] b_imm;
    assign b_imm = $signed({{{{instruction[B_IMM_TWELVE],instruction[B_IMM_ELEVEN]},
                            instruction[B_UPR_IMM_MSB:B_UPR_IMM_LSB]},
                            instruction[B_LWR_IMM_MSB:B_LWR_IMM_LSB]},B_IMM_ZERO});
                         
    // LUI 
    logic [31:0] lui_imm;
    assign lui_imm = $signed({instruction[LUI_IMM_MSB:LUI_IMM_LSB], LUI_LOWER_ZEROS});
                            
    // JAL 
    logic [31:0] jal_imm;
    assign jal_imm = $signed({{{{instruction[JAL_IMM_20],
                            instruction[JAL_IMM_19:JAL_IMM_12]},
                            instruction[JAL_IMM_11]},
                            instruction[JAL_IMM_10:JAL_IMM_01]},
                            B_IMM_ZERO});
                            
    // JALR
    logic [31:0] jalr_imm;
    assign jalr_imm = $signed(instruction[I_IMM_MSB:I_IMM_LSB]);
    
                            
    // immediate value for id and ex stages
	logic [31:0] id_imm, ex_imm;
	
	// This always_comb sets id_imm based on the decoded opcode
	always_comb begin
	   // Go to the appropriate case based on the opcode
	   case(id_opcode)
	       I_TYPE_INSTRUCTION: id_imm = i_imm;
	       S_TYPE_INSTRUCTION: id_imm = s_imm;
	       B_TYPE_INSTRUCTION: id_imm = b_imm;
	       LUI_INSTRUCTION: id_imm = lui_imm; 
	       JAL_INSTRUCTION: id_imm = jal_imm; 
	       JALR_INSTRUCTION: id_imm = jalr_imm; 
	       default: id_imm = i_imm;
	   endcase
	end
	
	///////////////////
	// 3. Register File
	
	// 32-bit output of regfile, this is Data read from port 1 and port 2
	logic [31:0] regfile_readData1, regfile_readData2, mem_regfile_readData2;
	// 5-bit data input to regfile for Address for read port 1 and port 2 and write port
	logic [4:0] id_readReg1, id_readReg2, ex_readReg1, ex_readReg2;
	logic [4:0] id_writeReg, ex_writeReg, mem_writeReg, wb_writeReg;
	// 32-bit data input to regfile for Data to be written during a write
	logic [31:0] wb_writeData;
	
	localparam REGISTER_ZERO = 5'b0; 
    assign id_readReg1 = (id_opcode == LUI_INSTRUCTION) ? REGISTER_ZERO : 
                          instruction[RISB_RS_ONE_MSB:RISB_RS_ONE_LSB]; 
    assign id_readReg2 = instruction[RSB_RS_TWO_MSB:RSB_RS_TWO_LSB];
    assign id_writeReg = instruction[RI_RD_MSB:RI_RD_LSB];
    
	// Instance regfile module
	regfile pipeline_regfile(
	   .clk(clk),
	   .readReg1(id_readReg1),
	   .readReg2(id_readReg2),
	   .writeReg(wb_writeReg),
       .writeData(wb_writeData),
       .write(wb_RegWrite),
       .readData1(regfile_readData1),
       .readData2(regfile_readData2)
    );
    
    /////////////////////////
    // Hazard Detection Logic
    
    // 1-bit HAZARD DETECTION signals
    logic load_use_hazard, branch_mem_taken, branch_wb_taken;
    
    // Detects the presence of the 'load-use' hazard in the pipeline.
    assign load_use_hazard = 
        (((id_readReg1 == ex_writeReg) || (id_readReg2 == ex_writeReg)) 
        && ex_MemtoReg && !branch_mem_taken) ? 1 : 0;
    // branch_mem_taken - Detects that a branch is in the MEM stage and it is taken.
    assign branch_mem_taken = (mem_PCSrc || mem_jump) ? 1 : 0;
    
    
	///////////////////////////////////////////////////////////////
    // EX: Execute
    ///////////////////////////////////////////////////////////////
	
	////////////////////
	// 1. ALU Operations
	
	// 1-bit output of ALU indicates when the ALU Result is zero
    logic ex_alu_Zero, mem_alu_Zero;
    // 32-bit output of ALU for ALU Result
    logic [31:0] alu_result, ex_alu_result, mem_alu_result, wb_alu_result;
    // 32-bit logic for alu op2 
    logic [31:0] alu_op1, alu_op2;
    
    
    //////////////////
    // Forwarding logic
    
    logic [31:0] ex_readData2;
    
    // This always_comb checks if writeReg in mem and wb stages are used in 
    // the ex stage and assign alu_op1 and alu_op2 accordingly
    always_comb begin 
        if (mem_RegWrite && (mem_writeReg != 0) && (ex_readReg1 == mem_writeReg)) alu_op1 = mem_alu_result;
        else if (wb_RegWrite && (wb_writeReg != 0) && (ex_readReg1 == wb_writeReg)) alu_op1 = wb_writeData;
        else alu_op1 = regfile_readData1;
    
        if (ex_ALUSrc) alu_op2 = ex_imm;
        else begin 
            if (mem_RegWrite && (mem_writeReg != 0) && (ex_readReg2 == mem_writeReg)) alu_op2 = mem_alu_result;
            else if (wb_RegWrite && (wb_writeReg != 0) && (ex_readReg2 == wb_writeReg)) alu_op2 = wb_writeData;
            else alu_op2 = regfile_readData2;
        end
        
        if (mem_RegWrite && (mem_writeReg != 0) && (ex_readReg2 == mem_writeReg)) ex_readData2 = mem_alu_result;
        else if (wb_RegWrite && (wb_writeReg != 0) && (ex_readReg2 == wb_writeReg)) ex_readData2 = wb_writeData;
        else ex_readData2 = regfile_readData2;
    end
	
	// Instance alu module
	alu pipeline_alu(
	   .op1(alu_op1),
	   .op2(alu_op2),
	   .alu_op(ex_ALUCtrl),
	   .result(alu_result),
	   .zero(ex_alu_Zero));
	
	///////////////////////////
	// 2. PC Target Address
	
	// 1-bit logic indicating if alu_result is negative
	logic ex_less_than, mem_less_than;
	assign ex_less_than = ex_alu_result[31];
	
    // 32-bit value for PC targets
    logic [31:0] ex_PCTarget, mem_PCTarget;
    assign ex_PCTarget = ex_jalr ? alu_op1 + ex_imm : ex_PC + ex_imm;
    
    // 32-bit value for pc + 4
    logic [31:0] ex_PC_plus_4;
    assign ex_PC_plus_4 = ex_PC + NEXT_INSTRUCTION_OFFSET;
    assign ex_alu_result = ex_jump ? ex_PC_plus_4 : alu_result;
	
        
    ///////////////////////////////////////////////////////////////
    // MEM: Memory Access
    ///////////////////////////////////////////////////////////////
   
    assign dAddress = mem_alu_result;
    assign dWriteData = mem_regfile_readData2;
  
    // This always comb determines if a branch is taken or not
    always_comb begin 
        if (mem_branch) begin
            case(mem_branch_type)
                BEQ: begin
                    if (mem_alu_Zero && !mem_less_than) mem_PCSrc = 1;
                    else mem_PCSrc = 0;
                end
                BNE: begin
                    if (mem_alu_Zero && !mem_less_than) mem_PCSrc = 0;
                    else mem_PCSrc = 1;
                end
                BLT: begin
                    if (!mem_alu_Zero && mem_less_than) mem_PCSrc = 1;
                    else mem_PCSrc = 0;
                end
                BGE: begin
                    if (!mem_alu_Zero && mem_less_than) mem_PCSrc = 0;
                    else mem_PCSrc = 1;
                end
                default: mem_PCSrc = 0;
            endcase
        end
        else mem_PCSrc = 0;
    end
	
	
	///////////////////////////////////////////////////////////////
    // WB: Write Back
    ///////////////////////////////////////////////////////////////
	
	// A multiplexer that selects the data to be written: 
	// the ALU result or the memory read based on the pipelined 'MemtoReg' control signal.
    assign wb_writeData = wb_MemtoReg ? dReadData : wb_alu_result;
    
    // This always_ff resets all pipeline registers to zero 
	// when the synchronous 'rst' is asserted.
	// Otherwise pipeline the necessary information to the next stages.
	always_ff@(posedge clk) begin
        if (rst) begin
            if_PC <= INITIAL_PC;
            id_PC <= INITIAL_PC;
            ex_PC <= INITIAL_PC;
            ex_ALUCtrl <= 0;
            ex_ALUSrc <= 0;
            ex_MemWrite <= 0;
            ex_MemRead <= 0;
            ex_branch <= 0;
            ex_RegWrite <= 0;
            ex_MemtoReg <= 0;
            ex_writeReg <= 0;
            ex_imm <= 0;
            mem_MemWrite <= 0;
            mem_MemRead <= 0;
            mem_branch <= 0;
            mem_RegWrite <= 0;
            mem_MemtoReg <= 0;
            mem_alu_Zero <= 0;
            mem_alu_result <= 0;
            mem_regfile_readData2 <= 0;
            mem_writeReg <= 0;
            wb_RegWrite <= 0;
            wb_MemtoReg <= 0;
            wb_alu_result <= 0;
            wb_writeReg <= 0;
        end
        else begin
            if (load_use_hazard) begin
                if_PC <= if_PC;
                id_PC <= id_PC;
            end
            else begin
                if (mem_PCSrc || mem_jump) if_PC <= mem_PCTarget;
                else if_PC <= if_PC + NEXT_INSTRUCTION_OFFSET;
                id_PC <= if_PC;
                
                ex_PC <= id_PC;
                ex_imm <= id_imm;
                ex_writeReg <= id_writeReg;
                ex_ALUCtrl <= id_ALUCtrl;
                ex_ALUSrc <= id_ALUSrc;
                ex_MemWrite <= id_MemWrite;
                ex_MemRead <= id_MemRead;
                ex_branch <= id_branch;
                ex_jalr <= id_jalr;
                ex_jump <= id_jump;
                ex_RegWrite <= id_RegWrite;
                ex_MemtoReg <= id_MemtoReg;
                ex_readReg1 <= id_readReg1;
                ex_readReg2 <= id_readReg2;
                ex_branch_type <= id_branch_type;
            end
            
            if (load_use_hazard || branch_mem_taken || branch_wb_taken) begin
                ex_PC <= 0;
                ex_imm <= 0;
                ex_writeReg <= 0;
                ex_ALUCtrl <= 0;
                ex_ALUSrc <= 0;
                ex_MemWrite <= 0;
                ex_MemRead <= 0;
                ex_branch <= 0;
                ex_jalr <= 0;
                ex_jump <= 0;
                ex_RegWrite <= 0;
                ex_MemtoReg <= 0;
                ex_readReg1 <= 0;
                ex_readReg2 <= 0;
            end
            
            if (branch_mem_taken) begin
                mem_alu_result <= 0;
                mem_alu_Zero <= 0;
                mem_regfile_readData2 <= 0;
                mem_writeReg <= 0;
                mem_PCTarget <= 0;
                mem_jump <= 0;
                mem_MemWrite <= 0;
                mem_MemRead <= 0;
                mem_branch <= 0;
                mem_RegWrite <= 0;
                mem_MemtoReg <= 0;
                mem_less_than <= 0;
            end
            else begin
                mem_alu_result <= ex_alu_result;
                mem_alu_Zero <= ex_alu_Zero;
                mem_regfile_readData2 <= ex_readData2;
                mem_writeReg <= ex_writeReg;
                mem_PCTarget <= ex_PCTarget;
                mem_jump <= ex_jump;
                mem_MemWrite <= ex_MemWrite;
                mem_MemRead <= ex_MemRead;
                mem_branch <= ex_branch;
                mem_RegWrite <= ex_RegWrite;
                mem_MemtoReg <= ex_MemtoReg;
                mem_less_than <= ex_less_than;
                mem_branch_type <= ex_branch_type;
            end
            
            wb_writeReg <= mem_writeReg;
            wb_alu_result <= mem_alu_result;
            wb_RegWrite <= mem_RegWrite;
            wb_MemtoReg <= mem_MemtoReg;
            branch_wb_taken <= branch_mem_taken;
        end
	end
	
	// drive the top-level ports
	assign PC = if_PC;
	assign ALUResult = ex_alu_result;
	assign WriteBackData = wb_writeData;
	assign MemRead = mem_MemRead;
	assign MemWrite = mem_MemWrite;
	assign iMemRead = load_use_hazard ? 0 : 1;
	
endmodule
