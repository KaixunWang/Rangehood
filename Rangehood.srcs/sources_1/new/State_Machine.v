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

module State_Machine(
    input clk,                        // 系统时钟信号
    input rst_n,                      // 复位信号
    input btn_power,                  // 开关机按键
    input btn_menu,                   // 菜单按键
    input [1:0] btn_level,            // 档位选择(00自清洁,01一档,10二档,11三档)
    input btn_confirm,                // 确认按键
    input btn_toggle,                 // 切换按键
    input btn_set_time,               // 时间设置按键
    input btn_check_time,             // 时间查看设置
    input [3:0] state,                // 当前状态
    input level3_is_used,             // 三档用没用过
    input [10:0] valid_standard,        // 手势开关有效时间
    input btn_hand_left,               // 左键
    input btn_hand_right,               // 右键
    output reg [3:0] next_state,       // 下一状态
    output reg out_btn_menu_posedge
);

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

//例化
wire power_short;
wire power_long;
Button_Press_Handler_power powerPressHandler (.clk(clk),.rst_n(rst_n),.btn_stable(btn_power),.short_press(power_short),.long_press(power_long));
wire level_3_10s;
wire level_3_menu_5s;
wire level_clean_10s;
reg level_3_menu_start;            // 启动计时器信号
Timer_s timerLevel3_10s (.clk(clk),.rst_n(rst_n),.start(state == LEVEL_3),.max_time(10),.timeout(level_3_10s));
Timer_s timerLevel3_menu_5s (.clk(clk),.rst_n(rst_n),.start(level_3_menu_start),.max_time(5),.timeout(level_3_menu_5s));
Timer_s timerClean_10s (.clk(clk),.rst_n(rst_n),.start(state == SELF_CLEAN),.max_time(10),.timeout(level_clean_10s));
reg time_to_standby_start;
wire time_to_standby_done;
Timer timerToStandby (.clk(clk),.rst_n(rst_n),.start(time_to_standby_start),.max_time(10),.timeout(time_to_standby_done));
reg wait_right_timer_start;            // 左键按下启动确认计时器信号
wire wait_right_timer_done;            // 左键按下确认计时完成信号
Timer_s wait_right_Timer (.clk(clk),.rst_n(rst_n),.start(wait_right_timer_start),.max_time(valid_standard),.timeout(wait_right_timer_done));
reg right_key_timer_start;            // 右键按下启动计时器信号
wire right_key_timer_done;            // 右键计时完成信号
Timer_s right_key_Timer (.clk(clk),.rst_n(rst_n),.start(right_key_timer_start),.max_time(valid_standard),.timeout(right_key_timer_done));
reg right_key_pressed;// 用于记录右键按下状态
reg time_to_standby_current_start;
wire time_to_standby_current_done;
Timer_s timerToStandbyCurrent (.clk(clk),.rst_n(rst_n),.start(time_to_standby_current_start),.max_time(1),.timeout(time_to_standby_current_done));

wire slow_clk_0p05s;//分频0.05s
clk_divider_0p05 clk_0p05(
    .clk_in(clk),.rst_n(rst_n),.clk_out(slow_clk_0p05s)
);
// 检测 btn_menu 上升沿
reg btn_menu_d1, btn_menu_d2;
always @(posedge slow_clk_0p05s or negedge rst_n) begin
    if (!rst_n) begin
        btn_menu_d1 <= 0;
        btn_menu_d2 <= 0;
    end else begin
        btn_menu_d1 <= btn_menu;
        btn_menu_d2 <= btn_menu_d1;
    end
end

wire btn_menu_posedge = (btn_menu_d1 && !btn_menu_d2); // 检测到menu上升沿
always @(posedge slow_clk_0p05s or negedge rst_n) begin
    if (!rst_n) begin
        out_btn_menu_posedge<=0;
    end else begin
        out_btn_menu_posedge <=btn_menu_posedge;
    end
end


