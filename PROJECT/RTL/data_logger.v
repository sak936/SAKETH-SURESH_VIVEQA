`timescale 1ns / 1ps
// Purpose: Handles all 10 UART commands, sends formatted
//          messages to PuTTY, and logs data to FIFO.
//
// Commands (from command_fsm):
//   T -> temp_req     : "TEMP> XXX C\r\n"
//   H -> hum_req      : "HUM>  XXX %\r\n"
//   S -> status_req   : "SYS> T:XXX C H:XXX % TH:XXX HH:XXX\r\n"
//   L -> log_req      : "LOG> T:XXX C H:XXX %\r\n"
//   C -> clear_req    : "CLR> Log Cleared\r\n"
//   F -> fifo_req     : "FIFO> F:X E:X CNT:XX\r\n"
//   A -> alert_req    : "ALRT> ON\r\n" or "ALRT> OFF\r\n"
//   P -> set_temp_req : "PTHR> Set XXX C\r\n"
//   U -> set_hum_req  : "UTHR> Set XXX %\r\n"
//   D -> display_req  : "DATA> T:XXX C H:XXX %\r\n"
// ============================================================

module data_logger(
    input  wire        clk,
    input  wire        rst,

    // Sensor inputs (from dht11_controller)
    input  wire [7:0]  temperature,
    input  wire [7:0]  humidity,
    input  wire        data_valid,

    // Command inputs (from command_fsm)
    input  wire        temp_req,
    input  wire        hum_req,
    input  wire        status_req,
    input  wire        log_req,
    input  wire        clear_req,
    input  wire        fifo_req,
    input  wire        alert_req,
    input  wire        set_temp_req,
    input  wire        set_hum_req,
    input  wire        display_req,

    // Threshold inputs (from threshold_manager)
    input  wire [7:0]  temp_threshold,
    input  wire [7:0]  hum_threshold,

    // Alert input (from alert_controller)
    input  wire        alert_flag,

    // FIFO status inputs (from fifo)
    input  wire        fifo_full,
    input  wire        fifo_empty,
    input  wire [4:0]  fifo_count,

    // UART TX interface (to uart_tx)
    output reg         tx_start,
    output reg  [7:0]  tx_data,
    input  wire        tx_busy,

    // FIFO write interface (to fifo)
    output reg         fifo_wr_en,
    output reg  [7:0]  fifo_din,

    // Status
    output reg         log_busy
);

// ============================================================
// FSM States
// ============================================================
localparam IDLE       = 4'd0;
localparam LOAD_MSG   = 4'd1;
localparam WAIT_READY = 4'd2;
localparam SEND_BYTE  = 4'd3;
localparam NEXT_BYTE  = 4'd4;
localparam DONE       = 4'd5;

// ============================================================
// Message buffer (48 bytes â€" enough for longest message)
// ============================================================
localparam MSG_LEN = 48;

reg [7:0]  msg_buf [0:MSG_LEN-1];
reg [5:0]  msg_len;
reg [5:0]  msg_idx;

// ============================================================
// Latched sensor values
// ============================================================
reg [7:0]  temp_latch;
reg [7:0]  hum_latch;

// ============================================================
// Pending request flags
// ============================================================
reg pending_temp;
reg pending_hum;
reg pending_status;
reg pending_log;
reg pending_clear;
reg pending_fifo;
reg pending_alert;
reg pending_set_temp;
reg pending_set_hum;
reg pending_display;
reg pending_auto;

// ============================================================
// FSM state
// ============================================================
reg [3:0]  state;

// ============================================================
// ASCII helpers â€" pre-computed as WIRES (fixes Vivado error)
// Vivado cannot call functions in non-blocking assignments.
// Pre-compute all digit wires here, use them in always block.
// ============================================================
localparam CR = 8'h0D;
localparam LF = 8'h0A;

// --- Temperature digits ---
wire [7:0] temp_h = 8'd48 + (temp_latch / 100);
wire [7:0] temp_t = 8'd48 + ((temp_latch % 100) / 10);
wire [7:0] temp_u = 8'd48 + (temp_latch % 10);

// --- Humidity digits ---
wire [7:0] hum_h  = 8'd48 + (hum_latch / 100);
wire [7:0] hum_t  = 8'd48 + ((hum_latch % 100) / 10);
wire [7:0] hum_u  = 8'd48 + (hum_latch % 10);

// --- Temp threshold digits ---
wire [7:0] tth_h  = 8'd48 + (temp_threshold / 100);
wire [7:0] tth_t  = 8'd48 + ((temp_threshold % 100) / 10);
wire [7:0] tth_u  = 8'd48 + (temp_threshold % 10);

// --- Hum threshold digits ---
wire [7:0] hth_h  = 8'd48 + (hum_threshold / 100);
wire [7:0] hth_t  = 8'd48 + ((hum_threshold % 100) / 10);
wire [7:0] hth_u  = 8'd48 + (hum_threshold % 10);

// --- FIFO count digits ---
wire [7:0] fcnt_t = 8'd48 + (fifo_count / 10);
wire [7:0] fcnt_u = 8'd48 + (fifo_count % 10);

// --- FIFO full/empty flags as ASCII ---
wire [7:0] fifo_f_char = fifo_full  ? 8'd49 : 8'd48; // '1' or '0'
wire [7:0] fifo_e_char = fifo_empty ? 8'd49 : 8'd48;

// ============================================================
// Latch sensor data on data_valid
// ============================================================
always @(posedge clk or posedge rst)
begin
    if (rst)
    begin
        temp_latch <= 8'd0;
        hum_latch  <= 8'd0;
    end
    else if (data_valid)
    begin
        temp_latch <= temperature;
        hum_latch  <= humidity;
    end
end

// ============================================================
// Set / clear pending flags
// ============================================================
always @(posedge clk or posedge rst)
begin
    if (rst)
    begin
        pending_temp     <= 1'b0;
        pending_hum      <= 1'b0;
        pending_status   <= 1'b0;
        pending_log      <= 1'b0;
        pending_clear    <= 1'b0;
        pending_fifo     <= 1'b0;
        pending_alert    <= 1'b0;
        pending_set_temp <= 1'b0;
        pending_set_hum  <= 1'b0;
        pending_display  <= 1'b0;
        pending_auto     <= 1'b0;
    end
    else
    begin
        // Set on incoming requests
        if (temp_req)     pending_temp     <= 1'b1;
        if (hum_req)      pending_hum      <= 1'b1;
        if (status_req)   pending_status   <= 1'b1;
        if (log_req)      pending_log      <= 1'b1;
        if (clear_req)    pending_clear    <= 1'b1;
        if (fifo_req)     pending_fifo     <= 1'b1;
        if (alert_req)    pending_alert    <= 1'b1;
        if (set_temp_req) pending_set_temp <= 1'b1;
        if (set_hum_req)  pending_set_hum  <= 1'b1;
        if (display_req)  pending_display  <= 1'b1;
        if (data_valid)   pending_auto     <= 1'b1;

        // Clear the one being serviced in LOAD_MSG
        if (state == LOAD_MSG)
        begin
            if      (pending_clear)    pending_clear    <= 1'b0;
            else if (pending_temp)     pending_temp     <= 1'b0;
            else if (pending_hum)      pending_hum      <= 1'b0;
            else if (pending_status)   pending_status   <= 1'b0;
            else if (pending_log)      pending_log      <= 1'b0;
            else if (pending_fifo)     pending_fifo     <= 1'b0;
            else if (pending_alert)    pending_alert    <= 1'b0;
            else if (pending_set_temp) pending_set_temp <= 1'b0;
            else if (pending_set_hum)  pending_set_hum  <= 1'b0;
            else if (pending_display)  pending_display  <= 1'b0;
            else if (pending_auto)     pending_auto     <= 1'b0;
        end
    end
end

// ============================================================
// FIFO write: store temp then humidity on data_valid
// ============================================================
reg fifo_phase;

always @(posedge clk or posedge rst)
begin
    if (rst)
    begin
        fifo_wr_en <= 1'b0;
        fifo_phase <= 1'b0;
    end
    else
    begin
        fifo_wr_en <= 1'b0;

        if (data_valid && !fifo_phase)
        begin
            fifo_din   <= temperature;
            fifo_wr_en <= 1'b1;
            fifo_phase <= 1'b1;
        end
        else if (fifo_phase)
        begin
            fifo_din   <= humidity;
            fifo_wr_en <= 1'b1;
            fifo_phase <= 1'b0;
        end
    end
end

// ============================================================
// Main FSM
// ============================================================
integer i;

always @(posedge clk or posedge rst)
begin
    if (rst)
    begin
        state    <= IDLE;
        tx_start <= 1'b0;
        tx_data  <= 8'd0;
        msg_idx  <= 6'd0;
        msg_len  <= 6'd0;
        log_busy <= 1'b0;
        for (i = 0; i < MSG_LEN; i = i + 1)
            msg_buf[i] <= 8'd0;
    end
    else
    begin
        tx_start <= 1'b0;

        case (state)

        // ------------------------------------------------
        // IDLE: check for any pending request
        // Priority: clear > T > H > S > L > F > A > P > U > D > auto
        // ------------------------------------------------
        IDLE:
        begin
            log_busy <= 1'b0;
            if (pending_clear  || pending_temp     || pending_hum  ||
                pending_status || pending_log      || pending_fifo ||
                pending_alert  || pending_set_temp || pending_set_hum ||
                pending_display || pending_auto)
            begin
                log_busy <= 1'b1;
                state    <= LOAD_MSG;
            end
        end

        // ------------------------------------------------
        // LOAD_MSG: build message into msg_buf[]
        // All digit wires (temp_h, temp_t, etc.) are
        // pre-computed combinationally above â€" safe to use here
        // ------------------------------------------------
        LOAD_MSG:
        begin
            if (pending_clear)
            begin
                // "CLR> Log Cleared\r\n"  18 bytes
                msg_buf[0]  <= "C"; msg_buf[1]  <= "L";
                msg_buf[2]  <= "R"; msg_buf[3]  <= ">";
                msg_buf[4]  <= " "; msg_buf[5]  <= "L";
                msg_buf[6]  <= "o"; msg_buf[7]  <= "g";
                msg_buf[8]  <= " "; msg_buf[9]  <= "C";
                msg_buf[10] <= "l"; msg_buf[11] <= "e";
                msg_buf[12] <= "a"; msg_buf[13] <= "r";
                msg_buf[14] <= "e"; msg_buf[15] <= "d";
                msg_buf[16] <= CR;  msg_buf[17] <= LF;
                msg_len <= 6'd18;
            end
            else if (pending_temp)
            begin
                // "TEMP> XXX C\r\n"  13 bytes
                msg_buf[0]  <= "T"; msg_buf[1]  <= "E";
                msg_buf[2]  <= "M"; msg_buf[3]  <= "P";
                msg_buf[4]  <= ">"; msg_buf[5]  <= " ";
                msg_buf[6]  <= temp_h;
                msg_buf[7]  <= temp_t;
                msg_buf[8]  <= temp_u;
                msg_buf[9]  <= " "; msg_buf[10] <= "C";
                msg_buf[11] <= CR;  msg_buf[12] <= LF;
                msg_len <= 6'd13;
            end
            else if (pending_hum)
            begin
                // "HUM> XXX %\r\n"  12 bytes
                msg_buf[0]  <= "H"; msg_buf[1]  <= "U";
                msg_buf[2]  <= "M"; msg_buf[3]  <= ">";
                msg_buf[4]  <= " ";
                msg_buf[5]  <= hum_h;
                msg_buf[6]  <= hum_t;
                msg_buf[7]  <= hum_u;
                msg_buf[8]  <= " "; msg_buf[9]  <= "%";
                msg_buf[10] <= CR;  msg_buf[11] <= LF;
                msg_len <= 6'd12;
            end
            else if (pending_status)
            begin
                // "SYS> T:XXX C H:XXX % TH:XXX HH:XXX\r\n"  38 bytes
                msg_buf[0]  <= "S"; msg_buf[1]  <= "Y";
                msg_buf[2]  <= "S"; msg_buf[3]  <= ">";
                msg_buf[4]  <= " "; msg_buf[5]  <= "T";
                msg_buf[6]  <= ":";
                msg_buf[7]  <= temp_h;
                msg_buf[8]  <= temp_t;
                msg_buf[9]  <= temp_u;
                msg_buf[10] <= " "; msg_buf[11] <= "C";
                msg_buf[12] <= " "; msg_buf[13] <= "H";
                msg_buf[14] <= ":";
                msg_buf[15] <= hum_h;
                msg_buf[16] <= hum_t;
                msg_buf[17] <= hum_u;
                msg_buf[18] <= " "; msg_buf[19] <= "%";
                msg_buf[20] <= " "; msg_buf[21] <= "T";
                msg_buf[22] <= "H"; msg_buf[23] <= ":";
                msg_buf[24] <= tth_h;
                msg_buf[25] <= tth_t;
                msg_buf[26] <= tth_u;
                msg_buf[27] <= " "; msg_buf[28] <= "H";
                msg_buf[29] <= "H"; msg_buf[30] <= ":";
                msg_buf[31] <= hth_h;
                msg_buf[32] <= hth_t;
                msg_buf[33] <= hth_u;
                msg_buf[34] <= CR;  msg_buf[35] <= LF;
                msg_len <= 6'd36;
            end
            else if (pending_log)
            begin
                // "LOG> T:XXX C H:XXX %\r\n"  22 bytes
                msg_buf[0]  <= "L"; msg_buf[1]  <= "O";
                msg_buf[2]  <= "G"; msg_buf[3]  <= ">";
                msg_buf[4]  <= " "; msg_buf[5]  <= "T";
                msg_buf[6]  <= ":";
                msg_buf[7]  <= temp_h;
                msg_buf[8]  <= temp_t;
                msg_buf[9]  <= temp_u;
                msg_buf[10] <= " "; msg_buf[11] <= "C";
                msg_buf[12] <= " "; msg_buf[13] <= "H";
                msg_buf[14] <= ":";
                msg_buf[15] <= hum_h;
                msg_buf[16] <= hum_t;
                msg_buf[17] <= hum_u;
                msg_buf[18] <= " "; msg_buf[19] <= "%";
                msg_buf[20] <= CR;  msg_buf[21] <= LF;
                msg_len <= 6'd22;
            end
            else if (pending_fifo)
            begin
                // "FIFO> F:X E:X CNT:XX\r\n"  22 bytes
                msg_buf[0]  <= "F"; msg_buf[1]  <= "I";
                msg_buf[2]  <= "F"; msg_buf[3]  <= "O";
                msg_buf[4]  <= ">"; msg_buf[5]  <= " ";
                msg_buf[6]  <= "F"; msg_buf[7]  <= ":";
                msg_buf[8]  <= fifo_f_char;
                msg_buf[9]  <= " "; msg_buf[10] <= "E";
                msg_buf[11] <= ":";
                msg_buf[12] <= fifo_e_char;
                msg_buf[13] <= " "; msg_buf[14] <= "C";
                msg_buf[15] <= "N"; msg_buf[16] <= "T";
                msg_buf[17] <= ":";
                msg_buf[18] <= fcnt_t;
                msg_buf[19] <= fcnt_u;
                msg_buf[20] <= CR;  msg_buf[21] <= LF;
                msg_len <= 6'd22;
            end
            else if (pending_alert)
            begin
                // "ALRT> ON\r\n"  (10) or "ALRT> OFF\r\n"  (11)
                msg_buf[0] <= "A"; msg_buf[1] <= "L";
                msg_buf[2] <= "R"; msg_buf[3] <= "T";
                msg_buf[4] <= ">"; msg_buf[5] <= " ";
                if (alert_flag)
                begin
                    msg_buf[6] <= "O"; msg_buf[7] <= "N";
                    msg_buf[8] <= CR;  msg_buf[9] <= LF;
                    msg_len <= 6'd10;
                end
                else
                begin
                    msg_buf[6] <= "O"; msg_buf[7] <= "F";
                    msg_buf[8] <= "F"; msg_buf[9] <= CR;
                    msg_buf[10] <= LF;
                    msg_len <= 6'd11;
                end
            end
            else if (pending_set_temp)
            begin
                // "PTHR> Set XXX C\r\n"  17 bytes
                msg_buf[0]  <= "P"; msg_buf[1]  <= "T";
                msg_buf[2]  <= "H"; msg_buf[3]  <= "R";
                msg_buf[4]  <= ">"; msg_buf[5]  <= " ";
                msg_buf[6]  <= "S"; msg_buf[7]  <= "e";
                msg_buf[8]  <= "t"; msg_buf[9]  <= " ";
                msg_buf[10] <= tth_h;
                msg_buf[11] <= tth_t;
                msg_buf[12] <= tth_u;
                msg_buf[13] <= " "; msg_buf[14] <= "C";
                msg_buf[15] <= CR;  msg_buf[16] <= LF;
                msg_len <= 6'd17;
            end
            else if (pending_set_hum)
            begin
                // "UTHR> Set XXX %\r\n"  17 bytes
                msg_buf[0]  <= "U"; msg_buf[1]  <= "T";
                msg_buf[2]  <= "H"; msg_buf[3]  <= "R";
                msg_buf[4]  <= ">"; msg_buf[5]  <= " ";
                msg_buf[6]  <= "S"; msg_buf[7]  <= "e";
                msg_buf[8]  <= "t"; msg_buf[9]  <= " ";
                msg_buf[10] <= hth_h;
                msg_buf[11] <= hth_t;
                msg_buf[12] <= hth_u;
                msg_buf[13] <= " "; msg_buf[14] <= "%";
                msg_buf[15] <= CR;  msg_buf[16] <= LF;
                msg_len <= 6'd17;
            end
            else if (pending_display)
            begin
                // "DATA> T:XXX C H:XXX %\r\n"  23 bytes
                msg_buf[0]  <= "D"; msg_buf[1]  <= "A";
                msg_buf[2]  <= "T"; msg_buf[3]  <= "A";
                msg_buf[4]  <= ">"; msg_buf[5]  <= " ";
                msg_buf[6]  <= "T"; msg_buf[7]  <= ":";
                msg_buf[8]  <= temp_h;
                msg_buf[9]  <= temp_t;
                msg_buf[10] <= temp_u;
                msg_buf[11] <= " "; msg_buf[12] <= "C";
                msg_buf[13] <= " "; msg_buf[14] <= "H";
                msg_buf[15] <= ":";
                msg_buf[16] <= hum_h;
                msg_buf[17] <= hum_t;
                msg_buf[18] <= hum_u;
                msg_buf[19] <= " "; msg_buf[20] <= "%";
                msg_buf[21] <= CR;  msg_buf[22] <= LF;
                msg_len <= 6'd23;
            end
            else if (pending_auto)
            begin
                // "AUTO> T:XXX C H:XXX %\r\n"  23 bytes
                msg_buf[0]  <= "A"; msg_buf[1]  <= "U";
                msg_buf[2]  <= "T"; msg_buf[3]  <= "O";
                msg_buf[4]  <= ">"; msg_buf[5]  <= " ";
                msg_buf[6]  <= "T"; msg_buf[7]  <= ":";
                msg_buf[8]  <= temp_h;
                msg_buf[9]  <= temp_t;
                msg_buf[10] <= temp_u;
                msg_buf[11] <= " "; msg_buf[12] <= "C";
                msg_buf[13] <= " "; msg_buf[14] <= "H";
                msg_buf[15] <= ":";
                msg_buf[16] <= hum_h;
                msg_buf[17] <= hum_t;
                msg_buf[18] <= hum_u;
                msg_buf[19] <= " "; msg_buf[20] <= "%";
                msg_buf[21] <= CR;  msg_buf[22] <= LF;
                msg_len <= 6'd23;
            end

            msg_idx <= 6'd0;
            state   <= WAIT_READY;
        end

        // ------------------------------------------------
        // WAIT_READY: wait for uart_tx to be free
        // ------------------------------------------------
        WAIT_READY:
        begin
            if (!tx_busy)
                state <= SEND_BYTE;
        end

        // ------------------------------------------------
        // SEND_BYTE: put byte on tx_data, pulse tx_start
        // ------------------------------------------------
        SEND_BYTE:
        begin
            tx_data  <= msg_buf[msg_idx];
            tx_start <= 1'b1;
            state    <= NEXT_BYTE;
        end

        // ------------------------------------------------
        // NEXT_BYTE: wait for tx_busy, then advance index
        // ------------------------------------------------
        NEXT_BYTE:
        begin
            tx_start <= 1'b0;
            if (tx_busy)
            begin
                if (msg_idx == msg_len - 1)
                    state <= DONE;
                else
                begin
                    msg_idx <= msg_idx + 1;
                    state   <= WAIT_READY;
                end
            end
        end

        // ------------------------------------------------
        // DONE: finished sending, back to IDLE
        // ------------------------------------------------
        DONE:
        begin
            log_busy <= 1'b0;
            state    <= IDLE;
        end

        default: state <= IDLE;

        endcase
    end
end

endmodule