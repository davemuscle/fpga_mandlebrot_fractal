ghdl -a --work=unisim C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VPKG.vhd
ghdl -a --work=unisim C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VCOMP.vhd
ghdl -a --work=unisim C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/primitive/MMCME2_ADV.vhd

ghdl -a squarer_32bit.vhd
ghdl -a squarer_tb.vhd
ghdl -r squarer_tb --stop-time=80us --wave=squarer.ghw

pause