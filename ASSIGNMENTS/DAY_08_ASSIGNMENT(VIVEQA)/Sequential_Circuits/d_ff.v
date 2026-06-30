module d_ff(clk,rst,D,Q);
input clk,rst,D;
output reg Q;

always @(clk or rst)
begin
if(rst)
Q<=0;
else
Q<=D;
end

endmodule