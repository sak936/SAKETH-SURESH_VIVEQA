// ============================================================
// Module : top_module
// Board  : Anmaya AT-STLN-Artix7-001 (Xilinx XC7A35T)
// Clock  : 24 MHz (Pin D13)
// ============================================================

module top_module(
    input  wire       clk_24mhz,   // 24 MHz system clock (Pin D13)
    input  wire       rst,          // Reset - Slide switch or Push Button
    input wire sw_buzzer_en,output wire led_buzzer_status,

    // UART (via PMOD + USB-UART adapter)
    input  wire       uart_rx,      // FTDI TX -> FPGA
    output wire       uart_tx_pin,  // FPGA TX -> FTDI RX

    // DHT11 sensor
    inout  wire       dht_data,     // DHT11 data pin

    // Alert outputs
    output wire       buzzer,       // Pin K5 (active HIGH)

    // Status LEDs
    output wire [3:0] led           // Pins D5, A3, B4, A4
);

// ============================================================
// Internal wires
// ============================================================

// UART TX
wire       tx_busy;
wire       uart_tx_wire;

// UART RX
wire [7:0] rx_data;
wire       rx_done;

// DHT11
wire [7:0] temperature;
wire [7:0] humidity;
wire       data_valid;
wire       dht_error;

// Command FSM outputs
wire       temp_req;
wire       hum_req;
wire       status_req;
wire       log_req;
wire       clear_req;
wire       fifo_req;
wire       alert_req;
wire       set_temp_req;
wire       set_hum_req;
wire       display_req;

// FIFO
wire       fifo_wr_en;
wire [7:0] fifo_din;
wire       fifo_rd_en;
wire [7:0] fifo_dout;
wire       fifo_full;
wire       fifo_empty;
wire [4:0] fifo_count; // FIXED: Must be a wire so data_logger can drive it

// Threshold manager
wire [7:0] temp_threshold;
wire [7:0] hum_threshold;
wire [7:0] manual_threshold_value;

// Alert controller
wire       buzzer_wire;
wire       alert_flag;

// Data logger
wire       log_tx_start;
wire [7:0] log_tx_data;
wire       log_busy;

// ============================================================
// DHT11 trigger: Fixed to auto-sample every 3 seconds (Issue 3)
// 3s @ 24MHz = 72,000,000 ticks (Requires a 27-bit counter)
// ============================================================
localparam DHT11_PERIOD = 27'd72_000_000;

reg [26:0] dht_timer;
reg        dht_start;

always @(posedge clk_24mhz or posedge rst)
begin
    if (rst)
    begin
        dht_timer <= 27'd0;
        dht_start <= 1'b0;
    end
    else
    begin
        dht_start <= 1'b0;
        if (dht_timer >= DHT11_PERIOD - 1)
        begin
            dht_timer <= 27'd0;
            dht_start <= 1'b1;  // 1-cycle pulse every 3s
        end
        else
            dht_timer <= dht_timer + 1;
    end
end

// ============================================================
// Logic Routing
// ============================================================
assign fifo_rd_en  = fifo_req & ~fifo_empty;
assign uart_tx_pin = uart_tx_wire;
assign buzzer      = buzzer_wire & sw_buzzer_en;
assign led_buzzer_status=sw_buzzer_en;

// ============================================================
// Module Instantiations
// ============================================================

// --- UART TX ---
uart_tx u_uart_tx (
    .clk      (clk_24mhz),
    .rst      (rst),
    .tx_start (log_tx_start),
    .tx_data  (log_tx_data),
    .tx       (uart_tx_wire),
    .tx_busy  (tx_busy)
);

// --- UART RX ---
uart_rx u_uart_rx (
    .clk     (clk_24mhz),
    .rst     (rst),
    .rx      (uart_rx),
    .rx_data (rx_data),
    .rx_done (rx_done)
);

