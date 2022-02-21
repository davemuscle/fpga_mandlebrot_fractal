-- Code your design here
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity top is
	port(
    	clk50M : in std_logic;
    	led0 : out std_logic;
		led1 : out std_logic;
		key1 : in std_logic;
		TMDS_clk_p  : out std_logic;
		TMDS_clk_n  : out std_logic;
		--2:0 are RGB (in order)
		TMDS_data_p : out std_logic_vector(2 downto 0);
		TMDS_data_n : out std_logic_vector(2 downto 0)
        );
end top;

architecture str of top is 

	signal clk62M : std_logic := '0';
	signal clk74M : std_logic := '0';
	signal clk148M : std_logic := '0';
	signal clk740M : std_logic := '0';
	
	signal locked  : std_logic := '0';
	signal locked_dly : std_logic_vector(31 downto 0) := (others => '1'); --used for an active low reset
	
	signal red, grn, blu : std_logic_vector(7 downto 0) := (others => '0');
	signal red_t, grn_t, blu_t : std_logic_vector(7 downto 0) := (others => '0');
	signal de : std_logic := '0';

	signal video_data : std_logic_vector(23 downto 0) := (others => '0');

	signal clkfb : std_logic := '0';

	signal video_count : integer := 0;
	signal sof : std_logic_vector(0 downto 0) := (others => '0');
	
	signal vid_sync_gen_in : std_logic_vector(23 downto 0) := (others => '0');
	signal vid_sync_gen_meta : std_logic_vector(0 downto 0) := (others => '0');
	
	signal hsync, vsync : std_logic := '0';
	
	signal vid_in : std_logic_vector(23 downto 0) := (others => '0');
	signal box_start : std_logic := '0';
	signal box_start_reg : std_logic := '0';
	signal box_start_dly : std_logic := '0';
	
	signal overflow, underflow : std_Logic := '0';
	
	signal pclk_count : integer := 0;
	
	signal vid_sync_gen_sig : std_logic_vector(23 downto 0) := (others => '0');
	signal vid_ext_out : std_logic_vector(23 downto 0) := (others => '0');
	signal vid_ext_out_meta : std_logic_vector(0 downto 0) := (others => '0');
	
