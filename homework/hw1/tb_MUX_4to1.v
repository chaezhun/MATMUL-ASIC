`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/14 12:47:52
// Design Name: 
// Module Name: tb_MUX_4to1
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

module tb_MUX_4to1;

    // 1. signal define
    reg [7:0]       D_IN_tb [3:0];
    reg [1:0]       IDX_tb;
    wire [7:0]      D_OUT_tb;
    
    integer i;

    // 2. module instantiation
    MUX_4to1 test (
        .D_IN       (D_IN_tb),
        .IDX        (IDX_tb),
        .D_OUT      (D_OUT_tb)
    );

    // 3. simulation code
    initial begin
    
        // (1) set initial value as random value
        D_IN_tb[0] = $random;
        D_IN_tb[1] = $random;
        D_IN_tb[2] = $random;
        D_IN_tb[3] = $random;       
        
        $display("------------------- Simulation Start -------------------");
        
        // (2) put IDX_tb 00 to 11 by for loop
        for (i=0; i<4; i=i+1) begin
        IDX_tb = i; 
        #10; // 10ns delay
        
        $display("Selector(IDX): %b | Output(D_OUT): %h", IDX_tb, D_OUT_tb); // display to see output value
        end
        
        $display("-------------------- Simulation End --------------------");
        $finish;
    end
    
endmodule