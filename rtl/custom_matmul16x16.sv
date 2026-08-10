`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/11/12 21:48:00
// Design Name: 
// Module Name: custom_matmul16x16
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


module custom_matmul16x16(
    // System Clock
    input   wire            i_clk,

    // Tester Interface (External Memory Access)
    input   wire            i_cen,          // Chip Enable (Active Low)
    input   wire            i_wen,          // Write Enable (Active Low)
    input   wire    [8:0]   i_addr,         // Address Map: 0x000(A), 0x080(B), 0x100(O)
    input   wire    [31:0]  i_din,          // Data Input
    output  wire    [31:0]  o_dout,         // Data Output

    // Control Interface
    input   wire            i_rstn,         // Active Low Reset
    input   wire            i_matmul_en,    // Start Pulse
    input   wire    [2:0]   i_fl,           // Fractional Length for Truncation
    output  wire            o_done          // Operation Done Signal
);

    //==========================================================================
    // 1. Internal Signal Declarations
    //==========================================================================
    
    // SRAM Signals
    wire            amem_cen, amem_wen;
    wire [6:0]      amem_addr;
    wire [15:0]     amem_din, amem_dout;

    wire            bmem_cen, bmem_wen;
    wire [6:0]      bmem_addr;
    wire [15:0]     bmem_din, bmem_dout;

    wire            omem_cen, omem_wen;
    wire [7:0]      omem_addr;
    wire [31:0]     omem_din, omem_dout;

    // Address Decoding
    wire is_access_amem = (i_addr[8:7] == 2'b00); // AMEM
    wire is_access_bmem = (i_addr[8:7] == 2'b01); // BMEM
    wire is_access_omem = (i_addr[8]   == 1'b1);  // OMEM

    // Core Control Signals
    wire core_working = !o_done; 
    wire core_cen_a, core_cen_b, core_cen_o;
    wire core_wen_a, core_wen_b, core_wen_o;
    wire [6:0] core_addr_a, core_addr_b;
    wire [7:0] core_addr_o;
    wire [31:0] core_din_o;

    //==========================================================================
    // 2. SRAM MUX Logic (Arbiter)
    //==========================================================================
    // Switches SRAM control between the external Tester (IDLE) and Internal Core (BUSY).

    // AMEM MUX
    assign amem_cen  = (core_working) ? core_cen_a  : ~( (~i_cen) && is_access_amem );
    assign amem_wen  = (core_working) ? core_wen_a  : i_wen;
    assign amem_addr = (core_working) ? core_addr_a : i_addr[6:0];
    assign amem_din  = i_din[15:0];

    // BMEM MUX
    assign bmem_cen  = (core_working) ? core_cen_b  : ~( (~i_cen) && is_access_bmem );
    assign bmem_wen  = (core_working) ? core_wen_b  : i_wen;
    assign bmem_addr = (core_working) ? core_addr_b : i_addr[6:0];
    assign bmem_din  = i_din[15:0];

    // OMEM MUX
    assign omem_cen  = (core_working) ? core_cen_o  : ~( (~i_cen) && is_access_omem );
    assign omem_wen  = (core_working) ? core_wen_o  : i_wen;
    assign omem_addr = (core_working) ? core_addr_o : i_addr[7:0];
    assign omem_din  = (core_working) ? core_din_o  : i_din;

    //==========================================================================
    // 3. Output Readout Logic (Pipelined)
    //==========================================================================
    // Compenses for SRAM Read Latency (1 Cycle) to align data with Tester requests.

    reg [31:0] o_dout_reg;
    reg [1:0]  rd_sel; // 0:None, 1:AMEM, 2:BMEM, 3:OMEM

    assign o_dout = o_dout_reg;

    always @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            o_dout_reg <= 32'd0;
            rd_sel     <= 2'd0;
        end else begin
            // Drive Output Stage
            case (rd_sel)
                2'd1: o_dout_reg <= {16'd0, amem_dout}; // Zero-pad AMEM
                2'd2: o_dout_reg <= {16'd0, bmem_dout}; // Zero-pad BMEM
                2'd3: o_dout_reg <= omem_dout;          // OMEM
                default: o_dout_reg <= 32'd0;
            endcase

            // Request Capture Stage
            if (!i_cen && i_wen) begin
                if (is_access_omem)      rd_sel <= 2'd3;
                else if (is_access_amem) rd_sel <= 2'd1;
                else if (is_access_bmem) rd_sel <= 2'd2;
                else                     rd_sel <= 2'd0;
            end else begin
                rd_sel <= 2'd0;
            end
        end
    end

    //==========================================================================
    // 4. Finite State Machine (FSM)
    //==========================================================================
    localparam S_IDLE = 2'b00;
    localparam S_CALC = 2'b01;
    localparam S_DONE = 2'b10;

    reg [1:0] current_state, next_state;
    wire is_calc_finished;

    always @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) current_state <= S_IDLE;
        else current_state <= next_state;
    end

    always @(*) begin
        next_state = current_state;
        case (current_state)
            S_IDLE: begin
                if (i_matmul_en) next_state = S_CALC;
            end
            S_CALC: begin
                if (is_calc_finished) next_state = S_DONE;
            end
            S_DONE: begin
                next_state = S_IDLE;
            end
            default: next_state = S_IDLE;
        endcase
    end

    assign o_done = (current_state == S_IDLE) || (current_state == S_DONE);

    //==========================================================================
    // 5. Pipelined Datapath Core
    //==========================================================================
    
    reg [3:0] cnt_i, cnt_j, cnt_k; 
    reg signed [31:0] accumulator;
    reg [7:0] addr_o_reg;
    reg [8:0] loop_cnt;   
    reg signed [31:0] pipe_reg; // Pipeline Register for Timing Optimization

    always @(posedge i_clk or negedge i_rstn) begin
        if (!i_rstn) begin
            cnt_i <= 0; cnt_j <= 0; cnt_k <= 0;
            accumulator <= 0;
            pipe_reg <= 0; 
            addr_o_reg <= 0; loop_cnt <= 0;
        end else if (current_state == S_IDLE) begin
            cnt_i <= 0; cnt_j <= 0; cnt_k <= 0;
            accumulator <= 0;
            pipe_reg <= 0;
            addr_o_reg <= 0; loop_cnt <= 0;
        end else if (current_state == S_CALC) begin
            
            // -----------------------------------------------------
            // A. Continuous Loop Control
            // -----------------------------------------------------
            // Runs continuously without bubbles between pixels.
            if (cnt_k < 7) begin
                cnt_k <= cnt_k + 1;
            end else begin
                cnt_k <= 0; 
                if (cnt_j < 15) begin
                    cnt_j <= cnt_j + 1;
                end else begin
                    cnt_j <= 0;
                    if (cnt_i < 15) cnt_i <= cnt_i + 1;
                end
            end
            
            // -----------------------------------------------------
            // B. Address Capture
            // -----------------------------------------------------
            // Capture the write address for the current pixel at the end of the loop (k=7)
            if (cnt_k == 7) begin
                addr_o_reg <= {cnt_i, cnt_j};
                loop_cnt <= loop_cnt + 1;
            end
            
            // -----------------------------------------------------
            // C. Pipeline Stage 1: Multiplication & Addition
            // -----------------------------------------------------
            // Reduces critical path delay by separating Multiply and Accumulate stages.
            pipe_reg <= ($signed(amem_dout[15:8]) * $signed(bmem_dout[15:8])) 
                      + ($signed(amem_dout[7:0])  * $signed(bmem_dout[7:0]));

            // -----------------------------------------------------
            // D. Pipeline Stage 2: Accumulation & Reset
            // -----------------------------------------------------
            // Due to pipeline latency, the result for a pixel is ready at k=2 of the NEXT loop.
            // k=2: Reset accumulator for the NEW pixel (load first partial sum from pipe_reg).
            // else: Keep accumulating.
            if (cnt_k == 2) begin
                accumulator <= pipe_reg; // Reset / Load New
            end else begin
                accumulator <= accumulator + pipe_reg; // Accumulate
            end
        end
    end

    //==========================================================================
    // 6. Core Logic Outputs
    //==========================================================================

    // Address Generation
    assign core_addr_a = {cnt_i, cnt_k[2:0]}; 
    assign core_addr_b = {cnt_j, cnt_k[2:0]};
    assign core_addr_o = addr_o_reg; // Write to the captured address
    
    // Result Output (Truncated)
    assign core_din_o  = accumulator >>> i_fl; 

    // SRAM Read Enable (Active Low) - Always Read
    assign core_cen_a  = 1'b0; 
    assign core_cen_b  = 1'b0;
    assign core_wen_a  = 1'b1; // Read Only
    assign core_wen_b  = 1'b1; // Read Only

    // -----------------------------------------------------
    // Write Timing Control
    // -----------------------------------------------------
    // Write Condition: k=2.
    // The calculation for a pixel finishes and is held in the accumulator until k=2.
    // At k=2, the accumulator is rewritten with new data, so we must write BEFORE that happens.
    // 'loop_cnt >= 1' prevents writing garbage data during the first warm-up loop.
    assign core_wen_o  = !((cnt_k == 2) && (loop_cnt >= 1)); 
    assign core_cen_o  = !((cnt_k == 2) && (loop_cnt >= 1));

    // Finish Condition
    // 256 pixels processed and the final write (at k=2) is complete.
    assign is_calc_finished = (loop_cnt == 256) && (cnt_k == 2);

    //==========================================================================
    // 7. Module Instantiation
    //==========================================================================
    
    sram_16x1_128 AMEM (
        .CLK    (i_clk      ),
        .CEN    (amem_cen   ),
        .WEN    (amem_wen   ),
        .A      (amem_addr  ),
        .D      (amem_din   ),
        .Q      (amem_dout  )
    );

    sram_16x1_128 BMEM (
        .CLK    (i_clk      ),
        .CEN    (bmem_cen   ),
        .WEN    (bmem_wen   ),
        .A      (bmem_addr  ),
        .D      (bmem_din   ),
        .Q      (bmem_dout  )
    );
    
    sram_32x1_256 OMEM (
        .CLK    (i_clk      ),
        .CEN    (omem_cen   ),
        .WEN    (omem_wen   ),
        .A      (omem_addr  ),
        .D      (omem_din   ),
        .Q      (omem_dout  )
    );
    
endmodule
