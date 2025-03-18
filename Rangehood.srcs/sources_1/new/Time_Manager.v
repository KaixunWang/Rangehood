`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/23 01:04:30
// Design Name: 
// Module Name: Time_manager
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


module Time_manager(
    input wire clk,                     // System clock
    input wire rst_n,                   // Active-low reset
    input wire [3:0] mode_state,        // Current operating mode
    input wire [3:0] next_state,        // Next operating mode
    input wire btn_confirm,             // Confirm button
    input wire [7:0] sig_btns_time_set, // Time setting via buttons (max 127 to cover <100)
    input wire sig_manual_set_work_time, // Manual signal to reset work time
    input wire btn_menu_posedge,        // Menu button positive edge

    // Outputs
    output reg [10:0] valid_standard,                // Valid time standard
    output reg [31:0] clean_standard,                // Clean time standard
    output reg [31:0] set_time_value,                // Current time setting value
    output reg slow_btn_menu_posedge,                // Slowed-down menu button posedge
    output reg [31:0] menu_timer,                    // Menu timer
    output reg light_need_self_cleaning,             // Self-cleaning indicator
    output reg [31:0] countdown_time_next,           // Next countdown time
    output reg [31:0] countdown_time_sync,           // Synchronized countdown time
    output reg [31:0] current_time,                  // Current time counter
    output reg [31:0] work_time                      // Accumulated work time
);

// Parameter Definitions
parameter POWER_OFF      = 4'b0000; // 关机
parameter STANDBY        = 4'b0001; // 待机模式
parameter READY_TO_SELECT= 4'b0010; // 准备选择模式
parameter SELF_CLEAN     = 4'b0011; // 自清洁模式
parameter LEVEL_1        = 4'b0100; // 1档模式
parameter LEVEL_2        = 4'b0101; // 2档模式
parameter LEVEL_3        = 4'b0110; // 3档模式
parameter CHECK_TIME     = 4'b0111; // 查看时间
parameter SET_HOUR       = 4'b1000; // 设置清洁提醒小时
parameter SET_MINUTE     = 4'b1001; // 设置清洁提醒分钟
parameter SET_SECOND     = 4'b1010; // 设置清洁提醒秒
parameter SET_VALID_TIME = 4'b1011; // 设置有效时间
parameter WAIT_RIGHT     = 4'b1100; // 按下左键等待右键
parameter SET_HOUR_1     = 4'b1101; // 设置当前时间小时
parameter SET_MINUTE_1   = 4'b1110; // 设置当前时间分钟
parameter SET_SECOND_1   = 4'b1111; // 设置当前时间秒

// ============================================================================
// Internal Wires and Registers
// ============================================================================
wire clk_1s; // 1-second clock

// ============================================================================
// Clock Divider Instance
// ============================================================================
Clock_divider #(
    .DIV_COUNT(100_000_000) // Assuming clk is 100 MHz, adjust as necessary
) clk_1s_u (
    .clk_in(clk),
    .rst_n(rst_n),
    .clk_out(clk_1s)
);

// ============================================================================
// Valid Time Standard Handling
// ============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        valid_standard <= 11'd5; // Initialize to default value
    end else begin
        case (mode_state)
            SET_VALID_TIME: begin
                if (btn_confirm) begin
                    if (sig_btns_time_set < 100) begin
                        valid_standard <= sig_btns_time_set;
                    end
                end
            end
            default: begin
                // Hold current value
            end
        endcase
    end
end

// ============================================================================
// Clean Time Standard Handling
// ============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clean_standard <= 32'd10; // Initialize to default value
    end else begin
        case (mode_state)
            SET_HOUR: begin
                if (btn_confirm) begin
                    if (sig_btns_time_set < 100) begin
                        // Clear the original hour part and add the new hour value (hour × 3600)
                        clean_standard <= (clean_standard - ((clean_standard / 32'd3600) * 32'd3600))
                                         + (sig_btns_time_set * 32'd3600);
                    end
                end
            end
            SET_MINUTE: begin
                if (btn_confirm) begin
                    if (sig_btns_time_set < 60) begin
                        // Clear the original minute part and add the new minute value (minute × 60)
                        clean_standard <= (clean_standard - (((clean_standard % 32'd3600) / 32'd60) * 32'd60))
                                         + (sig_btns_time_set * 32'd60);
                    end
                end
            end
            SET_SECOND: begin
                if (btn_confirm) begin
                    if (sig_btns_time_set < 60) begin
                        // Clear the original second part and add the new second value
                        clean_standard <= (clean_standard - (clean_standard % 32'd60))
                                         + sig_btns_time_set;
                    end
                end
            end
            default: begin
                // Hold current value
            end
        endcase
    end
end

// ============================================================================
// Self-Cleaning Requirement Indicator
// ============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        light_need_self_cleaning <= 1'b0;
    end else begin
        if (mode_state != POWER_OFF && mode_state != WAIT_RIGHT) begin
            light_need_self_cleaning <= (work_time > clean_standard);
        end else begin
            light_need_self_cleaning <= 1'b0;
        end
    end
end

// ============================================================================
// Set Time Value Handling
// ============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        set_time_value <= 32'd0;
    end else begin
        case (mode_state)
            SET_HOUR_1: begin
                if (btn_confirm) begin
                    if (sig_btns_time_set < 100) begin
                        // Clear the original hour part and add the new hour value (hour × 3600)
                        set_time_value <= (set_time_value - ((set_time_value / 32'd3600) * 32'd3600))
                                       + (sig_btns_time_set * 32'd3600);
                    end
                end
            end
            SET_MINUTE_1: begin
                if (btn_confirm) begin
                    if (sig_btns_time_set < 60) begin
                        // Clear the original minute part and add the new minute value (minute × 60)
                        set_time_value <= (set_time_value - (((set_time_value % 32'd3600) / 32'd60) * 32'd60))
                                       + (sig_btns_time_set * 32'd60);
                    end
                end
            end
            SET_SECOND_1: begin
                if (btn_confirm) begin
                    if (sig_btns_time_set < 60) begin
                        // Clear the original second part and add the new second value
                        set_time_value <= (set_time_value - (set_time_value % 32'd60))
                                       + sig_btns_time_set;
                    end
                end
            end
            default: begin
                set_time_value <= current_time;
            end
        endcase
    end
end

// ============================================================================
// Current Time and Work Time Handling
// ============================================================================
always @(posedge clk_1s or negedge rst_n) begin
    if (!rst_n) begin
        current_time <= 32'd0;
        work_time    <= 32'd0;
    end else begin
        if (mode_state == SET_HOUR_1 || mode_state == SET_MINUTE_1 || mode_state == SET_SECOND_1) begin
            if (btn_confirm) begin
                // After long press confirm button, update the current time to the set value
                current_time <= set_time_value;
            end else begin
                // Hold the current time
                current_time <= current_time;
            end
        end else begin
            // Normal counting in non-setting states
            current_time <= current_time + 32'd1;
        end

        if (sig_manual_set_work_time) begin
            work_time <= 32'd0;
        end else begin
            case (mode_state)
                POWER_OFF, WAIT_RIGHT: begin
                    current_time <= 32'd0;
                end
                SELF_CLEAN: begin
                    work_time <= 32'd0;
                end
                LEVEL_1, LEVEL_2, LEVEL_3: begin
                    work_time <= work_time + 32'd1;
                end
                default: begin
                    // No operation
                end
            endcase
        end
    end
end

// ============================================================================
// Countdown Time Next Handling
// ============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        countdown_time_next <= 32'd0;
    end else begin
        if (mode_state == POWER_OFF || mode_state == WAIT_RIGHT) begin
            countdown_time_next <= 32'd0;
        end else if (mode_state != SELF_CLEAN && next_state == SELF_CLEAN) begin
            countdown_time_next <= 32'd10;
        end else if (mode_state != LEVEL_3 && next_state == LEVEL_3) begin
            countdown_time_next <= 32'd10;
        end else if (mode_state == LEVEL_3 && btn_menu_posedge) begin
            countdown_time_next <= 32'd5;
        end else if (mode_state == STANDBY || mode_state == LEVEL_2) begin
            countdown_time_next <= 32'd0;
        end
    end
end

// ============================================================================
// Slow Menu Button Positional Edge Handling
// ============================================================================
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        slow_btn_menu_posedge <= 1'b0;
        menu_timer            <= 32'd0;
    end else begin
        if (btn_menu_posedge) begin
            slow_btn_menu_posedge <= 1'b1;
            menu_timer            <= 32'd100_000_000; // Assuming clk is 100 MHz for 1s
        end else if (menu_timer > 32'd0) begin
            menu_timer <= menu_timer - 32'd1;
            if (menu_timer == 32'd1) begin
                slow_btn_menu_posedge <= 1'b0;
            end
        end

        if (mode_state == POWER_OFF || mode_state == WAIT_RIGHT) begin
            slow_btn_menu_posedge <= 1'b0;
            menu_timer            <= 32'd0;
        end
    end
end

// ============================================================================
// Countdown Time Synchronized Handling
// ============================================================================
always @(posedge clk_1s or negedge rst_n) begin
    if (!rst_n) begin
        countdown_time_sync <= 32'd0;
        // level3_pressed_menu is commented out as it's not defined
    end else begin
        if (countdown_time_sync > 32'd0) begin
            if (slow_btn_menu_posedge) begin
                countdown_time_sync <= countdown_time_next;
            end else begin
                countdown_time_sync <= countdown_time_sync - 32'd1;
            end
        end else begin
            countdown_time_sync <= countdown_time_next;
        end
    end
end

endmodule