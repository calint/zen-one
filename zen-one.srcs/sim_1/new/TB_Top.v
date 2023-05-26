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

    #clk_tk; // [21] 60E3: shf 1 r6          # r6 == 0x091A
    if (top.core.regs.mem[6] == 16'h091a) $display("case 27 passed"); else $display("case 27 FAILED");
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
    
    #clk_tk; // [28] 004C: ifp jmp lbl1      # zn!=00 => does not execute
    if (top.core.pc == 30) $display("case 35 passed"); else $display("case 35 FAILED");

    #clk_tk; // [29] 003F: jmp lbl1
    if (top.core.pc == 32) $display("case 36 passed"); else $display("case 36 FAILED");
    #clk_tk; // wait for ram

    // zn==01
    #clk_tk; // [32] 003B: call x0030
    if (top.core.pc == 48) $display("case 37 passed"); else $display("case 37 FAILED");
    if (!top.core.zn_zf && !top.core.zn_nf) $display("case 38 passed"); else $display("case 38 FAILED");
    #clk_tk; // wait for ram

    #clk_tk; // [48] 8017: addi 1 r8 ret
    if (top.core.pc == 33) $display("case 38 passed"); else $display("case 38 FAILED");
    if (!top.core.zn_zf && top.core.zn_nf) $display("case 39 passed"); else $display("case 39 FAILED");
   
    // zn==01
    #clk_tk; // [33] 0048: ifp call x0040
    if (top.core.pc == 34) $display("case 40 passed"); else $display("case 40 FAILED");

    #clk_tk; // [34] 0049: ifz call x0040
    if (top.core.pc == 35) $display("case 41 passed"); else $display("case 41 FAILED");
   
    #clk_tk; // [35] 9030: ifp ldi 0x0040 r9
    #clk_tk; // [36] 0040
    if (top.core.regs.mem[9] != 16'h0040) $display("case 42 passed"); else $display("case 42 FAILED");

    #clk_tk; // [37] 9031: ifz ldi 0x0040 r9
    #clk_tk; // [38] 0040
    if (top.core.regs.mem[9] != 16'h0040) $display("case 43 passed"); else $display("case 43 FAILED");
    
    #clk_tk; // [39] 00AC: ifp jmp x007
    if (top.core.pc == 40) $display("case 44 passed"); else $display("case 44 FAILED");

    #clk_tk; // [40] 009D: ifz jmp x007
    if (top.core.pc == 41) $display("case 45 passed"); else $display("case 45 FAILED");
    
    #clk_tk; // [41] 005A: ifn call x0050
    #clk_tk; // wait for ram
    if (top.core.pc == 80) $display("case 46 passed"); else $display("case 46 FAILED");

    #clk_tk; // [80] 006B: call x0060
    #clk_tk; // wait for ram
    if (top.core.pc == 96) $display("case 47 passed"); else $display("case 47 FAILED");
    
    // r8 == 1, zn == 00
    #clk_tk; // [96] 8116: ifn addi 2 r8 ret
    if (top.core.pc == 97) $display("case 48 passed"); else $display("case 48 FAILED");
    if (top.core.regs.mem[8] == 1) $display("case 49 passed"); else $display("case 49 FAILED");
    
    #clk_tk; // [97] 8115: ifz addi 2 r8 ret
    if (top.core.pc == 98) $display("case 50 passed"); else $display("case 50 FAILED");
    if (top.core.regs.mem[8] == 1) $display("case 51 passed"); else $display("case 51 FAILED");
    
    #clk_tk; // [98] 8114: ifp addi 2 r8 ret
    #clk_tk; // wait for ram
    if (top.core.pc == 81)  $display("case 52 passed"); else $display("case 52 FAILED");
    if (top.core.regs.mem[8] == 3) $display("case 53 passed"); else $display("case 53 FAILED");
    
    #clk_tk; // [81] 8117: addi 2 r8 ret
    #clk_tk; // wait for ram
    if (top.core.pc == 42)  $display("case 54 passed"); else $display("case 54 FAILED");
    if (top.core.regs.mem[8] == 5) $display("case 55 passed"); else $display("case 55 FAILED");
        
    #clk_tk; // [42] 007B: call x0070
    #clk_tk; // wait for ram
    if (top.core.pc == 112)  $display("case 56 passed"); else $display("case 56 FAILED");
    
    #clk_tk; // [112] 9037: ldi 0xdcba r9  ret
    #clk_tk; // [113] DCBA
    if (top.core.pc == 43)  $display("case 57 passed"); else $display("case 57 FAILED");
    #clk_tk; // wait for ram
    if (top.core.regs.mem[9] == 16'hdcba) $display("case 58 passed"); else $display("case 58 FAILED");
    
    #clk_tk; // [43] AF33: ledi 0b1010
    #clk_tk; // [44] 9733: led r9        # r9==0xdcba => led==0xa
    #clk_tk; // [45] 004F: jmp x007
    
    $finish;
end

endmodule