`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module Top #(
    parameter RAM_FILE = "ROM.mem",
    parameter CLK_FREQ = 66_000_000,
    parameter BAUD_RATE = 9600
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

localparam RAM_ADDR_WIDTH = 16; // 2**16 64K instructions

wire clk = clk_in;
wire [15:0] ram_addra;
wire [15:0] ram_addrb;
wire [15:0] ram_doa;
wire [15:0] ram_dob;
wire [15:0] ram_dia;
wire ram_wea;

assign led0_r = 1;
assign led0_g = !btn;
assign led0_b = 1;

always @(posedge clk) begin
    `ifdef DBG
        $display("%0t: clk+: Top: %0d:%0h", $time, ram_addrb, ram_dob);
    `endif
end

// wireing of Core and UartTx
wire [7:0] core_utx_dat;
wire core_utx_go;
wire utx_bsy;

// wireing of Core and UartRx
wire [7:0] core_urx_dat;
wire urx_dr;
wire core_urx_go;

Core #(
    .RAM_ADDR_WIDTH(RAM_ADDR_WIDTH)
) core (
    .rst(reset),
    .clk(clk),
    .pc(ram_addrb),
    .instr(ram_dob),
    .ram_addra(ram_addra),
    .ram_dia(ram_dia),
    .ram_wea(ram_wea),
    .ram_doa(ram_doa),
    .led(led),
    .utx_dat(core_utx_dat),
    .utx_go(core_utx_go),
    .utx_bsy(utx_bsy),
    .urx_dat(core_urx_dat),
    .urx_dr(urx_dr),
    .urx_go(core_urx_go)
);

RAM #(
    .DATA_FILE(RAM_FILE),
    .ADDR_WIDTH(RAM_ADDR_WIDTH),
    .WIDTH(16)
) ram ( // 64K x 16b
    .clk(clk),
    .addra(ram_addra),
    .addrb(ram_addrb),
    .doa(ram_doa),
    .dob(ram_dob),
    .dia(ram_dia),
    .wea(ram_wea)
);

UartTx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) utx (
    .rst(reset),
    .clk(clk),
    .data(core_utx_dat),
    .go(core_utx_go),
    .tx(uart_tx),
    .bsy(utx_bsy)
);

UartRx #(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
) urx (
    .rst(reset),
    .clk(clk),
    .rx(uart_rx),
    .data(core_urx_dat),
    .dr(urx_dr),
    .go(core_urx_go)
);

endmodule

`undef DBG
`default_nettype wire