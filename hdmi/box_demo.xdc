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
#set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets {clocking_inst/inst/clk_in1_clk_wiz_0}]
############## HDMIOUT define##################
set_property PACKAGE_PIN C4 [get_ports {TMDS_clk_n}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_clk_n}]
set_property PACKAGE_PIN D4 [get_ports {TMDS_clk_p}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_clk_p}]

set_property PACKAGE_PIN D1 [get_ports {TMDS_data_n[0]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_n[0]}]
set_property PACKAGE_PIN E1 [get_ports {TMDS_data_p[0]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_p[0]}]

set_property PACKAGE_PIN E2 [get_ports {TMDS_data_n[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_n[1]}]
set_property PACKAGE_PIN F2 [get_ports {TMDS_data_p[1]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_p[1]}]

set_property PACKAGE_PIN G1 [get_ports {TMDS_data_n[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_n[2]}]
set_property PACKAGE_PIN G2 [get_ports {TMDS_data_p[2]}]
set_property IOSTANDARD TMDS_33 [get_ports {TMDS_data_p[2]}]

set_property IOSTANDARD LVCMOS33 [get_ports led0]
set_property PACKAGE_PIN J6 [get_ports led0]

set_property PACKAGE_PIN H6 [get_ports led1]
set_property IOSTANDARD LVCMOS33 [get_ports led1]

set_property IOSTANDARD LVCMOS33 [get_ports key1]
set_property PACKAGE_PIN J8 [get_ports key1]
