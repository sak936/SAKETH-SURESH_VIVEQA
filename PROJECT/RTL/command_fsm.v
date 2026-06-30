`timescale 1ns / 1ps

module command_fsm(
    input wire clk,
    input wire rst,
    input wire [7:0] rx_data,
    input wire rx_done,

    // Status / Mode Requests
    output reg temp_req, hum_req, status_req, log_req, clear_req, fifo_req, alert_req, display_req,
    
    // Manual Value Configuration Outputs
    output reg set_temp_req,
    output reg set_hum_req,
    output reg [7:0] manual_value // Sends the fully computed integer back to the manager
);

    // FSM State Encodings
    localparam STATE_IDLE      = 2'd0;
    localparam STATE_FIRST_DIGIT= 2'd1;
    localparam STATE_SECOND_DIGIT= 2'd2;

    reg [1:0] state;
    reg [3:0] temp_digit_1; // Stores the tens digit
    reg       is_setting_temp; // Tracks if modifying temp (1) or hum (0)

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            state           <= STATE_IDLE;
            temp_digit_1    <= 0;
            is_setting_temp <= 0;
            manual_value    <= 0;
            temp_req <= 0; hum_req <= 0; status_req <= 0; log_req <= 0;
            clear_req <= 0; fifo_req <= 0; alert_req <= 0; display_req <= 0;
            set_temp_req <= 0; set_hum_req <= 0;
        end else begin
            // Single pulse defaults
            temp_req     <= 0; hum_req      <= 0; status_req   <= 0; log_req      <= 0;
            clear_req    <= 0; fifo_req     <= 0; alert_req    <= 0; display_req  <= 0;
            set_temp_req <= 0; set_hum_req  <= 0;

            if(rx_done) begin
                case(state)
                    
                    // --------------------------------------------------------
                    STATE_IDLE: begin
                        case(rx_data)
                            "T": temp_req    <= 1;
                            "H": hum_req     <= 1;
                            "S": status_req  <= 1;
                            "L": log_req     <= 1;
                            "C": clear_req   <= 1;
                            "F": fifo_req    <= 1;
                            "A": alert_req   <= 1;
                            "D": display_req <= 1;
                            
                            // Setup user configuration input paths
                            "P": begin 
                                is_setting_temp <= 1'b1; 
                                state           <= STATE_FIRST_DIGIT; 
                            end
                            "U": begin 
                                is_setting_temp <= 1'b0; 
                                state           <= STATE_FIRST_DIGIT; 
                            end
                            default: state <= STATE_IDLE;
                        endcase
                    end

                    // --------------------------------------------------------
                    STATE_FIRST_DIGIT: begin
                        // Validate character is a valid number ('0' through '9')
                        if (rx_data >= "0" && rx_data <= "9") begin
                            temp_digit_1 <= rx_data - 8'd48; // Convert ASCII char to integer value
                            state        <= STATE_SECOND_DIGIT;
                        end else begin
                            state        <= STATE_IDLE; // Non-numeric character aborts
                        end
                    end

                    // --------------------------------------------------------
                    STATE_SECOND_DIGIT: begin
                        if (rx_data >= "0" && rx_data <= "9") begin
                            // Calculation: Total = (Tens * 10) + Units
                            manual_value <= (temp_digit_1 * 10) + (rx_data - 8'd48);
                            
                            if (is_setting_temp)
                                set_temp_req <= 1'b1;
                            else
                                set_hum_req  <= 1'b1;
                        end
                        state <= STATE_IDLE; // Return to monitoring commands
                    end

                    default: state <= STATE_IDLE;
                endcase
            end
        end
    end
endmodule