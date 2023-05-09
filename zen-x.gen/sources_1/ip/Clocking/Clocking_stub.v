// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
// Date        : Mon May  8 12:13:11 2023
// Host        : c running 64-bit Ubuntu 23.04
// Command     : write_verilog -force -mode synth_stub -rename_top Clocking -prefix
//               Clocking_ Clocking_stub.v
// Design      : Clocking
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7s25csga225-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module Clocking(clk_out, reset, locked, clk_in)
/* synthesis syn_black_box black_box_pad_pin="clk_out,reset,locked,clk_in" */;
  output clk_out;
  input reset;
  output locked;
  input clk_in;
endmodule
