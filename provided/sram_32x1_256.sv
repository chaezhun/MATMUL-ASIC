//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/12 21:46:53
// Design Name: 
// Module Name: sram_32x1_256
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



module sram_32x1_256(
    input   wire                CLK,
    input   wire                CEN,
    input   wire                WEN,
    input   wire    [ADDR-1:0]  A,
    input   wire    [BPW-1:0]   D,
    output  reg     [BPW-1:0]   Q
    );
    parameter BPW = 32;
    parameter WORD = 256;
    parameter ADDR = $clog2(WORD);
    //-------------------------------------
    //Output Ports
    //-------------------------------------

    //-------------------------------------
    //Input Ports
    //-------------------------------------;
    
    //-------------------------------------
    //Signal Declarations: reg
    //-------------------------------------
    reg     [BPW-1:0]   mem [0:WORD-1];

    //-------------------------------------
    //Assignments
    //-------------------------------------
    always @(posedge CLK)
    if(~CEN) begin
		if(~WEN) begin
            mem[A]     = D;
            Q = #1 {BPW{1'bx}};
        end
        else begin
            Q = #1 {mem[A]};
        end
    end
    else begin
        Q = #1 {BPW{1'bx}};
    end
endmodule
