`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/12/02 19:27:31
// Design Name: 
// Module Name: multiple5
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
////////////////////////////////////////////////////////////////////////////i//////


module multiple5(
    input wire [4:0] i_mult5,   // 5-bit input data (Range: 0 to 31)
    output wire o_mult5     // Output high (1) if input is a multiple of 5
);

    // Combinational logic to detect multiples of 5 (5, 10, 15, 20, 25, 30)
    assign o_mult5 = (i_mult5 == 5) || 
                     (i_mult5 == 10) ||
                     (i_mult5 == 15) || 
                     (i_mult5 == 20) ||  
                     (i_mult5 == 25) || 
                     (i_mult5 == 30); 

endmodule

