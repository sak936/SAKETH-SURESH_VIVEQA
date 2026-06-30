module t_ff(clk,rst,T,Q);
input clk,rst,T;
output Q;

wire d;

assign d = T ^ Q;

d_ff dff1(clk,rst,d,Q);

endmodule