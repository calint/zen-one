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
    
    #clk_tk // [0] boot
    
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
    if (top.led == 3'b0010) $display("case 6 passed"); else $display("case 6 FAILED");

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
    if (!top.core.zn_zf && top.core.zn_nf) $display("case 7.1 passed"); else $display("case 7.1 FAILED");

    // jmp lbl1            # pc -> 0x0020
    // 015F // [11] 13:5
    // note. pc is one instruction ahead
    if (top.core.pc == 12) $display("case 9 passed"); else $display("case 9 FAILED");

    #clk_tk
    #clk_tk
    // @ 0x0020 lbl1:
    // note. pc is one instruction ahead
    if (top.core.pc == 33) $display("case 10 passed"); else $display("case 10 FAILED");
    
    $finish;
end

endmodule