//
// This file contains macro defines for interface connections.
// We do this because it helps ensure that the interfaces are defined
// correctly for each instance each time to reduce typos.
//

// Conventions:
// `DEFINE_(name of interface)_IF( prefix , ... ) defines wires for (name of interface) with 'prefix' before it.
// `DEFINE_(name of interface)_IFV( prefix , suffix , ... ) defines wires for (name of interface) with 'prefix' before it and 'suffix' after it
// `CONNECT_(name of interface)_IF( port_prefix, if_prefix ) connects an interface with 'if_prefix' to ports with 'port_prefix'
// `CONNECT_(name of interface)_IFV( port_prefix, if_prefix, if_suffix ) connects an interface with 'if_prefix' and 'if_suffix' to ports with 'port_prefix'
// `HOST_NAMED_PORTS_(name of interface)_IF( prefix ) defines named ports for an interface with 'prefix' before them, defined as a host (initiator, master)
// `TARGET_NAMED_PORTS_(name of interface)_IF( prefix ) defines named ports for an interface with 'prefix' before them, defined as a target (slave)
//
// suffixes are only intended to be used for vector indices, that's why you can't define them for ports

// Dumb macros so that empty prefixes/suffixes don't look weird
`define NO_PREFIX
`define NO_SUFFIX

/////////////////////////////////////////////////////////
// AXI4-Stream minimal interface: TDATA/TVALID/TREADY. //
/////////////////////////////////////////////////////////

`define DEFINE_AXI4S_MIN_IFV( prefix , suffix, width )          \
    wire [ width - 1:0] prefix``tdata``suffix;                  \
    wire prefix``tvalid``suffix;                                \
    wire prefix``tready``suffix

`define DEFINE_AXI4S_MIN_IF( prefix , width )                   \
    `DEFINE_AXI4S_MIN_IFV( prefix, `NO_SUFFIX , width )

`define CONNECT_AXI4S_MIN_IFV( port_prefix , if_prefix , if_suffix )            \
    .``port_prefix``tdata ( if_prefix``tdata``if_suffix ),                      \
    .``port_prefix``tvalid ( if_prefix``tvalid``if_suffix ),                    \
    .``port_prefix``tready ( if_prefix``tready``if_suffix )                

`define CONNECT_AXI4S_MIN_IF( port_prefix , if_prefix )                         \
    `CONNECT_AXI4S_MIN_IFV( port_prefix, if_prefix, `NO_SUFFIX )

`define NAMED_PORTS_AXI4S_MIN_IF( port_prefix , width , tohost_type, fromhost_type)         \
    fromhost_type [ width - 1:0]    port_prefix``tdata,                                     \
    fromhost_type                   port_prefix``tvalid,                                    \
    tohost_type                     port_prefix``tready

`define HOST_NAMED_PORTS_AXI4S_MIN_IF( port_prefix, width )     \
    `NAMED_PORTS_AXI4S_MIN_IF( port_prefix, width, input, output )

`define TARGET_NAMED_PORTS_AXI4S_MIN_IF( port_prefix, width )     \
    `NAMED_PORTS_AXI4S_MIN_IF( port_prefix, width, output, input )

/////////////////////////////////////////////////////////////
// Darklite split interface.                               //
// macro for bus definition of 64/256 split interface      //
// holy crap this saves an utter boatload of typing        //
/////////////////////////////////////////////////////////////
// convenience define
`define DEFINE_SPLIT_IFV_DMA( prefix, suffix, idx )                         \
    wire [255:0]    prefix``dma``idx``_from_host_data;                      \
    wire [13:0]     prefix``dma``idx``_from_host_ctrl;                      \
    wire            prefix``dma``idx``_from_host_valid;                     \
    wire            prefix``dma``idx``_from_host_advance;                   \
    wire [255:0]    prefix``dma``idx``_to_host_data``suffix;                \
    wire [13:0]     prefix``dma``idx``_to_host_ctrl``suffix;                \
    wire            prefix``dma``idx``_to_host_valid``suffix;               \
    wire            prefix``dma``idx``_to_host_almost_full``suffix 
    
