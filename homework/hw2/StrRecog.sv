`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/04 19:49:57
// Design Name: 
// Module Name: StrRecog
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


module StrRecog (
    input wire clk,      // Clock signal
    input wire resetn,   // Active-low Reset: Resets the FSM when 0
    input wire in,       // Data Input
    output wire out      // Data Output: High when '010' is detected
);

    // State Parameters
    // We have 7 states (S0-S6), so we need 3 bits
    parameter S0 = 3'd0; // Idle state
    parameter S1 = 3'd1; // Seen '0'
    parameter S2 = 3'd2; // Seen '01'
    parameter S3 = 3'd3; // Match '010' (Output High)
    parameter S4 = 3'd4; // Seen '1'
    parameter S5 = 3'd5; // Seen '10'
    parameter S6 = 3'd6; // Seen '100' (Dead state)

    // 'current_state' stores the current state 
    // 'next_state' stores the calculated next state 
    reg [2:0] current_state; 
    reg [2:0] next_state;

    // 1. Sequential Logic: State Register
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            current_state <= S0;
        end else begin
            current_state <= next_state;
        end
    end

    // 2. Combinational Logic: Determines the next state based on the current state and input 'in'.
    always @(*) begin
        // Default assignment to prevent latches (good practice)
        next_state = current_state;

        case (current_state)
            // State S0: Initial / Idle state
            S0: begin
                if (in == 1'b0) next_state = S1; // Input '0'
                else            next_state = S4; // Input '1' 
            end

            // State S1: Seen "...0"
            S1: begin
                if (in == 1'b0) next_state = S1; // Input '0' -> Stay 
                else            next_state = S2; // Input '1'
            end

            // State S2: Seen "...01"
            S2: begin
                if (in == 1'b0) next_state = S3; // Input '0'
                else            next_state = S4; // Input '1'
            end

            // State S3: Seen "...010" (Output is High here)
            S3: begin
                if (in == 1'b0) next_state = S6; // Input '0' -> Ends with '100'
                else            next_state = S2; // Input '1' 
            end

            // State S4: Seen "...1"
            S4: begin
                if (in == 1'b0) next_state = S5; // Input '0'
                else            next_state = S4; // Input '1' -> Stay
            end

            // State S5: Seen "...10"
            S5: begin
                if (in == 1'b0) next_state = S6; // Input '0' -> Ends with '100'
                else            next_state = S2; // Input '1'
            end

            // State S6: Ends with '100'
            // Once '100' is detected, the machine stays here forever.
            S6: begin
                next_state = S6; 
            end

            // Default case
            default: next_state = S0;
        endcase
    end

    // 3. Output Logic: Moore Machine Implementation : Output is '1' only when the state is S3 (Seen '010').
    assign out = (current_state == S3) ? 1'b1 : 1'b0;

endmodule
