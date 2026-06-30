module tb_jk_ff;

reg clk,J,K;
wire Q;

jk_ff uut(clk,J,K,Q);

initial clk=0;
always #5 clk=~clk;

initial begin
J=0; K=0;     
#10;

J=1; K=0; #10;
J=0; K=0; #10;
J=0; K=1; #10;
J=1; K=1; #10;
J=1; K=1; #10;
J=0; K=0;     
#10;

$finish;
end

endmodule