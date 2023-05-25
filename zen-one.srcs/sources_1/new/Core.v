`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module Core(
    input wire rst,
    input wire clk,
    output reg [15:0] pc,
    input wire [15:0] instr,
    output wire [15:0] ram_addra,
    input wire [15:0] ram_doa,
    output wire [15:0] ram_dia,
    output wire ram_wea
);

localparam REGISTERS_ADDR_WIDTH = 4; // 2**4 16 registers (not changable since register address is encoded in instruction using 4 bits) 
localparam REGISTERS_WIDTH = 16; // 16 bit

localparam OP_ADDI = 4'b0001; // add immediate signed 4 bits value to 'regb' where imm4>=0?++imm4:-imm4
localparam OP_LDI  = 4'b0011; // load immediate 16 bits from next instruction
localparam OP_LD   = 4'b0101; // load ram address of 'rega' to 'regb'
localparam OP_ST   = 4'b0111; // store 'regb' to ram address 'rega'
localparam OP_SHF  = 4'b1110; // shift immediate signed 4 bits value where imm4>=0?++imm4:-imm4

localparam OP_IO_READ  = 3'b110;
localparam OP_IO_WRITE = 3'b010;
localparam OP_IO_LED   = 3'b111;

localparam ALU_ADD = 3'b000; // add 'rega' to 'regb'
localparam ALU_SUB = 3'b001; // substract 'rega' from 'regb'
localparam ALU_OR  = 3'b010; // bitwise or 'rega' to 'regb'
localparam ALU_XOR = 3'b011; // bitwise xor 'rega' to 'regb'
localparam ALU_AND = 3'b100; // bitwise and 'rega' to 'regb'
localparam ALU_NOT = 3'b101; // bitwise not 'rega' to 'regb'
localparam ALU_CP  = 3'b110; // copy 'rega' to 'regb'
localparam ALU_SHF = 3'b111; // shift immediate signed 4 bits value of 'regb' where imm4>=0?++imm4:-imm4

reg is_ldi;
reg [3:0] ldi_reg;
reg urx_reg_sel;
reg [3:0] urx_reg;

wire zn_zf = 0;
wire zn_nf = 0;
wire is_do_op = !is_ldi && ((instr_z && instr_n) || (zn_zf == instr_z && zn_nf == instr_n));
reg was_do_op;

wire instr_z = instr[0];
wire instr_n = instr[1];
wire instr_r = instr[2];
wire instr_c = instr[3];
wire is_jmp = instr_c && instr_r;
wire [3:0] instr_op = instr[7:4];
wire [3:0] rega = instr[11:8];
wire [3:0] regb =
    was_do_op && is_ldi ? ldi_reg :
    was_do_op && was_op_ld ? ld_reg :
    was_do_op && urx_reg_sel ? urx_reg : 
    instr[15:12];
wire [11:0] imm12 = instr[15:4];

wire regs_we = 
    was_do_op && (is_ldi || was_op_ld) ? 1 :
    0;

wire [REGISTERS_WIDTH-1:0] regs_wd =
    was_do_op && is_ldi ? instr :
    was_do_op && was_op_ld ? ram_doa :
    0;

wire [REGISTERS_WIDTH-1:0] rega_dat;
wire [REGISTERS_WIDTH-1:0] regb_dat;

wire is_op_st = is_do_op && !is_jmp && instr_op == OP_ST;
wire is_op_ld = is_do_op && !is_jmp && instr_op == OP_LD;
reg was_op_ld;
reg [3:0] ld_reg;

wire stall = was_op_ld && is_op_st;

assign ram_addra = rega_dat;
assign ram_dia = regb_dat;
assign ram_wea = is_op_st;

reg [3:0] stp;

always @(negedge clk) begin
    `ifdef DBG
        $display("%0t: clk-: Core: stp=%0d, %0d:%0h", $time, stp, pc, instr);
        $strobe("%0t: strobe clk-: Core: stp=%0d, [%0d]=%0h process", $time, stp, pc, instr);
    `endif
end

always @(posedge clk) begin
    `ifdef DBG
        $display("%0t: clk+: Core: %0d:%0h process", $time, pc, instr);
        $strobe("%0t: strobe clk+: Core: stp=%0d, [%0d]=%0h process", $time, stp, pc, instr);
    `endif
    if (rst) begin
        pc <= 0;
        stp <= 1;
        is_ldi <=0;
        ldi_reg <= 0;
        urx_reg_sel <=0;
        urx_reg <= 0;
        was_do_op <= 0;
        was_op_ld <= 0;
        ld_reg <= 0;
    end else begin
    
        case(stp)
        
        2'h1: begin 
            $display("%0t: clk+: Core: %0d:%0h boot", $time, pc, instr);
            stp <= 2;
        end
        
        2'h2: begin
            was_do_op <= is_do_op;
            was_op_ld <= is_op_ld;
            ld_reg <= instr[15:12];
            if (!is_do_op) begin
            end else begin
                case(instr_op)
                OP_LDI: begin
                    is_ldi <= 1;
                    ldi_reg <= regb;
                    stp <= 3;
                end
                endcase
            end
        end

        2'h3: begin
            is_ldi <= 0;
            stp <= 2;
        end
        
        endcase
        if (!stall) begin
            pc <= pc + 1;
        end else $display("*** stall");
    end
end

Registers #(
    .ADDR_WIDTH(REGISTERS_ADDR_WIDTH),
    .WIDTH(REGISTERS_WIDTH)
) regs ( // 16 x 16b
    .clk(clk),
    .ra1(rega),
    .ra2(regb),
    .wd(regs_wd),
    .we(regs_we),
    .rd1(rega_dat),
    .rd2(regb_dat)
);

endmodule

`undef DBG
`default_nettype wire