ghdl -a --work=unisim C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VPKG.vhd
ghdl -a --work=unisim C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VCOMP.vhd
ghdl -a --work=unisim C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd

ghdl -a clz_Q16_16.vhd
ghdl -a lod_4bit.vhd
ghdl -a fixed2float.vhd
ghdl -a float2fixed.vhd
ghdl -a fp_conv_tb.vhd
ghdl -r fp_conv_tb --stop-time=5us --wave=fp_conv.ghw

pause