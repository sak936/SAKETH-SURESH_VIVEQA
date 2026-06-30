module tb_t_ff;

reg clk,rst,T;
wire Q;

t_ff uut(clk,rst,T,Q);

initial clk=0;
always #5 clk=~clk;

initial begin
rst=1; T=0; #10;

rst=0;

T=0;#10;
T=1;#10;
T=1;#10;
T=0;#10;
T=1;#10;

rst=1;#10;

rst=0;#10;
T=1;#10;

$finish;
end

endmodule