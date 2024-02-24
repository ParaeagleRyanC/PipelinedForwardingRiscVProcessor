/***************************************************************************
* 
* File: riscv_datapath_constants.sv
*
* Author: Ryan Chiang
* Date: 02/06/2023
*
* Description:
*    This .sv file contains the constants related to 
*    bit positions for various intructions.
*
****************************************************************************/

// opcode
localparam OPCODE_MSB = 6;
localparam OPCODE_LSB = 0;
localparam [6:0] R_TYPE_INSTRUCTION = 7'b0110011;
localparam [6:0] I_TYPE_INSTRUCTION = 7'b0010011;
localparam [6:0] S_TYPE_INSTRUCTION = 7'b0100011;
localparam [6:0] B_TYPE_INSTRUCTION = 7'b1100011;
localparam [6:0] LW_TYPE_INSTRUCTION = 7'b0000011;
localparam [6:0] LUI_INSTRUCTION = 7'b0110111;
localparam [6:0] JAL_INSTRUCTION = 7'b1101111;
localparam [6:0] JALR_INSTRUCTION = 7'b1100111;

// func3 for R, I, S, B
localparam RISB_FUN_THREE_MSB = 14;
localparam RISB_FUN_THREE_LSB = 12;

// rd for R, I
localparam RI_RD_MSB = 11;
localparam RI_RD_LSB = 7;

// rs1 for R, I, S, B
localparam RISB_RS_ONE_MSB = 19;
localparam RISB_RS_ONE_LSB = 15;

// rs2 for R, S, B
localparam RSB_RS_TWO_MSB = 24;
localparam RSB_RS_TWO_LSB = 20;

// LUI
localparam LUI_IMM_MSB = 31;
localparam LUI_IMM_LSB = 12;
localparam LUI_LOWER_ZEROS = 12'b0;

// JAL
localparam JAL_IMM_20 = 31;
localparam JAL_IMM_19 = 19;
localparam JAL_IMM_12 = 12;
localparam JAL_IMM_11 = 20;
localparam JAL_IMM_10 = 30;
localparam JAL_IMM_01 = 21;

// R-type
localparam R_FUN_SEVEN_MSB = 31;
localparam R_FUN_SEVEN_LSB = 25;
localparam FUNC_SEVEN_SINGLE_BIT = 30;

// I-type
localparam I_IMM_MSB = 31;
localparam I_IMM_LSB = 20;


// S-type
localparam S_LWR_IMM_MSB = 11;
localparam S_LWR_IMM_LSB = 7;
localparam S_UPR_IMM_MSB = 31;
localparam S_UPR_IMM_LSB = 25;

// B-type
localparam B_LWR_IMM_MSB = 11;
localparam B_LWR_IMM_LSB = 8;
localparam B_UPR_IMM_MSB = 30;
localparam B_UPR_IMM_LSB = 25;
localparam B_IMM_ELEVEN = 7;
localparam B_IMM_TWELVE = 31;
localparam B_IMM_ZERO = 1'b0;

// B-type funct 3
localparam[2:0] BEQ = 3'b000;
localparam[2:0] BNE = 3'b001;
localparam[2:0] BLT = 3'b100;
localparam[2:0] BGE = 3'b101;