// 信号锁存
reg power_short_flag, power_long_flag;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        power_short_flag <= 0;
        power_long_flag <= 0;
    end else begin
        if (power_short)
            power_short_flag <= 1; // 锁存短按信号
        if (power_long)
            power_long_flag <= 1; // 锁存长按信号
        if (state == POWER_OFF && next_state == STANDBY || state != POWER_OFF && next_state == POWER_OFF||state == WAIT_RIGHT && next_state== STANDBY || state == WAIT_RIGHT && next_state== POWER_OFF) begin
            power_short_flag <= 0; // 状态转换后清除短按锁存
            power_long_flag <= 0; // 状态转换后清除长按锁存
        end
    end
end

// 状态机逻辑
always @(posedge slow_clk_0p05s or negedge rst_n) begin
    if (~rst_n) begin
        next_state <= POWER_OFF;     // 默认关机状态
        level_3_menu_start<=0;
        time_to_standby_start <= 0;
        time_to_standby_current_start<=0;
        right_key_pressed <=0;
    end else begin
        // 检测右键按下
        if (btn_hand_right && !right_key_pressed) begin
            right_key_pressed <= 1;
            right_key_timer_start <= 1;  // 启动计时器
        end
        if (btn_hand_left && right_key_pressed) begin
            // 右键计时期间左键按下，触发关机
            next_state <= POWER_OFF;
            right_key_timer_start <= 0;  // 停止计时器
            right_key_pressed <= 0;     // 重置右键状态
        end else begin
        if (right_key_timer_done) begin
            right_key_timer_start <= 0;  // 停止计时器
            right_key_pressed <= 0;     // 重置右键状态
        end
        // 优先判断 power_long_flag
        if (power_long_flag) begin
            next_state <= POWER_OFF;    // 长按关机
            wait_right_timer_start <= 0;
        end else begin
        case (state)
            POWER_OFF: begin
                level_3_menu_start<=0;
                right_key_pressed<=0;
                wait_right_timer_start <= 0;  // 复位计时器
                if (power_short_flag) begin      // 开机
                    next_state <= STANDBY;
                end else if(btn_hand_left)begin// 检测左键按下
                    next_state <= WAIT_RIGHT;  // 进入等待确认状态
                    wait_right_timer_start <= 1;       // 启动计时器
                end else begin
                    next_state <= POWER_OFF;
                end
            end
            WAIT_RIGHT: begin
                if (wait_right_timer_done) begin
                    next_state <= POWER_OFF;
                    wait_right_timer_start <=0;
                end else if (btn_hand_right) begin
                    next_state <= STANDBY;
                    wait_right_timer_start <=0;
                end else begin
                    next_state <= WAIT_RIGHT;
                end
            end
            // WAIT_LEFT: begin
            //     if (wait_left_timer_done) begin
            //         next_state<= STANDBY;
            //         wait_left_timer_start <=0;
            //     end else if (btn_hand_left) begin
            //         next_state <= POWER_OFF;
            //         wait_left_timer_start <=0;
            //     end else begin
            //         next_state <= WAIT_LEFT;
            //     end
            // end
            STANDBY: begin
                time_to_standby_start <= 0;
                time_to_standby_current_start<=0;
                if (btn_menu) // 按菜单键
                    next_state <= READY_TO_SELECT;
                else if (btn_check_time) //检查时间
                    next_state <= CHECK_TIME;
                else if (btn_set_time) //设置时间
                    next_state <= SET_HOUR;
                else
                    next_state <= STANDBY;
            end

            READY_TO_SELECT: begin
                if (btn_level == 2'b00 & btn_confirm)      // 自清洁
                    next_state <= SELF_CLEAN;
                else if (btn_level == 2'b01 & btn_confirm) // 1档
                    next_state <= LEVEL_1;
                else if (btn_level == 2'b10 & btn_confirm) // 2档
                    next_state <= LEVEL_2;
                else if (btn_level == 2'b11 & btn_confirm & !level3_is_used) // 3档
                    next_state <= LEVEL_3;
                else
                    next_state <= READY_TO_SELECT;
            end

            SELF_CLEAN: begin
                if (level_clean_10s)       // 10s返回待机
                    next_state <= STANDBY;
                else
                    next_state <= SELF_CLEAN;
            end

            LEVEL_1: begin
                if (btn_menu) // 返回待机
                    next_state <= STANDBY;
                else if (btn_confirm & btn_level==2'b10)
                    next_state <= LEVEL_2;
                else
                    next_state <= LEVEL_1;
            end

            LEVEL_2: begin
                if (btn_menu) // 返回待机
                    next_state <= STANDBY;
                else if (btn_confirm & btn_level==2'b01)
                    next_state <= LEVEL_1;
                else
                    next_state <= LEVEL_2;
            end

            LEVEL_3: begin
                if (btn_menu_posedge)
                    level_3_menu_start <= 1;  // 检测到按键上升沿，启动计时
                if (level_3_menu_5s) // 返回待机
                    next_state <= STANDBY;
                else if (level_3_10s && !level_3_menu_start)
                    next_state <= LEVEL_2;
                else
                    next_state <= LEVEL_3;
            end

            CHECK_TIME: begin
                if (btn_menu)      // 返回待机
                    next_state <= STANDBY;
                else
                    next_state <= CHECK_TIME;
            end

            SET_HOUR: begin
                if (btn_confirm) begin
                    time_to_standby_start <= 1; // 启动计时器
                end
                if (btn_menu || btn_confirm)      // 返回待机
                    next_state <= STANDBY;
                else if (btn_toggle) // 设置小时后设置分钟
                    next_state <= SET_MINUTE;
                else
                    next_state <= SET_HOUR;
            end

            SET_MINUTE: begin
                if (btn_confirm) begin
                    time_to_standby_start <= 1; // 启动计时器
                end
                if (btn_menu || time_to_standby_done)      // 返回待机
                    next_state <= STANDBY;
                else if (btn_toggle) // 设置分钟后设置秒
                    next_state <= SET_SECOND;
                else
                    next_state <= SET_MINUTE;
            end

            SET_SECOND: begin
                if (btn_confirm) begin
                    time_to_standby_start <= 1; // 启动计时器
                end
                if (btn_menu || time_to_standby_done)      // 返回待机
                    next_state <= STANDBY;
                else if (btn_toggle) // 设置秒后设置有效时间
                    next_state <= SET_VALID_TIME;
                else
                    next_state <= SET_SECOND;
            end

            SET_VALID_TIME: begin
                if (btn_confirm) begin
                    time_to_standby_start <= 1; // 启动计时器
                end
                if (btn_menu || time_to_standby_done) // 设置完有效时间后返回待机
                    next_state <= STANDBY;
                else if (btn_toggle) // 设置完有效时间后设置当前小时
                    next_state <= SET_HOUR_1;
                else
                    next_state <= SET_VALID_TIME;
            end
            
            SET_HOUR_1 : begin
                if (btn_confirm) begin
                    time_to_standby_current_start <= 1; // 启动计时器
                end
                if (btn_menu || time_to_standby_current_done) // 设置完有效时间后返回待机
                    next_state <= STANDBY;
                else if (btn_toggle) // 设置完有效时间后设置当前分钟
                    next_state <= SET_MINUTE_1;
                else
                    next_state <= SET_HOUR_1;
            end

            SET_MINUTE_1:begin
                if (btn_confirm) begin
                    time_to_standby_current_start <= 1; // 启动计时器
                end
                if (btn_menu || time_to_standby_current_done) // 设置完有效时间后返回待机
                    next_state <= STANDBY;
                else if (btn_toggle) // 设置完有效时间后设置当前秒
                    next_state <= SET_SECOND_1;
                else
                    next_state <= SET_MINUTE_1;
            end

            SET_SECOND_1:begin
                if (btn_confirm) begin
                   time_to_standby_current_start <= 1; // 启动计时器
                end
                if (btn_menu || time_to_standby_current_done) // 设置完有效时间后返回待机
                    next_state <= STANDBY;
                else if (btn_toggle) // 设置完有效时间后设置清洁小时
                    next_state <= SET_HOUR;
                else
                    next_state <= SET_SECOND_1;
            end

            default: next_state <= POWER_OFF;
        endcase
    end
        end
end
end

endmodule
