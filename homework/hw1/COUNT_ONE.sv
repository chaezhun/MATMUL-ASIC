//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/14 23:45:30
// Design Name: 
// Module Name: COUNT_ONE
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

// counting the number of 1's module //

module COUNT_ONE (
    // input port
    input   wire      IN_A,
    input   wire      IN_B,
    input   wire      IN_C,
    input   wire      IN_D,
   
    // output port
    output  reg [2:0] NUM
);

    // by using always statement with @(*), it can be operate parallelly
    always @(*) begin
    
    // behavioral modeling to count the number of '1's by simply summing the inputs
        NUM = IN_A + IN_B + IN_C + IN_D; 
    end

endmodule
