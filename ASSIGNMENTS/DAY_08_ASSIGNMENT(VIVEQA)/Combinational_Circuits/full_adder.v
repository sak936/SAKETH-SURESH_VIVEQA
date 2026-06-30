module full_adder (
    input  A,B,Cin,
    output S,Cout);

assign S = A ^ B ^ Cin;
assign Cout = (A & B) | (B & Cin) | (A & Cin);

endmodule