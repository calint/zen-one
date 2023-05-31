`timescale 1ns / 1ps
`default_nettype none
`define DBG

module SoC #(
//    parameter RAM_FILE = "/home/c/w/zen-one/zen-one.srcs/sim_1/new/TB_Top.mem"
//    parameter RAM_FILE = "/home/c/w/zen-one/zen-one.srcs/sim_2/new/TB_Uart.mem"
//    parameter RAM_FILE = "/home/c/w/zen-one/zen-one.srcs/sim_2/new/TB_UartRx.mem"
//    parameter RAM_FILE = "/home/c/w/zen-one/zen-one.srcs/sim_4/new/TB_Top.mem"
//    parameter RAM_FILE = "/home/c/w/zen-one/notes/zasm-samples/print-hex.mem"
    parameter RAM_FILE = "/home/c/w/zen-one/zen-one.srcs/sources_1/new/init.mem"
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

localparam CLK_FREQ = 66_000_000;
localparam BAUD_RATE = 9600;

wire clk;
wire clk_locked;

Clocking clocking (
    .reset(reset),
    .clk_in1(clk_in),
    .clk_out1(clk),
    .locked(clk_locked)
);

Top #(
    .RAM_FILE(RAM_FILE),
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) top (
    .reset(!clk_locked || reset),
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
