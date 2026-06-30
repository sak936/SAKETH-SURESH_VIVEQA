`timescale 1ns / 1ps

module tb_decoder2x4;

reg A,B;
wire [3:0] Y;

decoder2x4 d1(A,B,Y);

initial begin
    A=0; B=0; #10;
    A=0; B=1; #10;
    A=1; B=0; #10;
    A=1; B=1; #10;
    #10 $finish;
end

endmodule