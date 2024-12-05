`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/01 23:31:08
// Design Name: 
// Module Name: Clock_Divider
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Clock_Divider(
    input clk,           // 100 MHz 输入时钟
    input rst_n,         // 异步复位信号
    output reg clk_out   // 1 Hz 输出时钟
    );
    // 100 MHz 分频器计数器
    reg [26:0] counter;

    // 1 秒钟周期的计数值
    parameter COUNT_MAX = 100_000_000 - 1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            if (counter == COUNT_MAX) begin
                counter <= 0;
                clk_out <= ~clk_out;  
            end else begin
                counter <= counter + 1;
            end
        end
    end
endmodule
