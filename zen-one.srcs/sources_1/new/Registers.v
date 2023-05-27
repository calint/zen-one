`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module Registers #(
    parameter ADDR_WIDTH = 4,
    parameter WIDTH = 16
)(
    input wire clk,
    input wire [ADDR_WIDTH-1:0] ra1, // register address 1
    input wire [ADDR_WIDTH-1:0] ra2, // register address 2
    input wire [WIDTH-1:0] wd2, // data to write to register 'ra2' when 'we2' is enabled
    input wire we2, // enables write 'wd2' to address 'ra2'
    output wire [WIDTH-1:0] rd1, // value of register 'ra1'
    output wire [WIDTH-1:0] rd2, // value of register 'ra2'
    input wire [ADDR_WIDTH-1:0] ra3, // register address 3
    input wire [WIDTH-1:0] wd3, // data to write to register 'ra3' when 'we3' is enabled
    input wire we3
);

reg signed [WIDTH-1:0] mem [0:2**ADDR_WIDTH-1];

assign rd1 = mem[ra1];
assign rd2 = mem[ra2];

integer i;
initial begin
    for (i = 0; i < 2**ADDR_WIDTH; i = i + 1) begin
        mem[i] = {WIDTH{1'b0}};
    end
end

always @(posedge clk) begin
    `ifdef DBG
        $display("%0t: clk+: Registers (ra1,ra2,rd1,rd2)=(%0h,%0h,%0h,%0h)", $time, ra1, ra2, rd1, rd2);
    `endif

    // write first the 'wd3' which is from a 'ld'
    // then the 'wd2' which might overwrite the 'wd3'
    //   example: ld r1 r7 ; add r7 r7
    if (we3) 
        mem[ra3] <= wd3;
    if (we2)
        mem[ra2] <= wd2;
end

endmodule

`undef DBG
`default_nettype wire