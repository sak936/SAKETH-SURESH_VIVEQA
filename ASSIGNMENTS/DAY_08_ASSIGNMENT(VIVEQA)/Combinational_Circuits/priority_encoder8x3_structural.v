module priority_encoder8x3_structural(D,Y);
input [7:0] D;
output [2:0] Y;

wire [2:0] y1,y2,y3,y4,y5,y6;

mux2x1 m1(3'b000,3'b001,D[1],y1);
mux2x1 m2(y1,3'b010,D[2],y2);
mux2x1 m3(y2,3'b011,D[3],y3);
mux2x1 m4(y3,3'b100,D[4],y4);
mux2x1 m5(y4,3'b101,D[5],y5);
mux2x1 m6(y5,3'b110,D[6],y6);
mux2x1 m7(y6,3'b111,D[7],Y);

endmodule