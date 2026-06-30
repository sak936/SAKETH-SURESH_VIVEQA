`timescale 1ns / 1ps

module fifo #(
    parameter DEPTH = 16
)(
    input wire clk,
    input wire rst,
    input wire wr_en,
    input wire rd_en,
    input wire [7:0] din,
    output reg [7:0] dout,
    output wire full,
    output wire empty
);

    reg [7:0] mem [0:DEPTH-1];
    reg [4:0] wr_ptr;
    reg [4:0] rd_ptr;
    reg [4:0] count;

    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
            dout   <= 8'h00;
        end else begin
            // Concurrent Read and Write
            if (wr_en && !full && rd_en && !empty) begin
                mem[wr_ptr[3:0]] <= din;
                wr_ptr           <= wr_ptr + 1;
                dout             <= mem[rd_ptr[3:0]];
                rd_ptr           <= rd_ptr + 1;
                // count remains unchanged (+1 -1)
            end
            // Write Only
            else if (wr_en && !full) begin
                mem[wr_ptr[3:0]] <= din;
                wr_ptr           <= wr_ptr + 1;
                count            <= count + 1;
            end
            // Read Only
            else if (rd_en && !empty) begin
                dout   <= mem[rd_ptr[3:0]];
                rd_ptr <= rd_ptr + 1;
                count  <= count - 1;
            end
        end
    end

endmodule