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
    //#(clk_tk/2)
    
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
    #clk_tk; // ld r2 r6 completed
    if (top.core.regs.mem[6] == 16'h1234) $display("case 6 passed"); else $display("case 6 FAILED");
    #clk_tk; // [9] 4153: ld r1 r4          # r4=ram[0x1234] == 0xffff
    #clk_tk; // ld r1 r4 completed
    if (top.core.regs.mem[4] == 16'hffff) $display("case 7 passed"); else $display("case 7 FAILED");
    
    #clk_tk; // [10] 1373: st r3 r1          # ram[0xffff]=0x1234
    if (top.ram.ram[16'hffff] == 16'h1234) $display("case 8 passed"); else $display("case 8 FAILED");

    #clk_tk; // [11] 5353: ld r3 r5          # r5=ram[0xffff] == 0x1234
    #clk_tk;
    if (top.core.regs.mem[5] == 16'h1234) $display("case 9 passed"); else $display("case 9 FAILED");
    
    #clk_tk; // [12] 4013: addi 1 r4         # r4 == 0
    if (top.core.regs.mem[4] == 16'h0000) $display("case 10 passed"); else $display("case 10 FAILED");
    if (top.core.zn_zf && !top.core.zn_nf) $display("case 11 passed"); else $display("case 11 FAILED");

    #clk_tk; // [13] 4F13: addi -1 r4        # r4 == 0xffff
    if (top.core.regs.mem[4] == 16'hffff) $display("case 12 passed"); else $display("case 12 FAILED");
    if (!top.core.zn_zf && top.core.zn_nf) $display("case 13 passed"); else $display("case 13 FAILED");

    #clk_tk; // [14] 4303: add r3 r4         # r4 == 0xfffe
    if (top.core.regs.mem[4] == 16'hfffe) $display("case 14 passed"); else $display("case 14 FAILED");
    if (!top.core.zn_zf && top.core.zn_nf) $display("case 15 passed"); else $display("case 15 FAILED");
    
    #clk_tk; // [15] 4323: sub r3 r4         # r4 == 0xffff
    if (top.core.regs.mem[4] == 16'hffff) $display("case 16 passed"); else $display("case 16 FAILED");
    if (!top.core.zn_zf && top.core.zn_nf) $display("case 17 passed"); else $display("case 17 FAILED");

    #clk_tk; // [16] 6443: or r4 r6          # r6 == 0xffff
    if (top.core.regs.mem[6] == 16'hffff) $display("case 18 passed"); else $display("case 18 FAILED");
    if (!top.core.zn_zf && top.core.zn_nf) $display("case 19 passed"); else $display("case 19 FAILED");

    #clk_tk; // [17] 6663: xor r6 r6         # r6 == 0
    if (top.core.regs.mem[6] == 0) $display("case 20 passed"); else $display("case 20 FAILED");
    if (top.core.zn_zf && !top.core.zn_nf) $display("case 21 passed"); else $display("case 21 FAILED");

    #clk_tk; // [18] 6483: and r4 r6         # r6 == 0
    if (top.core.regs.mem[6] == 0) $display("case 21 passed"); else $display("case 21 FAILED");
    if (top.core.zn_zf && !top.core.zn_nf) $display("case 22 passed"); else $display("case 22 FAILED");

    #clk_tk; // [19] 64A3: not r4 r6         # r6 == 0
    if (top.core.regs.mem[6] == 0) $display("case 23 passed"); else $display("case 23 FAILED");
    if (top.core.zn_zf && !top.core.zn_nf) $display("case 24 passed"); else $display("case 24 FAILED");

    #clk_tk; // [20] 61C3: cp r1 r6          # r6 == 0x1234
    if (top.core.regs.mem[6] == 16'h1234) $display("case 25 passed"); else $display("case 25 FAILED");
    if (!top.core.zn_zf && !top.core.zn_nf) $display("case 26 passed"); else $display("case 26 FAILED");

    #clk_tk; // [21] 60E3: shf 1 r6          # r6 == 0x0910
    if (top.core.regs.mem[6] == 16'h0910) $display("case 27 passed"); else $display("case 27 FAILED");
    if (!top.core.zn_zf && !top.core.zn_nf) $display("case 28 passed"); else $display("case 28 FAILED");

    #clk_tk; // [22] 6FE3: shf -1 r6         # r6 = 0x1234
    if (top.core.regs.mem[6] == 16'h1234) $display("case 29 passed"); else $display("case 29 FAILED");
    if (!top.core.zn_zf && !top.core.zn_nf) $display("case 30 passed"); else $display("case 30 FAILED");
    
    #clk_tk; // [23] 7031: ifz ldi 0x0001 r7 # z!=1 => does not execute
    #clk_tk; // [24] 0x0001
    if (top.core.regs.mem[7] != 1) $display("case 31 passed"); else $display("case 31 FAILED");

    #clk_tk; // [25] 44C3: cp r4 r4          # r4 = 0xffff
    if (top.core.regs.mem[4] == 16'hffff) $display("case 32 passed"); else $display("case 32 FAILED");
    if (!top.core.zn_zf && top.core.zn_nf) $display("case 33 passed"); else $display("case 33 FAILED");

    #clk_tk; // [26] 7032: ifn ldi 0x0001 r7 # n==1 r7=0x0001
    #clk_tk; // [27] 0x0001
    if (top.core.regs.mem[7] == 1) $display("case 34 passed"); else $display("case 34 FAILED");
    
    $finish;
end

endmodule