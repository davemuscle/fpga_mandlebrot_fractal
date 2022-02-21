library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

library unisim;
use unisim.vcomponents.all;


entity video_deinterlacer_tb is 

end video_deinterlacer_tb;

architecture test of video_deinterlacer_tb is
    
	constant DATA_WIDTH : integer := 32;
	
	signal clk50M, clka, clkb, clkfb : std_logic := '0';
	
	signal pixel_a : std_logic_vector(9 downto 0) := (0 => '1', others => '0');
	signal pixel_b : std_logic_vector(9 downto 0) := (others => '0');
	
	signal metadata_a, metadata_b : std_logic_vector(3 downto 0) := (others => '0');
	signal clk_count : integer := 0;
	
	signal sof : std_logic := '0';
	signal eol : std_logic := '0';
	
	signal box_start : std_logic := '0';
	signal red_t, grn_t, blu_t : std_logic_vector(7 downto 0) := (others => '0');
	signal en : std_logic := '0';

begin
	
    video_deinterlacer_inst : entity work.video_deinterlacer
	generic map(
		DATA_WIDTH   => 10,
		META_WIDTH   => 4,
		SOF_BP => 0,
		EOL_BP => 1,
		line_width => 8
		
	)
	port map(
		clk_a => clka,
		pixel_a => pixel_a,
		metadata_a => metadata_a,
		
		clk_b => clkb,
		pixel_b => pixel_b,
		metadata_b => metadata_b
	);

	clk_gen_65_0 : process
	begin
		clka <= '0';
		wait for 2 ns;
		clka <= '1';
		wait for 2 ns;
		
	end process;

	clk_gen_65_1 : process
	begin
		clkb <= '0';
		wait for 1 ns;
		clkb <= '1';
		wait for 1 ns;
	end process;

	clk_stim : process
	begin
		clk50M <= '0';
		wait for 10 ns;
		clk50M <= '1';
		wait for 10 ns;
	end process;
	
	metadata_a(0) <= sof;
	metadata_a(1) <= eol;
	
	process(clka)
	begin
		if(clka'event and clka = '1') then
			
			eol <= '0';
			sof <= '0';
			
			if(clk_count = 7) then
				clk_count <= 0;
				sof <= '1';
			else
				clk_count <= clk_count + 1;

				sof <= '0';
			end if;

			if(clk_count = 6) then
				eol <= '1';
			end if;

			if(pixel_a = "0000010000") then
				pixel_a <= (0 => '1', others => '0');
			else
				pixel_a <= std_logic_vector(unsigned(pixel_a)+1);
			end if;
	

		end if;
	end process;

    process
    begin
  
	wait;
    
    end process;
    
end test;