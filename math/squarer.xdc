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
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets clk50M]
############## HDMIOUT define##################

#This allows the VIO to be clocked at a lower rate so it doesn't fail timing
#set_property ASYNC_REG TRUE [get_cells {a_reg_i_reg[*] a_reg_o_reg[*]}]
#set_property ASYNC_REG TRUE [get_cells {b_reg_i_reg[*] b_reg_o_reg[*]}]
#set_max_delay -from [get_cells {a_reg_i_reg[*]}] -to [get_cells {a_reg_o_reg[*]}] 10
#set_max_delay -from [get_cells {b_reg_i_reg[*]}] -to [get_cells {b_reg_o_reg[*]}] 10

#set_false_path -from [get_pins {squarer_smart_inst/stg4_reg[*]/C}] -to [get_pins {bababee/inst/PROBE_IN_INST/probe_in_reg_reg[*]/D}]
#set_false_path -from [get_pins {bababee/inst/PROBE_OUT_ALL_INST/G_PROBE_OUT[0].PROBE_OUT0_INST/Probe_out_reg[*]/C}] -to [get_pins {squarer_smart_inst/a_reg_reg[*]/D}]