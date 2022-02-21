ghdl -a --work=unisim C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VPKG.vhd
ghdl -a --work=unisim C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VCOMP.vhd
ghdl -a --work=unisim C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd

ghdl -a fp_mult.vhd

ghdl -a fp_mult_tb.vhd
ghdl -r fp_mult_tb --stop-time=5us --wave=fp_mult.ghw

pause