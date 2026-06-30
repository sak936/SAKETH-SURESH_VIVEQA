module tb_updown_counter;

reg clk,rst,load,up_down;
reg [3:0] din;
wire [3:0] count;

updown_counter uut(clk,rst,load,up_down,din,count);

initial clk=0;
always #5 clk=~clk;

initial begin
rst=1; load=0; up_down=1; din=4'b0000;
#10;

rst=0;

load=1; din=4'b0101;
#10;

load=0;
up_down=1;
#40;

up_down=0;
#40;

load=1; din=4'b1010;
#10;

load=0;
up_down=0;
#40;

rst=1;
#10;

rst=0;
#20;

$finish;
end

endmodule