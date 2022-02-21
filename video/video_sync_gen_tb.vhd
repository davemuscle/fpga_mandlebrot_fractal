library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

library unisim;
use unisim.vcomponents.all;


entity video_pclk_extender_tb is 

end video_pclk_extender_tb;

architecture test of video_pclk_extender_tb is
    
	constant DATA_WIDTH : integer := 32;
	
	signal clk50M, clka, clkb, clkfb : std_logic := '0';
	
	signal pixel_a : std_logic_vector(7 downto 0) := (0 => '1', others => '0');
	signal pixel_b : std_logic_vector(7 downto 0) := (others => '0');
	
	signal metadata_a, metadata_b : std_logic_vector(3 downto 0) := (others => '0');
	signal clk_count : integer range 0 to 15 := 0;
	
	signal sof : std_logic := '0';
	signal eol : std_logic := '0';
	
begin

	
    video_pclk_extender_inst : entity work.video_pclk_extender
	generic map(
		DATA_WIDTH   => 8,
		META_WIDTH   => 4,
		SCALE        => 4,
		SOF_BP       => 0,
		EOL_BP       => 1,
        h_active 	 => 4,
		h_blanking   => 1,
        h_total      => 5,
        v_active     => 4,
		v_blanking   => 1,
        v_total		 => 5
		
	)
	port map(
		clk_a => clka,
		pixel_a => pixel_a,
		metadata_a => metadata_a,
		
		clk_b => clkb,
		pixel_b => pixel_b,
		metadata_b => metadata_b
	);

	mmcm_adv_inst: unisim.vcomponents.MMCME2_ADV
		generic map(
		  BANDWIDTH => "OPTIMIZED",
		  CLKFBOUT_MULT_F => 12.500,
		  CLKFBOUT_PHASE => 0.000000,
		  CLKFBOUT_USE_FINE_PS => false,
		  CLKIN1_PERIOD => 20.000000,
		  CLKIN2_PERIOD => 0.000000,
		  CLKOUT0_DIVIDE_F => 15.625000,
		  CLKOUT0_DUTY_CYCLE => 0.500000,
		  CLKOUT0_PHASE => 0.000000,
		  CLKOUT0_USE_FINE_PS => false,
		  CLKOUT1_DIVIDE => 10,
		  CLKOUT1_DUTY_CYCLE => 0.500000,
		  CLKOUT1_PHASE => 0.000000,
		  CLKOUT1_USE_FINE_PS => false,
		  CLKOUT2_DIVIDE => 1,
		  CLKOUT2_DUTY_CYCLE => 0.500000,
		  CLKOUT2_PHASE => 0.000000,
		  CLKOUT2_USE_FINE_PS => false,
		  CLKOUT3_DIVIDE => 1,
		  CLKOUT3_DUTY_CYCLE => 0.500000,
		  CLKOUT3_PHASE => 0.000000,
		  CLKOUT3_USE_FINE_PS => false,
		  CLKOUT4_CASCADE => false,
		  CLKOUT4_DIVIDE => 1,
		  CLKOUT4_DUTY_CYCLE => 0.500000,
		  CLKOUT4_PHASE => 0.000000,
		  CLKOUT4_USE_FINE_PS => false,
		  CLKOUT5_DIVIDE => 1,
		  CLKOUT5_DUTY_CYCLE => 0.500000,
		  CLKOUT5_PHASE => 0.000000,
		  CLKOUT5_USE_FINE_PS => false,
		  CLKOUT6_DIVIDE => 1,
		  CLKOUT6_DUTY_CYCLE => 0.500000,
		  CLKOUT6_PHASE => 0.000000,
		  CLKOUT6_USE_FINE_PS => false,
		  COMPENSATION => "ZHOLD",
		  DIVCLK_DIVIDE => 1,
		  IS_CLKINSEL_INVERTED => '0',
		  IS_PSEN_INVERTED => '0',
		  IS_PSINCDEC_INVERTED => '0',
		  IS_PWRDWN_INVERTED => '0',
		  IS_RST_INVERTED => '0',
		  REF_JITTER1 => 0.010000,
		  REF_JITTER2 => 0.010000,
		  SS_EN => "FALSE",
		  SS_MODE => "CENTER_HIGH",
		  SS_MOD_PERIOD => 10000,
		  STARTUP_WAIT => false
		)
			port map (
		  CLKFBIN => clkfb,
		  CLKFBOUT => clkfb,
		  CLKFBOUTB => open,
		  CLKFBSTOPPED => open,
		  CLKIN1 => clk50M,
		  CLKIN2 => '0',
		  CLKINSEL => '1',
		  CLKINSTOPPED => open,
		  CLKOUT0 => clka,
		  CLKOUT0B => open,
		  CLKOUT1 => clkb,
		  CLKOUT1B => open,
		  CLKOUT2  => open,
		  CLKOUT2B => open,
		  CLKOUT3  => open,
		  CLKOUT3B => open,
		  CLKOUT4  => open,
		  CLKOUT5  => open,
		  CLKOUT6  => open,
		  DADDR(6 downto 0) => b"0000000",
		  DCLK => '0',
		  DEN => '0',
		  DI(15 downto 0) => B"0000000000000000",
		  DO              => open,
		  DRDY => open,
		  DWE => '0',
		  LOCKED => open,
		  PSCLK => '0',
		  PSDONE => open,
		  PSEN => '0',
		  PSINCDEC => '0',
		  PWRDWN => '0',
		  RST => '0'
    );

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
			
			if(clk_count = 15) then
				clk_count <= 0;
			else
				clk_count <= clk_count + 1;
			end if;
			
			eol <= '0';
			sof <= '0';
			
			case clk_count is 
			when 15 => sof <= '1';
			when 10 => eol <= '1';
			when 6  => eol <= '1';
			when 2  => eol <= '1';
			when 14 => eol <= '1';
			when others => --do nothing
			end case;
			
			if(pixel_a = std_logic_vector(to_unsigned(16,8))) then
				pixel_a <= (0 => '1', others => '0');
			else
				pixel_a <= std_logic_vector(unsigned(pixel_a) + 1);
			end if;
			
		end if;
	end process;

    process
    begin
  
	wait;
    
    end process;
    
end test;