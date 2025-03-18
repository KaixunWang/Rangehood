`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Testbench for State_Machine
//////////////////////////////////////////////////////////////////////////////////

module tb_State_Machine;

// Inputs
reg clk;
reg rst_n;
reg btn_power;
reg btn_menu;
reg [1:0] btn_level;
reg btn_confirm;
reg btn_toggle;
reg btn_set_time;
reg btn_check_time;
reg [3:0] state;
reg level3_is_used;

// Outputs
wire [3:0] next_state;
wire out_btn_menu_posedge;

// Instantiate the State_Machine module
State_Machine uut (
    .clk(clk),
    .rst_n(rst_n),
    .btn_power(btn_power),
    .btn_menu(btn_menu),
    .btn_level(btn_level),
    .btn_confirm(btn_confirm),
    .btn_toggle(btn_toggle),
    .btn_set_time(btn_set_time),
    .btn_check_time(btn_check_time),
    .state(state),
    .level3_is_used(level3_is_used),
    .next_state(next_state),
    .out_btn_menu_posedge(out_btn_menu_posedge)
);

// Generate clock signal
always begin
    clk = 0;
    #5 clk = 1;  // Clock period = 10ns
end

// Test sequence
initial begin
    // Initialize inputs
    rst_n = 0;
    btn_power = 0;
    btn_menu = 0;
    btn_level = 2'b00;
    btn_confirm = 0;
    btn_toggle = 0;
    btn_set_time = 0;
    btn_check_time = 0;
    state = 4'b0000; // Initial state (POWER_OFF)
    level3_is_used = 0;

    // Apply reset
    #10;
    rst_n = 1;

    // Power On (Short press btn_power)
    #20;
    btn_power = 1;
    #10;
    btn_power = 0;

    // Verify transition to STANDBY state
    #20;

    // Press Menu to enter READY_TO_SELECT
    btn_menu = 1;
    #10;
    btn_menu = 0;

    // Verify transition to READY_TO_SELECT state
    #20;

    // Select SELF_CLEAN mode by pressing btn_level and btn_confirm
    btn_level = 2'b00; // Self-clean
    btn_confirm = 1;
    #10;
    btn_confirm = 0;

    // Verify transition to SELF_CLEAN state
    #20;

    // Wait for 10s in SELF_CLEAN mode
    #100;  // Wait for the timer to expire and transition to STANDBY

    // Press Menu again to return to STANDBY
    btn_menu = 1;
    #10;
    btn_menu = 0;

    // Verify transition back to STANDBY state
    #20;

    // Test transition to SET_HOUR state (time setting mode)
    btn_set_time = 1;
    #10;
    btn_set_time = 0;

    // Verify transition to SET_HOUR state
    #20;

    // Test toggle behavior to change state from SET_HOUR to SET_MINUTE
    btn_toggle = 1;
    #10;
    btn_toggle = 0;

    // Verify transition to SET_MINUTE state
    #20;

    // End simulation
    $finish;
end

// Update state at every clock cycle
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        state <= 4'b0000; // Initial state (POWER_OFF)
    end else begin
        state <= next_state;
    end
end

endmodule
