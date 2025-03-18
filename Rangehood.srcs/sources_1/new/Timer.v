`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/20 12:17:52
// Design Name: 
// Module Name: Timer
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

module Timer(
    input wire clk,                // 100 MHz 时钟信号
    input wire rst_n,              // 复位信号，低电平有效
    input wire start,              // 启动计时信号
    input wire [9:0] max_time,     // 计时周期最大值
    output reg timeout             // 超时信号，高电平有效
);

    reg [9:0] counter;             // 计数器

    // 秒计时逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 10'b0;      // 复位时计数器清零
            timeout <= 1'b0;
        end else if (start) begin
            if (counter >= max_time) begin
                timeout <= 1'b1;  // 超时信号
            end else begin
                counter <= counter + 1'b1; // 每秒递增
                timeout <= 1'b0;
            end
        end else begin
            counter <= 10'b0;      // 如果未启动计时，计数器清零
            timeout <= 1'b0;
        end
    end

endmodule