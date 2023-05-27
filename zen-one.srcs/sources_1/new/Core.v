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
    output wire ram_wea,
    output reg [3:0] led,
    output reg [7:0] utx_dat,
    output reg utx_go,
    input wire utx_bsy,
    input wire [7:0] urx_dat,
    input wire urx_dr,
    output reg urx_go
);

localparam REGS_ADDR_WIDTH = 4; // (2**4) 16 registers (not changable since register address is encoded in instruction using 4 bits) 
localparam REGS_WIDTH = 16; // 16 bit
localparam CALLS_ADDR_WIDTH = 6; // (2**6) 64
localparam RAM_ADDR_WIDTH = 16; // (2**16) 64K

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

//
// load immediate (ldi)
//
// enabled if in data part of the instruction
reg is_ldi;
// destination register saved from previous cycle
reg [3:0] ldi_reg;

//
// UartRx
//
// the register to write to
reg [3:0] urx_reg;
// previous data of the register
reg [15:0] urx_reg_dat;
// write register high or low byte
reg urx_reg_hilo;
// enabled when 'urx_reg_dat' is written to 'urx_reg'
reg urx_wb;

// enabled when previous instruction did execute
reg was_do_op;

//
// load (ld)
//
// enabled when previous instruciton was 'ld'
// the load instruction writes to register during the second cycle
reg is_ld;
// the register to which the 'ld' instruction wants to write to
// set in the first cycle of the instruction
reg [3:0] ld_reg;

// the instruction
wire instr_z = instr[0];
wire instr_n = instr[1];
wire instr_r = instr[2];
wire instr_c = instr[3];
wire is_jmp = instr_c && instr_r;
wire [3:0] instr_op = instr[7:4];
wire [3:0] rega = instr[11:8];
wire [3:0] regb =
    was_do_op && is_ldi ? ldi_reg :
    was_do_op && is_ld ? ld_reg :
    urx_wb ? urx_reg : 
    instr[15:12];
wire [11:0] imm12 = instr[15:4];

// enabled when the current instruction is not valid because of previous 
// instruction being a 'jmp' or 'call'. in that case the next instruction
// in the pipeline should not be executed
reg is_bubble;

//
// Zen (part one)
//
wire zn_zf;
wire zn_nf;

// enabled if it is instruction and should execute
wire is_do_op = !is_ld && !is_ldi && !is_bubble && ((instr_z && instr_n) || (zn_zf == instr_z && zn_nf == instr_n));

//
// Calls
//
// true if it is a call
wire cs_call = is_do_op && instr_c && !instr_r;
// true if instruction is also a return from current call
wire cs_ret = is_do_op && !instr_c && instr_r;
// true if state of 'Calls' should change
wire cs_en = cs_call || cs_ret;
// program counter of the return address from current call
wire [RAM_ADDR_WIDTH-1:0] cs_pc_out;
// wire to Zn zero flag
wire cs_zf;
// wire to Zn negative flag
wire cs_nf;

//
// Registers (part one)
//
// value of register 'rega'
wire [REGS_WIDTH-1:0] rega_dat;

//
// ALU
//
wire is_alu_op = is_do_op && !is_jmp && !cs_call && (!instr_op[0] || instr_op == OP_ADDI);
wire [2:0] alu_op = 
    instr_op == OP_ADDI ? ALU_ADD : // 'addi' is add with signed immediate value 'rega'
    instr_op[3:1]; // same as upper 3 bits of op
