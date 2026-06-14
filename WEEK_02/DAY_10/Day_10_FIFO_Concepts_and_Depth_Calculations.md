# Day 10 - FIFO Concepts and Depth Calculations

## Introduction to FIFO

FIFO (First In First Out) is a memory structure in which the first data written into memory is the first data read out. FIFOs are used for buffering data between modules operating at different clock frequencies.

### Applications
- Clock Domain Crossing (CDC)
- Data buffering
- Rate matching between producer and consumer
- Streaming interfaces

---

## Memory Types Used in FIFOs

### 1. Single Port RAM
- One port for both read and write operations.
- Cannot read and write simultaneously.
- Requires the least area.

### 2. Simple Dual Port RAM
- One dedicated write port.
- One dedicated read port.
- Read and write can occur simultaneously.
- Most commonly used in FIFO implementations.

### 3. True Dual Port RAM
- Two fully independent ports.
- Each port can perform read or write operations.
- Both ports can access any address simultaneously.
- Most flexible but requires more area.

### FIFO Memory Usage
- Synchronous FIFO → Simple Dual Port RAM
- Asynchronous FIFO → Simple Dual Port RAM
- True Dual Port RAM is generally unnecessary for simple FIFO designs.

---

## FIFO Depth Calculation

FIFO depth determines the amount of storage required to avoid data loss when write and read rates are different.

### Scenario 1: FA > FB (No Idle Cycles)

Given:
- Write Frequency = 80 MHz
- Read Frequency = 50 MHz
- Burst Length = 120

Calculation:
- Write time per item = 1/80 MHz = 12.5 ns
- Total write time = 120 × 12.5 = 1500 ns
- Read time per item = 1/50 MHz = 20 ns
- Data read during 1500 ns = 1500/20 = 75

FIFO Depth = 120 − 75 = **45**

---

### Scenario 2: FA > FB (With Idle Cycles)

Given:
- Write Frequency = 80 MHz
- Read Frequency = 50 MHz
- Burst Length = 120
- One idle cycle between writes
- Three idle cycles between reads

Calculation:
- Write time per item = 2 × (1/80 MHz) = 25 ns
- Total write time = 3000 ns
- Read time per item = 4 × (1/50 MHz) = 80 ns
- Data read during 3000 ns = 3000/80 ≈ 37

FIFO Depth = 120 − 37 = **83**

---

### Scenario 3: FA < FB (No Idle Cycles)

Given:
- Write Frequency = 30 MHz
- Read Frequency = 50 MHz

Since reading is faster than writing, data will not accumulate.

Minimum FIFO Depth = **1**

---

### Scenario 4: FA < FB (With Idle Cycles)

Given:
- Write Frequency = 30 MHz
- Read Frequency = 50 MHz
- One idle cycle between writes
- Three idle cycles between reads

Calculation:
- Write time per item = 66.67 ns
- Total write time = 8000 ns
- Read time per item = 80 ns
- Data read during 8000 ns = 100

FIFO Depth = 120 − 100 = **20**

---

### Scenario 5: FA = FB (No Idle Cycles)

Given:
- Write Frequency = Read Frequency = 30 MHz

If there is no phase difference between clocks, FIFO is not required.

If phase difference exists, FIFO Depth = **1**

---

### Scenario 6: FA = FB (With Idle Cycles)

Given:
- Write Frequency = 50 MHz
- Read Frequency = 50 MHz
- One idle cycle between writes
- Three idle cycles between reads

Calculation:
- Write time per item = 40 ns
- Total write time = 4800 ns
- Read time per item = 80 ns
- Data read during 4800 ns = 60

FIFO Depth = 120 − 60 = **60**

---

## Key Takeaways

- FIFO stands for First In First Out.
- FIFO is used to buffer data between modules running at different speeds.
- Simple Dual Port RAM is the preferred memory structure for FIFOs.
- FIFO depth depends on:
  - Write frequency
  - Read frequency
  - Burst length
  - Idle cycles
- Correct FIFO sizing prevents overflow and data loss.