module updown_counter(clk,rst,load,up_down,din,count);
input clk,rst,load,up_down;
input [3:0] din;
output reg [3:0] count;

always @(posedge clk)
begin
if(rst)
count<=4'b0000;
else if(load)
count<=din;
else if(up_down)
count<=count+1;
else
count<=count-1;
end

endmodule