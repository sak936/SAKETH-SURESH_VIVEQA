`timescale 1ns / 1ps
module uart_tx(
    input clk,              // 24 MHz clock
    input rst,
    input tx_start,
    input [7:0] tx_data,
    output reg tx,
    output reg tx_busy
);

    parameter CLK_FREQ = 24000000;
    parameter BAUD_RATE = 9600;

    localparam BAUD_TICK = CLK_FREQ / BAUD_RATE;

    reg [13:0] baud_cnt;
    reg [3:0] bit_cnt;
    reg [9:0] tx_shift;

    always @(posedge clk or posedge rst)
    begin
        if (rst)
        begin
            tx <= 1'b1;
            tx_busy <= 1'b0;
            baud_cnt <= 0;
            bit_cnt <= 0;
            tx_shift <= 10'b1111111111;
        end
        else
        begin
            if (tx_start && !tx_busy)
            begin
                // UART Frame:
                // Start bit + 8 data bits + Stop bit
                tx_shift <= {1'b1, tx_data, 1'b0};

                tx_busy <= 1'b1;
                bit_cnt <= 0;
                baud_cnt <= 0;
            end
            else if (tx_busy)
            begin
                if (baud_cnt < BAUD_TICK-1)
                begin
                    baud_cnt <= baud_cnt + 1;
                end
                else
                begin
                    baud_cnt <= 0;

                    tx <= tx_shift[0];
                    tx_shift <= {1'b1, tx_shift[9:1]};

                    if (bit_cnt < 9)
                    begin
                        bit_cnt <= bit_cnt + 1;
                    end
                    else
                    begin
                        tx_busy <= 1'b0;
                        tx <= 1'b1;
                    end
                end
            end
        end
    end

endmodule