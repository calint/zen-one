`timescale 1ns / 1ps
`default_nettype none
//`define DBG

// from https://docs.xilinx.com/r/en-US/ug901-vivado-synthesis/Simple-Dual-Port-Block-RAM-Examples
module RAM #(
    parameter DATA_FILE = "ROM.mem",
    parameter ADDR_WIDTH = 16,
    parameter WIDTH = 16
)(
    input wire clk,
    input wire wea,
    input wire [WIDTH-1:0] addra,
    input wire [WIDTH-1:0] addrb,
    output reg [WIDTH-1:0] doa,
    output reg [WIDTH-1:0] dob,
    input wire [WIDTH-1:0] dia
);

reg [WIDTH-1:0] ram [0:2**ADDR_WIDTH-1];

initial begin
    $readmemh(DATA_FILE, ram);
end

always @(posedge clk) begin
    if (wea)
        ram[addra] <= dia;
end

always @(posedge clk) begin
    doa <= ram[addra];
    dob <= ram[addrb];
end

always @(posedge clk) begin
    `ifdef DBG
        $display("%0t: clk+: RAM: doa,dob=%0h,%0h process", $time, doa, dob);
        $strobe("%0t: strobe clk+: RAM: doa,dob=%0h,%0h process", $time, doa, dob);
    `endif
end

endmodule 

`undef DBG
`default_nettype wire