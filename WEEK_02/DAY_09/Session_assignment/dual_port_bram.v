module dual_port_bram (
    input clk,

    // Port A
    input we_a,
    input [3:0] addr_a,
    input [31:0] din_a,
    output reg [31:0] dout_a,

    // Port B
    input we_b,
    input [3:0] addr_b,
    input [31:0] din_b,
    output reg [31:0] dout_b
);

reg [31:0] mem [0:15];

always @(posedge clk)
begin
    // Port A
    if (we_a)
        mem[addr_a] <= din_a;
    dout_a <= mem[addr_a];

    // Port B
    if (we_b)
        mem[addr_b] <= din_b;
    dout_b <= mem[addr_b];
end

endmodule