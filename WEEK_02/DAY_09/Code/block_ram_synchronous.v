//Synchronous Write & Read
//32 Width 1024 Depth
//we =1 write the data at the posedge of clock
//we =0 read the at the posedge of clock
module block_ram(clk,addr,we,write_data,read_data);
input clk;
input [9:0]addr;
input we;
input [31:0]write_data;
output reg [31:0]read_data;

reg [31:0]mem[0:1023];

always@(posedge clk)begin
   if(we)
    mem[addr] <=write_data;
   else
    read_data <=mem[addr];
end
endmodule