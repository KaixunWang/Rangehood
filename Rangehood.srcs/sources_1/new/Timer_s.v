`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/15 04:02:40
// Design Name: 
// Module Name: Timer_s
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


module Timer_s(
    input wire clk,                // 100 MHz 时钟信号
    input wire rst_n,              // 复位信号，低电平有效
    input wire start,              // 启动计时信号
    input wire [9:0] max_time,     // 计时最大值（单位：秒）
    output reg timeout             // 超时信号，高电平有效
);

    reg [26:0] clk_divider;        // 分频计数器（log2(100M) = 27位）
    reg one_hz_clk;                // 1 Hz 时钟
    reg [9:0] counter;             // 秒计数器

    // 时钟分频逻辑（100 MHz -> 1 Hz）
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            clk_divider <= 27'b0;
            one_hz_clk <= 1'b0;
        end else begin
            if (clk_divider == 27'd49999999) begin 
                clk_divider <= 27'b0;
                one_hz_clk <= ~one_hz_clk;  // 翻转产生1 Hz信号
            end else begin
                clk_divider <= clk_divider + 1'b1;
            end
        end
    end

    // 秒计时逻辑
    always @(posedge one_hz_clk or negedge rst_n) begin
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

