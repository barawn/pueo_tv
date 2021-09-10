`timescale 1ns / 1ps
`include "interfaces.vh"
// Firmware for PUEO TV.
module pueo_tv( input adc0_clk_p,
                input adc0_clk_n,
                input adc1_clk_p,
                input adc1_clk_n,
                input adc2_clk_p,
                input adc2_clk_n,
                input adc3_clk_p,
                input adc3_clk_n,
                
                input adcA_p,
                input adcA_n,
                input adcB_p,
                input adcB_n,
                input adcC_p,
                input adcC_n,
                input adcD_p,
                input adcD_n,
                input adcE_p,
                input adcE_n,
                input adcF_p,
                input adcF_n,
                input adcG_p,
                input adcG_n,
                input adcH_p,
                input adcH_n,

                input sysref_p,
                input sysref_n            
    );
        
    wire memclk;
    wire syncclk;
    wire aclk;
    wire [127:0] ma_axis_tdata;
    wire         ma_axis_tvalid;
    wire [127:0] mb_axis_tdata;
    wire         mb_axis_tvalid;
    wire [127:0] mc_axis_tdata;
    wire         mc_axis_tvalid;
    wire [127:0] md_axis_tdata;
    wire         md_axis_tvalid;
    wire [127:0] me_axis_tdata;
    wire         me_axis_tvalid;
    wire [127:0] mf_axis_tdata;
    wire         mf_axis_tvalid;
    wire [127:0] mg_axis_tdata;
    wire         mg_axis_tvalid;
    wire [127:0] mh_axis_tdata;
    wire         mh_axis_tvalid;

    wire [127:0] adc_tdata[7:0];
    assign adc_tdata[0] = ma_axis_tdata;
    assign adc_tdata[1] = mb_axis_tdata;
    assign adc_tdata[2] = mc_axis_tdata;
    assign adc_tdata[3] = md_axis_tdata;
    assign adc_tdata[4] = me_axis_tdata;
    assign adc_tdata[5] = mf_axis_tdata;
    assign adc_tdata[6] = mg_axis_tdata;
    assign adc_tdata[7] = mh_axis_tdata;

    wire [127:0] adc_out[7:0];    
    
    localparam TBITS = 5;
    localparam NCHAN = 8;
    localparam NSAMP = 8;
    wire [TBITS*NSAMP-1:0] rescale_out[NCHAN-1:0]; 
    
    
    `DEFINE_AXI4L_IF( pueo_ , 40, 32 );    
    wire m_axi_aclk;
    wire m_axi_aresetn;    

    wire memclk;
    wire syncclk;
            
    ps_base_wrapper u_ps( .adc0_clk_clk_p(adc0_clk_p),
                          .adc0_clk_clk_n(adc0_clk_n),
                          .adc1_clk_clk_p(adc1_clk_p),
                          .adc1_clk_clk_n(adc1_clk_n),
                          .adc2_clk_clk_p(adc2_clk_p),
                          .adc2_clk_clk_n(adc2_clk_n),
                          .adc3_clk_clk_p(adc3_clk_p),
                          .adc3_clk_clk_n(adc3_clk_n),
                          
                          .adcA_in_v_p(adcA_p),
                          .adcA_in_v_n(adcA_n),
                          .adcB_in_v_p(adcB_p),
                          .adcB_in_v_n(adcB_n),
                          
                          .adcC_in_v_p(adcC_p),
                          .adcC_in_v_n(adcC_n),
                          .adcD_in_v_p(adcD_p),
                          .adcD_in_v_n(adcD_n),

                          .adcE_in_v_p(adcE_p),
                          .adcE_in_v_n(adcE_n),
                          .adcF_in_v_p(adcF_p),
                          .adcF_in_v_n(adcF_n),

                          .adcG_in_v_p(adcG_p),
                          .adcG_in_v_n(adcG_n),
                          .adcH_in_v_p(adcH_p),
                          .adcH_in_v_n(adcH_n),
                          
                          .ma_aclk(aclk),
                          .ma_axis_tdata(ma_axis_tdata),
                          .mb_axis_tdata(mb_axis_tdata),
                          .mc_axis_tdata(mc_axis_tdata),
                          .md_axis_tdata(md_axis_tdata),
                          .me_axis_tdata(me_axis_tdata),
                          .mf_axis_tdata(mf_axis_tdata),
                          .mg_axis_tdata(mg_axis_tdata),
                          .mh_axis_tdata(mh_axis_tdata),

                          .m_axi_aclk(m_axi_aclk),
                          .m_axi_aresetn(m_axi_aresetn),
                          `CONNECT_AXI4L_IF( m_axi_ , pueo_ ),                                                    

                          .mem_clk(memclk),
                          .sync_clk(syncclk),

                          .sysref_in_diff_p(sysref_p),
                          .sysref_in_diff_n(sysref_n));
                          
                              

    (* KEEP = "TRUE" *)
    wire [17:0] coeff_data;
    wire [7:0] coeff_address;
    wire       coeff_wr;
    wire       coeff_update;

    axi_pueo u_pueo( .s_axi_aclk(m_axi_aclk),
                     .s_axi_aresetn(m_axi_aresetn),
                     `CONNECT_AXI4L_IF( s_axi_ , pueo_ ),
                     
                     .aclk(aclk),
                     .coeff_dat_o(coeff_data),
                     .coeff_adr_o(coeff_address),
                     .coeff_wr_o(coeff_wr),
                     .coeff_update_o(coeff_update));

//    coeff_vio u_coeff_vio(.clk(aclk),
//                          .probe_out0(coeff_wr),
//                          .probe_out1(coeff_update),
//                          .probe_out2(coeff_address),
//                          .probe_out3(coeff_data));
    reg coeff_pole_fir_wr = 0;    
    reg coeff_pole_iir_wr = 0;
    reg coeff_incr_wr = 0;
    reg coeff_rescale_wr = 0;
    reg [7:0] rescale_wr = {8{1'b0}};
    always @(posedge aclk) begin
        coeff_pole_fir_wr <= coeff_wr && (coeff_address[7:5] == 0);                          
        coeff_pole_iir_wr <= coeff_wr && (coeff_address[7:5] == 1) && !coeff_address[4];
        coeff_incr_wr <= coeff_wr && (coeff_address[7:5] == 1) && (coeff_address[4:1] == 4'b1000);        
        coeff_rescale_wr <= coeff_wr && (coeff_address[7:5] == 2);
    end
    
    wire aclk_rstn;
    wire rst_done;
    SRLC32E u_aclk_rst_delay(.CE(1'b1),.CLK(aclk),.D(1'b1),.Q31(rst_done));
    FD u_aclk_rstn(.D(rst_done),.C(aclk),.Q(aclk_rstn));
    
    wire [15:0] addr_vio;
    wire        addr_go;
    
    wire aclk_sync;
    wire memclk_sync;
    pueo_clk_phase u_phase(.aclk(aclk),
                           .memclk(memclk),
                           .syncclk(syncclk),
                           .aclk_sync_o(aclk_sync),
                           .memclk_sync_o(memclk_sync));
    
    generate
        genvar i,j;
        for (i=0;i<8;i=i+1) begin : CL    
            always @(posedge aclk) begin
                rescale_wr[i] <= coeff_rescale_wr && (coeff_address[2:0] == i);
            end    
            wire [47:0] y0_fir;
            wire [47:0] y1_fir;
        
        
            // Drop the unused bits, and buffer.
            reg [95:0] dat_rereg = {96{1'b0}};
            for (j=0;j<8;j=j+1) begin : SRR
                always @(posedge aclk) begin : RRL
                    dat_rereg[12*j +: 12] <= adc_tdata[i][16*j+4 +: 12];
                end
            end
            
            wire [71:0] read_out;
            wire        read_valid;
            wire        read_ready;
                        
            pueo_uram u_uram( .aclk(aclk),
                              .aclk_sync_i(aclk_sync),
                              .memclk(memclk),
                              .memclk_sync_i(memclk_sync),
                              .aclk_rst_i(!aclk_rstn),
                              .dat_i(dat_rereg),
                              .s_axis_tdata(addr_vio),
                              .s_axis_tvalid(addr_go),
                              .m_axis_tdata(read_out),
                              .m_axis_tvalid(read_valid),
                              .m_axis_tready(read_ready));
                              
            wire [71:0] rdslow;
            wire        rdvalid;
            
            uram_cc_fifo u_fifo( .din(read_out),
                          .wr_en(read_valid),
                          .prog_full(!read_ready),
                          .rd_en(rdvalid),
                          .valid(rdvalid),
                          .dout(rdslow),
                          .wr_clk(memclk),
                          .rd_clk(aclk));
            
            biquad8_pole_fir u_bq8_fir(.clk(aclk),
                                        .dat_i(adc_tdata[i]),
                                        .coeff_adr_i(coeff_address[4:0]),
                                        .coeff_wr_i(coeff_pole_fir_wr),
                                        .coeff_update_i(coeff_update),
                                        .coeff_dat_i(coeff_data),
                                        .y0_out(y0_fir),
                                        .y1_out(y1_fir));
            wire [23:0] y0_out;
            wire [23:0] y1_out;
            biquad8_pole_iir u_bq8_iir(.clk(aclk),
                                        .y0_fir_in(y0_fir),
                                        .y1_fir_in(y1_fir),
                                        .coeff_adr_i(coeff_address[1:0]),
                                        .coeff_wr_i(coeff_pole_iir_wr),
                                        .coeff_update_i(coeff_update),
                                        .coeff_dat_i(coeff_data),
                                        .y0_out(y0_out),
                                        .y1_out(y1_out));
            
            // incremental computation only needs 2 coefficients
            biquad8_incremental u_bq8_incr( .clk(aclk),
                                            .dat_i(adc_tdata[i]),
                                            .y0_in(y0_out),
                                            .y1_in(y1_out),
                                            .coeff_adr_i(coeff_address[0]),
                                            .coeff_wr_i(coeff_incr_wr),
                                            .coeff_update_i(coeff_update),
                                            .coeff_dat_i(coeff_data),
                                            .dat_o(adc_out[i]));

            pueo_rescale8 u_rescale( .clk( aclk ),
                                     .dat_i(adc_out[i]),
                                     .coeff_wr_i(rescale_wr[i]),
                                     .coeff_update_i(coeff_update),
                                     .dat_o(rescale_out[i]));
            
            trig_ila u_ila(.clk(aclk),
                            .probe0( rescale_out[i][ TBITS*0 +: TBITS] ),
                            .probe1( rescale_out[i][ TBITS*1 +: TBITS] ),
                            .probe2( rescale_out[i][ TBITS*2 +: TBITS] ),
                            .probe3( rescale_out[i][ TBITS*3 +: TBITS] ),
                            .probe4( rescale_out[i][ TBITS*4 +: TBITS] ),
                            .probe5( rescale_out[i][ TBITS*5 +: TBITS] ),
                            .probe6( rescale_out[i][ TBITS*6 +: TBITS] ),
                            .probe7( rescale_out[i][ TBITS*7 +: TBITS] ));
                            
                                                  
//            iir_ila u_ila(.clk(aclk),
//                          .probe0( y0_out ),
//                          .probe1( y1_out ),
//                          .probe2( rdvalid),
//                          .probe3( rdslow ) );
        end
    endgenerate

    generate
        genvar b;
        for (b=0;b<10;b=b+1) begin : TESTBEAMS
            wire [95:0] beam_out;
            beamform_trigger #(.ADELAY(0),.BDELAY(0),
                               .CDELAY(b/4),.DDELAY(b/4),
                               .EDELAY(b/2),.FDELAY(b/2),
                               .GDELAY(b),.HDELAY(b)) 
                u_beamtest( .clk(aclk),
                            .A( rescale_out[0] ),
                            .B( rescale_out[1] ),
                            .C( rescale_out[2] ),
                            .D( rescale_out[3] ),
                            .E( rescale_out[4] ),
                            .F( rescale_out[5] ),
                            .G( rescale_out[6] ),
                            .H( rescale_out[7] ),
                            .beam_out(beam_out));
            beam_ila u_ila( .clk(aclk),
                            .probe0( beam_out[12*0 +: 12] ),
                            .probe1( beam_out[12*1 +: 12] ),
                            .probe2( beam_out[12*2 +: 12] ),
                            .probe3( beam_out[12*3 +: 12] ),
                            .probe4( beam_out[12*4 +: 12] ),
                            .probe5( beam_out[12*5 +: 12] ),
                            .probe6( beam_out[12*6 +: 12] ),
                            .probe7( beam_out[12*7 +: 12] ));                    
        end
    endgenerate
endmodule
