ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VPKG.vhd
ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VCOMP.vhd
ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/primitive/*.vhd

ghdl -a ../../Common/inferred_rom.vhd

ghdl -a fractal_smooth_count.vhd

ghdl -a fractal_smooth_count_tb.vhd

ghdl -r fractal_smooth_count_tb --stop-time=1us --wave=fractal_smooth_count_tb.ghw

pause