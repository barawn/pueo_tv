`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/10/2021 12:48:47 PM
// Design Name: 
// Module Name: pueo_notch_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pueo_notch_tb;
    // run at 3 GHz to begin
    reg sclk = 0;
    always #0.166 sclk = ~sclk;
    
    // 375 is 1/8th so toggle every 4
    reg [1:0] aclk_counter = {2{1'b0}};
    always @(posedge sclk) aclk_counter <= aclk_counter + 1;
    reg aclk = 1;
    always @(posedge sclk) if (aclk_counter == 2'b11) aclk <= ~aclk;

    wire [2:0] smpno = { ~aclk, aclk_counter };

    reg [16*8-1:0] dat_aclk = {16*8{1'b0}};
    wire [15:0] samples_out[7:0];
    
    reg [7:0] coeff_adr = {8{1'b0}};
    reg       coeff_wr = 0;
    reg       coeff_update = 0;
    reg [17:0] coeff_dat = {18{1'b0}};
    
    wire coeff_fir_wr = (coeff_wr && (coeff_adr[7:5] == 0));    
    wire [47:0] y0_fir;
    wire [47:0] y1_fir;
    biquad8_pole_fir u_fir(.clk(aclk),
                           .dat_i(dat_aclk),                           
                           .coeff_adr_i(coeff_adr[4:0]),
                           .coeff_wr_i(coeff_fir_wr),
                           .coeff_update_i(coeff_update),
                           .coeff_dat_i(coeff_dat),
                           .y0_out(y0_fir),
                           .y1_out(y1_fir));
    wire coeff_iir_wr = (coeff_wr && (coeff_adr[7:5] == 1) && !coeff_adr[4]);
    wire [23:0] y0_iir;
    wire [23:0] y1_iir;
    biquad8_pole_iir u_iir(.clk(aclk),
                           .coeff_adr_i(coeff_adr[1:0]),
                           .coeff_wr_i(coeff_iir_wr),
                           .coeff_update_i(coeff_update),
                           .coeff_dat_i(coeff_dat),
                           .y0_fir_in(y0_fir),
                           .y1_fir_in(y1_fir),
                           .y0_out(y0_iir),
                           .y1_out(y1_iir));
    // the incrementals pick up 48 and 49 for now. probably fix this later.                           
    wire coeff_incr_wr = coeff_wr && (coeff_adr[7:5] == 1) && (coeff_adr[4:1] == 4'b1000);        
    wire [16*8-1:0] notch_data;
    biquad8_incremental u_incr(.clk(aclk),
                               .dat_i(dat_aclk),
                               .y0_in(y0_iir),
                               .y1_in(y1_iir),
                               .coeff_adr_i(coeff_adr[0]),
                               .coeff_dat_i(coeff_dat),
                               .coeff_wr_i(coeff_incr_wr),
                               .coeff_update_i(coeff_update),
                               .dat_o(notch_data));
    reg [15:0] wfm = {16{1'b0}};
    always @(posedge sclk) wfm <= samples_out[smpno];
    generate
        genvar n;
        for (n=0;n<8;n=n+1) begin : UNVEC
            assign samples_out[n] = notch_data[16*n +: 16];
        end
    endgenerate

    task update_coeff;
        begin
            @(posedge aclk);
            #1 coeff_update <= 1;
            @(posedge aclk);
            #1 coeff_update <= 0;
        end
    endtask
    
    task write_coeff;
        input [7:0]     address;
        input [17:0]    coeff;
        begin
            // run for 16 clocks
            @(posedge aclk);
            #1 coeff_dat <= coeff;
               coeff_adr <= address;
               coeff_wr <= 1'b1;
            @(posedge aclk);
            @(posedge aclk);
            @(posedge aclk);
            @(posedge aclk);
            @(posedge aclk);
            @(posedge aclk);
            @(posedge aclk);
            @(posedge aclk);
            @(posedge aclk);
            @(posedge aclk);
            @(posedge aclk);
            @(posedge aclk);
            @(posedge aclk);
            @(posedge aclk);
            @(posedge aclk);
            @(posedge aclk);
            #1 coeff_wr <= 0;
            @(posedge aclk);
        end
    endtask

    function automatic real cheby2;
        input real val;
        input integer order;
        real result;
        begin
            if (order < 2) result = $pow(2*val, order);
            else result = 2*val*cheby2(val, order-1)-cheby2(val, order-2);
            cheby2 = result;
        end
    endfunction

    // coeffs are Q4.14 format, meaning (val*16384).
    function [17:0] cheby_coeff;
        input real mag;
        input real angle;
        input integer order;
        input integer power;
        real tmp;
        begin
            tmp = $pow(mag, power);
            tmp = tmp*cheby2($cos(angle), order);
            cheby_coeff = tmp*16384;
        end        
    endfunction        

    // 0 in[7]z^-1 * PU(1,cost)       output at clock 3   (SRL=1) (in[0] gets FF only and is stored in C)
    // 1 in[6]z^-1 * P^2 U(2, cost)   output at clock 4   (SRL=2)
    // 2 in[5]z^-1 * P^3 U(3, cost)   output at clock 5   (SRL=3)
    // 3 in[4]z^-1 * P^4 U(4, cost)   output at clock 6   (SRL=4)
    // 4 in[3]z^-1 * P^5 U(5, cost)   output at clock 7   (SRL=5)
    // 5 in[2]z^-1 * P^6 U(6, cost)   output at clock 8   (SRL=6)
    // 6 out5 z^-1 * -1*P^8 U(6, cost)   output at clock 9
    // 7 is the cross-link = g[n-1] * P^7 U(7, cost)
    // 16 in[0]*PU(1,cost)           output at clock 2
    // 17 in[7]z^-1 * P^2(U2,cost)   output at clock 3 (SRL=2)
    // ..
    // 22 in[2]z^-1 * P^7 U(7, cost) output at clock 8 (SRL=7)
    // 23 out22 z^-1 * P^8 U(8, cost) output at clock 9
    // 24 is the cross-link = f[n-1] * -1*P^9 U(7, cost)

    // A Q=5 375 MHz notch has poles at mag 0.92416486, angle 0.78228186.
    localparam real mag = 0.92416486;
    localparam real ang = 0.78228186;

    // calculate the IIR for the cross-terms (y0 looking at y1, and y1 looking at y0)
    function real iir_cross;
        input real mag;
        input real ang;
        input integer mypow;
        real tmp;
        begin
            tmp = cheby2($cos(ang), 7);
            iir_cross = 2*$pow(mag, mypow)*tmp;
        end
    endfunction

    function real iir_direct;
        input real mag;
        input real ang;
        input integer ord1;
        input integer ord2;
        real tmp1;
        real tmp2;
        begin
            tmp1 = $pow(cheby2($cos(ang), ord1), 2);
            tmp2 = $pow(cheby2($cos(ang), ord2), 2);
            iir_direct = $pow(mag, 16)*(tmp1-tmp2);
        end
    endfunction

    // The IIR coeffs are:
    // 0: y0's y0 lookback = -P^16 (U^2(7,cost)-U^2(6,cost))
    // 1:      y1 lookback = 2P^15 (U(7,cost)*cos(8t))
    // 2: y1's y1 lookback = P^16(U^2(8,cost)-U^2(7,cost))
    // 3:      y0 lookback = -2P^17(U(7,cost)*cos(8t))
    localparam [17:0] iir0 = -16384*iir_direct(mag, ang, 7, 6);
    localparam [17:0] iir1 = 16384*iir_cross(mag, ang, 15);
    localparam [17:0] iir2 = 16384*iir_direct(mag, ang, 8, 7);
    localparam [17:0] iir3 = -16384*iir_cross(mag, ang, 17);
 
    
    localparam [17:0] incr_0 = -16384*$pow(mag, 2);
    localparam [17:0] incr_1 = 16384*2*mag*$cos(ang);
 
    initial begin
        #100;
        // OK, now we need to program the coefficients (sooo slow)        
        // NOTE NOTE NOTE:
        // These have to be programmed BACKWARDS. The LAST one
        // has to be programmed FIRST.
        write_coeff(24, -1*cheby_coeff(mag, ang, 7, 9));
        write_coeff(23, cheby_coeff(mag, ang, 8, 8));
        write_coeff(22, cheby_coeff(mag, ang, 7, 7));
        write_coeff(21, cheby_coeff(mag, ang, 6, 6));
        write_coeff(20, cheby_coeff(mag, ang, 5, 5));
        write_coeff(19, cheby_coeff(mag, ang, 4, 4));
        write_coeff(18, cheby_coeff(mag, ang, 3, 3));
        write_coeff(17, cheby_coeff(mag, ang, 2, 2));
        write_coeff(16, cheby_coeff(mag, ang, 1, 1));

        write_coeff( 7, cheby_coeff(mag, ang, 7, 7) );
        write_coeff( 6, -1*cheby_coeff(mag, ang, 6, 8) );
        write_coeff( 5, cheby_coeff(mag, ang, 6, 6) );
        write_coeff( 4, cheby_coeff(mag, ang, 5, 5) );
        write_coeff( 3, cheby_coeff(mag, ang, 4, 4) );
        write_coeff( 2, cheby_coeff(mag, ang, 3, 3) );
        write_coeff( 1, cheby_coeff(mag, ang, 2, 2) );
        write_coeff( 0, cheby_coeff(mag, ang, 1, 1) );

        // now 32, 33, 34, 35 are the IIR coeffs
        write_coeff(35, iir3);
        write_coeff(34, iir2);
        write_coeff(33, iir1);
        write_coeff(32, iir0);

        write_coeff(49, incr_1);
        write_coeff(48, incr_0);
        update_coeff();
        #100;
        @(posedge aclk);
        #1 dat_aclk[ 0 +: 16] <= 100;
           dat_aclk[48 +: 16] <= 1;
        @(posedge aclk);
        #1 dat_aclk[ 0 +: 16] <= 0;
           dat_aclk[48 +: 16] <= 0;
    end
        
endmodule
