`timescale 1ns / 1ps
`include "dsp_macros.vh"
module pueo_rescale8 #(parameter NSAMP=8,
                       parameter NBITS=16,
                       parameter NFRAC=2,
                       parameter OUTBITS=5)(
        input clk,
        input [NSAMP*NBITS-1:0] dat_i,
        input coeff_wr_i,
        input coeff_update_i,
        input [17:0] coeff_dat_i,
        output [NSAMP*OUTBITS-1:0] dat_o
    );
    
    // Rescaling's easy, it's just a single DSP for all of them with AREG=1, PREG=1, BREG=2, etc.
    // All the same.
    // 
    // The *difficult* part is catching overflow, but thankfully we can do that with the pattern detector.
    // However, to work everything out, consider we want:
    //
    // overflow = anything bigger than 16
    // +15to correspond to everything from15 to 16 (15.5 avg)
    // ...
    // +2 to correspond to everything from 2 to  3 (+2.5 avg)
    // +1 to correspond to everything from 1 to  2 (+1.5 avg)
    // 0  to correspond to everything from 0 to +1 (+0.5 avg)
    // -1 to correspond to everything from -1 to 0 (-0.5 avg)
    // ..
    // -16to correspond to everything from -16 to -15 (-15.5 avg)
    //
    // Not worrying about the border cases at the moment!!
    // 
    // Our patterndetect looks for either all bits 0 or all bits 1. Call it PD and PBD.
    // PD PBD  bit[47] desired result
    // 0  0    0       01111
    // 0  0    1       10000
    // 1  0    0       out[4:0]
    // 0  1    1       out[4:0]
    // all others      impossible
    // so it works out to be
    // if (!PD && !PBD) sat_output <= {bit[47], {4{~bit[47]}} };
    // else             sat_output <= output;
    //
    
    // Our input is 16 bits in Q14.2 format remapped to Q17.13.
    // Because we're *clearly* downscaling our coefficient is all fractional, in Q0.19 format,
    // but only 18 bits.
    // In other words, our input is (value * 8192), our coefficient is (scaling * 524288).
    // so our output is value*scaling * 2^32, so the output is Q16.32.
    // Which means we grab bits 36:32.
    
    // Suppose our input is 500. Scale is 1/30, or 17476. Product results in
    // 0010 AA9A 0000. PATTERNDETECT is not set (bit[47:36] == 001). PATTERNBDETECT is not set.
    // sat_output <= 01111.
    // 
    // Suppose our input is 480. Results in 000F FFF0 0000. PATTERNDETECT is set.
    // sat_output <= 01111.
    // 
    // Suppose our input is -500. Output is FFEF 5566 0000. PATTERNBDETECT is not set.
    // sat_output <= 10000.
    //
    // Suppose our input is -480. Output is FFF0 0010 0000. PATTERNBDETECT is set.
    // sat_output <= 10000.
    //
    // Our transition points here are *basically* correct.
    // 451 = 15
    // 450 = 14
    // 421 = 14
    // 420 = 13
    // ...
    // 30  = 0
    // 0   = 0
    // -1  = -1
    // -30 = -1
    // -31 = -2
    //
    // This isn't *perfect* as it is, I think, I might need to tweak something. But I think
    // it's close enough that it doesn't matter?
    // Need to look at this I think.    
    localparam A_BITS = 30;
    localparam A_FRAC = 13;
    localparam B_BITS = 18;
    localparam B_FRAC = 19;
    localparam C_BITS = 48;
    localparam C_FRAC = A_FRAC+B_FRAC;
    
    localparam P_FRAC = C_FRAC;

    localparam A_HEAD_PAD = 17-(NBITS-NFRAC);
    localparam A_TAIL_PAD = 13-NFRAC;
    
    localparam [47:0] SAT_PATTERN = {48{1'b0}};
    // our mask is the top desired bit (36) and all bits above it.
    // Our integer bits are C_BITS-C_FRAC (16). Subtract off
    // OUTBITS and add back in 1. (C_BITS-C_FRAC-OUTBITS)+1 = 12.
    localparam TOP_MASK_BITS = (C_BITS-C_FRAC-OUTBITS)+1;
    localparam BOT_MASK_BITS = C_BITS-TOP_MASK_BITS;
    localparam [47:0] SAT_MASK = { {TOP_MASK_BITS{1'b0}}, {BOT_MASK_BITS{1'b1}} };
    
    
    wire [17:0] bcascade[NSAMP-1:0];
    `define COMMON_ATTRS `CONSTANT_MODE_ATTRS,`C_UNUSED_ATTRS,`DE2_UNUSED_ATTRS,.AREG(1),.ACASCREG(1),.ADREG(0),.MREG(0),.BREG(2),.BCASCREG(1),.PREG(1),.USE_PATTERN_DETECT("PATDET"),.SEL_PATTERN("PATTERN"),.SEL_MASK("MASK"),.PATTERN(SAT_PATTERN),.MASK(SAT_MASK)
    
    generate
        genvar i;
        for (i=0;i<NSAMP;i=i+1) begin : SL
            wire [NBITS-1:0] raw_in = dat_i[NBITS*i +: NBITS];
            wire [A_BITS-1:0] dspA_in = { {A_HEAD_PAD{raw_in[NBITS-1]}}, raw_in, {A_TAIL_PAD{1'b0}} };
            wire [C_BITS-1:0] dsp_out;
            wire patdet_out;
            wire patbdet_out;            
            wire [OUTBITS-1:0] scale_out = dsp_out[P_FRAC +: OUTBITS];
            reg [OUTBITS-1:0] sat_output = {OUTBITS{1'b0}};
            assign dat_o[OUTBITS*i +: OUTBITS] = sat_output;
            reg ceb1 = 0;
            reg ceb2 = 0;
            always @(posedge clk) begin
                if (!patdet_out && !patbdet_out) sat_output <= { dsp_out[47], {4{~dsp_out[47]}} };
                else sat_output <= scale_out;
                ceb1 <= coeff_wr_i;
                ceb2 <= coeff_update_i;
            end
            if (i == 0) begin : HEAD
                DSP48E2 #(`COMMON_ATTRS,.B_INPUT("DIRECT")) 
                        u_scale_head( .CLK(clk),                    
                               .CEP(1'b1),
                               .CEA2(1'b1),
                               .A(dspA_in),
                               .B(coeff_dat_i),
                               .BCOUT(bcascade[i]),
                               .CEB1(ceb1),
                               .CEB2(ceb2),
                               `C_UNUSED_PORTS,
                               `D_UNUSED_PORTS,
                               .CARRYINSEL(`CARRYINSEL_CARRYIN),
                               .ALUMODE(`ALUMODE_SUM_ZXYCIN),
                               .OPMODE( { 2'b00, `Z_OPMODE_0, `XY_OPMODE_M } ),
                               .INMODE( 0 ),
                               .P(dsp_out),
                               .PATTERNDETECT(patdet_out),
                               .PATTERNBDETECT(patbdet_out));
            end else begin : BODY
                DSP48E2 #(`COMMON_ATTRS,.B_INPUT("CASCADE")) 
                        u_scale_body( .CLK(clk),                    
                               .CEP(1'b1),
                               .A(dspA_in),
                               .CEA2(1'b1),
                               .BCIN(bcascade[i-1]),
                               .BCOUT(bcascade[i]),
                               .CEB1(ceb1),
                               .CEB2(ceb2),
                               `C_UNUSED_PORTS,
                               `D_UNUSED_PORTS,
                               .CARRYINSEL(`CARRYINSEL_CARRYIN),
                               .ALUMODE(`ALUMODE_SUM_ZXYCIN),
                               .OPMODE( { 2'b00, `Z_OPMODE_0, `XY_OPMODE_M } ),
                               .INMODE( 0 ),
                               .P(dsp_out),
                               .PATTERNDETECT(patdet_out),
                               .PATTERNBDETECT(patbdet_out));
                                    
            end
        end
    endgenerate
     
    
    
    
    
endmodule
