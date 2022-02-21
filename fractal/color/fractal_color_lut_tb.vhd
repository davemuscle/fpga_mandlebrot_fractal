library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.math_real.all;

library unisim;
use unisim.vcomponents.all;

entity fractal_color_lut_tb is 

end fractal_color_lut_tb;

architecture test of fractal_color_lut_tb is
    
	constant ITER_WIDTH : integer := 10;
	constant NUM_COLORS : integer := 80;
	

	signal clk50M, clk_core, clk_pixel : std_logic := '0';

	signal metadata_o : std_logic_vector(0 downto 0) := (others => '0');
	
	signal metadata_i : std_logic_vector(0 downto 0) := (others => '0');
	
	signal clk_count : integer := 0;
	
	signal iter  : integer := 0;
	signal iter_slv : std_logic_vector(ITER_WIDTH-1 downto 0) := (others => '0');
	
	signal color : std_logic_vector(23 downto 0) := (others => '0');
	
begin

	fractal_color_lut_inst : entity work.fractal_color_lut
	generic map(
		ITER_WIDTH => ITER_WIDTH,
		COLOR_DEPTH => 8,
		META_WIDTH => 1,
		NUM_COLORS => NUM_COLORS,
		NUM_PALETTES => 2,
		INIT_FILE => "fractal_color_lut.data"
		)
	port map(
		clk => clk_pixel,
		palette_select => 0,
		metadata_i => metadata_i,
		iter_i => iter_slv,
		metadata_o => metadata_o,
		color_o => color
	);
	
	iter_slv <= std_logic_vector(to_unsigned(iter,iter_slv'length));
	
	process(clk_pixel)
	begin
		if(clk_pixel'event and clk_pixel = '1') then

			clk_count <= clk_count + 1;

			if(clk_count = 20) then
				metadata_i(0) <= '1';
				iter <= 0;
			else
				metadata_i(0) <= '0';
				iter <= iter + 1;
			end if;
			
			if(clk_count = 20+NUM_COLORS-1) then
				clk_count <= 20;
			end if;
			
		end if;
	end process;
	

	clk_stim : process
	begin
		clk50M <= '0';
		wait for 10 ns;
		clk50M <= '1';
		wait for 10 ns;
	end process;

	clk_pixel <= clk50M;

    process
    begin
  
	wait;

    end process;
    
end test;