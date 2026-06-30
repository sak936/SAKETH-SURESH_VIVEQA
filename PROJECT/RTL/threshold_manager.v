`timescale 1ns / 1ps
module threshold_manager(
    input clk,
    input rst,

    input set_temp,
    input set_hum,

    input [7:0] temp_value,
    input [7:0] hum_value,

    output reg [7:0] temp_threshold,
    output reg [7:0] hum_threshold
);

always @(posedge clk or posedge rst)
begin
    if(rst)
    begin
        temp_threshold <= 8'd30; // Default 30°C
        hum_threshold  <= 8'd70; // Default 70%
    end
    else
    begin
        if(set_temp)
            temp_threshold <= temp_value;

        if(set_hum)
            hum_threshold <= hum_value;
    end
end

endmodule
