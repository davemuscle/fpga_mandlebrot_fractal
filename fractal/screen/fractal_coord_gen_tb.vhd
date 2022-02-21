library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.math_real.all;

library unisim;
use unisim.vcomponents.all;

entity fractal_coord_gen_tb is 

end fractal_coord_gen_tb;

architecture test of fractal_coord_gen_tb is
    
	constant DATA_WIDTH : integer := 32;

	signal clk_fb, locked : std_logic := '0';
	signal locked_dly : std_logic_vector(31 downto 0) := (others => '1');

	signal clk50M, clk_core, clk_pixel : std_logic := '0';

	signal metadata_o : std_logic_vector(3 downto 0) := (others => '0');
	signal coord_real_o, coord_imag_o : std_logic_vector(7 downto 0) := (others => '0');

	signal x_loc, y_loc : std_logic_vector(7 downto 0) := x"10";

	signal load_en : std_logic := '0';

	signal done : std_logic := '0';
	
	signal metadata_i : std_logic_vector(3 downto 0) := (others => '0');
	
	signal clk_count : integer := 0;
	
begin

	fractal_coord_gen_inst : entity work.fractal_coord_gen
	generic map(
		DATA_WIDTH   => 8,
		META_WIDTH   => 4,
		h_active     => 8,
		v_active     => 4
		)
	port map(
		clk => clk_pixel,
		
		metadata_i => metadata_i,
		
		screen_real_i => x_loc,
		screen_imag_i => y_loc,
		
		screen_step_x => x"01",
		screen_step_y => x"01",
		
		metadata_o => metadata_o,
		
		coord_real_o => coord_real_o,
		coord_imag_o => coord_imag_o
	);
	
	process(clk_pixel)
	begin
		if(clk_pixel'event and clk_pixel = '1') then

			clk_count <= clk_count + 1;

			if(clk_count = 20) then
				metadata_i(0) <= '1';
				x_loc <= std_logic_vector(signed(x_loc) + 1);
				y_loc <= std_logic_vector(signed(y_loc) - 1);
			else
				metadata_i(0) <= '0';
			end if;
			
			if(clk_count = 51) then
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