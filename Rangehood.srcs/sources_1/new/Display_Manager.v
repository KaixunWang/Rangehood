`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/17 22:17:39
// Design Name: 
// Module Name: Display_manager
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


module Display_manager(
    input clk,       // 输入时钟信号 100MHz
    input rst_n,     // 异步复位信号，低有效
    input [3:0] mode_state, // 输入状态信号
    input [31:0] current_time, // 当前时间
    input [31:0] countdown_time_sync, // 同步后的倒计时值
    input [31:0] work_time, // 工作时间
    input [10:0] valid_time, // 有效时间
    input [31:0] clean_set_time, //自清洁设置时间
    output reg [7:0] seg_en, // 输出控制信号
    output reg [7:0] seg_out_0, // 输出控制信号0 
    output reg [7:0] seg_out_1 // 输出控制信号1
    );

parameter flash_period = 200_000; // 500Hz
parameter LET_O = 8'b1111_1100;
parameter LET_F = 8'b1000_1110;

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


    reg [2:0] scan_cnt;
    reg [63:0] tub_symbol;
    // 250Hz 时钟信号
    wire clk_500Hz;
    Clock_divider #(.DIV_COUNT(flash_period)) clk_500Hz_u0(.clk_in(clk),.rst_n(rst_n),.clk_out(clk_500Hz));

    // 8段数码管显示刷新选择
    always @(posedge clk_500Hz, negedge rst_n) begin
        if (!rst_n) begin
            scan_cnt <= 0;
            // tub_symbol <= 0;
        end else begin
            if(scan_cnt == 3'd7) begin
                scan_cnt <= 0;
            end else begin
                scan_cnt <= scan_cnt + 1;
            end
        end
    end
    always @(scan_cnt) begin
        case(scan_cnt)
            3'h0: seg_en = 8'b0000_0001;
            3'h1: seg_en = 8'b0000_0010;
            3'h2: seg_en = 8'b0000_0100;
            3'h3: seg_en = 8'b0000_1000;
            3'h4: seg_en = 8'b0001_0000;
            3'h5: seg_en = 8'b0010_0000;
            3'h6: seg_en = 8'b0100_0000;
            3'h7: seg_en = 8'b1000_0000;
            default: seg_en = 8'b0000_0000;
        endcase
    end

    function [7:0] bcd_to_7seg(input [4:0] state);
        case(state)
            5'd0: bcd_to_7seg = 8'b1111_1100; // 0
            5'd1: bcd_to_7seg = 8'b0110_0000; // 1
            5'd2: bcd_to_7seg = 8'b1101_1010; // 2
            5'd3: bcd_to_7seg = 8'b1111_0010; // 3
            5'd4: bcd_to_7seg = 8'b0110_0110; // 4
            5'd5: bcd_to_7seg = 8'b1011_0110; // 5
            5'd6: bcd_to_7seg = 8'b1011_1110; // 6
            5'd7: bcd_to_7seg = 8'b1110_0000; // 7
            5'd8: bcd_to_7seg = 8'b1111_1110; // 8
            5'd9: bcd_to_7seg = 8'b1111_0110; // 9
            5'd10: bcd_to_7seg = 8'b1111_1101; // 0.
            5'd11: bcd_to_7seg = 8'b0110_0001; // 1.
            5'd12: bcd_to_7seg = 8'b1101_1011; // 2.
            5'd13: bcd_to_7seg = 8'b1111_0011; // 3.
            5'd14: bcd_to_7seg = 8'b0110_0111; // 4.
            5'd15: bcd_to_7seg = 8'b1011_0111; // 5.
            5'd16: bcd_to_7seg = 8'b1011_1111; // 6.
            5'd17: bcd_to_7seg = 8'b1110_0001; // 7.
            5'd18: bcd_to_7seg = 8'b1111_1111; // 8.
            5'd19: bcd_to_7seg = 8'b1111_0111; //9.
            default: bcd_to_7seg = 8'b0000_0000;
        endcase
    endfunction
    function [15:0] time_to_number(input [10:0] timeall);
        reg[10:0] timea;
        begin
            if(timeall > 99) time_to_number=0;
            else begin
                timea=timeall;
                time_to_number[15:8] = bcd_to_7seg((timea%10));
                // timea=timea/10;
                time_to_number[7:0] = bcd_to_7seg(((timea/10)%10));
            end
        end
    endfunction
    function [63:0] time_to_time_count(input [31:0] timeall);
        reg [7:0] hours;
        reg [7:0] minutes;
        reg [7:0] seconds;
        reg [4:0] h_tens, h_units, m_tens, m_units, s_tens, s_units;
        begin
            // 分解时间为小时、分钟和秒
            hours = (timeall / 3600) % 100;
            minutes = (timeall % 3600) / 60;
            seconds = timeall % 60;
            // 分解为各个位数
            h_tens = hours / 10;
            h_units = hours % 10 + 10;
            m_tens = minutes / 10;
            m_units = minutes % 10 + 10;
            s_tens = seconds / 10;
            s_units = seconds % 10;
            
            // 转换为七段显示编码
            time_to_time_count = {
                bcd_to_7seg(s_units),  // 秒个位
                bcd_to_7seg(s_tens),   // 秒十位
                bcd_to_7seg(m_units),  // 分个位
                bcd_to_7seg(m_tens),   // 分十位
                bcd_to_7seg(h_units),  // 时个位
                bcd_to_7seg(h_tens)    // 时十位
            };
            // 组合第一位是低位
        end
    endfunction
    // 8个8段数码管显示内容
    always @(mode_state,countdown_time_sync,work_time,current_time) begin
        if(!rst_n) begin
            tub_symbol<=0;
        end
        else begin
        case(mode_state)
            LEVEL_1: begin
                tub_symbol<=time_to_time_count(current_time);
                tub_symbol[63:56]<=bcd_to_7seg(5'd1);
            end
            LEVEL_2: begin
                tub_symbol<=time_to_time_count(current_time);
                tub_symbol[63:56]<=bcd_to_7seg(5'd2);
            end
            LEVEL_3: begin
                tub_symbol<=time_to_time_count(countdown_time_sync);
                tub_symbol[63:56]<=bcd_to_7seg(5'd3);
            end
            SELF_CLEAN: begin
                tub_symbol<=time_to_time_count(countdown_time_sync);
                tub_symbol[63:56]<=8'b00011100;
                tub_symbol[55:48]<=8'b10011100;
            end
            POWER_OFF,WAIT_RIGHT: begin
                tub_symbol<={LET_F,LET_F,LET_O};
            end
            // WAIT_RIGHT,WAIT_LEFT: begin
            //     tub_symbol[47:0]<=time_to_time_count(countdown_time_sync);
            //     tub_symbol[63:48]<=0;
            // end
            // STANDBY: begin
            //     tub_symbol<=time_to_time_count(current_time);
            // end
            CHECK_TIME: begin
                tub_symbol[47:0]<=time_to_time_count(work_time);
                tub_symbol[63:48]<=time_to_number(valid_time);
            end
            SET_HOUR: begin //hour.
                tub_symbol[7:0]<=8'b00101110;
                tub_symbol[15:8]<=8'b00111010;
                tub_symbol[23:16]<=8'b00111000;
                tub_symbol[31:24]<=8'b00001011;
                tub_symbol[39:32]<=bcd_to_7seg(((clean_set_time / 3600) % 100)/10);
                tub_symbol[47:40]<=bcd_to_7seg(((clean_set_time / 3600) % 100)% 10);
                tub_symbol[63:48]<=0;
            end
            SET_MINUTE: begin //min.
                tub_symbol[7:0]<=8'b11101100;
                tub_symbol[15:8]<=8'b11101100;
                tub_symbol[23:16]<=8'b01100000;
                tub_symbol[31:24]<=8'b00101011;
                tub_symbol[39:32]<=bcd_to_7seg((clean_set_time % 3600) / 60 /10);
                tub_symbol[47:40]<=bcd_to_7seg((clean_set_time % 3600) / 60 % 10);
                tub_symbol[63:48]<=0;
            end
            SET_SECOND: begin //sec.
                tub_symbol[7:0]<=8'b10110110;
                tub_symbol[15:8]<=8'b10011110;
                tub_symbol[23:16]<=8'b10011101;
                tub_symbol[31:24]<=bcd_to_7seg((clean_set_time % 60)/10);
                tub_symbol[39:32]<=bcd_to_7seg((clean_set_time % 60)% 10);
                tub_symbol[63:40]<=0;
            end
            SET_VALID_TIME: begin
                tub_symbol[63:48]<=time_to_number(valid_time);
                tub_symbol[47:0] <=0;
            end
            SET_HOUR_1: begin
                tub_symbol<=time_to_time_count(current_time);
            end
            SET_MINUTE_1: begin
                tub_symbol<=time_to_time_count(current_time);
            end
            SET_SECOND_1: begin
                tub_symbol<=time_to_time_count(current_time);
            end
            default: begin
                tub_symbol<=time_to_time_count(current_time);
                // tub_symbol<=0;
            end
        endcase
        end
    end
    // 选定的是左4个还是右4个
    always @(scan_cnt,tub_symbol) begin
        case(scan_cnt)
            3'h0: begin
                seg_out_0 <= tub_symbol[7:0];
                seg_out_1 <= 0;
                seg_en <= 8'b0000_0001;
            end
            3'h1: begin
                seg_out_0 <= tub_symbol[15:8];
                seg_out_1 <= 0;
                seg_en <= 8'b0000_0010;
            end
            3'h2: begin
                seg_out_0 <= tub_symbol[23:16];
                seg_out_1 <= 0;
                seg_en <= 8'b0000_0100;
            end
            3'h3: begin
                seg_out_0 <= tub_symbol[31:24];
                seg_out_1 <= 0;
                seg_en <= 8'b0000_1000;
            end
            3'h4: begin
                seg_out_0 <= 0;
                seg_out_1 <= tub_symbol[39:32];
                seg_en <= 8'b0001_0000;
            end
            3'h5: begin
                seg_out_0 <= 0;
                seg_out_1 <= tub_symbol[47:40];
                seg_en <= 8'b0010_0000;
            end
            3'h6: begin
                seg_out_0 <= 0;
                seg_out_1 <= tub_symbol[55:48];
                seg_en <= 8'b0100_0000;
            end
            3'h7: begin
                seg_out_0 <= 0;
                seg_out_1 <= tub_symbol[63:56];
                seg_en <= 8'b1000_0000;
            end
            default: begin
                seg_out_0 <= 8'b0000_0000;
                seg_out_1 <= 8'b0000_0000;
                seg_en <= 8'b0000_0000;
            end
        endcase
    end
endmodule
