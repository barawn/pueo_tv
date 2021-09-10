//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
//Date        : Mon Aug  9 11:00:58 2021
//Host        : DESKTOP-ELJAE7D running 64-bit major release  (build 9200)
//Command     : generate_target ps_base_wrapper.bd
//Design      : ps_base_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module ps_base_wrapper
   (adc0_clk_clk_n,
    adc0_clk_clk_p,
    adc1_clk_clk_n,
    adc1_clk_clk_p,
    adc2_clk_clk_n,
    adc2_clk_clk_p,
    adc3_clk_clk_n,
    adc3_clk_clk_p,
    adcA_in_v_n,
    adcA_in_v_p,
    adcB_in_v_n,
    adcB_in_v_p,
    adcC_in_v_n,
    adcC_in_v_p,
    adcD_in_v_n,
    adcD_in_v_p,
    adcE_in_v_n,
    adcE_in_v_p,
    adcF_in_v_n,
    adcF_in_v_p,
    adcG_in_v_n,
    adcG_in_v_p,
    adcH_in_v_n,
    adcH_in_v_p,
    m_axi_aclk,
    m_axi_araddr,
    m_axi_aresetn,
    m_axi_arprot,
    m_axi_arready,
    m_axi_arvalid,
    m_axi_awaddr,
    m_axi_awprot,
    m_axi_awready,
    m_axi_awvalid,
    m_axi_bready,
    m_axi_bresp,
    m_axi_bvalid,
    m_axi_rdata,
    m_axi_rready,
    m_axi_rresp,
    m_axi_rvalid,
    m_axi_wdata,
    m_axi_wready,
    m_axi_wstrb,
    m_axi_wvalid,
    ma_aclk,
    ma_axis_tdata,
    ma_axis_tready,
    ma_axis_tvalid,
    mb_axis_tdata,
    mb_axis_tready,
    mb_axis_tvalid,
    mc_axis_tdata,
    mc_axis_tready,
    mc_axis_tvalid,
    md_axis_tdata,
    md_axis_tready,
    md_axis_tvalid,
    me_axis_tdata,
    me_axis_tready,
    me_axis_tvalid,
    mem_clk,
    mf_axis_tdata,
    mf_axis_tready,
    mf_axis_tvalid,
    mg_axis_tdata,
    mg_axis_tready,
    mg_axis_tvalid,
    mh_axis_tdata,
    mh_axis_tready,
    mh_axis_tvalid,
    sync_clk,
    sysref_in_diff_n,
    sysref_in_diff_p);
  input adc0_clk_clk_n;
  input adc0_clk_clk_p;
  input adc1_clk_clk_n;
  input adc1_clk_clk_p;
  input adc2_clk_clk_n;
  input adc2_clk_clk_p;
  input adc3_clk_clk_n;
  input adc3_clk_clk_p;
  input adcA_in_v_n;
  input adcA_in_v_p;
  input adcB_in_v_n;
  input adcB_in_v_p;
  input adcC_in_v_n;
  input adcC_in_v_p;
  input adcD_in_v_n;
  input adcD_in_v_p;
  input adcE_in_v_n;
  input adcE_in_v_p;
  input adcF_in_v_n;
  input adcF_in_v_p;
  input adcG_in_v_n;
  input adcG_in_v_p;
  input adcH_in_v_n;
  input adcH_in_v_p;
  output m_axi_aclk;
  output [39:0]m_axi_araddr;
  output [0:0]m_axi_aresetn;
  output [2:0]m_axi_arprot;
  input [0:0]m_axi_arready;
  output [0:0]m_axi_arvalid;
  output [39:0]m_axi_awaddr;
  output [2:0]m_axi_awprot;
  input [0:0]m_axi_awready;
  output [0:0]m_axi_awvalid;
  output [0:0]m_axi_bready;
  input [1:0]m_axi_bresp;
  input [0:0]m_axi_bvalid;
  input [31:0]m_axi_rdata;
  output [0:0]m_axi_rready;
  input [1:0]m_axi_rresp;
  input [0:0]m_axi_rvalid;
  output [31:0]m_axi_wdata;
  input [0:0]m_axi_wready;
  output [3:0]m_axi_wstrb;
  output [0:0]m_axi_wvalid;
  output ma_aclk;
  output [127:0]ma_axis_tdata;
  input ma_axis_tready;
  output ma_axis_tvalid;
  output [127:0]mb_axis_tdata;
  input mb_axis_tready;
  output mb_axis_tvalid;
  output [127:0]mc_axis_tdata;
  input mc_axis_tready;
  output mc_axis_tvalid;
  output [127:0]md_axis_tdata;
  input md_axis_tready;
  output md_axis_tvalid;
  output [127:0]me_axis_tdata;
  input me_axis_tready;
  output me_axis_tvalid;
  output mem_clk;
  output [127:0]mf_axis_tdata;
  input mf_axis_tready;
  output mf_axis_tvalid;
  output [127:0]mg_axis_tdata;
  input mg_axis_tready;
  output mg_axis_tvalid;
  output [127:0]mh_axis_tdata;
  input mh_axis_tready;
  output mh_axis_tvalid;
  output sync_clk;
  input sysref_in_diff_n;
  input sysref_in_diff_p;

  wire adc0_clk_clk_n;
  wire adc0_clk_clk_p;
  wire adc1_clk_clk_n;
  wire adc1_clk_clk_p;
  wire adc2_clk_clk_n;
  wire adc2_clk_clk_p;
  wire adc3_clk_clk_n;
  wire adc3_clk_clk_p;
  wire adcA_in_v_n;
  wire adcA_in_v_p;
  wire adcB_in_v_n;
  wire adcB_in_v_p;
  wire adcC_in_v_n;
  wire adcC_in_v_p;
  wire adcD_in_v_n;
  wire adcD_in_v_p;
  wire adcE_in_v_n;
  wire adcE_in_v_p;
  wire adcF_in_v_n;
  wire adcF_in_v_p;
  wire adcG_in_v_n;
  wire adcG_in_v_p;
  wire adcH_in_v_n;
  wire adcH_in_v_p;
  wire m_axi_aclk;
  wire [39:0]m_axi_araddr;
  wire [0:0]m_axi_aresetn;
  wire [2:0]m_axi_arprot;
  wire [0:0]m_axi_arready;
  wire [0:0]m_axi_arvalid;
  wire [39:0]m_axi_awaddr;
  wire [2:0]m_axi_awprot;
  wire [0:0]m_axi_awready;
  wire [0:0]m_axi_awvalid;
  wire [0:0]m_axi_bready;
  wire [1:0]m_axi_bresp;
  wire [0:0]m_axi_bvalid;
  wire [31:0]m_axi_rdata;
  wire [0:0]m_axi_rready;
  wire [1:0]m_axi_rresp;
  wire [0:0]m_axi_rvalid;
  wire [31:0]m_axi_wdata;
  wire [0:0]m_axi_wready;
  wire [3:0]m_axi_wstrb;
  wire [0:0]m_axi_wvalid;
  wire ma_aclk;
  wire [127:0]ma_axis_tdata;
  wire ma_axis_tready;
  wire ma_axis_tvalid;
  wire [127:0]mb_axis_tdata;
  wire mb_axis_tready;
  wire mb_axis_tvalid;
  wire [127:0]mc_axis_tdata;
  wire mc_axis_tready;
  wire mc_axis_tvalid;
  wire [127:0]md_axis_tdata;
  wire md_axis_tready;
  wire md_axis_tvalid;
  wire [127:0]me_axis_tdata;
  wire me_axis_tready;
  wire me_axis_tvalid;
  wire mem_clk;
  wire [127:0]mf_axis_tdata;
  wire mf_axis_tready;
  wire mf_axis_tvalid;
  wire [127:0]mg_axis_tdata;
  wire mg_axis_tready;
  wire mg_axis_tvalid;
  wire [127:0]mh_axis_tdata;
  wire mh_axis_tready;
  wire mh_axis_tvalid;
  wire sync_clk;
  wire sysref_in_diff_n;
  wire sysref_in_diff_p;

  ps_base ps_base_i
       (.adc0_clk_clk_n(adc0_clk_clk_n),
        .adc0_clk_clk_p(adc0_clk_clk_p),
        .adc1_clk_clk_n(adc1_clk_clk_n),
        .adc1_clk_clk_p(adc1_clk_clk_p),
        .adc2_clk_clk_n(adc2_clk_clk_n),
        .adc2_clk_clk_p(adc2_clk_clk_p),
        .adc3_clk_clk_n(adc3_clk_clk_n),
        .adc3_clk_clk_p(adc3_clk_clk_p),
        .adcA_in_v_n(adcA_in_v_n),
        .adcA_in_v_p(adcA_in_v_p),
        .adcB_in_v_n(adcB_in_v_n),
        .adcB_in_v_p(adcB_in_v_p),
        .adcC_in_v_n(adcC_in_v_n),
        .adcC_in_v_p(adcC_in_v_p),
        .adcD_in_v_n(adcD_in_v_n),
        .adcD_in_v_p(adcD_in_v_p),
        .adcE_in_v_n(adcE_in_v_n),
        .adcE_in_v_p(adcE_in_v_p),
        .adcF_in_v_n(adcF_in_v_n),
        .adcF_in_v_p(adcF_in_v_p),
        .adcG_in_v_n(adcG_in_v_n),
        .adcG_in_v_p(adcG_in_v_p),
        .adcH_in_v_n(adcH_in_v_n),
        .adcH_in_v_p(adcH_in_v_p),
        .m_axi_aclk(m_axi_aclk),
        .m_axi_araddr(m_axi_araddr),
        .m_axi_aresetn(m_axi_aresetn),
        .m_axi_arprot(m_axi_arprot),
        .m_axi_arready(m_axi_arready),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awprot(m_axi_awprot),
        .m_axi_awready(m_axi_awready),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_bready(m_axi_bready),
        .m_axi_bresp(m_axi_bresp),
        .m_axi_bvalid(m_axi_bvalid),
        .m_axi_rdata(m_axi_rdata),
        .m_axi_rready(m_axi_rready),
        .m_axi_rresp(m_axi_rresp),
        .m_axi_rvalid(m_axi_rvalid),
        .m_axi_wdata(m_axi_wdata),
        .m_axi_wready(m_axi_wready),
        .m_axi_wstrb(m_axi_wstrb),
        .m_axi_wvalid(m_axi_wvalid),
        .ma_aclk(ma_aclk),
        .ma_axis_tdata(ma_axis_tdata),
        .ma_axis_tready(ma_axis_tready),
        .ma_axis_tvalid(ma_axis_tvalid),
        .mb_axis_tdata(mb_axis_tdata),
        .mb_axis_tready(mb_axis_tready),
        .mb_axis_tvalid(mb_axis_tvalid),
        .mc_axis_tdata(mc_axis_tdata),
        .mc_axis_tready(mc_axis_tready),
        .mc_axis_tvalid(mc_axis_tvalid),
        .md_axis_tdata(md_axis_tdata),
        .md_axis_tready(md_axis_tready),
        .md_axis_tvalid(md_axis_tvalid),
        .me_axis_tdata(me_axis_tdata),
        .me_axis_tready(me_axis_tready),
        .me_axis_tvalid(me_axis_tvalid),
        .mem_clk(mem_clk),
        .mf_axis_tdata(mf_axis_tdata),
        .mf_axis_tready(mf_axis_tready),
        .mf_axis_tvalid(mf_axis_tvalid),
        .mg_axis_tdata(mg_axis_tdata),
        .mg_axis_tready(mg_axis_tready),
        .mg_axis_tvalid(mg_axis_tvalid),
        .mh_axis_tdata(mh_axis_tdata),
        .mh_axis_tready(mh_axis_tready),
        .mh_axis_tvalid(mh_axis_tvalid),
        .sync_clk(sync_clk),
        .sysref_in_diff_n(sysref_in_diff_n),
        .sysref_in_diff_p(sysref_in_diff_p));
endmodule
