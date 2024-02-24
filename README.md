# Pipelined Forwarding RISC-V Processor

This program, **RISC-V Processor**, is the final product of several layers of work. Including **Datapath**, **Control**, **I/O System**, **Pipelining**, and **Forwarding**. 

Various hazards are properly detected and handled in order to ensure a successful processor.
* `Load-Use` Hazard -- occurs when a load instruction is followed by an instruction that needs the result of the memory load
* `Control` Hazards -- hazards that change the program counter (PC)
* `Load-Use/Branching` Hazard -- occurs when a ‘load-use’ stall occurs in the pipeline at the same time that a branch is taken

The processor utilizes the ALU (Arithmetic Logic Unit) and RegisterFile modules. 

A game is designed and implemented in `Assembly Language` to highlight the functionalities of the processor, and is to be run on an FPGA board with a VGA output.

This is a **5-stage** processor, with the stages being:
1. Fetch
2. Decode
3. Execute
4. Memory
5. Write Back

This processor follows the `RISC-V Instruction Set Manual` and supports basics instructions.
* Register-Register: add, sub, and, or, xor, slt, sll, srl, sra
* ALU Immediate: addi, andi, ori, xori, slti, slli, srli, srai, lui
* Memory: lw, sw
* Branch: beq, bne, blt, bge
* Jump: jal, jalr


This program demonstrates the knowledge and the ability to
* Implement low-level RISC-V datapath in SystemVerilog
* Implement a multi-cycle control unit for the RISC-V datapath in SystemVerilog
* Complete full synthesis and implementation of processor
* Create assembly language programs that run on your RISC-V processor
* Generate a bitstream that could be downloaded onto the FPGA
* Create a pipelined version of your single-cycle RISC-V processor
* Know the effects of instruction hazards and how to insert `NOP` instructions to prevent hazards
* Implement forwarding in your pipelined processor and verify its functionality
* Implement jump instructions
