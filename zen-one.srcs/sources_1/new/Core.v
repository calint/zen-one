`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module Core(
    input wire rst,
    input wire clk,
    output reg [ROM_ADDR_WIDTH-1:0] pc,
    input wire [15:0] instr,
    output wire [ROM_ADDR_WIDTH-1:0] ram_addra,
    input wire [15:0] ram_doa,
    output wire [15:0] ram_dia,
    output wire ram_wea
);

localparam REGISTERS_ADDR_WIDTH = 4; // (2**4) 16 registers (not changable since register address is encoded in instruction using 4 bits) 
localparam REGISTERS_WIDTH = 16; // 16 bit
localparam CALLS_ADDR_WIDTH = 6; // (2**6) 64
localparam ROM_ADDR_WIDTH = 16; // (2**16) 64K

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

wire zn_zf;
wire zn_nf;

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

//
// Calls
//
reg is_calling;
wire cs_call = is_do_op && !is_calling && instr_c && !instr_r;
wire cs_ret = is_do_op && !instr_c && instr_r;
wire cs_en = cs_call || cs_ret;
wire [ROM_ADDR_WIDTH-1:0] cs_pc_out;
wire cs_zf; // Calls -> Zn
wire cs_nf; // Calls -> Zn

//
// ALU
//
wire is_alu_op = !is_ldi && !is_jmp && !cs_call && (!instr_op[0] || instr_op == OP_ADDI);

wire [2:0] alu_op = 
    instr_op == OP_ADDI ? ALU_ADD : // 'addi' is add with signed immediate value 'rega'
    instr_op[3:1]; // same as upper 3 bits of op

wire [REGISTERS_WIDTH-1:0] alu_operand_a =
    instr_op == OP_SHF || instr_op == OP_ADDI ? (rega[3] ? {{(REGISTERS_WIDTH-4){rega[3]}},rega} : {{(REGISTERS_WIDTH-4){1'b0}},rega} + 1) : 
    rega_dat; // otherwise regs[a]

wire alu_zf;

wire alu_nf;

wire [REGISTERS_WIDTH-1:0] alu_result;

//
// Registers
//
wire regs_we = 
    (was_do_op && (is_ldi || was_op_ld)) || 
    (is_do_op && is_alu_op && !is_calling);
    
wire [REGISTERS_WIDTH-1:0] regs_wd =
    was_do_op && is_ldi ? instr :
    was_do_op && was_op_ld ? ram_doa :
    is_do_op && is_alu_op ? alu_result :
    0;

wire [REGISTERS_WIDTH-1:0] rega_dat;

wire [REGISTERS_WIDTH-1:0] regb_dat;

wire is_op_st = is_do_op && !is_jmp && instr_op == OP_ST;

wire is_op_ld = is_do_op && !is_jmp && instr_op == OP_LD;

reg was_op_ld;

reg [3:0] ld_reg;

assign ram_addra = rega_dat;
assign ram_dia = regb_dat;
assign ram_wea = is_op_st && !was_op_ld;

//
// Zn
//
wire zn_we = is_do_op && (is_alu_op || cs_call || cs_ret);
wire zn_sel = cs_ret;
wire zn_clr = cs_call;

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
        is_calling <= 0;
    end else begin
    
        if (cs_ret && !is_calling) begin
            pc <= cs_pc_out;
            stp <= 5;
        end else begin
            pc <= pc + 1;
        end
                
        case(stp)
        
        4'd1: begin 
            $display("%0t: clk+: Core: %0d:%0h boot", $time, pc, instr);
            stp <= 2;
        end
        
        4'd2: begin
            was_do_op <= is_do_op;
            if (!is_do_op) begin
            end else begin
                if (is_jmp) begin
                    pc <= pc + {{(16-12){imm12[11]}},imm12} - 1; // -1 because pc ahead by 1 instruction
                    stp <= 5;
                end else if (cs_call) begin
                    pc <= imm12 << 4;
                    is_calling <= 1;                
                    stp <= 5;
                end else begin
                    case(instr_op)
                    OP_LDI: begin
                        is_ldi <= 1;
                        ldi_reg <= regb;
                        stp <= 3;
                    end
                    OP_LD: begin
                        was_op_ld <= 1;
                        ld_reg <= instr[15:12];
                        if (!cs_ret) begin
                            pc <= pc; // overwrite pc to stall
                        end
                        stp <= 4;
                    end
                    endcase
                end // is_jmp
            end // !is_do_op
        end // case

        4'd3: begin // OP_LDI second part
            is_ldi <= 0;
            stp <= 2;
        end

        4'd4: begin // OP_LD second part
            was_op_ld <= 0;
            stp <= 2;
        end

        4'd5: begin // call second part
            is_calling <= 0;
            stp <= 2;
        end
        
        endcase
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

ALU #(
    .WIDTH(REGISTERS_WIDTH)
) alu (
    .op(alu_op),
    .a(alu_operand_a),
    .b(regb_dat),
    .result(alu_result),
    .zf(alu_zf),
    .nf(alu_nf)
);

Zn zn (
    .rst(rst),
    .clk(clk),
    .cs_zf(cs_zf),
    .cs_nf(cs_nf),
    .alu_zf(alu_zf),
    .alu_nf(alu_nf),
    .we(zn_we), // depending on 'sel' copy 'Calls' or 'ALU' zn flags
    .sel(zn_sel), // selector when 'we', enabled cs_*, disabled alu_* 
    .clr(zn_clr), // selector when 'we', clears the flags, has precedence over 'sel'
    .zf(zn_zf),
    .nf(zn_nf)
);

Calls #(
    .ADDR_WIDTH(CALLS_ADDR_WIDTH),
    .ROM_ADDR_WIDTH(ROM_ADDR_WIDTH)
) cs (
    .rst(rst),
    .clk(clk),
    .pc_in(pc), // current program counter
    .zf_in(zn_zf), // current zero flag
    .nf_in(zn_nf), // current negative flag
    .call(cs_call), // enabled when it is a 'call'
    .ret(cs_ret), // enabled when instruction is also 'return'
    .en(cs_en), // enables 'push' or 'pop'
    .pc_out(cs_pc_out), // top of stack program counter
    .zf_out(cs_zf), // top of stack zero flag
    .nf_out(cs_nf) // top of stack negative flag
);

endmodule

`undef DBG
`default_nettype wire