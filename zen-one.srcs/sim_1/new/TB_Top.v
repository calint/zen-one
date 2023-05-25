`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module TB_Top;

localparam ROM_FILE = "TB_Top.mem";
localparam clk_tk = 10; // clk_tk = 1_000_000_000 / CLK_FREQ;
localparam rst_dur = 200; // 100+ns of power-on delay in Verilog simulation due to the under-the-hood assertion of Global Set/Reset signal.

reg clk = 0;
always #(clk_tk/2) clk = ~clk;

reg rst = 1;

Top #(
    .ROM_FILE(ROM_FILE)
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
    
    #clk_tk; // [0] 1033: ldi 0x1234 r1     # r1=0x1234
    #clk_tk; // [1] 0x1234
    if (top.core.regs.mem[1] == 16'h1234) $display("case 1 passed"); else $display("case 1 FAILED");
    
    #clk_tk; // [2] 2033: ldi 0xabcd r2     # r2=0xabcd
    #clk_tk; // [3] ABCD
    if (top.core.regs.mem[2] == 16'habcd) $display("case 2 passed"); else $display("case 2 FAILED");
    
    #clk_tk; // [4] 3033: ldi 0xffff r3     # r3=0xffff 
    #clk_tk; // [5] FFFF
    if (top.core.regs.mem[3] == 16'hffff) $display("case 3 passed"); else $display("case 3 FAILED");
    
    #clk_tk; // [6] 1273: st r2 r1          # ram[0xabcd]=0x1234
    if (top.ram.ram[16'habcd] == 16'h1234) $display("case 4 passed"); else $display("case 4 FAILED");
     
    #clk_tk; // [7] 3173: st r1 r3          # ram[0x1234]=0xffff
    if (top.ram.ram[16'h1234] == 16'hffff) $display("case 5 passed"); else $display("case 5 FAILED");
       
    #clk_tk; // [8] 6253: ld r2 r6          # r6=ram[0xabcd] == 0x1234
    #clk_tk; // [9] 4153: ld r1 r4          # r4=ram[0x1234] == 0xffff
    // ld r2 r6 completed
    if (top.core.regs.mem[6] == 16'h1234) $display("case 6 passed"); else $display("case 6 FAILED");
    #clk_tk; // [10] 1373: st r3 r1          # ram[0xffff]=0x1234
    // ld r1 r4 completed
    if (top.core.regs.mem[4] == 16'hffff) $display("case 7 passed"); else $display("case 7 FAILED");
    
    #clk_tk;
    #clk_tk;
    #clk_tk;
    $finish;
end

endmodule