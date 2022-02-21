-- Code your design here
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity top is
	port(
    	clk50M : in std_logic;
    	
		TMDS_clk_p  : out std_logic;
		TMDS_clk_n  : out std_logic;
		--2:0 are RGB (in order)
		TMDS_data_p : out std_logic_vector(2 downto 0);
		TMDS_data_n : out std_logic_vector(2 downto 0)
        );
end top;

architecture str of top is 

	signal clk148M : std_logic := '0';
	signal clk740M : std_logic := '0';
	
	signal locked  : std_logic := '0';
	signal locked_dly : std_logic_vector(31 downto 0) := (others => '1'); --used for an active low reset
	
	signal hblank, vblank, hsync, vsync : std_logic := '0';
	signal hblank_pre, vblank_pre, hsync_pre, vsync_pre : std_logic := '0';
	signal hblank_dly, vblank_dly, hsync_dly, vsync_dly : std_logic_vector(2 downto 0) := (others => '0');
	
	signal red, grn, blu : std_logic_vector(7 downto 0) := (others => '0');
	signal de : std_logic := '0';

	signal video_data : std_logic_vector(23 downto 0) := (others => '0');
	
	-- component clk_wiz_0
	-- port
	 -- (-- Clock in ports
	  -- -- Clock out ports
	  -- clk_out1          : out    std_logic;
	  -- clk_out2          : out    std_logic;
	  -- -- Status and control signals
	  -- locked            : out    std_logic;
	  -- clk_in1           : in     std_logic
	 -- );
	-- end component;

	signal clkfb : std_logic := '0';

	begin
	
	--generates sync signals
  	vtc : entity work.vga_timing_gen
	port map(
		pclk => clk148M,
		hsync => open,
		hsync_n => hsync_pre,
		vsync => open,
		vsync_n => vsync_pre,
		hblank => hblank_pre,
		vblank => vblank_pre
	);

	--demo: of box moving around
	demo : entity work.vga_box_demo 
	port map(
		clk => clk148M,
		hblank => hblank_pre,
		vblank => vblank_pre,
		red => red,
		grn => grn,
		blu => blu
	);
	
	--delay the sync and blank signals by 3 clocks for the box demo
	process(clk148M)
	begin
		if(clk148M'event and clk148M = '1') then
			hblank_dly(0) <= hblank_pre;
			hblank_dly(2 downto 1) <= hblank_dly(1 downto 0);
			
			vblank_dly(0) <= vblank_pre;
			vblank_dly(2 downto 1) <= vblank_dly(1 downto 0);
			
			hsync_dly(0) <= hsync_pre;
			hsync_dly(2 downto 1) <= hsync_dly(1 downto 0);
			
			vsync_dly(0) <= vsync_pre;
			vsync_dly(2 downto 1) <= vsync_dly(1 downto 0);
		end if;
	end process;
	
	vsync <= vsync_dly(2);
	hsync <= hsync_dly(2);
	hblank <= hblank_dly(2);
	vblank <= vblank_dly(2);
	
	--active signal
	de <= not(hblank or vblank);

	process(clk148M)
	begin
		if(clk148M'event and clk148M = '1') then
			locked_dly(0) <= not locked;
			locked_dly(31 downto 1) <= locked_dly(30 downto 0);
		end if;
	end process;

	video_data(23 downto 16) <= red;
	video_data(15 downto  8) <= grn;
	video_data( 7 downto  0) <= blu;

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
	 
	mmcm_adv_inst: unisim.vcomponents.MMCME2_ADV
		generic map(
		  BANDWIDTH => "OPTIMIZED",
		  CLKFBOUT_MULT_F => 59.375000,
		  CLKFBOUT_PHASE => 0.000000,
		  CLKFBOUT_USE_FINE_PS => false,
		  CLKIN1_PERIOD => 20.000000,
		  CLKIN2_PERIOD => 0.000000,
		  CLKOUT0_DIVIDE_F => 5.000000,
		  CLKOUT0_DUTY_CYCLE => 0.500000,
		  CLKOUT0_PHASE => 0.000000,
		  CLKOUT0_USE_FINE_PS => false,
		  CLKOUT1_DIVIDE => 1,
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
		  DIVCLK_DIVIDE => 4,
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
		  CLKOUT0 => clk148M,
		  CLKOUT0B => open,
		  CLKOUT1 => clk740M,
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
		  LOCKED => locked,
		  PSCLK => '0',
		  PSDONE => open,
		  PSEN => '0',
		  PSINCDEC => '0',
		  PWRDWN => '0',
		  RST => '0'
    );

	
end str;