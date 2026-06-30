module tb_mod12_counter;

reg clk,rst,load;
reg [3:0] din;
wire [3:0] count;

mod12_counter uut(clk,rst,load,din,count);

initial clk=0;
always #5 clk=~clk;

initial begin
rst=1; load=0; din=4'b0000;
#10;

rst=0;

load=0;
#60;

load=1; din=4'b1001;
#10;

load=0;
#40;

load=1; din=4'b0011;
#10;

load=0;
#80;

rst=1;
#10;

rst=0;
#20;

$finish;
end

endmodule