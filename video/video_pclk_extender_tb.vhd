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
	
	signal pixel_a : std_logic_vector(9 downto 0) := (0 => '1', others => '0');
	signal pixel_b : std_logic_vector(9 downto 0) := (others => '0');
	
	signal metadata_a, metadata_b : std_logic_vector(3 downto 0) := (others => '0');
	signal clk_count : integer := -1;
	
	signal sof : std_logic := '0';
	signal eol : std_logic := '0';
	
	signal box_start : std_logic := '0';
	signal red_t, grn_t, blu_t : std_logic_vector(7 downto 0) := (others => '0');

begin

	process(clka)
	begin
		if(clka'event and clka = '1') then
		
			if(clk_count = 50) then
				box_start <= '1';		
			end if;
			
		end if;
	end process;
	
	video_box_demo : entity work.vga_box_demo
	port map(
		clk => clka,
		en => box_start,
		red => red_t,
		grn => grn_t,
		blu => blu_t,
		sof => sof
	);
	
    video_pclk_extender_inst : entity work.video_pclk_extender
	generic map(
		DEBUG => 0,
		DATA_WIDTH   => 8,
		META_WIDTH   => 4,
		SCALE_MULT   => 2,
		SCALE_DIV    => 1,
		SOF_BP       => 0,
		EOL_BP       => 1,
        h_active 	 => 1920,
		h_blanking   => 280,
        h_total      => 2200,
        v_active     => 540,
		v_blanking   => 23,
        v_total		 => 563
		
	)
	port map(
		clk_a => clka,
		pixel_a => red_t,
		metadata_a => metadata_a,
		
		clk_b => clkb,
		pixel_b => open,
		metadata_b => open,
		
		overflow => open,
		underflow => open
	);


    -- video_sync_gen_inst : entity work.video_sync_gen
	-- generic map(
		-- DATA_WIDTH   => 8,
		-- META_WIDTH   => 1,
		-- SYNC_POL_BP  => 1,
		-- SOF_BP       => 0,
		-- EOL_BP       => 1,
        -- h_active 	 => 4,
		-- h_frontporch => 0,
		-- h_syncwidth  => 1,
		-- h_backporch  => 0,
        -- h_total      => 5,
        -- v_active     => 4,
		-- v_frontporch => 0,
		-- v_syncwidth  => 1,
		-- v_backporch  => 0,
        -- v_total		 => 5
		
	-- )
	-- port map(
		-- clk => clkb,
		-- pixel_in => pixel_b,
		-- metadata_in => metadata_b(0 downto 0),
		-- hsync => open,
		-- vsync => open,
		-- hblank => open,
		-- vblank => open,
		-- de => open,
		-- pixel_out => open
	-- );

	-- mmcm_adv_inst: unisim.vcomponents.MMCME2_ADV
		-- generic map(
		  -- BANDWIDTH => "OPTIMIZED",
		  -- CLKFBOUT_MULT_F => 59.375,
		  -- CLKFBOUT_PHASE => 0.000000,
		  -- CLKFBOUT_USE_FINE_PS => false,
		  -- CLKIN1_PERIOD => 20.000000,
		  -- CLKIN2_PERIOD => 0.000000,
		  -- CLKOUT0_DIVIDE_F => 2.500000,
		  -- CLKOUT0_DUTY_CYCLE => 0.500000,
		  -- CLKOUT0_PHASE => 0.000000,
		  -- CLKOUT0_USE_FINE_PS => false,
		  -- CLKOUT1_DIVIDE => 3,
		  -- CLKOUT1_DUTY_CYCLE => 0.500000,
		  -- CLKOUT1_PHASE => 0.000000,
		  -- CLKOUT1_USE_FINE_PS => false,
		  -- CLKOUT2_DIVIDE => 1,
		  -- CLKOUT2_DUTY_CYCLE => 0.500000,
		  -- CLKOUT2_PHASE => 0.000000,
		  -- CLKOUT2_USE_FINE_PS => false,
		  -- CLKOUT3_DIVIDE => 1,
		  -- CLKOUT3_DUTY_CYCLE => 0.500000,
		  -- CLKOUT3_PHASE => 0.000000,
		  -- CLKOUT3_USE_FINE_PS => false,
		  -- CLKOUT4_CASCADE => false,
		  -- CLKOUT4_DIVIDE => 1,
		  -- CLKOUT4_DUTY_CYCLE => 0.500000,
		  -- CLKOUT4_PHASE => 0.000000,
		  -- CLKOUT4_USE_FINE_PS => false,
		  -- CLKOUT5_DIVIDE => 1,
		  -- CLKOUT5_DUTY_CYCLE => 0.500000,
		  -- CLKOUT5_PHASE => 0.000000,
		  -- CLKOUT5_USE_FINE_PS => false,
		  -- CLKOUT6_DIVIDE => 1,
		  -- CLKOUT6_DUTY_CYCLE => 0.500000,
		  -- CLKOUT6_PHASE => 0.000000,
		  -- CLKOUT6_USE_FINE_PS => false,
		  -- COMPENSATION => "ZHOLD",
		  -- DIVCLK_DIVIDE => 2,
		  -- IS_CLKINSEL_INVERTED => '0',
		  -- IS_PSEN_INVERTED => '0',
		  -- IS_PSINCDEC_INVERTED => '0',
		  -- IS_PWRDWN_INVERTED => '0',
		  -- IS_RST_INVERTED => '0',
		  -- REF_JITTER1 => 0.010000,
		  -- REF_JITTER2 => 0.010000,
		  -- SS_EN => "FALSE",
		  -- SS_MODE => "CENTER_HIGH",
		  -- SS_MOD_PERIOD => 10000,
		  -- STARTUP_WAIT => false
		-- )
			-- port map (
		  -- CLKFBIN => clkfb,
		  -- CLKFBOUT => clkfb,
		  -- CLKFBOUTB => open,
		  -- CLKFBSTOPPED => open,
		  -- CLKIN1 => clk50M,
		  -- CLKIN2 => '0',
		  -- CLKINSEL => '1',
		  -- CLKINSTOPPED => open,
		  -- CLKOUT0 => clkb,
		  -- CLKOUT0B => open,
		  -- CLKOUT1 => clka,
		  -- CLKOUT1B => open,
		  -- CLKOUT2  => open,
		  -- CLKOUT2B => open,
		  -- CLKOUT3  => open,
		  -- CLKOUT3B => open,
		  -- CLKOUT4  => open,
		  -- CLKOUT5  => open,
		  -- CLKOUT6  => open,
		  -- DADDR(6 downto 0) => b"0000000",
		  -- DCLK => '0',
		  -- DEN => '0',
		  -- DI(15 downto 0) => B"0000000000000000",
		  -- DO              => open,
		  -- DRDY => open,
		  -- DWE => '0',
		  -- LOCKED => open,
		  -- PSCLK => '0',
		  -- PSDONE => open,
		  -- PSEN => '0',
		  -- PSINCDEC => '0',
		  -- PWRDWN => '0',
		  -- RST => '0'
    -- );

	clk_gen_65_0 : process
	begin
		clka <= '0';
		wait for 0.6 ps;
		clka <= '1';
		wait for 0.6 ps;
		
	end process;

	clk_gen_65_1 : process
	begin
		clkb <= '0';
		wait for 0.5 ps;
		clkb <= '1';
		wait for 0.5 ps;
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
			
			-- eol <= '0';
			-- sof <= '0';
			
			-- if(clk_count = 0) then
				-- sof <= '1';
			-- end if;
			
			if(clk_count = (1920*540)-1) then
				clk_count <= 0;
			else
				clk_count <= clk_count + 1;
			end if;
			
			if(pixel_a = std_logic_vector(to_unsigned(7,10))) then
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