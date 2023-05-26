`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module TB_Uart;

localparam ROM_FILE = "TB_Uart.mem";
localparam clk_tk = 10; // clk_tk = 1_000_000_000 / CLK_FREQ;
localparam rst_dur = 200; // 100+ns of power-on delay in Verilog simulation due to the under-the-hood assertion of Global Set/Reset signal.

reg clk = 0;
always #(clk_tk/2) clk = ~clk;

reg rst = 1;

Top #(
    .ROM_FILE(ROM_FILE),
    .CLK_FREQ(66_000_000),
    .BAUD_RATE(66_000_000>>1)
) top (
    .reset(rst),
    .clk_in(clk)
);

integer i;

initial begin
    $display("ROM '%s'", ROM_FILE);
    #rst_dur
    rst = 0;
    
    #clk_tk; // [0] boot

    #4000;
    
    $finish;
end

endmodule