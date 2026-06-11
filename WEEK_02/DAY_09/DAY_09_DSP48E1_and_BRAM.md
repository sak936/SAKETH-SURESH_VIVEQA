# Day 09 - DSP48E1 and Block RAM (BRAM)

## DSP Slices in FPGAs

### Why DSP Slices?
Arithmetic operations such as multiplication and addition consume a large number of LUTs. To perform these operations efficiently, FPGAs provide dedicated DSP slices.

### DSP48E1 Block
DSP48E1 is a dedicated arithmetic block used for:
- Multiplication
- Addition/Subtraction
- Multiply-Accumulate (MAC) operations
- Signal Processing applications

### Applications
1. Signal Scaling
2. FIR Filters
3. MAC (Multiply-Accumulate) Operations

### DSP48E1 Inputs
- A Input
- B Input
- C Input
- D Input

### Internal Components
- 25 × 18 Multiplier
- Pre-Adder
- 48-bit Accumulator

### Why Pre-Adder?
The pre-adder performs addition before multiplication, reducing hardware usage and improving efficiency in DSP applications.

### 32 × 32 Multiplication
Since DSP48E1 supports a 25 × 18 multiplier, larger multiplications such as 32 × 32 are implemented using multiple DSP slices.

### DSP Slice vs LUT Logic

| DSP Slice | LUT Logic |
|------------|------------|
| Dedicated arithmetic hardware | General-purpose logic |
| Faster | Slower for large arithmetic |
| Lower LUT usage | Higher LUT usage |
| Efficient for multiplication | Resource intensive |

---

## Verilog Example
File: `mult.v`

Implemented multiplication operation using DSP resources.

---

# Block RAM (BRAM)

## What is BRAM?
Block RAM (BRAM) is dedicated memory available inside an FPGA.

## Characteristics
- High-speed memory
- Stored inside FPGA fabric
- Does not consume LUTs for storage
- Suitable for large data storage

## Types of BRAM

### Single-Port BRAM
- One port for read/write operations

### Dual-Port BRAM
- Two independent ports
- Simultaneous read/write possible

### FIFO Using BRAM
FIFO (First In First Out) buffers are commonly implemented using BRAM.

### Why FIFO?
- Data buffering
- Clock domain crossing
- Streaming applications

## Verilog Example
File: `block_ram.v`

Implementation of Block RAM.

---

## Homework
- Design and implement Dual-Port BRAM.