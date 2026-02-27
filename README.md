# 🖥️ 5‑Stage Pipelined RISC‑V Processor (RV32I)

**Computer Architecture Course Project**  
**Shahid Beheshti University – Spring 2025**

---

## 📌 Overview

This repository contains a complete implementation of a **5‑stage pipelined RISC‑V processor** supporting the **RV32I base integer instruction set**. The design emphasises correct pipeline behaviour with dedicated **hazard detection**, **data forwarding**, and a **write‑back cache** for memory access.

All modules are written in **Verilog HDL** and have been tested with a Fibonacci sequence program to verify functionality.

---

## ✨ Key Features

- ✅ **5‑stage pipeline** (IF → ID → EX → MEM → WB) with inter‑stage registers
- ✅ **Hazard Detection Unit** – detects load‑use and control hazards, stalls the pipeline, and flushes instructions when necessary
- ✅ **Forwarding Unit** – resolves data hazards by forwarding results from EX/MEM and MEM/WB stages
- ✅ **Cache Controller** – direct‑mapped write‑back cache (5‑bit index, 2‑bit offset) integrated into the MEM stage
- ✅ **Full RV32I support** for R‑type, I‑type (including loads), S‑type, and B‑type instructions
- ✅ **Tested with a Fibonacci program** – result visible in register `x10`
- ✅ **Waveform generation** for in‑depth debugging (`RISC_V_TestBench.vcd`)

---

## 🧠 Pipeline Stages & Modules

### 1. **Instruction Fetch (IF)**
- `PC` – program counter with hold logic  
- `InstructionMemory` – contains the Fibonacci test program  
- `IF_ID_reg` – pipeline register with flush/hold capability  

### 2. **Instruction Decode (ID)**
- `ControlUnit_RV` – generates all control signals based on opcode  
- `RegisterFile_RV` – 32×32‑bit register file, writes on negedge (for forwarding simplicity)  
- `SignExtend_RV` – generates immediates for I/S/B‑type instructions  
- `HazardDetectionUnit_RV` – stalls and flushes on load‑use or branches  
- `Comparator` – used for branch equality check (with forwarding support)

### 3. **Execute (EX)**
- `ID_EX_reg_RV` – pipeline register between ID and EX  
- `ForwardingUnit_RV` – selects correct operands from EX/MEM or MEM/WB  
- `ALU32Bit_RV` – performs addition, subtraction, and set‑less‑than  
- `ALUControl_RV` – decodes ALUOp and funct fields into ALU control  
- `Mux` structures – for operand forwarding and ALU source selection

### 4. **Memory Access (MEM)**
- `EX_MemReg_RV` – pipeline register between EX and MEM  
- `DataMemory_RV` – top‑level memory module that instantiates:
  - `CacheController` – direct‑mapped write‑back cache (25‑bit tag, 5‑bit index, 2‑bit offset)  
  - `MainMemory` – simple behavioural memory (1024 words)

### 5. **Write Back (WB)**
- `Mem_WbReg_RV` – pipeline register between MEM and WB  
- Final write‑back mux selects either ALU result or memory read data

---

## ⚙️ Hazard Handling

| Hazard Type | Mechanism |
| :--- | :--- |
| **Data Hazard (RAW)** | Forwarding unit resolves most cases; load‑use hazard detected by Hazard Detection Unit (stall + flush). |
| **Control Hazard** | On branches, the pipeline flushes the fetched instruction and waits for branch resolution. |
| **Structural Hazard** | None – separate instruction and data memory interfaces. |

---

## 🧪 Test Program (Fibonacci)

The instruction memory is preloaded with a small program that computes the **10th Fibonacci number**. The result is stored in register `x10` and can be observed at the top‑level output `register_10_out`.

```assembly
# Initial values:
# x1 = 1, x2 = 1  (set in RegisterFile initial block)
# The program loops to compute F10
