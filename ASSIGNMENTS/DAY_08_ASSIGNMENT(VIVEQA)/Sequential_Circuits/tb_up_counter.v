module tb_up_counter;

reg clk,rst,load;
reg [3:0] din;
wire [3:0] count;

up_counter uut(clk,rst,load,din,count);

initial clk=0;
always #5 clk=~clk;

initial begin
rst=1; load=0; din=0;
#10;

rst=0;

load=0; din=4;
#20;

load=1; din=4'b1010;
#10;

load=0;
#40;

load=1; din=4'b0011;
#10;

load=0;
#30;

rst=1;
#10;

rst=0;
load=0;
#20;

$finish;
end

endmodule