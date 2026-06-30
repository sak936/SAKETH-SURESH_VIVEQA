# 🌡️ Intelligent Climate Monitor & Data Logger (FPGA-DHT11)

An advanced, hardware-driven environmental monitoring system designed in **Verilog HDL** and deployed on the **Anmaya Artix-7 XC7A35T** development platform. This system handles real-time single-wire bidirectional communication with a DHT11 sensor, evaluates dual environmental thresholds dynamically via a UART serial interface, features a hardware-buffered FIFO logging queue, and implements an audio/visual safety alert subsystem.

---

## 📋 Project Overview

This project implements a self-contained, real-time climate telemetry engine. Running on a native $24\text{ MHz}$ system clock, it abstracts complex physical-layer timing constraints into modular hardware logic. 

### Key Features
* **Custom DHT11 Master Controller:** A robust 10-state Finite State Machine (FSM) that accurately samples temperature and relative humidity using precise microsecond timing windows and 2-stage input metastable synchronization.
* **Interactive UART Interface:** An asynchronous serial terminal link ($9600\text{ Baud}$) allowing operators to fetch live telemetry, view system metrics, and program boundary thresholds on-the-fly using simple keyboard strokes in terminal applications like PuTTY.
* **On-Chip FIFO Data Logger:** A synchronous First-In, First-Out ($16\text{-byte}$ depth) storage buffer that logs environmental telemetry records using an interleaved toggle phase machine to write data without dropping tracking states.
* **Dual-Threshold Alert System:** An automatic safety monitor that evaluates current environmental criteria against programmable limits, triggering a resonant frequency active-buzzer pulse ($2.7\text{ kHz}$) and flashing warning LEDs upon boundary breach, featuring a hardware master mute bypass slide switch.

---

## 📐 Design and Architecture

The project adheres to a strict hierarchical design methodology. The `top_module.v` acts as the structural wrapper, routing physical system interconnects across fully decoupled synchronous submodules.


## 🎨 Structural System Block Diagram

 ┌────────────────────────────────────────────────────────────────────────────────────────┐
 │                                       TOP_MODULE                                       │
 │                                                                                        │
 │                    ┌──────────────┐                  ┌────────────────────┐            │
 │                    │   uart_rx    │                  │  dht11_controller  │            │
 ├─► uart_rx ────────►│              │                  │                    │◄──► dht_dat│
 │                    │  rx_data[7:0]│                  │ temperature[7:0]   │            │
 │                    └──────┬───────┘                  │ humidity[7:0]      │            │
 │                           │                          │ data_valid         │            │
 │                           │ [rx_done]                └─────────┬──────────┘            │
 │                           ▼                                    │                       │
 │                    ┌──────────────┐                            │                       │
 │                    │ command_fsm  │                            │                       │
 │                    │              │                            ▼                       │
 │                    │ manual_val   │                  ┌────────────────────┐            │
 │                    └──────┬───────┘                  │    data_logger     │            │
 │                           │                          │                    │            │
 │                           │ [set_temp/hum]           │ fifo_din[7:0]      │            │
 │                           ▼                          │ fifo_wr_en         │            │
 │                    ┌──────────────┐                  └─────────┬──────────┘            │
 │                    │  threshold_  │                            │                       │
 │                    │  manager     │                            │                       │
 │                    │              │                            │ [push]                │
 │                    │  t_thresh    │                            ▼                       │
 │                    │  h_thresh    │                  ┌────────────────────┐            │
 │                    └──────┬───────┘                  │       fifo         │            │
 │                           │                          │                    │            │
 │                           │                          │ count[4:0]         │            │
 │                           │                          │ empty / full       │            │
 │                           │                          └─────────┬──────────┘            │
 │                           │ [Limits]                           │ [Status]              │
 │                           ▼                                    ▼                       │
 │                    ┌──────────────────────────────────────────────────────┐            │
 │                    │                    alert_controller                  │            │
 │                    └──────────────────────────┬───────────────────────────┘            │
 │                                               │                                        │
 │                                               ▼ [buzzer_wire]                          │
 │                                        [AND Mute Gate] ◄─────────────────── sw_buzzer_ │
 │                                               │                                  en    │
 ├───────────────────────────────────────────────┼────────────────────────────────────────┤
                                                 ▼
                                        🔔 BUZZER & LEDS

