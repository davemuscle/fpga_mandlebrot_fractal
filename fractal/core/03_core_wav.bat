ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VPKG.vhd
ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VCOMP.vhd
ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/primitive/*.vhd

ghdl -a ../../../Common/bram_n_init.vhd

ghdl -a ../../math/squarer_32bit.vhd
ghdl -a ../../math/inferred_dsp.vhd

ghdl -a ../fractal_pkg.vhd
ghdl -a fractal_slice.vhd
ghdl -a fractal_datapath.vhd

ghdl -a fractal_flow_control.vhd
ghdl -a fractal_core.vhd

ghdl -a fractal_core_tb.vhd
ghdl -r fractal_core_tb --stop-time=20us --wave=fractal_core_tb.ghw

pause