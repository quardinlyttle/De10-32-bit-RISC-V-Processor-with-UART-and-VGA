# 32-bit RISC-V Processor with UART and VGA on DE10-Lite FPGA

This project implements a custom 32-bit RISC-V processor designed for educational purposes using Verilog. It interfaces with UART for dynamic instruction input and a VGA display to visualize register values in real-time. The processor was developed as part of **EECS 3216: Digital Systems Design** at York University.

**Contributors**:
- Salwan Aldhahab
- Jessica Buentipo
- Quardin Lyttle
- Karanpreet Raja

---

## Project Overview
Our objective was to deepen our understanding of CPU design and cyber-physical systems by building a functional RISC-V processor. This project answers the question, "How do processors work?" by enabling real-time interaction with a processor core through:

- **Input via UART**: Dynamic loading of 32-bit machine code instructions from an external serial device.
- **Output via VGA**: Display of register values on a VGA monitor for real-time observation of computation.

The project simulates key CPU operations, including instruction fetch, decode, execution, memory access, and write-back, with pipelining implemented for enhanced instruction throughput.

---

## Tools and Technologies
- **Quartus Prime Lite**: FPGA synthesis and design
- **ModelSim**: Simulation and timing analysis
- **Verilog HDL**: Hardware description language for module design
- **DE10-Lite FPGA**: Hardware platform
- **USB-to-UART Converter**: Serial communication with FPGA

---

## Features
- **Dynamic Instruction Loading**: Supports real-time loading of instructions through UART.
- **Pipelined Processor Design**: Implements a basic RISC-V pipeline with instruction fetch (IF), decode (ID), execute (EX), memory (MEM), and write-back (WB) stages.
- **VGA Output**: Visualizes the contents of registers on a connected monitor.
- **UART Communication**: Sends and receives data to/from external devices.

---

## Module Breakdown
| Module Name                  | Description                                          |
|------------------------------|------------------------------------------------------|
| **controlALU**               | Executes arithmetic and logic operations              |
| **dataMemory**               | Handles data storage and retrieval                    |
| **instructionDecoder**       | Decodes fetched instructions                         |
| **instructionFetch**         | Manages the program counter and fetches instructions |
| **registerFile**             | Implements general-purpose registers                  |
| **serial_comm**              | Interfaces with UART input for dynamic instruction loading |
| **pll (Quartus IP)**         | Manages clock synchronization                        |
| **ascii_to_bits_converter**  | Converts ASCII inputs for display                     |

---

## Results
- Successfully sent instructions via UART, processed them in the RISC-V core, and displayed register values on the VGA screen.
- Timing challenges were encountered and resolved during the pipelining implementation.
- A remaining issue with instruction progression required manual reset but demonstrated the overall functionality.

---

## Challenges and Lessons
1. **Instruction Loading Synchronization**: Timing mismatches between instruction memory and the program counter were resolved by flagging data comparisons.
2. **UART Reset Sensitivity**: Mismatched positive/negative edge sensitivity required careful signal coordination.
3. **Pipeline Integration**: Addressed bugs in instruction flushing that stalled instruction execution beyond the first command.

---

## Original Collaboration
This repository is a detailed documentation of my contributions and an independent presentation of our collaborative work. The original group repository can be accessed [here](https://github.com/KaranpreetRaja/Verilog-RISC-V-Processor).

---

## Future Improvements
- Fixing the instruction progression bug to allow seamless multi-instruction execution.
- Reducing VGA compile times for faster testing and iteration.

---

## How to Run
1. Open the Quartus project file: `DE10_LITE_Golden_Top.qpf`.
2. Compile the design and load it onto a DE10-Lite FPGA.
3. Connect a UART-enabled device to load instructions.
4. Observe register values on a connected VGA monitor.

For more details, explore the source files and simulations included in this repository.

---
## Supported RISC-V Instructions

### R-type

| Inst Name | Description (C) | Note |
|---|---|---|
| add | `rd = rs1 + rs2` |  |
| sub | `rd = rs1 - rs2` |  |
| xor | `rd = rs1 ^ rs2` |  |
| or  | `rd = rs1 | rs2` |  |
| and | `rd = rs1 & rs2` |  |
| sll | `rd = rs1 << rs2` |  |
| srl | `rd = rs1 >> rs2` |  |
| sra | `rd = rs1 >> rs2` | msb-extends |
| slt | `rd = (rs1 < rs2)?1:0` |  |
| sltu | `rd = (rs1 < rs2)?1:0` | zero-extends | 

### I-type

| Inst Name | Description (C) | Note |
|---|---|---|
| addi | `rd = rs1 + imm` |  |
| xori | `rd = rs1 ^ imm` |  |
| ori  | `rd = rs1 | imm` |  |
| andi | `rd = rs1 & imm` |  |
| slli | `rd = rs1 << imm[0:4]` | imm[5:11]=0x00 |
| srli | `rd = rs1 >> imm[0:4]` | imm[5:11]=0x00 |
| srai | `rd = rs1 >> imm[0:4]` | imm[5:11]=0x20, msb-extends |
| slti | `rd = (rs1 < imm)?1:0` |  |
| sltiu | `rd = (rs1 < imm)?1:0` | zero-extends |
| lb   | `rd = M[rs1+imm][0:7]` |  |
| lh   | `rd = M[rs1+imm][0:15]` |  |
| lw   | `rd = M[rs1+imm][0:31]` |  |
| lbu  | `rd = M[rs1+imm][0:7]` | zero-extends |
| lhu  | `rd = M[rs1+imm][0:15]` | zero-extends |

### S-type

| Inst Name | Description (C) | Note |
|---|---|---|
| sb   | `M[rs1+imm][0:7] = rs2[0:7]` |  |
| sh   | `M[rs1+imm][0:15] = rs2[0:15]` |  |
| sw   | `M[rs1+imm][0:31] = rs2[0:31]` |  |



