`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/15 22:01:32
// Design Name: 
// Module Name: slow_clk_0p6s
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



module clk_divider_0p05(
    input wire clk_in,       // 输入时钟信号 (100 MHz)
    input wire rst_n,        // 异步复位信号，低有效
    output reg clk_out       // 输出 1 Hz 时钟信号
);

    reg [26:0] counter;      // 计数器，27 位可计数到 2^27 - 1 (> 100,000,000)

    // 参数定义
    parameter DIV_COUNT = 5_000_000; // 100 MHz 时钟对应的计数上限

    // 分频逻辑
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            clk_out <= 0;
        end else begin
            if (counter == DIV_COUNT - 1) begin
                counter <= 0;         // 计数器清零
                clk_out <= ~clk_out; // 翻转输出时钟
            end else begin
                counter <= counter + 1; // 计数器递增
            end
        end
    end

endmodule