// --- Command FSM ---
command_fsm u_command_fsm (
    .clk         (clk_24mhz),
    .rst         (rst),
    .rx_data     (rx_data),
    .rx_done     (rx_done),
    .temp_req    (temp_req),
    .hum_req     (hum_req),
    .status_req  (status_req),
    .log_req     (log_req),
    .clear_req   (clear_req),
    .fifo_req    (fifo_req),
    .alert_req   (alert_req),
    .set_temp_req(set_temp_req),
    .set_hum_req (set_hum_req),
    .display_req (display_req), .manual_value(manual_threshold_value)
);

// --- DHT11 Controller ---
dht11_controller u_dht11 (
    .clk         (clk_24mhz),
    .rst         (rst),
    .start       (dht_start),
    .dht_data    (dht_data),
    .temperature (temperature),
    .humidity    (humidity),
    .data_valid  (data_valid),
    .error       (dht_error)
);

// --- FIFO ---
fifo u_fifo (
    .clk   (clk_24mhz),
    .rst   (rst),
    .wr_en (fifo_wr_en),
    .rd_en (fifo_rd_en),
    .din   (fifo_din),
    .dout  (fifo_dout),
    .full  (fifo_full),
    .empty (fifo_empty)
);

// --- Threshold Manager ---
threshold_manager u_threshold (
    .clk           (clk_24mhz),
    .rst           (rst),
    .set_temp      (set_temp_req),
    .set_hum       (set_hum_req),
    .temp_value    (manual_threshold_value), // Connects straight to the FSM output instead of temperature wire
    .hum_value     (manual_threshold_value), // Connects straight to the FSM output instead of humidity wire
    .temp_threshold(temp_threshold),
    .hum_threshold (hum_threshold)
);

// --- Alert Controller ---
alert_controller u_alert (
    .clk            (clk_24mhz),
    .rst            (rst),
    .temperature    (temperature),
    .humidity       (humidity),
    .temp_threshold (temp_threshold),
    .hum_threshold  (hum_threshold),
    .buzzer         (buzzer_wire),
    .alert_flag     (alert_flag)
);

// --- Data Logger ---
data_logger u_data_logger (
    .clk            (clk_24mhz),
    .rst            (rst),
    .temperature    (temperature),
    .humidity       (humidity),
    .data_valid     (data_valid),
    .temp_req       (temp_req),
    .hum_req        (hum_req),
    .status_req     (status_req),
    .log_req        (log_req),
    .clear_req      (clear_req),
    .fifo_req       (fifo_req),
    .alert_req      (alert_req),
    .set_temp_req   (set_temp_req),
    .set_hum_req    (set_hum_req),
    .display_req    (display_req),
    .temp_threshold (temp_threshold),
    .hum_threshold  (hum_threshold),
    .alert_flag     (alert_flag),
    .fifo_full      (fifo_full),
    .fifo_empty     (fifo_empty),
    .fifo_count     (fifo_count), // Driven directly by module
    .tx_start       (log_tx_start),
    .tx_data        (log_tx_data),
    .tx_busy        (tx_busy),
    .fifo_wr_en     (fifo_wr_en),
    .fifo_din       (fifo_din),
    .log_busy       (log_busy)
);

// ============================================================
// Alert LED blink (led[0]): blinks at ~2Hz when alert active
// ============================================================
localparam BLINK_PERIOD = 24'd6_000_000;
reg [23:0] blink_cnt;
reg        blink_tog;

always @(posedge clk_24mhz or posedge rst)
begin
    if (rst)
    begin
        blink_cnt <= 24'd0;
        blink_tog <= 1'b0;
    end
    else if (alert_flag)
    begin
        if (blink_cnt >= BLINK_PERIOD - 1)
        begin
            blink_cnt <= 24'd0;
            blink_tog <= ~blink_tog;
        end
        else
            blink_cnt <= blink_cnt + 1;
    end
    else
    begin
        blink_cnt <= 24'd0;
        blink_tog <= 1'b0;
    end
end

// ============================================================
// LED Status Assignments
// ============================================================
assign led[0] = alert_flag ? blink_tog : 1'b0;
assign led[1] = data_valid;
assign led[2] = fifo_full;
assign led[3] = log_busy;

endmodule