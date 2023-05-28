#!/bin/sh
set -e
./run-iverilog.sh sim_1 TB_Top
./run-iverilog.sh sim_2 TB_Uart
./run-iverilog.sh sim_3 TB_UartRx
./run-iverilog.sh sim_4 TB_Top
