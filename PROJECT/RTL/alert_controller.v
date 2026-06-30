`timescale 1ns / 1ps
module alert_controller(
    input clk,             // 24 MHz clock
    input rst,
    input [7:0] temperature,
    input [7:0] humidity,
    input [7:0] temp_threshold,
    input [7:0] hum_threshold,
    output reg buzzer,
    output reg alert_flag
);

    // 2.7 kHz Tone Generation: 24,000,000 / (2700 * 2) = ~4444 ticks per toggle
    localparam TONE_HALF_PERIOD = 14'd4444; 
    reg [13:0] tone_cnt;
    reg        tone_reg;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            tone_cnt <= 0;
            tone_reg <= 0;
            buzzer   <= 1'b0;
            alert_flag <= 1'b0;
        end else begin
            if((temperature > temp_threshold) || (humidity > hum_threshold)) begin
                alert_flag <= 1'b1;
                
                // Toggle the audio signal at 2.7kHz
                if(tone_cnt >= TONE_HALF_PERIOD - 1) begin
                    tone_cnt <= 0;
                    tone_reg <= ~tone_reg;
                end else begin
                    tone_cnt <= tone_cnt + 1;
                end
                
                buzzer <= tone_reg; // Output the resonant square wave
            end else begin
                alert_flag <= 1'b0;
                tone_cnt   <= 0;
                tone_reg   <= 0;
                buzzer     <= 1'b0;
            end
        end
    end
endmodule