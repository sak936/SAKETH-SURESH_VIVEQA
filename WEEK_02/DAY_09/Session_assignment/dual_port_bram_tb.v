module dual_port_bram_tb;

reg clk;
reg we_a, we_b;
reg [3:0] addr_a, addr_b;
reg [31:0] din_a, din_b;
wire [31:0] dout_a, dout_b;

dual_port_bram uut (
    .clk(clk),
    .we_a(we_a),
    .addr_a(addr_a),
    .din_a(din_a),
    .dout_a(dout_a),

    .we_b(we_b),
    .addr_b(addr_b),
    .din_b(din_b),
    .dout_b(dout_b)
);

always #5 clk = ~clk;

initial
begin
    clk = 0;

    // Write through Port A
    we_a = 1;
    addr_a = 4'd1;
    din_a = 32'd100;

    // Write through Port B
    we_b = 1;
    addr_b = 4'd2;
    din_b = 32'd200;

    #10;

    // Read back
    we_a = 0;
    we_b = 0;

    addr_a = 4'd1;
    addr_b = 4'd2;

    #20;

    $finish;
end

endmodule