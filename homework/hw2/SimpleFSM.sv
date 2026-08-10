`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/02 20:14:47
// Design Name: 
// Module Name: SimpleFSM
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


module SimpleFSM (
    input wire clk,     // Clock signal
    input wire resetn,  // Active reset
    input wire in,      // Input
    output wire out     // Output
);

    // Current states
    reg A, B; // A: MSB bit, B: LSB bit

    // Next states
    wire N_A, N_B;

    // 1. Next State Logic : N_A = (B * in') + (A * B' * in)
    assign N_A = (B & ~in) | (A & ~B & in);
    
    // N_B = in
    assign N_B = in;

    // 2. State Register
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin  // reset (active when 0 )
            A <= 1'b0;
            B <= 1'b0;
        end
        
        else begin
            // update next state to current state
            A <= N_A;
            B <= N_B;
        end
    end

    // 3. Output Logic : out = A * B
    assign out = A & B;

endmodule