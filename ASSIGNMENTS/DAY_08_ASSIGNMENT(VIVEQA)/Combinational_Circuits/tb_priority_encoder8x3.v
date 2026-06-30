`timescale 1ns / 1ps

module tb_priority_encoder8x3;

reg [7:0] D;
wire [2:0] Y;

priority_encoder8x3 pe(D,Y);

initial begin
    D=8'b00000001; #10;
    D=8'b00000010; #10;
    D=8'b00000100; #10;
    D=8'b00001000; #10;
    D=8'b00010000; #10;
    D=8'b00100000; #10;
    D=8'b01000000; #10;
    D=8'b10000000; #10;

    D=8'b00101010; #10;
    D=8'b11001001; #10;
    D=8'b11111111; #10;

    #10 $finish;
end

endmodule