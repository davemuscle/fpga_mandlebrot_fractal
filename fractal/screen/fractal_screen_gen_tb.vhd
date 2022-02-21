library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.math_real.all;

library unisim;
use unisim.vcomponents.all;

entity fractal_screen_gen_tb is 

end fractal_screen_gen_tb;

architecture test of fractal_screen_gen_tb is
    
	signal clk50M : std_logic := '0';

	signal clk_count : integer := 0;

	signal metadata_o : std_logic_vector(0 downto 0) := (others => '0');
	
	signal sof : std_logic := '0';
	
	signal scrn_q_o : std_logic_vector(31 downto 0) := (others => '0');
	signal scrn_i_o : std_logic_vector(31 downto 0) := (others => '0');
	signal step_q_o : std_logic_vector(31 downto 0) := (others => '0');
	signal step_i_o : std_logic_vector(31 downto 0) := (others => '0');
	
	signal scrn_q : real := 0.0;
	signal scrn_i : real := 0.0;
	signal step_q : real := 0.0;
	signal step_i : real := 0.0;
	
	signal pan_en : std_logic_vector(3 downto 0) := (others => '0');
	signal pan_step : std_logic_vector(31 downto 0) := (others => '0');
	
begin

	fractal_screen_gen_inst : entity work.fractal_screen_gen
	generic map(
		SIM => 1,
		DATA_WIDTH => 32,
		QINT_WIDTH => 8,
		QFRAC_WIDTH => 24,
		META_WIDTH => 1,
		h_active => 1920,
		v_active => 540
		)
	port map(
		clk => clk50M,
		field_marker => sof,
		pan_en => pan_en,
		zoom_en => (others => '0'),
		pan_step => pan_step,
		zoom_step => (others => '0'),
		metadata_o => metadata_o,
		scrn_q_o => scrn_q_o,
		scrn_i_o => scrn_i_o,
		step_q_o => step_q_o,
		step_i_o => step_i_o
	);
	
	scrn_q <= real(to_integer(signed(scrn_q_o)))/real(2**24);
    scrn_i <= real(to_integer(signed(scrn_i_o)))/real(2**24);
	step_q <= real(to_integer(signed(step_q_o)))/real(2**24);
	step_i <= real(to_integer(signed(step_i_o)))/real(2**24);
	
	process(clk50M)
	begin
		if(clk50M'event and clk50M = '1') then

			clk_count <= clk_count + 1;
			sof <= '0';
			pan_step <= (others => '0');
			pan_en <= (others => '0');
			
			if(clk_count = 20) then
				sof <= '1';
			end if;

			if(clk_count = 30) then
				sof <= '1';
				pan_en <= "1000"; --down
				pan_step <= x"00000001";
			end if;


			if(clk_count = 50) then
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

    process
    begin
  
	wait;

    end process;
    
end test;