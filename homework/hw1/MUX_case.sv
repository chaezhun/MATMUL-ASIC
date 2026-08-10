//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/14 18:26:10
// Design Name: 
// Module Name: MUX_case
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

// by using ‘case’ statement //

module MUX_4to1(
    // input port
    input  wire [7:0] D_IN [3:0], 
    input  wire [1:0] IDX,

    // output port
    output reg  [7:0] D_OUT
);

    // A combinational logic block that always executes whenever the input(D_IN or IDX) change
    always @(*) begin
        // Divides the cases based on the value of IDX (selector)
        case (IDX)
            2'b00:   D_OUT = D_IN[0]; 
            2'b01:   D_OUT = D_IN[1]; 
            2'b10:   D_OUT = D_IN[2]; 
            2'b11:   D_OUT = D_IN[3]; 
            default: D_OUT = 8'hXX;   // Otherwise, output unknown X value
        endcase
    end

endmodule
