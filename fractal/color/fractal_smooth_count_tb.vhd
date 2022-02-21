library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.math_real.all;

library unisim;
use unisim.vcomponents.all;

entity fractal_smooth_count_tb is 

end fractal_smooth_count_tb;

architecture test of fractal_smooth_count_tb is
    
	constant ITER_WIDTH : integer := 10;
	constant NUM_COLORS : integer := 80;
	

	signal clk50M, clk_core, clk_pixel : std_logic := '0';

	signal clk_count : integer := 0;

	signal metadata_o : std_logic_vector(0 downto 0) := (others => '0');
	signal metadata_i : std_logic_vector(0 downto 0) := (others => '0');

	signal iter_i : std_logic_vector(9 downto 0) := (others => '0');
	signal rad_i  : std_logic_vector(7 downto 0) := (others => '0');
	signal smooth_o : std_logic_vector(14 downto 0) := (others => '0');

	signal lock : std_logic := '0';
	
	signal out_real : real := 0.0;
	
	signal smooth_o_int : std_logic_vector(9 downto 0) := (others => '0');
	signal smooth_o_frac : std_logic_vector(4 downto 0) := (others => '0');
	
	
begin

	fractal_smooth_count_inst : entity work.fractal_smooth_count
	generic map(
		ITER_WIDTH => ITER_WIDTH,
		RAD_WIDTH  => 8,
		META_WIDTH => 1,
		
		INT_WIDTH  => 3,
		FRAC_WIDTH => 5,
		


		INIT_FILE => "fractal_smooth_lut.data"
		)
	port map(
		clk => clk_pixel,
		passthrough => '0',
		lock_i => lock,
		metadata_i => metadata_i,
		iter_i => iter_i,
		rad_i => rad_i,
		metadata_o => metadata_o,
		smooth_o_int => smooth_o_int,
		smooth_o_frac => smooth_o_frac
	);
	
	smooth_o <= smooth_o_int & smooth_o_frac;
	
	out_real <= (real(to_integer(unsigned(smooth_o)))/real(2**5));
	process(clk_pixel)
	begin
		if(clk_pixel'event and clk_pixel = '1') then

			clk_count <= clk_count + 1;
			
			metadata_i <= (others => '0');
			rad_i <= (others => '0');
			iter_i <= (others => '0');
			lock <= '0';
			
			if(clk_count = 10) then
				lock <= '1';
				metadata_i(0) <= '1';
				rad_i <= std_logic_vector(to_unsigned(113-1,8));	
				iter_i <= std_logic_vector(to_unsigned(511,10));
			end if;
			
			if(clk_count = 11) then
				lock <= '0';
				rad_i <= std_logic_vector(to_unsigned(3-1,8));	
				iter_i <= std_logic_vector(to_unsigned(2,10));
			end if;
			
			
			if(clk_count = 20) then
				clk_count <= 10;
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