`define DEFINE_SPLIT_IFV( prefix, suffix )                                  \
    wire [63:0]     prefix``target_address``suffix;                         \
    wire [63:0]     prefix``target_write_data``suffix;                      \
    wire [7:0]      prefix``target_write_be``suffix;                        \
    wire            prefix``target_address_valid``suffix;                   \
    wire            prefix``target_write_enable``suffix;                    \
    wire            prefix``target_write_accept``suffix;                    \
    wire            prefix``target_read_enable``suffix;                     \
    wire [3:0]      prefix``target_request_tag``suffix;                     \
    wire [63:0]     prefix``target_read_data``suffix;                       \
    wire            prefix``target_read_accept``suffix;                     \
    wire [3:0]      prefix``target_read_data_tag``suffix;                   \
    wire            prefix``target_read_data_valid``suffix;                 \
    wire [7:0]      prefix``target_read_ctrl``suffix;                       \
    wire [7:0]      prefix``target_read_data_ctrl``suffix;                  \
    `DEFINE_SPLIT_IFV_DMA( prefix , suffix, 0);                             \
    `DEFINE_SPLIT_IFV_DMA( prefix , suffix, 1);                             \
    `DEFINE_SPLIT_IFV_DMA( prefix , suffix, 2)

`define DEFINE_SPLIT_IF( prefix )                                       \
    `DEFINE_SPLIT_IFV( prefix, `NO_SUFFIX )    

// convenience function for DMA
`define CONNECT_SPLIT_IFV_DMA( port_prefix , if_prefix, if_suffix, idx )                                        \
    .``port_prefix``dma``idx``_from_host_data       ( if_prefix``dma``idx``_from_host_data``if_suffix ),        \
    .``port_prefix``dma``idx``_from_host_ctrl       ( if_prefix``dma``idx``_from_host_ctrl``if_suffix ),        \
    .``port_prefix``dma``idx``_from_host_valid      ( if_prefix``dma``idx``_from_host_valid``if_suffix ),       \
    .``port_prefix``dma``idx``_from_host_advance    ( if_prefix``dma``idx``_from_host_advance``if_suffix ),     \
    .``port_prefix``dma``idx``_to_host_data         ( if_prefix``dma``idx``_to_host_data``if_suffix ),          \
    .``port_prefix``dma``idx``_to_host_ctrl         ( if_prefix``dma``idx``_to_host_ctrl``if_suffix ),          \
    .``port_prefix``dma``idx``_to_host_valid        ( if_prefix``dma``idx``_to_host_valid``if_suffix ),         \
    .``port_prefix``dma``idx``_to_host_almost_full  ( if_prefix``dma``idx``_to_host_almost_full``if_suffix )

// macro for port connection of split interface
`define CONNECT_SPLIT_IFV( port_prefix , if_prefix, if_suffix )                                         \
    .``port_prefix``target_address                  ( if_prefix``target_address``if_suffix ),           \
    .``port_prefix``target_write_data               ( if_prefix``target_write_data``if_suffix ),        \
    .``port_prefix``target_write_be                 ( if_prefix``target_write_be``if_suffix ),          \
    .``port_prefix``target_address_valid            ( if_prefix``target_address_valid``if_suffix ),     \
    .``port_prefix``target_write_enable             ( if_prefix``target_write_enable``if_suffix ),      \
    .``port_prefix``target_write_accept             ( if_prefix``target_write_accept``if_suffix ),      \
    .``port_prefix``target_read_enable              ( if_prefix``target_read_enable``if_suffix ),       \
    .``port_prefix``target_request_tag              ( if_prefix``target_request_tag``if_suffix ),       \
    .``port_prefix``target_read_data                ( if_prefix``target_read_data``if_suffix ),         \
    .``port_prefix``target_read_accept              ( if_prefix``target_read_accept``if_suffix ),       \
    .``port_prefix``target_read_data_tag            ( if_prefix``target_read_data_tag``if_suffix ),     \
    .``port_prefix``target_read_data_valid          ( if_prefix``target_read_data_valid``if_suffix ),   \
    .``port_prefix``target_read_ctrl                ( if_prefix``target_read_ctrl``if_suffix ),         \
    .``port_prefix``target_read_data_ctrl           ( if_prefix``target_read_data_ctrl``if_suffix ),    \
    `CONNECT_SPLIT_IFV_DMA( port_prefix, if_prefix, if_suffix, 0 ),                                     \
    `CONNECT_SPLIT_IFV_DMA( port_prefix, if_prefix, if_suffix, 1 ),                                     \
    `CONNECT_SPLIT_IFV_DMA( port_prefix, if_prefix, if_suffix, 2 )

`define CONNECT_SPLIT_IF( port_prefix, if_prefix )  \
    `CONNECT_SPLIT_IFV( port_prefix, if_prefix, `NO_SUFFIX )

`define NAMED_PORTS_SPLIT_IF_DMA( port_prefix , fromhost_type, tohost_type, idx)        \
    fromhost_type   [255:0] ``port_prefix``dma``idx``_from_host_data,                   \
    fromhost_type   [13:0]  ``port_prefix``dma``idx``_from_host_ctrl,                   \
    fromhost_type           ``port_prefix``dma``idx``_from_host_valid,                  \
    tohost_type             ``port_prefix``dma``idx``_from_host_advance,                \
    tohost_type     [255:0] ``port_prefix``dma``idx``_to_host_data,                     \
    tohost_type     [13:0]  ``port_prefix``dma``idx``_to_host_ctrl,                     \
    tohost_type             ``port_prefix``dma``idx``_to_host_valid,                    \
    fromhost_type           ``port_prefix``dma``idx``_to_host_almost_full

`define NAMED_PORTS_SPLIT_IF( port_prefix, fromhost_type, tohost_type )                 \
    fromhost_type [63:0]    ``port_prefix``target_address,                              \
    fromhost_type [63:0]    ``port_prefix``target_write_data,                           \
    fromhost_type [7:0]     ``port_prefix``target_write_be,                             \
    fromhost_type           ``port_prefix``target_address_valid,                        \
    fromhost_type           ``port_prefix``target_write_enable,                         \
    tohost_type             ``port_prefix``target_write_accept,                         \
    fromhost_type           ``port_prefix``target_read_enable,                          \
    fromhost_type [3:0]     ``port_prefix``target_request_tag,                          \
    tohost_type [63:0]      ``port_prefix``target_read_data,                            \
    tohost_type             ``port_prefix``target_read_accept,                          \
    tohost_type [3:0]       ``port_prefix``target_read_data_tag,                        \
    tohost_type             ``port_prefix``target_read_data_valid,                      \
    fromhost_type [7:0]     ``port_prefix``target_read_ctrl,                            \
    tohost_type [7:0]       ``port_prefix``target_read_data_ctrl,                       \
    `NAMED_PORTS_SPLIT_IF_DMA( port_prefix, fromhost_type, tohost_type, 0),             \
    `NAMED_PORTS_SPLIT_IF_DMA( port_prefix, fromhost_type, tohost_type, 1),             \
    `NAMED_PORTS_SPLIT_IF_DMA( port_prefix, fromhost_type, tohost_type, 2)
 
`define HOST_NAMED_PORTS_SPLIT_IF( port_prefix )    \
    `NAMED_PORTS_SPLIT_IF( port_prefix, output , input )

`define TARGET_NAMED_PORTS_SPLIT_IF( port_prefix )  \
    `NAMED_PORTS_SPLIT_IF( port_prefix, input , output )      
    
/////////////////////////////////////////////////////////////
// Darklite 64-bit combined interface.                     //
// macro for bus definition of 64-bit combined interface   //
/////////////////////////////////////////////////////////////
`define DEFINE_COMBINED_IFV( prefix , suffix )                          \
    wire         prefix``interface_ready``suffix;                       \
    wire [63:0]  prefix``register_write_address``suffix;                \
    wire [63:0]  prefix``register_write_data``suffix;                   \
    wire [7:0]   prefix``register_write_be``suffix;                     \
    wire         prefix``register_write_enable``suffix;                 \
    wire [63:0]  prefix``register_read_address``suffix;                 \
    wire [7:0]   prefix``register_request_tag``suffix;                  \
    wire         prefix``register_read_enable``suffix;                  \
    wire [63:0]  prefix``register_read_data``suffix;                    \
    wire [7:0]   prefix``register_read_data_tag``suffix;                \
    wire         prefix``register_read_data_valid``suffix

`define DEFINE_COMBINED_IF( prefix )                                    \
    `DEFINE_COMBINED_IFV( prefix, `NO_SUFFIX )

// macro for port connection of 64-bit combined interface
`define CONNECT_COMBINED_IFV( port_prefix , if_prefix , if_suffix )                             \
    .``port_prefix``interface_ready          ( if_prefix``interface_ready``if_suffix),          \
    .``port_prefix``register_write_address   ( if_prefix``register_write_address``if_suffix),   \
    .``port_prefix``register_write_data      ( if_prefix``register_write_data``if_suffix),      \
    .``port_prefix``register_write_be        ( if_prefix``register_write_be``if_suffix),        \
    .``port_prefix``register_write_enable    ( if_prefix``register_write_enable``if_suffix),    \
    .``port_prefix``register_read_address    ( if_prefix``register_read_address``if_suffix),    \
    .``port_prefix``register_request_tag     ( if_prefix``register_request_tag``if_suffix),     \
    .``port_prefix``register_read_enable     ( if_prefix``register_read_enable``if_suffix),     \
    .``port_prefix``register_read_data       ( if_prefix``register_read_data``if_suffix),       \
    .``port_prefix``register_read_data_tag   ( if_prefix``register_read_data_tag``if_suffix),   \
    .``port_prefix``register_read_data_valid ( if_prefix``register_read_data_valid``if_suffix)

`define CONNECT_COMBINED_IF( port_prefix , if_prefix )          \
    `CONNECT_COMBINED_IFV(port_prefix, if_prefix, `NO_SUFFIX )

