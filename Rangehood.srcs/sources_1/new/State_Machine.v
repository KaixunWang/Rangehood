`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/01 23:31:18
// Design Name: 
// Module Name: State_Machine
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


module StateMachine(
    input clk,               // 时钟信号
    input rst_n,             // 复位信号
    input btn_power,         // 开关机按键
    input btn_menu,          // 菜单按键
    input [1:0] btn_level,   // 档位选择
    input btn_clean,         // 清洁模式按钮
    input btn_set_time,      // 时间设置按钮
    input btn_check_time,    // 查看时间按钮
    output reg [3:0] state   // 当前状态
);

    // 状态定义
    parameter POWER_OFF          = 4'b0000;
    parameter STANDBY            = 4'b0001;
    parameter READY_TO_SELECT    = 4'b0010;
    parameter SELF_CLEAN         = 4'b0011;
    parameter LEVEL_1            = 4'b0100;
    parameter LEVEL_2            = 4'b0101;
    parameter LEVEL_3            = 4'b0110;
    parameter CHECK_TIME         = 4'b0111;
    parameter SET_HOUR           = 4'b1000;
    parameter SET_MINUTE         = 4'b1001;
    parameter SET_SECOND         = 4'b1010;
    parameter SET_VALID_TIME     = 4'b1011;

    reg [3:0] next_state;      // 下一状态

    // 状态机转换
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= POWER_OFF;    // 复位时，设置为关机状态
        else
            state <= next_state;   // 正常时更新状态
    end

    // 状态转换逻辑
    always @(*) begin
        case (state)
            POWER_OFF: begin
                if (btn_power)
                    next_state = STANDBY; // 按下开关机按钮时进入待机模式
                else
                    next_state = POWER_OFF;
            end
            STANDBY: begin
                if (btn_power)
                    next_state = POWER_OFF;  // 按下开关机按钮时关机
                else if (btn_menu)
                    next_state = READY_TO_SELECT; // 按下菜单进入选择模式
                else
                    next_state = STANDBY;
            end
            READY_TO_SELECT: begin
                if (btn_level == 2'b01)
                    next_state = LEVEL_1;   // 选择一档
                else if (btn_level == 2'b10)
                    next_state = LEVEL_2;   // 选择二档
                else if (btn_level == 2'b11)
                    next_state = LEVEL_3;   // 选择三档
                else if (btn_clean)
                    next_state = SELF_CLEAN; // 选择自清洁
                else
                    next_state = READY_TO_SELECT;
            end
            LEVEL_1: begin
                if (btn_menu)
                    next_state = STANDBY;   // 按下菜单返回待机模式
                else
                    next_state = LEVEL_1;
            end
            LEVEL_2: begin
                if (btn_menu)
                    next_state = STANDBY;   // 按下菜单返回待机模式
                else
                    next_state = LEVEL_2;
            end
            LEVEL_3: begin
                if (btn_menu)
                    next_state = STANDBY;   // 按下菜单返回待机模式
                else
                    next_state = LEVEL_3;
            end
            SELF_CLEAN: begin
                if (btn_menu)
                    next_state = STANDBY;   // 按下菜单返回待机模式
                else
                    next_state = SELF_CLEAN;
            end
            CHECK_TIME: begin
                if (btn_set_time)
                    next_state = SET_HOUR;  // 按下时间设置按钮进入设置小时模式
                else
                    next_state = CHECK_TIME;
            end
            SET_HOUR: begin
                if (btn_check_time)
                    next_state = SET_MINUTE;  // 按下确认进入设置分钟模式
                else
                    next_state = SET_HOUR;
            end
            SET_MINUTE: begin
                if (btn_check_time)
                    next_state = SET_SECOND;  // 按下确认进入设置秒模式
                else
                    next_state = SET_MINUTE;
            end
            SET_SECOND: begin
                if (btn_check_time)
                    next_state = STANDBY;   // 完成设置，回到待机模式
                else
                    next_state = SET_SECOND;
            end
            SET_VALID_TIME: begin
                if (btn_check_time)
                    next_state = STANDBY;   // 设置有效时间完成后返回待机模式
                else
                    next_state = SET_VALID_TIME;
            end
            default: next_state = POWER_OFF;
        endcase
    end

endmodule
