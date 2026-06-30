module mux4x1(I0,I1,I2,I3,S0,S1,Y);
input I0,I1,I2,I3,S0,S1;
output Y;

wire w1,w2;

mux2x1 m1(I0,I1,S0,w1);
mux2x1 m2(I2,I3,S0,w2);
mux2x1 m3(w1,w2,S1,Y);

endmodule