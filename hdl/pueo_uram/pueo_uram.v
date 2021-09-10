`timescale 1ns / 1ps
// the ZU25 has 48 URAM blocks per. Each channel needs 96 bits: URAMs are quantized in units of 72.
// We handle this by jumping to a 500 MHz domain.
// Each URAM handles 24k samples, since each one is groups of 6. This is 8 us. So we use 4 each at first,
module pueo_uram #(parameter NSAMP=8, 
                   parameter NBIT=12,
                   parameter RDLEN=1024,
                   parameter NURAM=4,
                   parameter ADDRLEN)(
        input aclk,
        input aclk_sync_i,
        input aclk_rst_i,
        input [NSAMP*NBIT-1:0] dat_i,

        input memclk,
        input memclk_sync_i,

        input 

    );
endmodule
