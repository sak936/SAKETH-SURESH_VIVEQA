module mod12_counter(clk,rst,load,din,count);
input clk,rst,load;
input [3:0] din;
output reg [3:0] count;

always @(posedge clk)
begin
if(rst)
count<=4'b0000;
else if(load)
count<=din;
else if(count==4'b1011)
count<=4'b0000;
else
count<=count+1;
end

endmodule