### 📦 Module Descriptions

| File Name | Functional Description |
| :--- | :--- |
| **`top_module.v`** | Structural top-level wrapper. Performs clock distribution, resets, bidirectional I/O line buffering (`IOBUF`), hardware control gating (Switch/LED routing), and wire-interconnect stitching. |
| **`dht11_controller.v`** | Manages the custom single-wire bus interface. Features an integrated 10-state FSM executing structural microsecond wait-states ($18\text{ms}$ start pulses, $47\mu\text{s}$ bit midpoints) to securely capture, decode, and checksum the 40-bit DHT11 data payload. |
| **`uart_rx.v` / `uart_tx.v`** | Modular Universal Asynchronous Receiver-Transmitter block. Converts serial bitstreams over physical FPGA pins into parallel byte lines (and vice-versa) locked exactly to $9600\text{ Baud}$ using a calculated internal oversampling tick rate generator. |
| **`command_fsm.v`** | Interactive ASCII command parser. Monitors incoming UART RX buffers, capturing distinct keypress instructions (`T`, `H`, `S`, `L`, `C`, `F`, `A`, `D`) and orchestrating dynamic multi-cycle numeric parsing states for threshold entry commands (`P`, `U`). |
| **`threshold_manager.v`** | Dedicated volatile memory storage cell holding the maximum allowable limits for climate parameters. Defaults to $30^\circ\text{C}$ and $70\%$ RH on startup, overwriting values upon command requests. |
| **`data_logger.v`** | Central system coordinator. Operates on a periodic timer to push formatted ASCII metrics strings down the UART transmitter while concurrently handling back-to-back variable logging using an integrated write phase pipeline selector. |
| **`fifo.v`** | Synchronous memory queue array ($16\times8\text{-bit}$). Implements dual-pointer wrap-around safety logic (`wr_ptr` and `rd_ptr`) handling simultaneous single-cycle updates while reporting clean status boundaries (`Full`, `Empty`, and true current element tracking `Count`). |

---

## 🛠️ Implementation & Technical Approach

### 1. Bidirectional Physical-Layer Interface
The DHT11 utilizes a single shared wire for communication. To prevent electrical contention and hardware damage to the FPGA I/O buffers, the controller actively handles tri-state impedance selection logic using high-impedance mode assignment:

``verilog
// Tri-state buffer logic inside top_module.v
assign dht_data = (dht_dir) ? dht_out : 1'bZ;

When dht_dir drops to 0, the FPGA line floats safely into high-impedance listening mode, allowing the external pull-up resistor on the Anmaya board to manage voltage fluctuations triggered by the sensor.

### 2. Time-Domain Boundary Integrity
Operating under a native system clock speed of 24 MHz, each single clock cycle tick spans exactly $\approx 41.67\text{ ns}$. Timing parameters inside `dht11_controller.v` are hardcoded to scale up smoothly to avoid drift errors:

* **Host Start Low Duration** ($18\text{ ms}$) = $432,000\text{ ticks}$
* **Data Bit Resolution Threshold** ($47\ \mu\text{s}$) = $1,128\text{ ticks}$
* **Safety Watchdog Timeout** ($150\ \mu\text{s}$) = $3,600\text{ ticks}$

### 3. Dual-Pulse Phase Switching Log Logic
To interface back-to-back environmental attributes cleanly into a single unified data bus for storage, `data_logger.v` utilizes an independent single-wire dual-phase register (`fifo_phase`). When a high pulse from `data_valid` triggers, it sets off an atomic two-step sequential routing sweep:

``verilog
// Exact Logging Framework in data_logger.v
if (data_valid && !fifo_phase) begin
    fifo_din   <= temperature;
    fifo_wr_en <= 1'b1;
    fifo_phase <= 1'b1;
end
else if (fifo_phase) begin
    fifo_din   <= humidity;
    fifo_wr_en <= 1'b1;
    fifo_phase <= 1'b0;
end

### ⌨️ UART User Console Interface

