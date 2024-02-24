/***************************************************************************
* 
* File: riscv_alu_constants.sv
*
* Author: Ryan Chiang
* Class: ECEN 323, Winter Semester 2023
* Date: 02/27/2023
*
* Module: riscv_alu_constants
*
* Description:
*    This .sv file contains the constants that are used across various modules.
*    
*
****************************************************************************/

localparam[3:0] ALUOP_AND = 4'b0000;
localparam[3:0] ALUOP_OR = 4'b0001;
localparam[3:0] ALUOP_ADDITION = 4'b0010;
localparam[3:0] ALUOP_SUBTRACTION = 4'b0110;
localparam[3:0] ALUOP_LESS_THAN = 4'b0111;
localparam[3:0] ALUOP_SRL = 4'b1000;
localparam[3:0] ALUOP_SLL = 4'b1001;
localparam[3:0] ALUOP_SRA = 4'b1010;
localparam[3:0] ALUOP_XOR = 4'b1101;

localparam[2:0] FUNCT_3_ADD_SUB = 3'b000;
localparam[2:0] FUNCT_3_SLT = 3'b010;
localparam[2:0] FUNCT_3_SLTU = 3'b011;
localparam[2:0] FUNCT_3_XOR = 3'b100;
localparam[2:0] FUNCT_3_OR = 3'b110;
localparam[2:0] FUNCT_3_AND = 3'b111;
localparam[2:0] FUNCT_3_SLL = 3'b001;
localparam[2:0] FUNCT_3_SRL_SRA = 3'b101;
localparam[6:0] FUNCT_7_ADD = 7'b0000000;
localparam[6:0] FUNCT_7_SUB = 7'b0100000;
localparam[6:0] FUNCT_7_SRL = 7'b0000000;
localparam[6:0] FUNCT_7_SRA = 7'b0100000;
localparam[2:0] FUNCT_3_BEQ = 3'b000;
