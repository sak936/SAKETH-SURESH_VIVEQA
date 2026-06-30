module decoder2x4(A,B,Y);
input A,B;
output [3:0] Y;

assign Y[0]=~A&~B;
assign Y[1]=~A&B;
assign Y[2]=A&~B;
assign Y[3]=A&B;

endmodule