When connected via a serial terminal client (Baud: **9600**, Data Bits: **8**, Parity: **None**, Stop Bits: **1**), the following interaction console mapping is available:

| Keystroke | Terminal Header | Action Description | Example Console Output |
| :---: | :--- | :--- | :--- |
| **`T`** | `TEMP>` | Instantly query current temperature reading. | `TEMP> 026 C` |
| **`H`** | `HUMI>` | Instantly query current humidity reading. | `HUMI> 074 %` |
| **`S`** | `SYS>` | Dumps full real-time telemetry matrix block. | `SYS> T:026 C H:074 % TH:030 HH:070` |
| **`A`** | `ALRT>` | Queries the electrical status of safety alarm. | `ALRT> OFF` or `ALRT> ON` |
| **`F`** | `FIFO>` | Reads current state and capacity of hardware log stack. | `FIFO> F:0 E:1 CNT:00` |
| **`L`** | `DATA>` | Pops and streams oldest unread record from FIFO log stack. | `DATA> T:026 C H:074 %` |
| **`C`** | `CLR>` | Clears internal pointer registers, flushing FIFO logs. | `CLR> Log Cleared` |
| **`P` + `[X][X]`** | `PTHR>` | Sets custom maximum temperature limit manually (2 digits). | Type `P35` &rarr; `PTHR> Set 35 C` |
| **`U` + `[X][X]`** | `UTHR>` | Sets custom maximum humidity limit manually (2 digits). | Type `U82` &rarr; `UTHR> Set 82 %` |

## 🚀 Compilation, Build, and Operational Steps

Follow these instructions to synthesize, implement, generate bitstreams, and verify the project using **AMD/Xilinx Vivado Design Suite**:

### 1. Project Initialization & Setup
1. Launch **Vivado** (Recommended Version: 2020.x or newer).
2. Select **Create Project** &rarr; Name it `Climate_Monitor_Logger`.
3. Choose **RTL Project** configuration.
4. When prompted to select target hardware, click **Parts** and search for the target device configuration ID: **`xc7a35tftg256-1`** (Artix-7).

### 2. Sourcing Project Code
1. Click **Add Sources** &rarr; Select **Add or Create Design Sources** &rarr; Upload the following Verilog modules:
   * `top_module.v`
   * `dht11_controller.v`
   * `uart_rx.v`
   * `uart_tx.v`
   * `command_fsm.v`
   * `threshold_manager.v`
   * `data_logger.v`
   * `fifo.v`
   * `alert_controller.v`
2. Click **Add Sources** &rarr; Select **Add or Create Constraints** &rarr; Upload your project `.xdc` file.

### 3. Synthesis and Implementation Execution Flow
1. Under the **Flow Navigator** column on the left panel, click **Run Synthesis** and wait for the calculations to complete.
2. Click **Run Implementation** to map standard structural routes into specific programmable Lookup Tables (LUTs) on your Artix-7 device.
3. Click **Generate Bitstream** to build the hardware configuration payload `.bit` data file.

### 4. Flashing and Running Code on Device
1. Connect the Anmaya Artix-7 development board via a mini-USB cable to your workstation PC. Turn on the hardware power switch.
2. Inside Vivado, click **Open Hardware Manager** &rarr; Click **Auto Connect**.
3. Right-click on your listed Artix-7 target chip configuration row, choose **Program Device**, reference your generated compilation file path location for `top_module.bit`, and execute the flash command routines.

### 5. Launching the Testing Environment Console (PuTTY Verification)
1. Open Windows **Device Manager** and check under **Ports (COM & LPT)** to note your board's active connection address (e.g., `COM3`).
2. Boot up **PuTTY**. Select the **Serial** connection mode tracking option toggle.
3. Input the required configuration specs:
   * **Serial line:** `COM3` *(Replace with your exact identifier)*
   * **Speed:** `9600`
4. Expand the **Connection** subcategory on the left side configuration panel &rarr; Select **Serial**. Ensure parameters read: 
   * **Data bits:** `8`
   * **Stop bits:** `1`
   * **Parity:** `None`
   * **Flow Control:** `None`
5. Click **Open** to initialize your telemetry interface dashboard control matrix!


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
