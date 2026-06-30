module priority_encoder8x3(D,Y);
input [7:0] D;
output reg [2:0] Y;

always @(D)
begin
    if(D[7]) Y=3'b111;
    else if(D[6]) Y=3'b110;
    else if(D[5]) Y=3'b101;
    else if(D[4]) Y=3'b100;
    else if(D[3]) Y=3'b011;
    else if(D[2]) Y=3'b010;
    else if(D[1]) Y=3'b001;
    else Y=3'b000;
end

endmodule