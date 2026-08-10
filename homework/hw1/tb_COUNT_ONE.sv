`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/15 00:13:34
// Design Name: 
// Module Name: tb_COUNT_ONE
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



module tb_COUNT_ONE;

    // 1. signal define
    reg in_a, in_b, in_c, in_d;
    wire [2:0] num;
    integer i;
    
    // 2. module instantiation
    COUNT_ONE test (
        .IN_A       (in_a),
        .IN_B       (in_b),
        .IN_C       (in_c),
        .IN_D       (in_d),
        .NUM        (num)
    );
    
    // 3. simulation code
    initial begin
        // print out this comment just one time\
        $display("| IN_A IN_B IN_C IN_D | num of one)");
        
        // it prints out input value and num simultaneously when the value is changed
        $monitor("| %b %b %b %b | %d", in_a, in_b, in_c, in_d, num);
        
        // this for loop generate every possible 4-bit binary number
        for (i = 0; i < 16; i = i + 1) begin
        
            //  the bits of i are assigned to the individual input signals
            in_a = i[3]; // MSB
            in_b = i[2];
            in_c = i[1];
            in_d = i[0]; // LSB
            #10;
        end
        $finish;
    end

endmodule