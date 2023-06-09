`timescale 1ns / 1ps
`default_nettype none
//`define DBG

module Calls #(
    parameter ADDR_WIDTH = 4,
    parameter RAM_ADDR_WIDTH = 16
)(
    input wire rst,
    input wire clk,
    input wire [RAM_ADDR_WIDTH-1:0] pc_in, // current program counter
    input wire zf_in, // current zero flag
    input wire nf_in, // current negative flag
    input wire call, // pushes current 'pc_in', 'zf_in' and 'nf_in' on the stack
    input wire ret, // pops stack and on negedge the top of stack is available on *_out 
    input wire en, // enables 'call' or 'ret'
    output reg [RAM_ADDR_WIDTH-1:0] pc_out, // top of stack program counter
    output reg zf_out, // top of stack zero flag
    output reg nf_out // top of stack negative flag
);

reg [ADDR_WIDTH-1:0] idx;
reg [RAM_ADDR_WIDTH+1:0] mem [0:2**ADDR_WIDTH-1]; // {zf, nf, addr}

integer i;
initial begin
    for (i = 0; i < 2**ADDR_WIDTH; i = i + 1) begin
        mem[i] = {(RAM_ADDR_WIDTH+2){1'b0}}; // {zf, nf, addr}
    end
end

always @(posedge clk) begin
    `ifdef DBG
        $display("%0t: clk+: Calls: pc=%0d, en=%0d, call=%0d, ret=%0d", $time, pc_in, en, call, ret);
    `endif

    if (rst) begin
        idx <= {ADDR_WIDTH{1'b1}};
        pc_out <= 0;
        zf_out <= 0;
        nf_out <= 0;
    end else begin
        if (en) begin
            if (call) begin
                idx = idx + 1;
                //$display("*** call from: %0d, idx=%0d", pc_in, idx);
                mem[idx] <= {zf_in, nf_in, pc_in};
                zf_out <= zf_in;
                nf_out <= nf_in;
                pc_out <= pc_in;
            end else if (ret) begin
                //$display("*** ret to: %0d, idx=%0d", mem[idx][RAM_ADDR_WIDTH-1:0], idx);
                idx = idx - 1;
                {zf_out, nf_out, pc_out} <= mem[idx];
            end
        end
    end
end

endmodule

`undef DBG
`default_nettype wire