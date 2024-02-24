`timescale 1ns / 1ps
/***************************************************************************
* 
* File: alu.sv
*
* Author: Ryan Chiang
* Date: 01/17/2023
*
* Module: alu
*
* Description:
*    This .sv file contains a ALU module which performs various operations 
*    on two operands.
*
****************************************************************************/


module alu(op1, op2, alu_op, zero, result);
    
    `include "riscv_alu_constants.sv"

    // 32-bit inputs for Operand 1 and Operand 2
    input wire logic [31:0] op1, op2;
    // 4-bit input indicates which operation to perform
    input wire logic [3:0] alu_op;
    // 1-bit output indicates when the ALU Result is zero
    output logic zero;
    // 32-bit output for ALU Result
    output logic [31:0] result;
    
    // 9 different cases of ALU operations
    always_comb begin
        case(alu_op)
            ALUOP_AND:
                result = op1 & op2;
            ALUOP_OR:
                result = op1 | op2;
            ALUOP_ADDITION:
                result = op1 + op2;
            ALUOP_SUBTRACTION:
                result = op1 - op2;
            ALUOP_LESS_THAN:
                result = $signed(op1) < $signed(op2);
            ALUOP_SRL:
                result = op1 >> op2[4:0];
            ALUOP_SLL:
                result = op1 << op2[4:0];
            ALUOP_SRA:
                result = $unsigned($signed(op1) >>> op2[4:0]);
            ALUOP_XOR:
                result = op1 ^ op2;
            default:
                result = op1 + op2;
        endcase
        
        // Set output signal to be '1' when the result of the operation is 0
        // and '0' otherwise
        if (result == 0)
            zero = 1;
        else
            zero = 0;
    end
    
endmodule
