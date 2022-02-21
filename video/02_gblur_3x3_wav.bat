ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VPKG.vhd
ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VCOMP.vhd
ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/primitive/*.vhd

ghdl -a ../../Common/bram_n_init.vhd


ghdl -a gblur_3x3.vhd

ghdl -a gblur_3x3_tb.vhd
ghdl -r gblur_3x3_tb --stop-time=100us --wave=gblur_3x3_tb.ghw

pause