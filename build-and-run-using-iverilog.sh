#!/bin/sh
# tools:
#   iverilog: Icarus Verilog version 11.0 (stable)
#        vvp: Icarus Verilog runtime version 11.0 (stable)
set -e
SIMPTH=zen-x.srcs/sim_1/new
SRCPTH=../../sources_1/new

cd $SIMPTH
pwd

iverilog -o zen-x \
    TB_Zenx.v \
    $SRCPTH/ALU.v \
    $SRCPTH/Calls.v \
    $SRCPTH/RAM.v \
    $SRCPTH/Registers.v \
    $SRCPTH/ROM.v \
    $SRCPTH/UartRx.v \
    $SRCPTH/UartTx.v \
    $SRCPTH/Zenx.v \
    $SRCPTH/Zn.v
vvp zen-x