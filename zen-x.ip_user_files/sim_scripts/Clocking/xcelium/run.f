-makelib xcelium_lib/xpm -sv \
  "/home/c/xilinix/Vivado/2022.2/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
  "/home/c/xilinix/Vivado/2022.2/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "/home/c/xilinix/Vivado/2022.2/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../zen-x.gen/sources_1/ip/Clocking/Clocking_clk_wiz.v" \
  "../../../../zen-x.gen/sources_1/ip/Clocking/Clocking.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

