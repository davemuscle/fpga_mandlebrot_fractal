ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VPKG.vhd
ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VCOMP.vhd
ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/primitive/*.vhd

ghdl -a fractal_screen_gen.vhd

ghdl -a fractal_screen_gen_tb.vhd

ghdl -r fractal_screen_gen_tb --stop-time=10us --wave=fractal_screen_gen_tb.ghw

pause