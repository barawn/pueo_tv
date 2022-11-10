`include "dsp_macros.vh"
module biquad8_incremental #(parameter NBITS=16,
                             parameter NFRAC=2,
                             parameter NBITS2=24,
                             parameter NFRAC2=10,
                             parameter NSAMP=8)(
             input clk,
             input [NBITS*NSAMP-1:0] dat_i,
             input [NBITS2-1:0] y0_in,
             input [NBITS2-1:0] y1_in,
                          
             input coeff_adr_i,
             input coeff_wr_i,
             input coeff_update_i,
             input [17:0] coeff_dat_i,
             
             output [NBITS*NSAMP-1:0] dat_o );

    wire [NBITS-1:0] samp_in[NSAMP-1:0];
    wire [NBITS-1:0] samp_out[NSAMP-1:0];
    
    // effing FIGURE THIS OUT
    // Note that this is *** very *** likely totally wrong
    // and we'll actually need a chained set of SRLs to get
    // the delay. dear god need to simulate.
    localparam BASE_DELAY = 13;
    // effing FIGURE THIS OUT TOO
    localparam REALIGN_DELAY = 10;
    
    // the two inputs are Q14.10
    parameter NUM_DSPS = NSAMP-2;    
    // these have pointless ones to simplify the HDL
    
    // OK. So, "low" DSPs take sample number - 2.
    // "high" DSPs take sample number - 1.
    
    wire [NBITS2-1:0] dsp_low_in[NUM_DSPS+1:0];
    wire [NBITS2-1:0] dsp_high_in[NUM_DSPS:0];
    wire [47:0] dsp_out[NUM_DSPS-1:0];
    
    reg [NBITS2-1:0] y1_store = {NBITS2{1'b0}};
    
    assign dsp_low_in[0] = y0_in;
    assign dsp_high_in[0] = y1_in;
    assign dsp_low_in[1] = y1_store;
    
    wire [NBITS-1:0] y0_delay_out;
    wire [NBITS-1:0] y1_delay_out;
    reg [NBITS-1:0] y0_delay_reg = {NBITS{1'b0}};
    reg [NBITS-1:0] y1_delay_reg = {NBITS{1'b0}};
    srlvec #(.NBITS(NBITS)) u_delay_y0( .clk(clk),
                                        .ce(1'b1),
                                        .a(REALIGN_DELAY+3),
                                        .din(y0_in[ NFRAC2-NFRAC +: NBITS]),
                                        .dout(y0_delay_out));
    srlvec #(.NBITS(NBITS)) u_delay_y1( .clk(clk),
                                        .ce(1'b1),
                                        .a(REALIGN_DELAY+2),
                                        .din(y1_store[ NFRAC2-NFRAC +: NBITS ]),
                                        .dout(y1_delay_out));                           

    always @(posedge clk) begin
        y1_store <= y1_in;
        y1_delay_reg <= y1_delay_out;
        y0_delay_reg <= y0_delay_out;
    end
    assign samp_out[0] = y0_delay_reg;
    assign samp_out[1] = y1_delay_reg;
    
    `define COMMON_ATTRS `CONSTANT_MODE_ATTRS,`DE2_UNUSED_ATTRS,.ACASCREG(0),.ADREG(0),.MREG(0),.BREG(2),.BCASCREG(1),.PREG(1)
    
    generate
        genvar i,j;
        for (j=0;j<NSAMP;j=j+1) begin : VECTORIZE
            assign samp_in[j] = dat_i[NBITS*j +: NBITS];
            assign dat_o[NBITS*j +: NBITS] = samp_out[j];
        end
        for (i=0;i<NUM_DSPS;i=i+1) begin : DSP
            localparam C_FRAC_BITS = 27;
            localparam C_BITS = 48;
            localparam C_HEAD_PAD = (C_BITS-C_FRAC_BITS) - (NBITS-NFRAC);
            localparam C_TAIL_PAD = C_FRAC_BITS - NFRAC;
            // Q17.13. Passed around as Q14.10.
            localparam A_FRAC_BITS = 13;
            localparam A_BITS = 30;
            // The input is NBITS2 with NFRAC2 fractional bits.
            localparam A_HEAD_PAD = (A_BITS-A_FRAC_BITS) - (NBITS2-NFRAC2);
            localparam A_TAIL_PAD = A_FRAC_BITS - NFRAC2;
            reg ceblow1 = 0;
            reg cebhigh1 = 0;
            reg ceblow2 = 0;
            reg cebhigh2 = 0;
            reg [NBITS-1:0] dat_in_reg = {NBITS{1'b0}};
            reg [NBITS-1:0] dat_out_reg = {NBITS{1'b0}};
            wire [NBITS-1:0] delay_out;
            wire [NBITS-1:0] align_out;
            srlvec #(.NBITS(NBITS)) u_delay1( .clk(clk),
                                             .ce(1'b1),
                                             .a( BASE_DELAY + 2*i ),
                                             .din( samp_in[i+2] ),
                                             .dout(delay_out));        
            srlvec #(.NBITS(NBITS)) u_delay2( .clk(clk),
                                              .ce(1'b1),
                                              .a( REALIGN_DELAY - 2*i ),
                                              .din( dsp_out[i][C_FRAC_BITS-NFRAC +: NBITS] ),
                                              .dout( align_out )); 
            always @(posedge clk) begin
                dat_in_reg <= delay_out;
                dat_out_reg <= align_out;
                // It's a cascade, so the low DSP *always* clocks in,
                // and the high DSP only clocks in if address is high.
                // Program them in reverse order (from high address to low).
                ceblow1 <=  coeff_wr_i;
                cebhigh1 <= coeff_adr_i && coeff_wr_i;
                ceblow2 <= coeff_update_i;
                cebhigh2 <= coeff_update_i;
            end
            // OK so our goal here is to add the input as C,
            // and our previous input as A in the low DSP
            // and as A in the high DSP.
            // Late in the chain, the A inputs (= P outputs of 2 below and 1 below)
            // are separated by 2 clocks. So the *first* input
            // has AREG=2, and the second input has AREG=1.
            // However for the *first* one they're aligned, so there we do AREG=1 and AREG=2.
            // For the *second* one, the high DSP is 3 clocks later, but we eat one
            // in a fanout register (maybe not needed, but whatever). So 
            localparam AREG_LOW =   (i==  0) ? 1 : 2;
            localparam AREG_HIGH =  (i == 0) ? 2 : 1;
            wire [47:0] dspC_in = { {C_HEAD_PAD{dat_in_reg[NBITS-1]}}, dat_in_reg, {C_TAIL_PAD{1'b0}} };
            wire [29:0] dsplowA_in = { {A_HEAD_PAD{dsp_low_in[i][NBITS2-1]}},   dsp_low_in[i],  {A_TAIL_PAD{1'b0}} };
            wire [29:0] dsphighA_in = {{A_HEAD_PAD{dsp_high_in[i][NBITS2-1]}},  dsp_high_in[i], {A_TAIL_PAD{1'b0}} };
            
            wire [17:0] bcascade;
            wire [47:0] pcascade;
            
            DSP48E2 #(`COMMON_ATTRS,.AREG(AREG_LOW),.ACASCREG(AREG_LOW),.CREG(1)) 
                    u_low( .CLK(clk),
                           .CEP(1'b1),
                           .CEC(1'b1),
                           .CEA2(1'b1),
                           .CEA1(1'b1),
                           .C(dspC_in),                            
                           .A(dsplowA_in),
                           .B(coeff_dat_i),
                           .BCOUT(bcascade),
                           .CEB1(ceblow1),
                           .CEB2(ceblow2),
                           `D_UNUSED_PORTS,
                           .CARRYINSEL(`CARRYINSEL_CARRYIN),
                           .ALUMODE(`ALUMODE_SUM_ZXYCIN),
                           .OPMODE( { 2'b00, `Z_OPMODE_C, `XY_OPMODE_M } ),
                           .INMODE( 0 ),
                           .PCOUT(pcascade));
            DSP48E2 #(`COMMON_ATTRS,.AREG(AREG_HIGH),.ACASCREG(AREG_HIGH),`C_UNUSED_ATTRS,.B_INPUT("CASCADE"))
                    u_high( .CLK(clk),
                            .CEP(1'b1),
                            .CEA1(1'b1),
                            .CEA2(1'b1),
                            `C_UNUSED_PORTS,
                            .A(dsphighA_in),
                            .BCIN(bcascade),
                            .CEB1(cebhigh1),
                            .CEB2(cebhigh2),
                            `D_UNUSED_PORTS,
                            .CARRYINSEL(`CARRYINSEL_CARRYIN),
                            .OPMODE( {2'b00, `Z_OPMODE_PCIN, `XY_OPMODE_M }),
                            .INMODE(0),
                            .PCIN(pcascade),
                            .P(dsp_out[i]));

            // OK. So, "low" DSPs take sample number - 2.
            // "high" DSPs take sample number - 1.
            assign dsp_low_in[i+2] = dsp_out[i][ (C_FRAC_BITS-NFRAC2) +: NBITS2 ];
            assign dsp_high_in[i+1] = dsp_out[i][ (C_FRAC_BITS-NFRAC2) +: NBITS2 ];
            // we start at 2
            assign samp_out[i+2] = dat_out_reg;
        end
    endgenerate
                
            
endmodule
         
                             