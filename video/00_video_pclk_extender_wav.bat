ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VPKG.vhd
ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/unisim_VCOMP.vhd
ghdl -a --work=unisim --ieee=synopsys -fexplicit C:/Xilinx/Vivado/2017.4/data/vhdl/src/unisims/primitive/*.vhd

ghdl -a ../../Common/bram_n_init.vhd
ghdl -a ../../Common/sync_fifo_simple.vhd


ghdl -a ../hdmi/vga_timing_gen_pkg.vhd
ghdl -a vga_color_bars_interlaced.vhd

ghdl -a video_pclk_extender.vhd
ghdl -a video_sync_gen.vhd

ghdl -a video_pclk_extender_tb.vhd
ghdl -r video_pclk_extender_tb --stop-time=20us --vcd=video_pclk_extender_tb.vcd

pause