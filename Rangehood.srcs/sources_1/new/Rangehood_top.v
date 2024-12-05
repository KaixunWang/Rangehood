`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/01 20:41:45
// Design Name: 
// Module Name: Rangehood_top
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


module Rangehood_Top(
    input clk,                              // 系统时钟信号
    input btn_power,                        // 开关机按键
    input rst_n,                            // 恢复出厂设置按键
    input btn_menu,                         // 菜单按键
    input btn_confirm,                      // 确认按键
    input [1:0] btn_level,                  // 档位选择(00自清洁,01一档,10二档,11三档)
    input btn_manual_set_work_time,         // 手动设置工作时间为0
    input btn_light,                        // 照明按键
    input btn_set_time,                     // 时间设置按键
    input btn_check_time,                   // 时间查看设置
    input hand_left,                        // 手势左键
    input hand_right,                       // 手势右键
    input [7:0] btns_time_set,              // 时间设置拨码开关
    output [7:0] seg_data,                  // 数码管数据
    output [7:0] seg_select,                // 数码管选择信号
    output reg light_lighting,              // 照明状态（LED)
    output reg light_need_self_cleaning,    // 照明状态 (是否需要清洁)
    output reg power
    );

    //信号定义
    wire clk_slow;              // 慢时钟信号
    wire power_state;           // 当前电源状态
    wire [3:0] mode_state;      // 当前模式（0000关机,0001stand-by,0010ready-to-select,0011自清洁,0100一档,0101二档,0110三档,0111检查时间,1000设置小时,1001设置分钟,1010设置秒,1011设置有效时间）
    wire [31:0] current_time;   // 当前时间 (hh:mm:ss)
    wire [31:0] countdown_time; // 倒计时时间 (mm:ss)
    wire time_setting_active;   // 时间设置模式激活信号
    wire cleaning_reminder;     // 清洁提醒信号
    wire [2:0] fan_level;       // 当前档位
    wire level3_is_used;        // 三档有没有用过

    //参数定义
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
    
    //模块实例化
    // 时钟分频
    Clock_Divider clock_divider (
        .clk(clk),
        .rst_n(rst_n),
        .clk_out(clk_slow)
    );
    
    // 状态机
    State_Machine state_machine (
        .clk(clk),
        .rst_n(rst_n),
        .btn_power(btn_power),
        .btn_menu(btn_menu),
        .btn_level(btn_level),
        .btn_clean(btn_clean),
        .btn_set_time(btn_set_time),
        .btn_check_time(btn_check_time),
        .state(mode_state)
    );

    // 档位控制
    Fan_Control fan_control (
    );

    // 时间显示与倒计时
    Time_Manager time_manager (
    );

    // 显示模块
    Display_Manager display_manager (
    );

endmodule
