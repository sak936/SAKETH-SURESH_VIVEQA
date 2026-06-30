`timescale 1ns / 1ps

module dht11_controller (
    input wire clk,                  // 24 MHz clock input
    input wire rst,                  // Active-high synchronous reset
    input wire start,                // Trigger pulse to start a reading (from top_module)
    inout wire dht_data,             // Bidirectional single-wire data line
    output reg [7:0] humidity,       // 8-bit Integral Humidity
    output reg [7:0] temperature,    // 8-bit Integral Temperature
    output reg data_valid,           // High for 1 clock cycle when data passes all checks
    output reg error                 // High if checksum or sanity check fails
);

    // --- Timing Constants for 24 MHz Clock (1 tick = ~41.67 ns) ---
    localparam TICKS_18MS      = 24 * 18000; // 432,000 ticks (Host start low duration)
    localparam TICKS_30US      = 24 * 30;    // 720 ticks (Host pull-up duration)
    localparam TICKS_47US_THRES= 24 * 47;    // 1,128 ticks (Midpoint bit threshold)
    localparam TIME_OUT_LIMIT  = 24 * 150;   // 3,600 ticks (Safety timeout for response edges)

    // --- 10-State FSM State Encoding ---
    localparam STATE_IDLE             = 4'd0;
    localparam STATE_START_LOW        = 4'd1;
    localparam STATE_START_HIGH       = 4'd2;
    localparam STATE_WAIT_RESP_LOW    = 4'd3;
    localparam STATE_RESP_LOW         = 4'd4;
    localparam STATE_RESP_HIGH        = 4'd5;
    localparam STATE_BIT_LOW          = 4'd6;
    localparam STATE_BIT_HIGH         = 4'd7;
    localparam STATE_STORE_BIT        = 4'd8;
    localparam STATE_CHECK_DATA       = 4'd9;

    reg [3:0]  state, next_state;
    reg [19:0] timer;                // 20-bit counter safely holds up to 432,000 ticks
    reg [5:0]  bit_cnt;              // Counts 0 to 39 bits
    reg [39:0] shift_reg;            // Holds 40 bits of raw incoming DHT11 packet
    reg [19:0] high_duration;        // FIXED: Capture register for the high-pulse timer width

    // --- Tri-State / Bidirectional Control ---
    reg dht_out;
    reg dht_dir; // 1 = Output (FPGA drives line), 0 = Input (High-Z / Pull-up module listens)

    assign dht_data = (dht_dir) ? dht_out : 1'bZ;

    // --- 2-Stage Input Synchronizer ---
    reg dht_in_raw, dht_in;
    always @(posedge clk) begin
        if (rst) begin
            dht_in_raw <= 1'b1;
            dht_in     <= 1'b1;
        end else begin
            dht_in_raw <= dht_data;
            dht_in     <= dht_in_raw;
        end
    end

    // --- FSM State Transitions & Counter Control ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            timer <= 0;
        end else begin
            state <= next_state;
            
            // Clean timer control on state boundaries
            if (state != next_state) begin
                timer <= 0;
            end else begin
                timer <= timer + 1;
            end
        end
    end

    // --- FSM Next State Combinational Logic ---
    always @(*) begin
        next_state = state;
        case (state)
            STATE_IDLE: begin
                if (start) next_state = STATE_START_LOW;
            end

            STATE_START_LOW: begin
                if (timer >= TICKS_18MS) next_state = STATE_START_HIGH;
            end

            STATE_START_HIGH: begin
                if (timer >= TICKS_30US) next_state = STATE_WAIT_RESP_LOW;
            end

            STATE_WAIT_RESP_LOW: begin
                if (!dht_in)             next_state = STATE_RESP_LOW;
                else if (timer > TIME_OUT_LIMIT) next_state = STATE_IDLE; // Timeout fail
            end

            STATE_RESP_LOW: begin
                if (dht_in)              next_state = STATE_RESP_HIGH;
                else if (timer > TIME_OUT_LIMIT) next_state = STATE_IDLE;
            end

            STATE_RESP_HIGH: begin
                if (!dht_in)             next_state = STATE_BIT_LOW;
                else if (timer > TIME_OUT_LIMIT) next_state = STATE_IDLE;
            end

            STATE_BIT_LOW: begin
                if (dht_in)              next_state = STATE_BIT_HIGH;
                else if (timer > TIME_OUT_LIMIT) next_state = STATE_IDLE;
            end

            STATE_BIT_HIGH: begin
                if (!dht_in)             next_state = STATE_STORE_BIT; // Captures falling edge
                else if (timer > TIME_OUT_LIMIT) next_state = STATE_IDLE;
            end

            STATE_STORE_BIT: begin
                if (bit_cnt >= 39)       next_state = STATE_CHECK_DATA;
                else                     next_state = STATE_BIT_LOW;
            end

            STATE_CHECK_DATA: begin
                next_state = STATE_IDLE;
            end

            default: next_state = STATE_IDLE;
        endcase
    end

    // --- Registered Output & Datapath Logic ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dht_dir       <= 1'b0; // Default to input listening mode
            dht_out       <= 1'b1;
            bit_cnt       <= 0;
            shift_reg     <= 40'b0;
            humidity      <= 8'h00;
            temperature   <= 8'h00;
            data_valid    <= 1'b0;
            error         <= 1'b0;
            high_duration <= 0;
        end else begin
            data_valid    <= 1'b0; // Assert as default single clock pulse
            error         <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    dht_dir <= 1'b0;
                    dht_out <= 1'b1;
                    bit_cnt <= 0;
                end

                STATE_START_LOW: begin
                    dht_dir <= 1'b1; // FPGA actively drives the single-wire bus
                    dht_out <= 1'b0; // Drive bus low for start condition
                end

                STATE_START_HIGH: begin
                    dht_dir <= 1'b0; // Release line to allow module pull-up to pull high
                    dht_out <= 1'b1;
                end

                STATE_BIT_HIGH: begin
                    // FIXED (Issue 1): Lock the current timer width continuously right up 
                    // until the FSM steps to STATE_STORE_BIT.
                    high_duration <= timer; 
                end

                STATE_STORE_BIT: begin
                    // FIXED (Issue 2): Compare captured duration cleanly against 47us threshold
                    if (high_duration >= TICKS_47US_THRES) begin
                        shift_reg <= {shift_reg[38:0], 1'b1};
                    end else begin
                        shift_reg <= {shift_reg[38:0], 1'b0};
                    end
                    bit_cnt <= bit_cnt + 1;
                end

                STATE_CHECK_DATA: begin
                    // Checksum Calculation: Byte 4 = Byte0 + Byte1 + Byte2 + Byte3
                    if ((shift_reg[39:32] + shift_reg[31:24] + shift_reg[23:16] + shift_reg[15:8]) == shift_reg[7:0]) begin
                        // FIXED (Issue 2 Part 2): Add hard physical environmental constraints check
                        if (shift_reg[39:32] <= 8'd99 && shift_reg[23:16] <= 8'd80) begin
                            humidity    <= shift_reg[39:32];
                            temperature <= shift_reg[23:16];
                            data_valid  <= 1'b1;
                            error       <= 1'b0;
                        end else begin
                            error       <= 1'b1; // Checksum passed, but data failed environmental limits
                        end
                    end else begin
                        error           <= 1'b1; // Packet corrupted (Checksum calculation failed)
                    end
                end
            endcase
        end
    end

endmodule