`timescale 1ns / 1ps
`default_nettype none
`define DBG

module SoC #(
    parameter ROM_FILE = "/home/c/w/zen-one/zen-one.srcs/sim_1/new/TB_Top.mem"
)(
    input wire reset,
    input wire clk_in,
    output wire uart_tx,
    input wire uart_rx,
    input wire btn,
    output wire [3:0] led,
    output wire led0_r,
    output wire led0_g,
    output wire led0_b
);

wire clk;
wire clk_locked;

Clocking clocking (
    .reset(reset),
    .clk_in1(clk_in),
    .clk_out1(clk),
    .locked(clk_locked)
);

Top #(
    .ROM_FILE(ROM_FILE)
) top (
    .reset(!clk_locked),
    .clk_in(clk),
    .uart_tx(uart_tx),
    .uart_rx(uart_rx),
    .btn(btn),
    .led(led),
    .led0_r(led0_r),
    .led0_g(led0_g),
    .led0_b(led0_b)
);

endmodule
