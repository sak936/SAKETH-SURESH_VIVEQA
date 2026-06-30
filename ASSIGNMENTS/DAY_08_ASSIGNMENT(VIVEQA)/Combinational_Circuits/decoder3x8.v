module decoder3x8(A,B,C,Y);
input A,B,C;
output [7:0] Y;

assign Y[0]=~A&~B&~C;
assign Y[1]=~A&~B&C;
assign Y[2]=~A&B&~C;
assign Y[3]=~A&B&C;
assign Y[4]=A&~B&~C;
assign Y[5]=A&~B&C;
assign Y[6]=A&B&~C;
assign Y[7]=A&B&C;

endmodule