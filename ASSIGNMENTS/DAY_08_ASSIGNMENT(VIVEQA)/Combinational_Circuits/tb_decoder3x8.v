`timescale 1ns / 1ps

module tb_decoder3x8;

reg A,B,C;
wire [7:0] Y;
integer i;

decoder3x8 d1(A,B,C,Y);

initial begin
    for(i=0;i<8;i=i+1) begin
        {A,B,C}=i;
        #10;
    end
    #10 $finish;
end

endmodule