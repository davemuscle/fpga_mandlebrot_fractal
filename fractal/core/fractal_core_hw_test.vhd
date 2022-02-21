library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

use work.fractal_pkg.all;


entity fractal_core_hw_test is 
	port(
		clk50M : in  std_logic;
    	led0   : out std_logic;
		led1   : out std_logic;
		key1   : in  std_logic;
		key2   : in  std_logic;
		TMDS_clk_p  : out std_logic;
		TMDS_clk_n  : out std_logic;
		--2:0 are RGB (in order)
		TMDS_data_p : out std_logic_vector(2 downto 0);
		TMDS_data_n : out std_logic_vector(2 downto 0)
	);
end fractal_core_hw_test;

architecture test of fractal_core_hw_test is
    
	signal metadata_i : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	signal metadata_o : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	
	signal clk62M, clk74M : std_logic := '0';
	signal clk_core : std_logic := '0';
	signal clk148M, clk740M : std_logic := '0';

	signal locked_dly : std_logic_vector(31 downto 0) := (others => '1');

	signal hblank, vblank, hsync, vsync : std_logic := '0';

	signal core_i, core_o : fractal_slice_data := fractal_slice_data_init;
	signal load_en : std_logic := '0';
	
	signal core_coord_real_in, core_coord_imag_in : std_logic_vector(31 downto 0) := (others => '0');
	signal core_metadata_in : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	
	signal de : std_logic := '0';
	
	signal mmcm_main_fb, mmcm_main_locked : std_logic := '0';
	signal mmcm_core_fb, mmcm_core_locked : std_logic := '0';
	
	signal clk_count_start : integer := 0;
	signal start : std_logic := '0';
	
	--metadata flow:
	signal vid_ext_out_meta : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');	
	signal vid_deint_out_meta : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	signal vid_sync_gen_meta : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	
	--data flow:
	signal iter_count : std_logic_vector(9 downto 0) := (others => '0');
	signal vid_ext_out : std_logic_vector(11 downto 0) := (others => '0');
	signal vid_deint_out : std_logic_vector(11 downto 0) := (others => '0');
	signal vid_color_lut_out : std_logic_vector(23 downto 0) := (others => '0');
	signal vid_gblur_out : std_logic_vector(23 downto 0) := (others => '0');
	signal vid_sync_gen_in : std_logic_vector(23 downto 0) := (others => '0');
	signal vid_sync_gen_out : std_logic_vector(23 downto 0) := (others => '0');	
	signal vid_data : std_logic_vector(23 downto 0) := (others => '0');
	
	signal vid_color_lut_out_meta : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	signal vid_gblur_out_meta : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	
	signal smooth_o_int : std_logic_vector(9 downto 0) := (others => '0');
	signal smooth_o_frac : std_logic_vector(4 downto 0) := (others => '0');
	signal smooth_o : std_logic_vector(11 downto 0) := (others => '0');
	
	signal overflow, underflow : std_logic := '0';
	
	signal sof : std_logic := '0';
	
	
	signal pixel_count : integer := 0;
	
	signal h_count, v_count : integer := 0;
	signal h_count_slv, v_count_slv : std_logic_vector(31 downto 0) := (others => '0');
	
	signal start_core : std_logic := '0';
	
	signal key1_meta : std_logic := '0';
	signal key1_reg  : std_logic := '0';
	signal key1_dly  : std_logic := '0';
	signal key_release : std_logic := '0';
	signal key_count : integer := 0;
	signal key_en : std_logic := '0';
	
	signal key2_meta : std_logic := '0';
	signal key2_reg  : std_logic := '0';
	signal key2_dly  : std_logic := '0';
	signal key2_count : integer := 0;
	signal key2_en : std_logic := '0';
	

	
	signal smooth_passthrough : std_logic := '0';
	signal palette_select : integer := 0;
	
	COMPONENT ila_1
	PORT (
		clk : IN STD_LOGIC;
		probe0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe4 : IN STD_LOGIC_VECTOR( 3 DOWNTO 0); 
		probe5 : IN STD_LOGIC_VECTOR( 0 DOWNTO 0)
	);
	END COMPONENT  ;
	
	signal iter_ext : std_logic_vector(31 downto 0) := (others => '0');
	
	signal smooth_iter_ext : std_logic_vector(31 downto 0) := (others => '0');
	signal color_ext : std_logic_vector(31 downto 0) := (others => '0');
	
	signal gblur_enable : std_logic := '0';
	
	signal gblur_ext : std_logic_vector(31 downto 0) := (others => '0');
	
	signal scrn_q_o : std_logic_vector(31 downto 0) := (others => '0');
	signal scrn_i_o : std_logic_vector(31 downto 0) := (others => '0');
	signal step_q_o : std_logic_vector(31 downto 0) := (others => '0');
	signal step_i_o : std_logic_vector(31 downto 0) := (others => '0');
	
	COMPONENT zoom_pan_vio
	  PORT (
		clk : IN STD_LOGIC;
		probe_in0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		probe_in1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		probe_out0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		probe_out1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		probe_out2 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
		probe_out3 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
		probe_out4 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
		probe_out5 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
		probe_out6 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
		probe_out7 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
	  );
	END COMPONENT;
	
	signal zoom_step, pan_step : std_logic_vector(31 downto 0) := (others => '0');

	signal zoom_en : std_logic_vector(1 downto 0) := (others => '0');
	signal pan_en : std_logic_vector(3 downto 0)  := (others => '0');
	
	signal pan_l, pan_r, pan_u, pan_d, zoom_i, zoom_o : std_logic := '0';
	
	signal vsync_reg, hsync_reg, de_reg : std_logic := '0';
	
	signal fractal_sync_checker_v_count, fractal_sync_checker_h_count : std_logic_vector(31 downto 0) := (others => '0');
	signal fractal_sync_checker_error : std_logic := '0';

	COMPONENT sync_checker_ila
	PORT (
		clk : IN STD_LOGIC;
		probe0 : IN STD_LOGIC_VECTOR(3 DOWNTO 0); 
		probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
		probe2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
	END COMPONENT  ;
	
	signal core_i_iter_count_ext, core_o_iter_count_ext : std_logic_vector(31 downto 0);
	
	signal st_up_wr_addr, st_up_rd_addr : std_logic_vector(TPL_NP2 downto 0);
	signal st_dn_wr_addr, st_dn_rd_addr : std_logic_vector(TPL_NP2 downto 0);
	signal st_up_wr_addr_ext, st_up_rd_addr_ext : std_logic_vector(31 downto 0);
	signal st_dn_wr_addr_ext, st_dn_rd_addr_ext : std_logic_vector(31 downto 0);
	
	signal st_up_wr_en, st_up_rd_en : std_logic;
	signal st_dn_wr_en, st_dn_rd_en : std_logic;
	
	signal st_up_wr_buffer_sel, st_up_rd_buffer_sel : std_logic;
	signal st_dn_wr_buffer_sel, st_dn_rd_buffer_sel : std_logic;
	
	signal st_up_buffer_done, st_dn_buffer_done : std_logic;
	signal st_up_error, st_dn_error : std_logic;

	COMPONENT flowcontrol_ila
	PORT (
		clk     : IN STD_LOGIC;
		probe0  : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe1  : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe2  : IN STD_LOGIC_VECTOR( 0 DOWNTO 0); 
		probe3  : IN STD_LOGIC_VECTOR( 0 DOWNTO 0); 
		probe4  : IN STD_LOGIC_VECTOR( 0 DOWNTO 0); 
		probe5  : IN STD_LOGIC_VECTOR( 0 DOWNTO 0);
		probe6  : IN STD_LOGIC_VECTOR( 0 DOWNTO 0); 
		probe7  : IN STD_LOGIC_VECTOR( 0 DOWNTO 0);
		probe8  : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe9  : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe10 : IN STD_LOGIC_VECTOR( 0 DOWNTO 0); 
		probe11 : IN STD_LOGIC_VECTOR( 0 DOWNTO 0); 
		probe12 : IN STD_LOGIC_VECTOR( 0 DOWNTO 0); 
		probe13 : IN STD_LOGIC_VECTOR( 0 DOWNTO 0);
		probe14 : IN STD_LOGIC_VECTOR( 0 DOWNTO 0); 
		probe15 : IN STD_LOGIC_VECTOR( 0 DOWNTO 0)
		
	);
	END COMPONENT  ;
	
	signal clk50M_ibuf, clk50M_bufg : std_logic := '0';
	
	COMPONENT screen_setter_vio
	  PORT (
		clk : IN STD_LOGIC;
		probe_out0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		probe_out1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		probe_out2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		probe_out3 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
		
	  );
	END COMPONENT;
	
	signal metadly : std_logic := '0';
	signal coord_o_real_dly, coord_o_imag_dly : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal coord_o_real_dly2, coord_o_imag_dly2 : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal checker_start : std_logic := '0';	
	signal checker : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal checker_bad : std_logic := '0';	
	
begin

	process(clk62M)
	begin
		if(rising_edge(clk62M)) then
			key1_meta <= key1;
			key1_reg <= key1_meta;
			key1_dly <= key1_reg;
			
			key_count <= 0;
			
			if(key1_dly = '1' and key1_reg = '0') then
				key_en <= '1';
			end if;

			if(key_en = '1') then
				key_count <= key_count + 1;
				if(key_count = 40*(10**6)) then
					load_en <= '1';
					key_en <= '0';
				end if;
			end if;

		end if;
	end process;

	--test the core with counting data
	process(clk62M)
	begin
		if(clk62M'event and clk62M = '1') then

			if(load_en = '1') then
				start_core  <= '1';
			
				core_i.metadata(0) <= '1';
				
				core_i.coord_real <= std_logic_vector(unsigned(core_i.coord_real)+1);
				core_i.coord_imag <= std_logic_vector(unsigned(core_i.coord_imag)+1);
			
			
			end if;
			
			coord_o_real_dly <= core_o.coord_real;
			coord_o_imag_dly <= core_o.coord_imag;
			
			coord_o_real_dly2 <= coord_o_real_dly;
			coord_o_imag_dly2 <= coord_o_imag_dly;
			
			metadly <= core_o.metadata(0);
			
			if(core_o.metadata(0) = '1' and metadly = '0') then
				checker_start <= '1';
				assert false report "Checker Started" severity error;
			end if;
			
			if(checker_start = '1') then
				checker <= std_logic_vector(unsigned(checker)+1);
				if(checker /= coord_o_real_dly2) then
					checker_bad <= '1';
					assert false report "Checker Bad" severity error;
				end if;
				
				if(checker /= coord_o_imag_dly2) then
					checker_bad <= '1';
					assert false report "Checker Bad" severity error;
				end if;
			end if;
		end if;
	end process;

	--leds
	led0 <= not checker_start;
	led1 <= not checker_bad;

	--ila for test data
	ila_checker: ila_1
	PORT MAP (
		clk        => clk62M,
		probe0     => coord_o_real_dly2,
		probe1     => coord_o_imag_dly2,
		probe2     => checker,
		probe3     => (others => '0'),
		probe4     => (others => '0'),
		probe5(0)  => checker_bad

	);	
    fractal_core_inst : entity work.fractal_core
	generic map(
		NUM_DSP_SLICES => NUM_DSP_SLICES,
		NUM_LUT_SLICES => NUM_LUT_SLICES,
		NUM_SLICES   => NUM_SLICES,
		DATA_WIDTH   => DATA_WIDTH,
		QFORMAT_INT  => QFORMAT_INT,
		QFORMAT_FRAC => QFORMAT_FRAC,
		BRAM_LATENCY => BRAM_LATENCY,
		TPL          => TPL,
		TPL_NP2      => TPL_NP2,
		DRY_RUN      => 0
	)
	port map(
		clk_pixel           => clk62M,
		clk_core            => clk_core,
		escape              => x"04",
		enable              => start_core,
		core_port_i         => core_i,
		core_port_o         => core_o,
		st_up_wr_addr       => st_up_wr_addr,
		st_up_rd_addr       => st_up_rd_addr,
		st_up_wr_en         => st_up_wr_en,
		st_up_rd_en         => st_up_rd_en,
		st_up_wr_buffer_sel => st_up_wr_buffer_sel,
		st_up_rd_buffer_sel => st_up_rd_buffer_sel,
		st_up_buffer_done   => st_up_buffer_done,
		st_up_error         => st_up_error,
		st_dn_wr_addr       => st_dn_wr_addr,
		st_dn_rd_addr       => st_dn_rd_addr,
		st_dn_wr_en         => st_dn_wr_en,
		st_dn_rd_en         => st_dn_rd_en,
		st_dn_wr_buffer_sel => st_dn_wr_buffer_sel,
		st_dn_rd_buffer_sel => st_dn_rd_buffer_sel,
		st_dn_buffer_done   => st_dn_buffer_done,
		st_dn_error         => st_dn_error        
	);

	st_up_wr_addr_ext <= std_logic_vector(resize(unsigned(st_up_wr_addr),32));
	st_up_rd_addr_ext <= std_logic_vector(resize(unsigned(st_up_rd_addr),32));
	st_dn_wr_addr_ext <= std_logic_vector(resize(unsigned(st_dn_wr_addr),32));
	st_dn_rd_addr_ext <= std_logic_vector(resize(unsigned(st_dn_rd_addr),32));


	core_o_iter_count_ext <= std_logic_vector(resize(unsigned(core_o.iter_count),32));

	ila_fractal_output : ila_1
	PORT MAP (
		clk        => clk62M,
		probe0     => core_o_iter_count_ext,
		probe1     => core_o.coord_real,
		probe2     => core_o.coord_imag,
		probe3     => core_o.math_r,
		probe4     => core_o.metadata,
		probe5(0)  => core_o.lock

	);

	hdmi_if_inst : entity work.hdmi_if
	port map(
		pclk     => clk74M, 
		pclk5x   => clk740M, 
		rst      => '1',
		hsync    => '0',
		vsync    => '0',
		de       => '0',   
		video_in => (others => '0'),
		TMDS_clk_p  => TMDS_clk_p, 
		TMDS_clk_n  => TMDS_clk_n, 
		TMDS_data_p => TMDS_data_p,
		TMDS_data_n => TMDS_data_n
	);




	IBUF_inst : IBUF
	generic map(
		IBUF_LOW_PWR => FALSE,
		IOSTANDARD => "LVCMOS33"
	)
	port map(
		O => clk50M_ibuf,
		I => clk50M
	);
	
	BUFG_inst : BUFG
	port map(
		O => clk50M_bufg,
		I => clk50M_ibuf
	);
	
	mmcm_main_inst: unisim.vcomponents.MMCME2_ADV
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
		  CLKOUT2_DIVIDE => 2,
		  CLKOUT2_DUTY_CYCLE => 0.500000,
		  CLKOUT2_PHASE => 0.000000,
		  CLKOUT2_USE_FINE_PS => false,
		  CLKOUT3_DIVIDE => 2,
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
		  CLKFBIN => mmcm_main_fb,
		  CLKFBOUT => mmcm_main_fb,
		  CLKFBOUTB => open,
		  CLKFBSTOPPED => open,
		  CLKIN1 => clk50M_bufg,
		  CLKIN2 => '0',
		  CLKINSEL => '1',
		  CLKINSTOPPED => open,
		  CLKOUT0 => clk62M,
		  CLKOUT0B => open,
		  CLKOUT1 => clk74M,
		  CLKOUT1B => open,
		  CLKOUT2  => clk_core,
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
		  LOCKED => mmcm_main_locked,
		  PSCLK => '0',
		  PSDONE => open,
		  PSEN => '0',
		  PSINCDEC => '0',
		  PWRDWN => '0',
		  RST => '0'
    );

	
    
end test;