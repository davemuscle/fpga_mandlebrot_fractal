library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
	
use work.fractal_pkg.all;
	
--Dave Muscle
--Datapath of the fractal core

entity fractal_datapath is
	generic(
		NUM_DSP_SLICES : integer := NUM_DSP_SLICES; -- how many slices should use all dsp units
		NUM_LUT_SLICES : integer := NUM_LUT_SLICES; -- how many slices should use my lut squarers
		NUM_SLICES     : integer := NUM_SLICES      -- the sum of the previous two
		);
	port(
		clk          : in  std_logic;                                -- fast clock
		escape       : in  std_logic_vector(QFORMAT_INT-1 downto 0); -- fractal parameters
		load         : in  std_logic;                                -- mux signal
		datapath_i   : in  fractal_slice_data;		                 -- fractal input data
		datapath_o   : out fractal_slice_data		                 -- fractal output data
        );
end fractal_datapath;

architecture arch of fractal_datapath is 

	--engine data
	type engine_data_t is array(0 to NUM_SLICES) of fractal_slice_data;
	signal engine_data : engine_data_t := (others => fractal_slice_data_init);
	

begin	
	
	--switch between looping back and inputting new data
	engine_data(0) <= datapath_i when load = '1' else engine_data(NUM_SLICES);
	
	--instantiate the fractal slices
	--instantiate fractal slices that use only dsp units for mults and squarers
	place_dsp_slices: if NUM_DSP_SLICES /= 0 generate
		place_dsp_slices_loop: for i in 0 to NUM_DSP_SLICES-1 generate
			fractal_slice_inst : entity work.fractal_slice
			generic map(
				USE_SQ_LOGIC  => 0
			)
			port map(
				clk          => clk,
				escape       => escape,
				slice_port_i => engine_data(i),
				slice_port_o => engine_data(i+1)
			);
			end generate place_dsp_slices_loop;
	end generate place_dsp_slices;
	
	--instantiate fractal slices that use dsp units for mults and luts for squarers
	place_lut_slices: if NUM_LUT_SLICES /= 0 generate
		place_lut_slices_loop: for i in 0 to NUM_LUT_SLICES-1 generate
			fractal_slice_inst : entity work.fractal_slice
			generic map(
				USE_SQ_LOGIC  => 1
			)
			port map(
				clk          => clk,
				escape       => escape,
				slice_port_i => engine_data(i+NUM_DSP_SLICES),
				slice_port_o => engine_data(i+1+NUM_DSP_SLICES)
			);
			end generate place_lut_slices_loop;
	end generate place_lut_slices;
	
	--assign the output
	datapath_o <= engine_data(NUM_SLICES);

end arch;
