/*A memory has two different ports to Write Data and to Read data 
and different addresses and Enable Signals */

module block_ram(clk,w_addr,r_addr,we,re,write_data,read_data);
input clk;
input [9:0]w_addr;
input [9:0]r_addr;
input we;
input re;
input [31:0]write_data;
output reg[31:0]read_data;

reg [31:0]mem[0:1023];

always@(posedge clk)begin
   if(we)
    mem[w_addr] <=write_data;
end

always@(posedge clk)begin
   if(re)
     read_data <=mem[r_addr];
end

endmodule
