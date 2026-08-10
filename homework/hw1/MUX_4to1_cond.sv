//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/15 01:32:08
// Design Name: 
// Module Name: MUX_4to1_cond
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

// by using conditional operator //

module MUX_4to1_cond (
    // input port
    input wire [7:0] D_IN [0:3],
    input wire [1:0] IDX,

    // output port
    output wire [7:0] D_OUT
);

    // by IDX value, allocate one of D_IN to D_OUT
    assign D_OUT = (IDX == 2'b00) ? D_IN[0] :
                   (IDX == 2'b01) ? D_IN[1] :
                   (IDX == 2'b10) ? D_IN[2] :
                   (IDX == 2'b11) ? D_IN[3] :
                   8'hXX; // exceptional case

endmodule

