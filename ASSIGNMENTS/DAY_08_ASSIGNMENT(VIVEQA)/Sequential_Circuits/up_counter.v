module up_counter(clk,rst,load,din,count);
input clk,rst,load;
input [3:0] din;
output reg [3:0] count;

always @(posedge clk)
begin
if(rst)
count<=0;
else if(load)
count<=din;
else
count<=count+1;
end

endmodule