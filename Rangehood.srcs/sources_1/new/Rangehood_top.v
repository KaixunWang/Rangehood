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
    input clk,                         // 系统时钟信号
    input btn_power,                   // 开关机按键
    input rst_n,                       // 恢复出厂设置按键
    input btn_menu,                    // 菜单按键
    input btn_confirm,                 // 确认按键
    input [1:0] btn_level,             // 档位选择(00自清洁,01一档,10二档,11三档)
    input btn_manual_set_work_time,    // 手动设置工作时间置0
    input btn_light,                   // 照明按键
    input btn_set_time,                // 时间设置按键
    input btn_check_time,              // 时间查看设置
    input btn_toggle,                  // 切换按键
    input hand_left,                   // 手势左键
    input hand_right,                  // 手势右键
    input [7:0] btns_time_set,         // 时间设置拨码开关
    output reg [3:0] state_indicator,  // 当前状态指示
    output reg light_lighting,        // 照明状态（LED)
    output light_need_self_cleaning, // 照明状态 (是否需要清洁)
    output [7:0] seg_en, // 输出控制信号
    output [7:0] seg_out_0, // 输出控制信号0 
    output [7:0] seg_out_1 // 输出控制信号1
);

// 信号定义
wire power_state;                     // 当前电源状态
wire [3:0] mode_state;                // 当前模式
wire [3:0] next_state;                  //下一模式
wire [31:0] current_time;             // 当前时间
wire [31:0] countdown_time_next;    // 计时目标值
wire [31:0] countdown_time_sync;    // 同步后的倒计时值
wire [31:0] work_time;                 // 工作时间
wire cleaning_reminder;               // 清洁提醒信号
wire [2:0] fan_level;                 // 当前档位
reg level3_is_used;                  // 三档有没有用过
wire btn_menu_posedge;              // 三档用menu返回
wire [10:0] valid_standard;         // 当前手势开关有效时间
wire [31:0] clean_standard;         // 当前超过某一工作时间开始提醒清洁
wire [31:0] set_time_value; // 保存当前时间设置的时间值
wire slow_btn_menu_posedge; // 检测当前menu是否按下（慢时钟）
wire [31:0] menu_timer;     // 上一次menu按下的时间

// 状态定义
parameter POWER_OFF = 4'b0000;       // 关机
parameter STANDBY = 4'b0001;         // 待机模式
parameter READY_TO_SELECT = 4'b0010; // 准备选择模式
parameter SELF_CLEAN = 4'b0011;      // 自清洁模式
parameter LEVEL_1 = 4'b0100;         // 1档模式
parameter LEVEL_2 = 4'b0101;         // 2档模式
parameter LEVEL_3 = 4'b0110;         // 3档模式
parameter CHECK_TIME = 4'b0111;      // 查看时间
parameter SET_HOUR = 4'b1000;        // 设置清洁提醒小时
parameter SET_MINUTE = 4'b1001;      // 设置清洁提醒分钟
parameter SET_SECOND = 4'b1010;      // 设置清洁提醒秒
parameter SET_VALID_TIME = 4'b1011;  // 设置有效时间
parameter WAIT_RIGHT = 4'b 1100;     // 按下左键等待右键
parameter SET_HOUR_1 = 4'b1101;      // 设置当前时间小时
parameter SET_MINUTE_1 = 4'b1110;    // 设置当前时间分钟
parameter SET_SECOND_1 = 4'b1111;    // 设置当前时间秒

// 模块实例化
// 消抖
// 消抖后的信号
wire sig_power;
wire sig_menu;
wire sig_confirm;
wire [1:0] sig_level;
wire sig_manual_set_work_time;
wire sig_light;
wire sig_set_time;
wire sig_check_time;
wire sig_toggle;
wire sig_hand_left;
wire sig_hand_right;
wire [7:0] sig_btns_time_set;
Debouncer debouncer (
    .clk(clk),
    .rst_n(rst_n),
    .btns({btn_power, btn_menu, btn_confirm, btn_level, btn_manual_set_work_time, btn_light, btn_set_time, btn_check_time, btn_toggle, hand_left, hand_right, btns_time_set}),
    .short_press({sig_power, sig_menu, sig_confirm, sig_level, sig_manual_set_work_time, sig_light, sig_set_time, sig_check_time, sig_toggle, sig_hand_left, sig_hand_right,sig_btns_time_set})
);

// 时间管理器
Time_manager time_manager (
    .clk(clk),
    .rst_n(rst_n),
    .mode_state(mode_state),
    .next_state(next_state),
    .btn_confirm(sig_confirm),
    .sig_btns_time_set(sig_btns_time_set),
    .sig_manual_set_work_time(sig_manual_set_work_time),
    .btn_menu_posedge(btn_menu_posedge),
    .valid_standard(valid_standard),
    .clean_standard(clean_standard),
    .set_time_value(set_time_value),
    .slow_btn_menu_posedge(slow_btn_menu_posedge),
    .menu_timer(menu_timer),
    .light_need_self_cleaning(light_need_self_cleaning),
    .countdown_time_next(countdown_time_next),
    .countdown_time_sync(countdown_time_sync),
    .current_time(current_time),
    .work_time(work_time)
);

// 状态机
State_Machine state_machine (
    .clk(clk),
    .rst_n(rst_n),
    .btn_power(sig_power),
    .btn_menu(sig_menu),
    .btn_level(sig_level),
    .btn_confirm(sig_confirm),
    .btn_toggle(sig_toggle),
    .btn_set_time(sig_set_time),
    .btn_check_time(sig_check_time),
    .state(mode_state),
    .level3_is_used(level3_is_used),
    .valid_standard(valid_standard),
    .btn_hand_left(sig_hand_left),
    .btn_hand_right(sig_hand_right),
    .next_state(next_state),
    .out_btn_menu_posedge(btn_menu_posedge)
);

// 额外功能
parameter period_0p001s = 100_000; // 0.001s
wire slow_clk_0p001s;//分频0.001s
Clock_divider #(.DIV_COUNT(period_0p001s)) clk_0p001s(.clk_in(clk),.rst_n(rst_n),.clk_out(slow_clk_0p001s));
reg4 state_reg (
    .load(1),
    .clk(slow_clk_0p001s),
    .clr(!rst_n),
    .D(next_state),
    .Q(mode_state)
);// 把next state赋值给mode state

always @(posedge clk or negedge rst_n) begin // 输出当前状态
    if (!rst_n) begin
        state_indicator <= POWER_OFF;
    end else begin
        state_indicator <= mode_state;
    end
end

// 检测第三档位有没有被用过
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        level3_is_used<=0;
    end else begin
        if(mode_state == LEVEL_3)begin
            level3_is_used<=1;
        end else if(mode_state == POWER_OFF) begin
            level3_is_used<=0;
        end
    end
end

//打开照明模式
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        light_lighting <=0;
    end else begin
        if (mode_state == POWER_OFF || mode_state == WAIT_RIGHT) begin
            light_lighting <=0;
        end else begin
            light_lighting = sig_light;
        end
    end
end

// 七段数码显示管显示管理器
Display_manager display_manager_u(
    .clk(clk),
    .rst_n(rst_n),
    .mode_state(mode_state),
    .current_time(current_time),
    .countdown_time_sync(countdown_time_sync),
    .valid_time(valid_standard),
    .clean_set_time(clean_standard),
    .work_time(work_time),
    .seg_en(seg_en),
    .seg_out_0(seg_out_0),
    .seg_out_1(seg_out_1)
);
endmodule
