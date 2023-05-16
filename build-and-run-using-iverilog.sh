#!/bin/sh
# tools:
#   iverilog: Icarus Verilog version 11.0 (stable)
#        vvp: Icarus Verilog runtime version 11.0 (stable)
set -e

iverilog -o zen-x \
    zen-x.srcs/sim_1/new/TB_Zenx.v \
    zen-x.srcs/sources_1/new/ALU.v \
    zen-x.srcs/sources_1/new/Calls.v \
    zen-x.srcs/sources_1/new/RAM.v \
    zen-x.srcs/sources_1/new/Registers.v \
    zen-x.srcs/sources_1/new/ROM.v \
    zen-x.srcs/sources_1/new/UartRx.v \
    zen-x.srcs/sources_1/new/UartTx.v \
    zen-x.srcs/sources_1/new/Zenx.v \
    zen-x.srcs/sources_1/new/Zn.v
vvp zen-x