// macro for named port definition of 64-bit combined interface. see below for simpler macros for host/target
`define NAMED_PORTS_COMBINED_IF( port_prefix , fromhost_type, tohost_type)          \
    tohost_type                 port_prefix``interface_ready,                       \
    fromhost_type       [63:0]  port_prefix``register_write_address,                \
    fromhost_type       [63:0]  port_prefix``register_write_data,                   \
    fromhost_type       [7:0]   port_prefix``register_write_be,                     \
    fromhost_type               port_prefix``register_write_enable,                 \
    fromhost_type       [63:0]  port_prefix``register_read_address,                 \
    fromhost_type       [7:0]   port_prefix``register_request_tag,                  \
    fromhost_type               port_prefix``register_read_enable,                  \
    tohost_type         [63:0]  port_prefix``register_read_data,                    \
    tohost_type         [7:0]   port_prefix``register_read_data_tag,                \
    tohost_type                 port_prefix``register_read_data_valid
// convenience macro for defining a port at the host (master) side
`define HOST_NAMED_PORTS_COMBINED_IF( port_prefix )                                 \
    `NAMED_PORTS_COMBINED_IF( port_prefix , output, input)
`define TARGET_NAMED_PORTS_COMBINED_IF( port_prefix )                               \
    `NAMED_PORTS_COMBINED_IF( port_prefix , input, output)
    
// AXI4-Lite interface macros.
//
// The "CONNECT" macros also exist for individual channels
// for connecting half-connected channels like exist in some Xilinx
// modules. We don't do this for the define or port definition
// macros because unused ports can just be ignored.
//
`define DEFINE_AXI4L_IFV( prefix , suffix , address_width, data_width )             \
    wire    [ address_width -1:0]       prefix``awaddr``suffix;                     \
    wire                                prefix``awvalid``suffix;                    \
    wire                                prefix``awready``suffix;                    \
    wire    [ data_width -1:0]          prefix``wdata``suffix;                      \
    wire                                prefix``wvalid``suffix;                     \
    wire                                prefix``wready``suffix;                     \
    wire    [ ( data_width /8 ) -1:0]   prefix``wstrb``suffix;                      \
    wire    [1:0]                       prefix``bresp``suffix;                      \
    wire                                prefix``bvalid``suffix;                     \
    wire                                prefix``bready``suffix;                     \
    wire    [ address_width -1:0]       prefix``araddr``suffix;                     \
    wire                                prefix``arvalid``suffix;                    \
    wire                                prefix``arready``suffix;                    \
    wire    [ data_width -1:0]          prefix``rdata``suffix;                      \
    wire    [1:0]                       prefix``rresp``suffix;                      \
    wire                                prefix``rvalid``suffix;                     \
    wire                                prefix``rready``suffix

