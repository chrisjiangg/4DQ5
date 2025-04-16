# **COMPENG 4DQ5 – Digital Systems Design**  
**McMaster University**  
**Term:** Winter 2025  
**Group:** 84  

---

## 📘 **Course Overview**  
COMPENG 4DQ5 covers the design, simulation, and implementation of digital systems using hardware description languages (HDLs).  
The course includes topics such as logic synthesis, finite state machines, datapath and control design, and FPGA deployment.  
Students gain hands-on experience building hardware systems using SystemVerilog and tools like Xilinx Vivado or ModelSim.

---

## 🧪 **Labs Overview**

### 🔹 **Lab 1 – Combinational Logic Design**  
Designed and simulated combinational circuits using SystemVerilog.  
Tasks included writing truth tables, creating logic expressions, and verifying outputs via testbenches.

### 🔹 **Lab 2 – Sequential Logic and Flip-Flops**  
Built circuits using D and JK flip-flops to implement counters and memory elements.  
Simulated behavior over clock cycles and tested edge-triggered behavior.

### 🔹 **Lab 3 – Finite State Machines (FSMs)**  
Implemented both Moore and Mealy FSMs.  
Used state diagrams to guide hardware design and verified logic through simulation.

### 🔹 **Lab 4 – Datapath and Control**  
Designed a basic CPU-like architecture using separate datapath and control modules.  
Implemented arithmetic operations and branching logic.

### 🔹 **Lab 5 – Integration and Timing**  
Focused on timing constraints, clock domain management, and integrating all modules into a cohesive system.  
Prepared for synthesis and implementation on an FPGA board.

---

## 🧩 **Final Project – Pipelined Processor with Instruction Decode and Register File**  

**Overview:**  
Designed a pipelined processor in SystemVerilog that supports instruction decoding, register file operations, and basic ALU execution.  
The processor follows a multi-stage pipeline to improve performance by overlapping instruction fetch, decode, execution, and write-back.  
Key focus areas included proper handling of control signals, register reads/writes, and pipeline stage synchronization.

**Key Features:**  
- 4-stage instruction pipeline (Fetch, Decode, Execute, Write-back)  
- General-purpose register file  
- Instruction decoder module supporting basic R-type and I-type formats  
- Modular ALU with arithmetic operations  
- Cycle-accurate simulation and waveform analysis in ModelSim

---

## 🛠️ **Tools & Technologies**  
- **Languages:** SystemVerilog, Verilog, C  
- **Simulation:** ModelSim  
- **Synthesis/Implementation:** Xilinx Vivado  
- **HDL Design:** FSMs, pipelined datapaths, control units  
- **Platforms:** FPGA board (e.g., Nexys A7 if applicable)

---

## 📚 **Learning Outcomes**  
- Designed digital circuits using SystemVerilog  
- Simulated and debugged digital logic with timing diagrams  
- Built a pipelined processor with modular instruction decoding  
- Implemented register file and ALU components  
- Gained insight into hardware pipeline hazards and control flow
