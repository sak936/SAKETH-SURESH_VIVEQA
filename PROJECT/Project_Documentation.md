# Smart Temperature and Humidity Monitoring, Logging and Alert System Using DHT11 and UART

A complete FPGA-based environmental monitoring system developed on the **Anmaya AT-STLN-Artix7-001 (Xilinx Artix-7 XC7A35T)** platform using **Verilog HDL**.

The system periodically acquires temperature and humidity data from a DHT11 sensor, logs the readings, compares them with user-defined thresholds, generates alerts, and communicates with a PC through UART.

---

## Project Overview

This project demonstrates the implementation of a real-time environmental monitoring system completely in hardware using Verilog HDL.

The FPGA communicates with a DHT11 digital sensor to acquire temperature and humidity values every few seconds. These readings are stored, monitored against configurable threshold values, and transmitted to a computer through UART where they can be viewed using PuTTY.

The project follows a modular design approach, making each component reusable and independently testable.

---

## Features

- Real-time DHT11 temperature and humidity acquisition
- UART communication with PC using FTDI module
- Command-based interface using PuTTY
- FIFO-based data logging
- User-configurable temperature threshold
- User-configurable humidity threshold
- Automatic alert generation
- Buzzer indication
- LED status indication
- Modular Verilog implementation
- Fully synthesizable on Xilinx Artix-7 FPGA

---

## Hardware Used

| Component | Description |
|------------|-------------|
| FPGA Board | Anmaya AT-STLN-Artix7-001 |
| FPGA Device | Xilinx Artix-7 XC7A35T |
| Sensor | DHT11 (3-pin) |
| USB-UART | FTDI USB to TTL Converter |
| Development Software | Vivado 2018.1 |
| Terminal Software | PuTTY |

---

## Software Requirements

- Vivado 2018.1
- PuTTY
- Git
- GitHub

---

## Communication

### UART Configuration

- Baud Rate : 9600 bps
- Data Bits : 8
- Stop Bits : 1
- Parity : None

---

## System Architecture
+----------------------+
| DHT11 Sensor |
+----------+-----------+
|
v
+----------------------+
| DHT11 Controller |
+----------+-----------+
|
v
+----------------------+
| Threshold Manager |
+----------+-----------+
|
v
+----------------------+
| Alert Controller |
+----------+-----------+
|
+---------+
| |
v v
Buzzer LEDs

|
v

+----------------------+
| FIFO Logger |
+----------+-----------+
|
v
+----------------------+
| Data Logger |
+----------+-----------+
|
v
+----------------------+
| UART TX |
+----------+-----------+
|
FTDI
|
PuTTY


---

## Project Modules

### top_module.v

Top-level integration module.

Responsible for:

- Connecting all modules
- Auto-triggering DHT11 every 2 seconds
- LED control
- Buzzer control
- UART routing

---

### dht11_controller.v

Interfaces with the DHT11 sensor.

Functions:

- Generates start pulse
- Receives sensor response
- Reads 40-bit data frame
- Performs checksum verification
- Extracts

- Temperature
- Humidity

Outputs:

- temperature
- humidity
- data_valid
- error

---

### uart_rx.v

Receives UART commands from PuTTY.

---

### uart_tx.v

Transmits formatted messages back to PuTTY.

---

### command_fsm.v

Decodes received UART commands and generates request signals.

Supported commands:

| Command | Function |
|-----------|----------------------------|
| T | Display Temperature |
| H | Display Humidity |
| S | System Status |
| L | Log Current Reading |
| D | Display Latest Data |
| C | Clear Log |
| F | FIFO Status |
| A | Alert Status |
| P | Set Temperature Threshold |
| U | Set Humidity Threshold |

---

### fifo.v

Stores historical temperature and humidity values.

Features:

- FIFO write
- FIFO read
- Full detection
- Empty detection

---

### threshold_manager.v

Maintains user-configurable threshold values.

Outputs:

- Temperature threshold
- Humidity threshold

---

### alert_controller.v

Continuously compares sensor readings with threshold values.

Outputs:

- Alert flag
- Buzzer
- LED indication

---

### data_logger.v

Formats all UART messages.

Examples:
TEMP> 030 C

HUM> 065 %

SYS> T:030 C H:065 %

LOG> T:030 C H:065 %

FIFO> F:0 E:1 CNT:05


---

## Project Flow

1. FPGA powers up
2. DHT11 sampling begins
3. Sensor values are validated
4. FIFO stores readings
5. Threshold comparison performed
6. Alert generated if necessary
7. UART sends information to PuTTY
8. User commands processed continuously

---

## Build Instructions

1. Open Vivado 2018.1
2. Create/Open the project.
3. Add all Verilog source files.
4. Add the XDC constraints file.
5. Run Synthesis.
6. Run Implementation.
7. Generate Bitstream.
8. Program the FPGA.
9. Connect FTDI module.
10. Open PuTTY with:
9600 Baud
8 Data Bits
No Parity
1 Stop Bit

11. View sensor data and issue commands.

---

## Testing

The project was verified using:

- Vivado Simulation
- Integrated Logic Analyzer (ILA)
- Hardware Debugger
- PuTTY UART Terminal
- DHT11 Sensor
- FTDI USB-UART Module

---

## Repository Structure
SAKETH-SURESH_VIVEQA
│
├── rtl/
│ ├── top_module.v
│ ├── dht11_controller.v
│ ├── uart_tx.v
│ ├── uart_rx.v
│ ├── fifo.v
│ ├── data_logger.v
│ ├── command_fsm.v
│ ├── threshold_manager.v
│ └── alert_controller.v
│
├── constraints/
│ └── DHT.xdc
│
├── docs/
│
└── README.md

---

## Applications

- Environmental Monitoring
- Smart Agriculture
- Server Room Monitoring
- Greenhouse Automation
- Laboratory Monitoring
- Home Automation
- Industrial Safety

---

## Future Improvements

- OLED/LCD display support
- Wi-Fi connectivity
- IoT cloud integration
- SD card data logging
- Real-Time Clock (RTC)
- Mobile application support
- Multiple sensor support

---

## Contributors

**Saketh Suresh**

Electronics and Communication Engineering

NMAM Institute of Technology

---

**Nishaan**

Electronics and Communication Engineering

NMAM Institute of Technology

---

## Acknowledgement

This project was developed as part of the **VIVEQA FPGA Internship Program**, focusing on digital design using Verilog HDL on the Xilinx Artix-7 FPGA platform.
