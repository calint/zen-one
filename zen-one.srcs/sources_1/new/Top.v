`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module Top #(
    parameter ROM_FILE = "ROM.mem"
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

assign led = ram_doa[3:0];

always @(posedge clk) begin
    `ifdef DBG
        $display("%0t: clk+: Top: %0d:%0h", $time, ram_addrb, ram_dob);
    `endif
end

Core core (
    .rst(reset),
    .clk(clk),
    .pc(ram_addrb),
    .instr(ram_dob),
    .ram_addra(ram_addra),
    .ram_dia(ram_dia),
    .ram_wea(ram_wea),
    .ram_doa(ram_doa)
);

RAM #(
    .DATA_FILE(ROM_FILE),
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

endmodule

`undef DBG
`default_nettype wire