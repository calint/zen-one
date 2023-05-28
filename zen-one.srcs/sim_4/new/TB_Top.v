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
    .RAM_FILE(RAM_FILE)
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
    
    // start the pipe-line
    // note. first instruction runs twice and must be a single cycle
    // ledi 0b1000         # start the pipe-line (runs twice)
    // 8F33 // [0] 4:5
    #clk_tk
    
    // ledi 0b1000         # start the pipe-line (runs twice)
    // 8F33 // [0] 4:5    
    #clk_tk
    
    // ldi 0x0001 r1       # r1=0x0001
    // 1033 // [0] 4:5
    // 0001 // [1] 4:5
    #clk_tk
    #clk_tk
    if (top.core.regs.mem[1] == 1) $display("case 1 passed"); else $display("case 1 FAILED");
       
    // ldi 0xffff r2       # r2=0xffff
    // 2033 // [2] 5:5
    // FFFF // [3] 5:5 
    #clk_tk;
    #clk_tk;
    if (top.core.regs.mem[2] == -1) $display("case 2 passed"); else $display("case 2 FAILED");

    // cp r1 r3            # r3=r1 == 0x0001
    // 31C3 // [4] 6:5
    #clk_tk
    if (top.core.regs.mem[3] == 1) $display("case 3 passed"); else $display("case 3 FAILED");
    
    // add r2 r3           # r3+=r1 == 0
    // 3203 // [5] 7:5
    #clk_tk
    if (top.core.regs.mem[3] == 0) $display("case 4 passed"); else $display("case 4 FAILED");
    if (top.core.zn_zf && !top.core.zn_nf) $display("case 5 passed"); else $display("case 5 FAILED");

    // zn=10
    // r0 = 0x0000
    // r1 = 0x0001
    // r2 = 0xffff
    // r3 = 0x0000
    
    // ifz ledi 0b0010     # if(r3==0)     
    // 2F31 // [6] 8:5
    #clk_tk
    if (top.led == 4'b0010) $display("case 6 passed"); else $display("case 6 FAILED");

    // ifp call err         # if(r3>0) ; branch not taken
    // FFF8 // [7] 8:5
    #clk_tk
    
    // ifn call err         # if(r3<0) ; branch not taken
    // FFFA // [8] 9:5
    #clk_tk

    // cp r2 r3            # r3=r2 == 0xffff
    // 32C3 // [9] 11:5
    #clk_tk
    if (!top.core.zn_zf && top.core.zn_nf) $display("case 7 passed"); else $display("case 7 FAILED");
    
    // ifn call foo        # if(r3<0) ; branch taken
    // 001A // [10] 12:5
    #clk_tk
    #clk_tk
    
    // @ 0x0010 foo: func
    // ledi 0b0010  ret    # 
    // 2F37 // [16] 19:5
    // note. pc is one instruction ahead
    if (top.core.pc == 17) $display("case 8 passed"); else $display("case 8 FAILED");
    #clk_tk
    #clk_tk
    if (!top.core.zn_zf && top.core.zn_nf) $display("case 9 passed"); else $display("case 9 FAILED");

    // jmp lbl1            # pc -> 0x0020
    // 015F // [11] 13:5
    // note. pc is one instruction ahead
    if (top.core.pc == 13) $display("case 10 passed"); else $display("case 10 FAILED");

    #clk_tk
    #clk_tk
    // @ 0x0020 lbl1:
    // note. pc is one instruction ahead
    if (top.core.pc == 33) $display("case 11 passed"); else $display("case 11 FAILED");

    // zn=01
    // r0 = 0x0000
    // r1 = 0x0001
    // r2 = 0xffff
    // r3 = 0xffff
    
    // st r1 r3            # ram[0x0001]=0xffff
    // 3173 // [32] 20:5
    #clk_tk
    if (top.ram.ram[1] == 16'hffff) $display("case 12 passed"); else $display("case 12 FAILED");
   
    // ifp ld r1 r4        # zn!=00 ; not executed
    // 4150 // [33] 21:5
    #clk_tk
    
    // ifn ld r1 r4        # zn==01 ; executed r4=ram[0x0001] == 0xffff
    // 4152 // [34] 22:5
    #clk_tk
    // check that previous 'ld' did not load register
    if (top.core.regs.mem[4] == 0) $display("case 13 passed"); else $display("case 13 FAILED");
    
    // zn=01
    // r0 = 0x0000
    // r1 = 0x0001
    // r2 = 0xffff
    // r3 = 0xffff
    // r4 = 0xffff
    
    // call bar
    // 003B // [35] 23:5
    #clk_tk
    // check that previous 'ld' did load register
    if (top.core.regs.mem[4] == 16'hffff) $display("case 14 passed"); else $display("case 14 FAILED");
    #clk_tk

    // @ 0x0030 bar: func
    // note. pc is one instruction ahead
    if (top.core.pc == 49) $display("case 15 passed"); else $display("case 15 FAILED");
    // check that zn==00 when entering call
    if (!top.core.zn_zf && !top.core.zn_nf) $display("case 16 passed"); else $display("case 16 FAILED");

    // ld r1 r5  ret       # r5=ram[0x0001] == 0xffff
    // 5157 // [48] 26:5 
    #clk_tk
    #clk_tk // extra cycle for the bubble from 'ret'
    if (top.core.pc == 37) $display("case 17 passed"); else $display("case 17 FAILED");
    // check that zn flags restore after returning from call. zn==01
    if (!top.core.zn_zf && top.core.zn_nf) $display("case 18 passed"); else $display("case 18 FAILED");

    // zn=01
    // r0 = 0x0000
    // r1 = 0x0001
    // r2 = 0xffff
    // r3 = 0xffff
    // r4 = 0xffff
    // r5 = 0xffff
    
    // jmp lbl2
    // 01CF // [36] 24:5
    #clk_tk
    // note. check that the 'ld' run in previous instruction has loaded the register
    if (top.core.regs.mem[5] == 16'hffff) $display("case 19 passed"); else $display("case 19 FAILED");
    #clk_tk
    // @ 0x0040  lbl2:
    // note. pc is one instruction ahead
    if (top.core.pc == 65) $display("case 20 passed"); else $display("case 20 FAILED");
    // ifz ldi 0x0002 r6   # zn==01 ; not executed
    // 6031 // [64] 33:5
    // 0002 // [65] 33:5
    #clk_tk
    #clk_tk
    if (top.core.regs.mem[6] != 2) $display("case 21 passed"); else $display("case 21 FAILED");
    // bug check. if the data part of the 'ldi' is interpreted as an instruction then zn becomes 10 because r0+=r0 == 0
    if (!top.core.zn_zf && top.core.zn_nf) $display("case 22 passed"); else $display("case 22 FAILED");
    
    // ram[1] = 0xffff
    
    // ld r1 r7            # r7=ram[1] == 0xffff
    // 7153 // [66] 34:5
    #clk_tk
    
    // add r7 r7           # 0xffff + 0xffff = 0xfffe
    // 7703 // [67] 35:5
    #clk_tk
    if (top.core.regs.mem[7] == 16'hfffe) $display("case 23 passed"); else $display("case 23 FAILED");
    
    // ld r1 r8            # r8=ram[1] == 0xffff
    // 8153 // [68] 36:5
    #clk_tk

    // st r8 r1            # ram[0xffff]=1
    // 1873 // [69] 37:5
    #clk_tk
    if (top.ram.ram[16'hffff] == 1) $display("case 24 passed"); else $display("case 24 FAILED");
    
    $finish;
end

endmodule