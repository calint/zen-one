`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module TB_Top;

localparam RAM_FILE = "TB_Top.mem";
localparam clk_tk = 10; // clk_tk = 1_000_000_000 / CLK_FREQ;
localparam rst_dur = 200; // 100+ns of power-on delay in Verilog simulation due to the under-the-hood assertion of Global Set/Reset signal.

reg clk = 0;
always #(clk_tk/2) clk = ~clk;

reg rst = 1;

reg uart_rx = 1;

Top #(
    .RAM_FILE(RAM_FILE),
    .CLK_FREQ(66_000_000),
    .BAUD_RATE(66_000_000>>1)
) top (
    .reset(rst),
    .clk_in(clk),
    .uart_rx(uart_rx)
);

integer i;

initial begin
    $display("RAM '%s'", RAM_FILE);
    #rst_dur
    rst = 0;

    #clk_tk
    #clk_tk
    #clk_tk;
    #clk_tk;
    #clk_tk;
    #clk_tk;
    #clk_tk
    #clk_tk
    #clk_tk;
    #clk_tk;
    #clk_tk;
    #clk_tk;
    #clk_tk;
    #clk_tk;
    #clk_tk;
    #clk_tk;
    #1000;
    $finish;
end

endmodule