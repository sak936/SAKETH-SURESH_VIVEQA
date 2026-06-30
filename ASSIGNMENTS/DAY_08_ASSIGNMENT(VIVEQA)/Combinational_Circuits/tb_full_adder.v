`timescale 1ns / 1ps

module tb_full_adder;

reg a, b, cin;
wire sum, cout;

integer i;

full_adder fa1(a,b,cin,sum,cout);

initial begin
for(i = 0; i < 8; i = i + 1) begin
    {a, b, cin} = i;
    #10;
end

#10;
$finish;
end

endmodule