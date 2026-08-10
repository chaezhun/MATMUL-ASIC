`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/13 00:09:32
// Design Name: 
// Module Name: tb_mm
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


module tb_mm;

    // (1) clock define
    reg     clk;
    initial begin
        clk = 0;
        forever #(10) clk=~clk;
    end
    
    // (2) signal define
   
    wire            tester_cen;
    wire            tester_wen;
    wire    [8:0]   tester_addr;
    wire    [31:0]  tester_din;
    wire    [31:0]  tester_dout;
    
    wire            tester_rstn;
    wire            tester_matmul_en;
    wire    [2:0]   tester_fl;
    wire            tester_done;
    
    // (3) module instantiation
    custom_matmul16x16 mm_ip(
        .i_clk          (clk),
        
        .i_cen          (tester_cen),
        .i_wen          (tester_wen),
        .i_addr         (tester_addr),
        .i_din          (tester_din),
        .o_dout         (tester_dout),
        
        .i_rstn         (tester_rstn),
        .i_matmul_en    (tester_matmul_en),
        .i_fl           (tester_fl),
        .o_done         (tester_done)
    );
    
    // (4) simulation code
    mm_tester tester(
        .i_clk          (clk),
        
        .o_cen          (tester_cen),
        .o_wen          (tester_wen),
        .o_addr         (tester_addr),
        .o_din          (tester_din),
        .i_dout         (tester_dout),
        
        .o_rstn         (tester_rstn),
        .o_matmul_en    (tester_matmul_en),
        .o_fl           (tester_fl),
        .i_done         (tester_done)
    );
    
endmodule

