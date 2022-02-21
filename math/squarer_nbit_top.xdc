# Chinese constraints lol
############## NET - IOSTANDARD ##################
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]
#############SPI Configurate Setting##################
#set_property BITSTREAM.CONFIG.SPI_BUSWIDTH 4 [current_design]
#set_property CONFIG_MODE SPIx4 [current_design]
#set_property BITSTREAM.CONFIG.CONFIGRATE 50 [current_design]
############## clock and reset define##################
create_clock -period 20.000 [get_ports clk50M]
set_property IOSTANDARD LVCMOS33 [get_ports clk50M]
set_property PACKAGE_PIN M22 [get_ports clk50M]
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {clk50M}]

set_property IOSTANDARD LVCMOS33 [get_ports led]
set_property PACKAGE_PIN G1 [get_ports led]