wire [REGS_WIDTH-1:0] alu_operand_a =
    instr_op == OP_SHF || instr_op == OP_ADDI ? (rega[3] ? {{(REGS_WIDTH-4){rega[3]}},rega} : {{(REGS_WIDTH-4){1'b0}},rega} + 1) : 
    rega_dat; // otherwise regs[a]
// wire zero flag to Zn
wire alu_zf;
// wire negative flag to Zn
wire alu_nf;
// result of 'alu_operand_a' OP 'regb_dat'
wire [REGS_WIDTH-1:0] alu_result;

//
// Registers (part two)
//
wire regs_we = 
    is_alu_op ||
    was_do_op && (is_ldi || is_ld) || 
    urx_wb; // if uart wants to write recieved data

wire [REGS_WIDTH-1:0] regs_wd =
    was_do_op && is_ldi ? instr :
    was_do_op && is_ld ? ram_doa :
    // note. check 'is_alu_op' after 'is_ld' because both might be true when
    //       the pipeline is in stall during the second part of 'ld'
    is_alu_op ? alu_result :
    urx_reg_dat;

wire [REGS_WIDTH-1:0] regb_dat;

wire is_op_st = is_do_op && !is_jmp && !cs_call && instr_op == OP_ST;

//
// RAM
//
// note. don't write enable if running second cycle of 'ld'
assign ram_wea = is_op_st && !is_ld;
assign ram_addra = rega_dat;
// data that will be written if 'ram_wea'
assign ram_dia = regb_dat;

//
// Zn
//
// enabled if Zn will change state.
wire zn_we = is_do_op && (is_alu_op || cs_call || cs_ret);
// enabled to copy flags from 'Calls' or disabled to copy flags from 'ALU'
wire zn_sel = cs_ret;
// enabled if flags should be cleared
wire zn_clr = cs_call;

//
// Core
// 
reg [3:0] stp;
localparam STP_EXECUTE       = 1;
localparam STP_LDI           = 2;
localparam STP_LD_WB         = 3;
localparam STP_BRANCH        = 4;
localparam STP_UART_WRITE    = 5;
localparam STP_UART_READ     = 6;
localparam STP_UART_READ_WB  = 7;

always @(posedge clk) begin
    `ifdef DBG
        $display("%0t: clk+: Core: %0d:%0h process", $time, pc, instr);
        $strobe("%0t: strobe clk+: Core: stp=%0d, [%0d]=%0h process", $time, stp, pc, instr);
    `endif
    if (rst) begin
        pc <= 0;
        stp <= STP_EXECUTE;
        is_ldi <=0;
        ldi_reg <= 0;
        urx_reg <= 0;
        was_do_op <= 0;
        is_ld <= 0;
        ld_reg <= 0;
        is_bubble <= 0;
        led <= 0;
        utx_dat <= 0;
        utx_go <= 0;
        urx_go <= 0;
        urx_reg_dat <= 0;
        urx_reg_hilo <= 0;
        urx_wb <= 0;
    end else begin
    
        urx_wb <= 0; // disable writing 'urx_reg_dat'
        is_bubble <= 0; // disable flag if set in previous instruction
        
        if (cs_ret) begin
            //$display("***** cs_ret %0d", cs_pc_out);
            pc <= cs_pc_out;
            // next instruction in the pipeline should be ignored
            is_bubble <= 1;
            stp <= STP_BRANCH;
            
        end else begin
            // if reading or writing uart stay at same instruction until done.
            // note. instruction in context is the next instruction in the pipeline
            if (stp != STP_UART_WRITE && 
                stp != STP_UART_READ && 
                stp != STP_UART_READ_WB)
            begin
                pc <= pc + 1;
            end
        end
                
        case(stp)
        
        STP_EXECUTE: begin
            // remember for the next cycle if this was an executed instruction
            was_do_op <= is_do_op;
            if (is_do_op) begin

                if (is_jmp) begin
                    pc <= pc + {{(16-12){imm12[11]}},imm12} - 1; // -1 because pc is ahead by 1 instruction
                    is_bubble <= 1;
                    stp <= STP_BRANCH;

                end else if (cs_call) begin
                    pc <= imm12 << 4;
                    is_bubble <= 1;                
                    stp <= STP_BRANCH;

                end else begin
                    if (instr_op == OP_LDI && rega != 0) begin
                        case(rega[2:0]) // operation encoded in 'rega'

                        OP_IO_READ: begin // receive blocking
                            urx_reg <= regb; // save 'regb' to be used at write register
                            urx_reg_dat <= regb_dat; // save current value of 'regb'
                            urx_reg_hilo <= rega[3]; // save if read is to lower or higher 8 bits of 'urx_reg_dat'
                            urx_go <= 1; // enable start read
                            if (!cs_ret) begin
                                pc <= pc; // overwrite pc to stall
                            end
                            stp <= STP_UART_READ;
                        end 
                        
                        OP_IO_WRITE: begin // send blocking
                            utx_dat <= rega[3] ? regb_dat[15:8] : regb_dat[7:0]; // select the lower or higher bits to send
                            utx_go <= 1; // enable start of write
                            if (!cs_ret) begin
                                pc <= pc; // overwrite pc to stall
                            end
                            stp <= STP_UART_WRITE;
                        end                       
                        
                        OP_IO_LED: begin // led and ledi
                            led <= rega[3] ? regb : regb_dat[3:0];
                        end

                        endcase

                    end else begin // else of if (instr_op == OP_LDI && rega != 0)
                        
                        case(instr_op)
                        
                        OP_LDI: begin
                            is_ldi <= 1;
                            ldi_reg <= regb;
                            stp <= STP_LDI;
                        end

                        OP_LD: begin
                            is_ld <= 1;
                            ld_reg <= instr[15:12];
                            if (!cs_ret) begin
                                pc <= pc; // overwrite pc to stall
                            end
                            stp <= STP_LD_WB;
                        end
                        
                        endcase
                    end // if (instr_op == OP_LDI && rega != 0)
                end // if (is_jmp)
            end else begin // else of if (is_do_op)
                // if 'ldi' enable 'is_ldi' so that data part of the 
                // 'ldi' does not get interpreted as an instruction
                if (!cs_call && !is_jmp && instr_op == OP_LDI && rega == 0) begin
                    is_ldi <= 1;
                    stp <= STP_LDI;
                end
            end // if (is_do_op)
        end // case

        STP_LDI: begin // OP_LDI second part
            is_ldi <= 0;
            stp <= STP_EXECUTE;
        end

        STP_LD_WB: begin // OP_LD second part
            is_ld <= 0;
            stp <= STP_EXECUTE;
        end

        STP_BRANCH: begin // jump / call / ret second part, waiting for next instruction
            is_bubble <= 0;
            stp <= STP_EXECUTE;
        end
        
        STP_UART_WRITE: begin // OP_IO_WRITE: wait for Uart to finish
            if (!utx_bsy) begin
                utx_go <= 0; // acknowledge that the write is done
                pc <= pc + 1;
                stp <= STP_EXECUTE;
            end
        end
        
        STP_UART_READ: begin // OP_IO_READ: wait for Uart to finish
           if (urx_dr) begin // if data ready
                if (urx_reg_hilo) begin
                    urx_reg_dat[15:8] <= urx_dat; // write the high byte
                end else begin
                    urx_reg_dat[7:0] <= urx_dat; // write the low byte
                end
                urx_go <= 0; // acknowledge the ready data has been read
                urx_wb <= 1;
                stp <= STP_UART_READ_WB;
            end
        end
        
        STP_UART_READ_WB: begin // one cycle to write back the register
            pc <= pc + 1;
            stp <= STP_EXECUTE;
        end
        
        endcase
    end
end

Registers #(
    .ADDR_WIDTH(REGS_ADDR_WIDTH),
    .WIDTH(REGS_WIDTH)
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
    .WIDTH(REGS_WIDTH)
) alu (
//    .clk(clk),
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
    .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH)
) cs (
    .rst(rst),
    .clk(clk),
    .pc_in(pc), // current program counter
    .zf_in(zn_zf), // current zero flag
    .nf_in(zn_nf), // current negative flag
    .call(cs_call), // enabled when it is a 'call'
    .ret(cs_ret), // enabled when instruction is also 'return'
    .en(cs_en), // enables 'call' or 'ret'
    .pc_out(cs_pc_out), // top of stack program counter
    .zf_out(cs_zf), // top of stack zero flag
    .nf_out(cs_nf) // top of stack negative flag
);

endmodule

`undef DBG
`default_nettype wire