`timescale 1ns / 1ps
// super-dumb axi4-lite PUEO control instance. This guy just interfaces to the entire rest of the
// framework from the CPU.
module axi_pueo(
        input s_axi_aclk,
        input s_axi_aresetn,
        input [23:0] s_axi_awaddr,
        input        s_axi_awvalid,
        output       s_axi_awready,
        //
        input [31:0] s_axi_wdata,
        input [3:0]  s_axi_wstrb,
        input        s_axi_wvalid,
        output       s_axi_wready,
        //
        input [23:0] s_axi_araddr,
        input        s_axi_arvalid,
        output       s_axi_arready,
        //
        output [31:0] s_axi_rdata,
        output [1:0]  s_axi_rresp,
        output        s_axi_rvalid,
        input         s_axi_rready,
        //
        output [1:0]  s_axi_bresp,
        output        s_axi_bvalid,
        input         s_axi_bready,
        
        input         aclk,
        output [7:0]  coeff_adr_o,
        output        coeff_wr_o,
        output        coeff_update_o,
        output [17:0] coeff_dat_o        
    );
    // dumbass address split
    // 0x000 - 0x3FC : control registers
    // 0x400 - 0x7FF : coefficient registers
    // 0x000 : IDENT
    // 0x004 : VERSION
    // 0x008-0x3FC: reserved
    // 0x400-0x4FC: recursive biquad 0
    // 0x500-0x5FC: recursive biquad 1
    // 0x600-0x6FC: gain and zeros
    // 0x700-0x7FC: write *anything* to update all biquad coeffs (addr[9] && addr[8]). 
    // for each biquad:
    // 0x00-0x3F: F-chain FIR
    // 0x40-0x7F: G-chain FIR
    // 0x80-0x8F: IIR coeffs
    // 0x90-0x9F: Incremental computation coeffs
    // 0xA0-0xBF: reserved

    // first pass at a state machine for le stuff
    // make this bigger when I care more
    localparam FSM_BITS=3;
    localparam [FSM_BITS-1:0] IDLE = 0;                 // no txn
    localparam [FSM_BITS-1:0] WRITE_ACCEPT = 1;         // AWADDR accepted
    localparam [FSM_BITS-1:0] WRITE_EXECUTE = 2;        // AWADDR + WDATA arrived, issued transaction to ACLK
    localparam [FSM_BITS-1:0] WRITE_COMPLETING = 3;     // transaction completed from ACLK
    localparam [FSM_BITS-1:0] READ_ACCEPT = 4;          // ARADDR accepted
    localparam [FSM_BITS-1:0] READ_COMPLETING = 5;      // uh, capture the desired data I guess
    localparam [FSM_BITS-1:0] WRITE_DONE = 6;           // issue BVALID
    localparam [FSM_BITS-1:0] READ_DONE = 7;            // issue RVALID
    reg [FSM_BITS-1:0] state = IDLE;

    // register 0 = "PUEO" (damn that's handy)    
    localparam [31:0] IDENT = "PUEO";
    localparam [7:0] VER_REV = 1;
    localparam [3:0] VER_MINOR = 0;
    localparam [3:0] VER_MAJOR = 0;
    // screw date for now
    localparam [31:0] DATEVERSION = { {16{1'b0}}, VER_MAJOR, VER_MINOR, VER_REV };
    
    reg [23:0] address = {24{1'b0}};
    reg [31:0] data = {32{1'b0}};
    reg write_data_valid = 0;
    reg read_data_valid = 0;
    
    // just 2 spaces fix this
    wire write_flag_axiclk = (state == WRITE_EXECUTE && address[10]) && write_data_valid;    
    wire write_flag_aclk;
    flag_sync u_write_flag(.in_clkA(write_flag_axiclk),.clkA(s_axi_aclk),.out_clkB(write_flag_aclk),.clkB(aclk));
    reg coeff_wr = 0;
    reg coeff_update = 0;
    reg write_done_aclk = 0;
    flag_sync u_done_flag(.in_clkA(write_done_aclk),.clkA(aclk),.out_clkB(write_done_axiclk),.clkB(s_axi_aclk));
    wire write_done_axiclk;
    
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn || state <= WRITE_DONE) write_data_valid <= 1'b0;
        else if (s_axi_wvalid && s_axi_wready) write_data_valid <= 1;

        // this is NOT rvalid
        if (!s_axi_aresetn || state <= READ_DONE) read_data_valid <= 1'b0;
        else begin
            if (state == READ_COMPLETING) begin
                // just single cycle for now
                read_data_valid <= 1;
            end
        end
        // data capture
        if (s_axi_wready && s_axi_wvalid) data <= s_axi_wdata;
        else if (state == READ_COMPLETING) begin
            // just two registers, improve this
            // Give local stuff 256 registers = 1k of address space = address[10] = 0
            if (!address[10]) begin
                if (!address[2]) data <= IDENT;
                else if (address[2]) data <= DATEVERSION;
            end else begin 
                // no readback
                data <= {32{1'b0}};
            end
        end            
        // address capture
        if (s_axi_awvalid && s_axi_awready) address <= s_axi_awaddr;
        else if (s_axi_arvalid && s_axi_arready) address <= s_axi_araddr;

        if (!s_axi_aresetn) state <= IDLE;
        else begin
            case (state)
                IDLE: 
                    if (s_axi_awvalid) state <= WRITE_ACCEPT;
                    else if (s_axi_arvalid) state <= READ_ACCEPT;
                WRITE_ACCEPT:
                    if (s_axi_awvalid) state <= WRITE_EXECUTE;
                WRITE_EXECUTE:
                    if (write_data_valid) begin
                        // just 2 spaces, fix this
                        if (address[10]) state <= WRITE_COMPLETING;
                        else state <= WRITE_DONE;
                    end
                WRITE_COMPLETING:
                    // just 2 spaces, fix this
                    if (address[10]) begin
                        if (write_done_axiclk) state <= WRITE_DONE;
                    end
                WRITE_DONE: if (s_axi_bready) state <= IDLE;
                READ_ACCEPT: state <= READ_COMPLETING;
                READ_COMPLETING: state <= READ_DONE;
                READ_DONE: if (s_axi_rready) state <= IDLE;
            endcase
        end        
    end
    
    wire write_delay_done;
    // coeff_wr takes a while to actually update, so we hold it for like, 30 clocks.
    SRLC32E u_write_delay(.D(write_flag_aclk),.CLK(aclk),.CE(1'b1),.Q31(write_delay_done));
    
    always @(posedge aclk) begin
        write_done_aclk <= write_delay_done;
        
        if (write_flag_aclk) coeff_update <= address[9] && address[8];
        else if (write_done_aclk) coeff_update <= 1'b0;
        
        if (write_flag_aclk) coeff_wr <= !address[9] || !address[8];
        else if (write_done_aclk) coeff_update <= 1'b0;        
    end
    
    
    // output channels
    assign s_axi_rdata = data;
    assign s_axi_rvalid = (state == READ_DONE);
    assign s_axi_bvalid = (state == WRITE_DONE);
    // only respond OK
    assign s_axi_bresp = 2'b00;
    assign s_axi_rresp = 2'b00;
    // input channels
    assign s_axi_arready = (state == READ_ACCEPT);
    assign s_axi_awready = (state == WRITE_ACCEPT);
    assign s_axi_wready = (state == WRITE_EXECUTE);
    

    assign coeff_wr_o = coeff_wr;
    assign coeff_update_o = coeff_update;
    assign coeff_dat_o = data[17:0];
    assign coeff_adr_o = address[2 +: 8];
endmodule
