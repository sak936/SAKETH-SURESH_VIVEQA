module mux2x1(I0,I1,S,Y);
input [2:0] I0,I1;
input S;
output [2:0] Y;

assign Y=S?I1:I0;

endmodule