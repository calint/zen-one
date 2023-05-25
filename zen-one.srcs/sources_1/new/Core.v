`timescale 1ns / 1ps
`default_nettype none
`define DBG

module Core(
    input wire rst,
    input wire clk,
    output reg [15:0] pc,
    input wire [15:0] instr,
    output reg [15:0] ram_addra,
    output reg [15:0] ram_dia,
    output reg ram_wea
);

reg [1:0] stp;

always @(posedge clk) begin
    if (rst) begin
        pc <= 0;
        stp <= 0;
    end else begin
//        `ifdef DBG
//            $display("%0t: clk+: CPU: %0d:%0h", $time, pc, instr);
//        `endif
        case(stp)
        2'h0: begin 
            $display("%0t: clk+: Core: %0d:%0h boot", $time, pc, instr);
            stp <= 1;
        end
        2'h1: begin
            $display("%0t: clk+: Core: %0d:%0h process", $time, pc, instr);
            ram_addra <= pc + 16'h0100;
            ram_dia <= instr;
            ram_wea <= 1;
        end
        endcase
        pc <= pc + 1;
    end
end

endmodule

`undef DBG
`default_nettype wire