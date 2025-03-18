`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/15 21:38:58
// Design Name: 
// Module Name: Debouncer
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


module Debouncer(
    input clk, rst_n,
    input [19:0] btns,
    output wire [19:0] short_press
    );
    // 时钟总赫兹为 100MHz
    // parameter N = 4;
    // parameter DEBOUNCE_TIME = 25000000; // 250ms
    parameter DEBOUNCE_TIME = 500000; // 1us!

    reg [19:0] button_state;
    reg [19:0] press_detect;
    reg [31:0] cnt [19:0];

    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            button_state <= 0;
            press_detect <= 0;
            for (i = 0; i < 20; i = i + 1) begin
                cnt[i] <= 0;
            end
        end else begin
            for (i = 0; i < 20; i = i + 1) begin
                if (btns[i] != button_state[i]) begin
                    cnt[i] <= cnt[i] + 1;
                    if (cnt[i] >= DEBOUNCE_TIME) begin
                        button_state[i] <= btns[i];
                        cnt[i] <= 0;
                    end
                end else begin
                    cnt[i] <= 0;
                end
            end
        end
    end
    assign short_press = button_state;
endmodule