`define DEFINE_AXI4L_IF( prefix , address_width, data_width )                       \
    `DEFINE_AXI4L_IFV( prefix , `NO_SUFFIX , address_width, data_width )

`define CONNECT_AXI4L_IFV( port_prefix, if_prefix , if_suffix )             \
    `CONNECT_AXI4L_AW_IFV( port_prefix, if_prefix , if_suffix ),            \
    `CONNECT_AXI4L_W_IFV( port_prefix, if_prefix, if_suffix ),              \
    `CONNECT_AXI4L_B_IFV( port_prefix, if_prefix, if_suffix ),              \
    `CONNECT_AXI4L_AR_IFV( port_prefix, if_prefix, if_suffix ),             \
    `CONNECT_AXI4L_R_IFV( port_prefix, if_prefix, if_suffix )

`define CONNECT_AXI4L_IF( port_prefix, if_prefix )                          \
    `CONNECT_AXI4L_IFV( port_prefix , if_prefix , `NO_SUFFIX )

// Auxiliary AXI4-Lite connect macros, for the modules that don't have all
// channels.

`define CONNECT_AXI4L_AW_IFV( port_prefix, if_prefix , if_suffix )          \
    .``port_prefix``awaddr          ( if_prefix``awaddr``if_suffix ),       \
    .``port_prefix``awvalid         ( if_prefix``awvalid``if_suffix ),      \
    .``port_prefix``awready         ( if_prefix``awready``if_suffix )

`define CONNECT_AXI4L_AW_IF( port_prefix , if_prefix )              \
    `CONNECT_AXI4L_AW_IFV( port_prefix, if_prefix, `NO_SUFFIX )

