`timescale 1ns / 1ps

module tb_mux4x1;

reg I0,I1,I2,I3,S0,S1;
wire Y;

mux4x1 m(I0,I1,I2,I3,S0,S1,Y);

initial begin
    I0=0; I1=1; I2=0; I3=1;

    S1=0; S0=0; #10;
    S1=0; S0=1; #10;
    S1=1; S0=0; #10;
    S1=1; S0=1; #10;

    I0=1; I1=0; I2=1; I3=0;

    S1=0; S0=0; #10;
    S1=0; S0=1; #10;
    S1=1; S0=0; #10;
    S1=1; S0=1; #10;

    #10 $finish;
end

endmodule