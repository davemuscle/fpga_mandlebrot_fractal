ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VPKG.vhd
ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VCOMP.vhd
ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/primitive/*.vhd

ghdl -a ../../Common/bram_n_init.vhd


ghdl -a video_deinterlacer.vhd

ghdl -a video_deinterlacer_tb.vhd
ghdl -r video_deinterlacer_tb --stop-time=20us --vcd=video_deinterlacer_tb.vcd

pause