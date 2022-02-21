ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VPKG.vhd
ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VCOMP.vhd
ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/primitive/*.vhd

ghdl -a ../../Common/bram_n_init.vhd
ghdl -a ../../Common/sync_fifo_simple.vhd

ghdl -a fractal_pkg.vhd

ghdl -a fractal_flow_control.vhd

ghdl -a fractal_flow_control_tb.vhd
ghdl -r fractal_flow_control_tb --stop-time=10us --wave=fractal_flow_control_tb.ghw

pause