// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
// Date        : Mon Aug  9 11:01:42 2021
// Host        : DESKTOP-ELJAE7D running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               V:/pueo_tv/bd/ps_base/ip/ps_base_adc0_clk_wiz_0/ps_base_adc0_clk_wiz_0_stub.v
// Design      : ps_base_adc0_clk_wiz_0
// Purpose     : Stub declaration of top-level module interface
// Device      : xczu25dr-ffve1156-1-e
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module ps_base_adc0_clk_wiz_0(clk_out1, clk_out2, clk_out3, reset, locked, 
  clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_out1,clk_out2,clk_out3,reset,locked,clk_in1" */;
  output clk_out1;
  output clk_out2;
  output clk_out3;
  input reset;
  output locked;
  input clk_in1;
endmodule