`define CONNECT_AXI4L_W_IFV( port_prefix, if_prefix , if_suffix )                       \
    .``port_prefix``wdata           ( if_prefix``wdata``if_suffix  ),                   \
    .``port_prefix``wvalid          ( if_prefix``wvalid``if_suffix  ),                  \
    .``port_prefix``wready          ( if_prefix``wready``if_suffix  ),                  \
    .``port_prefix``wstrb           ( if_prefix``wstrb``if_suffix  )

`define CONNECT_AXI4L_W_IF( port_prefix , if_prefix )               \
    `CONNECT_AXI4L_W_IFV( port_prefix, if_prefix, `NO_SUFFIX )

`define CONNECT_AXI4L_B_IFV( port_prefix, if_prefix , if_suffix)                        \
    .``port_prefix``bresp           ( if_prefix``bresp``if_suffix  ),                   \
    .``port_prefix``bvalid          ( if_prefix``bvalid``if_suffix  ),                  \
    .``port_prefix``bready          ( if_prefix``bready``if_suffix  )

`define CONNECT_AXI4L_B_IF( port_prefix, if_prefix )                            \
    `CONNECT_AXI4L_B_IFV( port_prefix, if_prefix, `NO_SUFFIX )
    
`define CONNECT_AXI4L_AR_IFV( port_prefix, if_prefix , if_suffix)                       \
    .``port_prefix``araddr          ( if_prefix``araddr``if_suffix  ),                  \
    .``port_prefix``arvalid         ( if_prefix``arvalid``if_suffix  ),                 \
    .``port_prefix``arready         ( if_prefix``arready``if_suffix  )

`define CONNECT_AXI4L_AR_IF( port_prefix, if_prefix )                           \
    `CONNECT_AXI4L_AR_IFV( port_prefix , if_prefix , `NO_SUFFIX )
    
`define CONNECT_AXI4L_R_IFV( port_prefix, if_prefix , if_suffix)                        \
    .``port_prefix``rdata           ( if_prefix``rdata``if_suffix  ),                   \
    .``port_prefix``rresp           ( if_prefix``rresp``if_suffix  ),                   \
    .``port_prefix``rvalid          ( if_prefix``rvalid``if_suffix  ),                  \
    .``port_prefix``rready          ( if_prefix``rready``if_suffix  )

`define CONNECT_AXI4L_R_IF( port_prefix , if_prefix )                           \
    `CONNECT_AXI4L_R_IFV( port_prefix , if_prefix, `NO_SUFFIX )

`define NAMED_PORTS_AXI4L_IF( port_prefix , address_width, data_width, fromhost_type , tohost_type )    \
    fromhost_type   [ address_width -1:0]   port_prefix``awaddr,                                        \
    fromhost_type                           port_prefix``awvalid,                                       \
    tohost_type                             port_prefix``awready,                                       \
    fromhost_type   [ data_width -1:0]      port_prefix``wdata,                                         \
    fromhost_type                           port_prefix``wvalid,                                        \
    tohost_type                             port_prefix``wready,                                        \
    fromhost_type   [( data_width /8)-1:0]  port_prefix``wstrb,                                         \
    tohost_type     [1:0]                   port_prefix``bresp,                                         \
    tohost_type                             port_prefix``bvalid,                                        \
    fromhost_type                           port_prefix``bready,                                        \
    fromhost_type   [ address_width -1:0]   port_prefix``araddr,                                        \
    fromhost_type                           port_prefix``arvalid,                                       \
    tohost_type                             port_prefix``arready,                                       \
    tohost_type     [ data_width -1:0]      port_prefix``rdata,                                         \
    tohost_type     [1:0]                   port_prefix``rresp,                                         \
    tohost_type                             port_prefix``rvalid,                                        \
    fromhost_type                           port_prefix``rready
 
 `define HOST_NAMED_PORTS_AXI4L_IF( port_prefix, address_width, data_width )    \
    `NAMED_PORTS_AXI4L_IF( port_prefix , address_width, data_width, output , input )
 `define TARGET_NAMED_PORTS_AXI4L_IF( port_prefix, address_width, data_width )    \
       `NAMED_PORTS_AXI4L_IF( port_prefix , address_width, data_width, input , output )
