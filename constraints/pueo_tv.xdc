set_property BITSTREAM.GENERAL.COMPRESS TRUE [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]

set_false_path -through [get_nets -hier *coeff_data*]

set axiclk [get_clocks clk_pl_0]
set axiclk_net [get_nets -of_objects $axiclk]
set aclk [get_clocks clk_out1_ps_base_adc0_clk_wiz_0_2]
set aclk_net [get_nets -of_objects $aclk]
set memclk [get_clocks clk_out2_ps_base_adc0_clk_wiz_0_2]
set memclk_net [get_nets -of_objects $aclk]
set syncclk [get_clocks clk_out3_ps_base_adc0_clk_wiz_0_2]
set syncclk_net [get_nets -of_objects $syncclk]

set_property CLOCK_DELAY_GROUP ADC_CLKS $aclk_net
set_property CLOCK_DELAY_GROUP ADC_CLKS $memclk_net
set_property CLOCK_DELAY_GROUP ADC_CLKS $syncclk_net

set aclk_period [get_property PERIOD $aclk]
set memclk_period [get_property PERIOD $memclk]

set_max_delay -datapath_only -from $axiclk -to $aclk 10.00
set_max_delay -datapath_only -from $aclk -to $axiclk 10.00

set uram_areset [get_cells -hier -filter { NAME=~ *u_uram/aclk_reset* && PRIMITIVE_TYPE =~ REGISTER*}]
set uram_reset [get_cells -hier -filter { NAME=~ *u_uram/write_reset* && PRIMITIVE_TYPE =~ REGISTER*}]
set uram_run [get_cells -hier -filter { NAME=~ *u_uram/write_run* && PRIMITIVE_TYPE =~ REGISTER*}]
set uram_addr [get_cells -hier -filter { NAME=~ *u_uram/write_addr* && PRIMITIVE_TYPE =~ REGISTER*}]

# This just groups the whole things at first. Later we'll repartition buffer_data
# into 6 different groups so we can specifically call out all of the delays properly.
# Doing that with regexps isn't easy.
set uram_buffer_data [get_cells -hier -filter { NAME=~ *u_uram/buffer_data* && PRIMITIVE_TYPE =~ REGISTER*}]
set uram_write_data [get_cells -hier -filter { NAME=~ *u_uram/write_data* && PRIMITIVE_TYPE =~ REGISTER*}]

## These are the multicycle paths in memclk domain
#set_multicycle_path 2 -setup -from $uram_reset -to $uram_run
#set_multicycle_path 2 -setup -from $uram_reset -to $uram_addr
## if you set this to 4, Vivado goes apeshit
#set_multicycle_path 2 -setup -from $uram_addr -to $uram_addr

# These are the cross-clock paths from aclk->memclk
# Let's *first* try just using the tightest constraint, at clk1. Which is 6 ticks, or 2x memclk periods
# Note "datapath" is not here, we *have* to handle the clock skew.
# Also I need to figure out WTF I do with "min_delay" here. Technically for a normal
# clock the max delay is 1 clock, the min delay is 0 (full setup/hold).
# But I don't know if that's actually true here, I think the "min_delay" is actually *negative*
# if I properly do it. By a *lot*. Because none of this data changes except once every 4 clock periods.

# The *minimum* setup time is 6 ticks (2x memclk period)
set_max_delay -from $uram_buffer_data -to $uram_write_data [expr 2*$memclk_period]
# The *maximum* hold time is 1 ticks (1/3x memclk period)
set_min_delay -from $uram_buffer_data -to $uram_write_data [expr -1*$memclk_period/3.]

# this *works* but is stupid
#set_multicycle_path -setup 2 -end -from $uram_buffer_data -to $uram_write_data
#set_multicycle_path -hold 1 -end -from $uram_buffer_data -to $uram_write_data

# reset cross-path
set_max_delay -from $uram_areset -to $uram_reset [expr 2*$memclk_period]
set_min_delay -from $uram_areset -to $uram_reset [expr -2*$memclk_period]

