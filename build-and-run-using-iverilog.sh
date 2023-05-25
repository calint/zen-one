#!/bin/sh
# tools:
#   iverilog: Icarus Verilog version 11.0 (stable)
#        vvp: Icarus Verilog runtime version 11.0 (stable)
set -e
SIMPTH=zen-one.srcs/sim_1/new
SRCPTH=../../sources_1/new

cd $SIMPTH
pwd

iverilog -o zen-one \
    TB_Top.v \
    $SRCPTH/Top.v \
    $SRCPTH/RAM.v \
    $SRCPTH/Core.v
vvp zen-one