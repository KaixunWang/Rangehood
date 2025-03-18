`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/15 02:59:50
// Design Name: 
// Module Name: Button_Press_Handler
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


module Button_Press_Handler_power (
    input wire clk,           // 时钟信号
    input wire rst_n,         // 异步复位信号，低有效
    input wire btn_stable,    // 已经消抖过的按钮信号
    output reg short_press,   // 短按标志
    output reg long_press     // 长按标志
);

    // 参数定义
    parameter LONG_PRESS_TIME = 300_000_000; // 长按时间阈值（时钟周期数）300000000

    // 中间信号定义
    reg [32:0] press_counter;   // 计数器，用于计时按钮按下的时间
    reg btn_prev;               // 记录上一时钟周期的按钮状态

    // 长按和短按检测逻辑
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            press_counter <= 0;
            short_press <= 0;
            long_press <= 0;
            btn_prev <= 0;
        end else begin
            short_press <= 0; // 清除短按标志
            long_press <= 0;  // 清除长按标志
            btn_prev <= btn_stable;

            if (btn_stable && !btn_prev) begin
                // 按钮按下，开始计时
                press_counter <= 0;
            end else if (!btn_stable && btn_prev) begin
                // 按钮松开，根据计数器判断长按或短按
                if (press_counter < LONG_PRESS_TIME) begin
                    short_press <= 1; // 短按
                end else begin
                    long_press <= 1; // 长按
                end
            end else if (btn_stable) begin
                // 按钮保持按下，计数器递增
                press_counter <= press_counter + 1;
            end
        end
    end

endmodule