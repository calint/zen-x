// Copyright 1986-2022 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2022.2 (lin64) Build 3671981 Fri Oct 14 04:59:54 MDT 2022
// Date        : Mon May  8 03:26:19 2023
// Host        : c running 64-bit Ubuntu 23.04
// Command     : write_verilog -force -mode synth_stub /home/c/w/zen-x/zen-x.gen/sources_1/ip/BlockROM/BlockROM_stub.v
// Design      : BlockROM
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7s25csga225-1
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_5,Vivado 2022.2" *)
module BlockROM(clka, ena, addra, douta)
/* synthesis syn_black_box black_box_pad_pin="clka,ena,addra[14:0],douta[15:0]" */;
  input clka;
  input ena;
  input [14:0]addra;
  output [15:0]douta;
endmodule
