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

localparam UART_TICKS_PER_BIT = 2; // CLK_FREQ / BAUD_RATE

integer i;

initial begin
    $display("RAM '%s'", RAM_FILE);
    #rst_dur
    rst = 0;

    // ledi 0b1000         # start pipeline with nop like instruction
    // 8F33 // [0] 1:1
    #clk_tk
    
    // rl r1
    // 1633 // [1] 3:1
    #clk_tk

    // receive 0b0101_0101
    uart_rx = 1; // idle
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0; // start bit
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1; // stop bit
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1; // idle

    // uart writes reg
    #clk_tk
    
    if (top.core.regs.mem[1]==16'b0101_0101) $display("case 1 passed"); else $display("case 1 FAILED");
 
    // ldi 0x0002 r2
    // 2033 // [2] 4:1
    // 0002 // [3] 4:1
    #clk_tk
    #clk_tk
    if (top.core.regs.mem[2]==2) $display("case 2 passed"); else $display("case 2 FAILED");
    
    // call foo
    // 002B // [4] 6:1
    #clk_tk
    #clk_tk // bubble
    
    // foo: func
    // call bar
    // 004B // [32] 11:5
    #clk_tk
    #clk_tk // bubble
    
    // bar: func
    // rl r3  ret
    // 3637 // [64] 16:5
    #clk_tk
    
    // receive 0b1010_1010
    uart_rx = 1; // idle
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0; // start bit
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0;
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1; // stop bit
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1; // idle
    
    // uart writes reg
    #clk_tk
    
    if (top.core.regs.mem[3]==16'b1010_1010) $display("case 3 passed"); else $display("case 3 FAILED");
    
    #clk_tk // ret bubble
    
    // rl r4  ret
    // 4637 // [33] 12:5
    #clk_tk
    
    // receive 0b1111_1111
    uart_rx = 1; // idle
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 0; // start bit
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1;    
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1; // stop bit
    for (i = 0; i < UART_TICKS_PER_BIT; i = i + 1) #clk_tk;
    uart_rx = 1; // idle
    
    // uart writes reg
    #clk_tk
    if (top.core.regs.mem[4]==16'b1111_1111) $display("case 4 passed"); else $display("case 4 FAILED");
    
    // end:
    // jmp end
    // 000F // [5] 8:5
    #clk_tk
    #clk_tk // bubble
    
    // jmp end
    // 000F // [5] 8:5
    // note. pc is one step ahead of current instruction
    if (top.core.pc==6) $display("case 5 passed"); else $display("case 5 FAILED");

    
    $finish;
end

endmodule