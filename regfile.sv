`timescale 1ns / 1ps
/***************************************************************************
* 
* File: regfile.sv
*
* Author: Ryan Chiang
* Class: ECEN 323, Winter Semester 2023
* Date: 01/23/2023
*
* Module: regfile
*
* Description:
*    This .sv file is an implementaion in SystemVerilog of a register file 
*    and will be used within another top-level module in this project (Lab 3)
*    and for your RISC-V processor in later labs of the course.
*
****************************************************************************/


module regfile(clk, readReg1, readReg2, writeReg, writeData, write, readData1, readData2);

    // 1-bit inputs for global clock and Control signal indicating a write
    input wire logic clk, write;
	// 5-bit data input ports for Address for read port 1 and port 2 and write port
	input wire logic [4:0] readReg1, readReg2, writeReg;
	// 32-bit data input port for Data to be written during a write
	input wire logic [31:0] writeData;
	// 32-bit Data read from port 1 and port 2
	output logic [31:0] readData1, readData2;
	
	// constants
	localparam ZERO = 'b0;
	localparam NUM_REGISTERS = 'd32;
	
	// Declare multi-dimensional logic array (32 words, 32 bits each)
    logic [31:0] register[31:0];
    
    // Initialize the 32 words
    integer index;
    initial
      for (index = ZERO; index < NUM_REGISTERS; index++)
        register[index] = ZERO;
        
    
    // This always_ff block describes the behavior of the memory
    // using a "write-first" mode (when you write to the same address 
    // that you read from, return the new write value rather than the old value).
    always_ff@(posedge clk) begin
        readData1 <= register[readReg1];
        readData2 <= register[readReg2];
        if (write && writeReg != ZERO) begin
            register[writeReg] <= writeData;
            if (readReg1 == writeReg)
                readData1 <= writeData;
            if (readReg2 == writeReg)
                readData2 <= writeData;
        end
    end
	
    
endmodule
