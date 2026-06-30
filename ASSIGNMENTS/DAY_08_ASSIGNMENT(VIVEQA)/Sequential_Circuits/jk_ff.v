module jk_ff(clk,J,K,Q);
input clk,J,K;
output reg Q;

parameter HOLD=2'b00,
          RESET=2'b01,
          SET=2'b10,
          TOGGLE=2'b11;

always @(posedge clk)
begin
case({J,K})
HOLD:   Q<=Q;
RESET:  Q<=0;
SET:    Q<=1;
TOGGLE: Q<=~Q;
endcase
end

endmodule