`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company:
// Engineer:
//
// Create Date: 2024/12/01 23:31:36
// Design Name:
// Module Name: regN
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


module reg4(
input wire load,clk,clr,
input wire [3:0] D,
output reg [3:0] Q
);

always @(posedge clk or posedge clr) begin
if(clr==1) begin
    Q<=0;
end
else if(load ==1)begin
    Q<=D;
end
else begin
    Q<=Q;
end
end
endmodule