#!/bin/sh
# tools:
#   iverilog: Icarus Verilog version 11.0 (stable)
#        vvp: Icarus Verilog runtime version 11.0 (stable)
set -e

SIMPTH=zen-one.srcs/$1/new
SRCPTH=../../sources_1/new

cd $SIMPTH
pwd

iverilog -o iverilog.out \
    $2.v \
    $SRCPTH/Top.v \
    $SRCPTH/RAM.v \
    $SRCPTH/Core.v \
    $SRCPTH/Registers.v \
    $SRCPTH/ALU.v \
    $SRCPTH/Zn.v \
    $SRCPTH/Calls.v \
    $SRCPTH/UartTx.v \
    $SRCPTH/UartRx.v
vvp iverilog.out
rm iverilog.out