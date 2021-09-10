`timescale 1ns / 1ps
`include "dsp_macros.vh"
module beamform_trigger #(parameter NSAMP=8, 
                          parameter NBIT=5,
                          parameter ADELAY=0,
                          parameter BDELAY=0,
                          parameter CDELAY=0,
                          parameter DDELAY=0,
                          parameter EDELAY=0,
                          parameter FDELAY=0,
                          parameter GDELAY=0,
                          parameter HDELAY=0)(
        input clk,
        input [NSAMP*NBIT-1:0] A,
        input [NSAMP*NBIT-1:0] B,
        input [NSAMP*NBIT-1:0] C,
        input [NSAMP*NBIT-1:0] D,
        input [NSAMP*NBIT-1:0] E,
        input [NSAMP*NBIT-1:0] F,
        input [NSAMP*NBIT-1:0] G,
        input [NSAMP*NBIT-1:0] H,
        
        output [95:0] beam_out
    );
    
    localparam NCHAN = 8;
    
    // OK, the *best* way to go about this is using a quad-beam structure
    // but we're not going to do that now.
    // Instead we're going to do
    // Delay and align each of them
    // Run through 8:2 compressors
    // Then we've got 16 inputs to add, which we handle via 6 DSPs.
    
    // Aligning them isn't easy. 
    // First, determine base SRL delay of DELAY/8. Then sample delay of DELAY % 8. Loop and realign:
    // if (i < SAMPDELAY) then SRL delay = base+1 and output = sample[8+i-SAMPDELAY]. (since i < delay this is less than 8).
    // else SRL delay = base delay and output = sample[i-SAMPDELAY] (since i >= SAMPDELAY this is greater than 0)

    // vectorize the inputs
    wire [NBIT*NSAMP-1:0] in_data[NCHAN-1:0];
    assign in_data[0] = A;
    assign in_data[1] = B;
    assign in_data[2] = C;
    assign in_data[3] = D;
    assign in_data[4] = E;
    assign in_data[5] = F;
    assign in_data[6] = G;
    assign in_data[7] = H;    
    // Delay vectorization. This *completely* sucks, but hey, what are you going to do.
    localparam [4:0] ABASE = (ADELAY/NSAMP);
    localparam [4:0] BBASE = (BDELAY/NSAMP);
    localparam [4:0] CBASE = (CDELAY/NSAMP);
    localparam [4:0] DBASE = (DDELAY/NSAMP);
    localparam [4:0] EBASE = (EDELAY/NSAMP);
    localparam [4:0] FBASE = (FDELAY/NSAMP);
    localparam [4:0] GBASE = (GDELAY/NSAMP);
    localparam [4:0] HBASE = (HDELAY/NSAMP);

    localparam [2:0] ASAMP = (ADELAY % 8);
    localparam [2:0] BSAMP = (BDELAY % 8);
    localparam [2:0] CSAMP = (CDELAY % 8);
    localparam [2:0] DSAMP = (DDELAY % 8);
    localparam [2:0] ESAMP = (EDELAY % 8);
    localparam [2:0] FSAMP = (FDELAY % 8);
    localparam [2:0] GSAMP = (GDELAY % 8);
    localparam [2:0] HSAMP = (HDELAY % 8);
    
    localparam [5*NSAMP-1:0] BASEDELAYS =
        { HBASE,
          GBASE,
          FBASE,
          EBASE,
          DBASE,
          CBASE,
          BBASE,
          ABASE } ;
    localparam [3*NSAMP-1:0] SAMPDELAYS =
        {   HSAMP,
            GSAMP,
            FSAMP,
            ESAMP,
            DSAMP,
            CSAMP,
            BSAMP,
            ASAMP };          

    // these are the aligned outputs
    wire [NBIT-1:0] beam_data[NCHAN-1:0][NSAMP-1:0];
    wire [(NBIT+3)-1:0] sum_data[NSAMP-1:0][1:0];
    generate
        genvar chan, samp, beamsamp;
        for (chan=0;chan<NCHAN;chan=chan+1) begin : CL
            localparam [4:0] THIS_BASE_DELAY = BASEDELAYS[5*chan +: 5];
            localparam [2:0] THIS_SAMP_DELAY = SAMPDELAYS[3*chan +: 3];
            for (samp=0;samp<NSAMP;samp=samp+1) begin : SL
                wire [NBIT-1:0] align_delay;
                reg [NBIT-1:0] align_reg = {NBIT{1'b0}};
                localparam THIS_SRL_DELAY = (samp < THIS_SAMP_DELAY) ? THIS_BASE_DELAY + 1 : THIS_BASE_DELAY;
                localparam THIS_SAMPLE = (samp < THIS_SAMP_DELAY) ? 8+samp-THIS_SAMP_DELAY : samp-THIS_SAMP_DELAY;
                srlvec #(.NBITS(NBIT)) u_delay( .clk(clk),.ce(1'b1),
                                                 .a(THIS_SRL_DELAY),
                                                 .din( in_data[chan][NBIT*THIS_SAMPLE +: NBIT] ),
                                                 .dout(align_delay));
                always @(posedge clk) begin : DLYREG
                    align_reg <= align_delay;
                end
                assign beam_data[chan][samp] = align_reg;
            end                
        end
        for (beamsamp=0;beamsamp<NSAMP;beamsamp=beamsamp+1) begin : BL
            fast_csa82_adder #(.NBITS(NBIT)) 
                u_adder( .CLK(clk),
                         .CE(1'b1),
                         .A( beam_data[0][beamsamp] ),
                         .B( beam_data[1][beamsamp] ),
                         .C( beam_data[2][beamsamp] ),
                         .D( beam_data[3][beamsamp] ),
                         .E( beam_data[4][beamsamp] ),
                         .F( beam_data[5][beamsamp] ),
                         .G( beam_data[6][beamsamp] ),
                         .H( beam_data[7][beamsamp] ),
                         .OA(sum_data[beamsamp][0]),
                         .OB(sum_data[beamsamp][1]));                                     
        end
    endgenerate

    // sigh, is this the smartest way to do this? We could actually do 8 DSPs and the square/sum
    // altogether in one shot. Otherwise we've still got another 8:2 and DSP collapse, and
    // that's 3 DSPs. 8 DSPs for 50 beams just isn't that big a deal, it's only 400 DSPs total.

    wire [47:0] dsp03_concat_in = { sum_data[0][0], sum_data[1][0], sum_data[2][0], sum_data[3][0] };
    wire [47:0] dsp03_Cin =       { sum_data[0][1], sum_data[1][1], sum_data[2][1], sum_data[3][1] };
    wire [47:0] dsp03_out;
    wire [47:0] dsp47_concat_in = { sum_data[4][0], sum_data[5][0], sum_data[6][0], sum_data[7][0] };
    wire [47:0] dsp47_Cin =       { sum_data[4][1], sum_data[5][1], sum_data[6][1], sum_data[7][1] };
    wire [47:0] dsp47_out;
    
    
    wire [29:0] dsp03_Ain = `DSP_AB_A(dsp03_concat_in);
    wire [17:0] dsp03_Bin = `DSP_AB_B(dsp03_concat_in);
    wire [29:0] dsp47_Ain = `DSP_AB_A(dsp47_concat_in);
    wire [17:0] dsp47_Bin = `DSP_AB_B(dsp47_concat_in);

    DSP48E2 #(`DE2_UNUSED_ATTRS, `CONSTANT_MODE_ATTRS, `NO_MULT_ATTRS, .USE_SIMD("FOUR12"),.AREG(1),.BREG(1),.CREG(1),.PREG(1),.BCASCREG(1),.ACASCREG(1))
        u_dsp03( .CLK(clk),
                 .CEC(1'b1),
                 .CEP(1'b1),
                 .CEA2(1'b1),
                 .CEB2(1'b1),
                 .A(dsp03_Ain),
                 .B(dsp03_Bin),
                 .C(dsp03_Cin),
                 `D_UNUSED_PORTS,
                 .INMODE(0),
                 .ALUMODE( `ALUMODE_SUM_ZXYCIN ),
                 .OPMODE( { 2'b00, `Z_OPMODE_0, `Y_OPMODE_C, `X_OPMODE_0 } ),
                 .P( dsp03_out ));
    DSP48E2 #(`DE2_UNUSED_ATTRS, `CONSTANT_MODE_ATTRS, `NO_MULT_ATTRS, .USE_SIMD("FOUR12"),.AREG(1),.BREG(1),.CREG(1),.PREG(1),.BCASCREG(1),.ACASCREG(1))
        u_dsp47( .CLK(clk),
                 .CEC(1'b1),
                 .CEP(1'b1),
                 .CEA2(1'b1),
                 .CEB2(1'b1),
                 .A(dsp47_Ain),
                 .B(dsp47_Bin),
                 .C(dsp47_Cin),
                 `D_UNUSED_PORTS,
                 .INMODE(0),
                 .ALUMODE( `ALUMODE_SUM_ZXYCIN ),
                 .OPMODE( { 2'b00, `Z_OPMODE_0, `Y_OPMODE_C, `X_OPMODE_0 } ),
                 .P( dsp47_out ));                 
    assign beam_out[0 +: 48] = dsp03_out;
    assign beam_out[48 +: 48] = dsp47_out;        
endmodule
