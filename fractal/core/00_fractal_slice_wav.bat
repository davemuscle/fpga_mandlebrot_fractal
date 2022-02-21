ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VPKG.vhd
ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VCOMP.vhd
ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/primitive/*.vhd

ghdl -a ../../math/squarer_32bit.vhd
ghdl -a ../../math/inferred_dsp.vhd

ghdl -a ../fractal_pkg.vhd
ghdl -a fractal_slice.vhd
ghdl -a fractal_slice_tb.vhd

ghdl -r fractal_slice_tb --stop-time=5us --wave=fractal_slice_tb.ghw
pause