begin
	
	
	process(clk62M)
	begin
		if(clk62M'event and clk62M = '1') then
		
			if(pclk_count = 50) then
				box_start <= '1';		
			end if;
			
			pclk_count <= pclk_count + 1;
			
			-- if(key1 = '0') then
				-- box_start <= '1';
			-- end if;
			
			
		end if;
	end process;
	
	video_box_demo : entity work.vga_box_demo
	generic map(
		h_active => 1920,
		v_active => 540
	)
	port map(
		clk => clk62M,
		en => box_start,
		red => red_t,
		grn => grn_t,
		blu => blu_t,
		sof => sof(0)
	);
	
	vid_in <= red_t & grn_t & blu_t;
	
    video_pclk_extender_inst : entity work.video_pclk_extender
	generic map(
		DEBUG => 1,
		DATA_WIDTH   => 8,
		META_WIDTH   => 1,
		SCALE_MULT   => 1,
		SCALE_DIV    => 1,
		SOF_BP       => 0,
		EOL_BP       => 1,
        h_active 	 => 1920,
		h_blanking   => 240,
        h_total      => 2160,
        v_active     => 540,
		v_blanking   => 36,
        v_total		 => 576
		
	)
	port map(
		clk_a => clk62M,
		pixel_a => vid_in(23 downto 16),
		metadata_a => sof,
		
		clk_b => clk74M,
		pixel_b => vid_ext_out(23 downto 16),
		metadata_b => vid_ext_out_meta,
		
		overflow => overflow,
		underflow => underflow
	);
	
	-- led0 <= not box_start;
	-- led1 <= key1;
	led0 <= not overflow;
	led1 <= not underflow;
	
	-- video_box_demo2 : entity work.vga_box_demo
	-- generic map(
		-- h_active => 2160,
		-- v_active => 576
	-- )
	-- port map(
		-- clk => clk74M,
		-- en => '1',
		-- red => vid_ext_out(23 downto 16),
		-- grn => open,
		-- blu => open,
		-- sof => vid_ext_out_meta(0)
	-- );
	
	-- --deinterlacer
    video_deinterlacer_inst : entity work.video_deinterlacer
	generic map(
		DATA_WIDTH   => 8,
		META_WIDTH   => 1,
		SOF_BP       => 0,
		EOL_BP       => 1,
        line_width   => 2160
		
	)
	port map(
		clk_a => clk74M,
		pixel_a => vid_ext_out(23 downto 16),
		metadata_a => vid_ext_out_meta,
		
		clk_b => clk148M,
		pixel_b => vid_sync_gen_in(23 downto 16),
		metadata_b => vid_sync_gen_meta
	);	

	
	-- --deinterlacer
    -- video_deinterlacer_inst : entity work.video_deinterlacer
	-- generic map(
		-- DATA_WIDTH   => 8,
		-- META_WIDTH   => 1,
		-- SOF_BP       => 0,
		-- EOL_BP       => 1,
        -- line_width   => 2200
		
	-- )
	-- port map(
		-- clk_a => clk74M,
		-- pixel_a => vid_ext_out(23 downto 16),
		-- metadata_a => vid_ext_out_meta,
		
		-- clk_b => clk148M,
		-- pixel_b => vid_sync_gen_in(23 downto 16),
		-- metadata_b => vid_sync_gen_meta
	-- );	

	-- video_box_demo2 : entity work.vga_box_demo
	-- generic map(
		-- h_active => 2160,
		-- v_active => 1152
	-- )
	-- port map(
		-- clk => clk148M,
		-- en => '1',
		-- red => vid_sync_gen_in(23 downto 16),
		-- grn => open,
		-- blu => open,
		-- sof => vid_sync_gen_meta(0)
	-- );
	
	--sync marker generation
    video_sync_gen_inst : entity work.video_sync_gen
	generic map(
		-- DATA_WIDTH   => 8,
		-- META_WIDTH   => 1,
		-- SYNC_POL_BP  => 1,
		-- SOF_BP       => 0,
		-- EOL_BP       => 1,
        -- h_active 	 => 1920,
		-- h_frontporch => 88,
		-- h_syncwidth  => 44,
		-- h_backporch  => 148,
        -- h_total      => 2200,
        -- v_active     => 1080,
		-- v_frontporch => 4,
		-- v_syncwidth  => 5,
		-- v_backporch  => 37,
        -- v_total		 => 1126
		DATA_WIDTH   => 8,
		META_WIDTH   => 1,
		SYNC_POL_BP  => 1,
		SOF_BP       => 0,
		EOL_BP       => 1,
        h_active 	 => 1920,
		h_frontporch => 76,
		h_syncwidth  => 36,
		h_backporch  => 128,
        h_total      => 2160,
        v_active     => 1080,
		v_frontporch => 6,
		v_syncwidth  => 8,
		v_backporch  => 58,
        v_total		 => 1152
		
	)
	port map(
		clk => clk148M,
		pixel_in => vid_sync_gen_in(23 downto 16),
		metadata_in => vid_sync_gen_meta,
		hsync => hsync,
		vsync => vsync,
		hblank => open,
		vblank => open,
		de => de,
		pixel_out => video_data(23 downto 16)
	);

	process(clk148M)
	begin
		if(clk148M'event and clk148M = '1') then
			locked_dly(0) <= not locked;
			locked_dly(31 downto 1) <= locked_dly(30 downto 0);
		end if;
	end process;

	hdmi_if_inst : entity work.hdmi_if
	port map(
		pclk     => clk148M, 
		pclk5x   => clk740M, 
		rst      => locked_dly(31),
		hsync    => hsync,
		vsync    => vsync,
		de       => de,   
		video_in => video_data,
		TMDS_clk_p  => TMDS_clk_p, 
		TMDS_clk_n  => TMDS_clk_n, 
		TMDS_data_p => TMDS_data_p,
		TMDS_data_n => TMDS_data_n
	);


	mmcm_adv_inst: unisim.vcomponents.MMCME2_ADV
		generic map(
		  BANDWIDTH => "OPTIMIZED",
		  CLKFBOUT_MULT_F => 29.875000,
		  CLKFBOUT_PHASE => 0.000000,
		  CLKFBOUT_USE_FINE_PS => false,
		  CLKIN1_PERIOD => 20.000000,
		  CLKIN2_PERIOD => 0.000000,
		  CLKOUT0_DIVIDE_F => 12.00000,
		  CLKOUT0_DUTY_CYCLE => 0.500000,
		  CLKOUT0_PHASE => 0.000000,
		  CLKOUT0_USE_FINE_PS => false,
		  CLKOUT1_DIVIDE => 10,
		  CLKOUT1_DUTY_CYCLE => 0.500000,
		  CLKOUT1_PHASE => 0.000000,
		  CLKOUT1_USE_FINE_PS => false,
		  CLKOUT2_DIVIDE => 5,
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
		  DIVCLK_DIVIDE => 2,
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
		  CLKOUT0 => clk62M,
		  CLKOUT0B => open,
		  CLKOUT1 => clk74M,
		  CLKOUT1B => open,
		  CLKOUT2  => clk148M,
		  CLKOUT2B => open,
		  CLKOUT3  => clk740M,
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
		  LOCKED => locked,
		  PSCLK => '0',
		  PSDONE => open,
		  PSEN => '0',
		  PSINCDEC => '0',
		  PWRDWN => '0',
		  RST => '0'
    );


	-- --clock wizard
	-- clocking_inst : clk_wiz_0
	   -- port map ( 
	  -- -- Clock out ports  
	   -- clk_out1 => clk148M,
	   -- clk_out2 => clk740M,
	  -- -- Status and control signals                
	   -- locked => locked,
	   -- -- Clock in ports
	   -- clk_in1 => clk50M
	-- );
	
end str;