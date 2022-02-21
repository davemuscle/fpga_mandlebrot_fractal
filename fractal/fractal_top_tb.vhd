library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

library unisim;
use unisim.vcomponents.all;

use work.fractal_pkg.all;

entity fractal_top_tb is 

end fractal_top_tb;

architecture test of fractal_top_tb is

	signal clk50M : std_logic := '0';
	signal h_count, v_count : integer := 0;

	signal metadata_i : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	signal metadata_o : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	
	signal clk62M, clk74M : std_logic := '0';
	signal clk_core : std_logic := '0';
	signal clk148M, clk740M : std_logic := '0';

	--signal locked_dly : std_logic_vector(31 downto 0) := (others => '1');
	signal locked_dly : std_logic := '0';
	
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

	signal start_core : std_logic := '0';

	signal scrn_q_o : std_logic_vector(31 downto 0) := x"FE78FAE2";
	signal scrn_i_o : std_logic_vector(31 downto 0) := x"0007BC00";
	signal step_q_o : std_logic_vector(31 downto 0) := x"00000755";
	signal step_i_o : std_logic_vector(31 downto 0) := x"00000755";
	

	signal fractal_sync_checker_v_count, fractal_sync_checker_h_count : std_logic_vector(31 downto 0) := (others => '0');
	signal fractal_sync_checker_error : std_logic := '0';

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

	signal clk_count : integer := 0;
	
begin

	fractal_coord_gen_inst : entity work.fractal_coord_gen
	generic map(
		DATA_WIDTH   => DATA_WIDTH,
		META_WIDTH   => META_WIDTH,
		h_active     => 32,
		v_active     => 8
		)
	port map(
		clk           => clk62M,
		metadata_i    => metadata_i,
		screen_real_i => scrn_q_o,
		screen_imag_i => scrn_i_o,
		screen_step_x => step_q_o,
		screen_step_y => step_i_o,
		metadata_o    => core_metadata_in,
		coord_real_o  => core_coord_real_in,
		coord_imag_o  => core_coord_imag_in
	);
	
	process(clk62M)
	begin
		if(clk62M'event and clk62M = '1') then
			if(core_metadata_in(0) = '1') then
				start_core <= '1';
			end if;
			
			core_i.metadata   <= core_metadata_in;
			core_i.coord_real <= core_coord_real_in;
			core_i.coord_imag <= core_coord_imag_in;
			
		end if;
	end process;

    fractal_core_inst : entity work.fractal_core
	generic map(
		NUM_SLICES   => NUM_SLICES,
		NUM_LOOPS    => NUM_LOOPS,
		DATA_WIDTH   => DATA_WIDTH,
		QFORMAT_INT  => QFORMAT_INT,
		QFORMAT_FRAC => QFORMAT_FRAC,
		BRAM_LATENCY => BRAM_LATENCY,
		TPL          => TPL,
		TPL_NP2      => TPL_NP2
	)
	port map(
		clk_pixel           => clk62M,
		clk_core            => clk_core,
		escape              => x"0A",
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

	fractal_sync_checker_inst : entity work.fractal_sync_checker
	generic map(
		META_WIDTH   => META_WIDTH,
		h_active     => 32,
		v_active     => 8
		)
	port map(
		clk           => clk62M,
		metadata_i    => core_o.metadata,
		h_count_o     => fractal_sync_checker_h_count,
		v_count_o     => fractal_sync_checker_v_count,
		error_o       => fractal_sync_checker_error
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
		  CLKOUT2_DIVIDE => 3,
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
		  CLKIN1 => clk50M,
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

	clk_stim : process
	begin
		clk50M <= '0';
		wait for 10 ns;
		clk50M <= '1';
		wait for 10 ns;
	end process;
	
	process(clk62M)
	begin
		if(clk62M'event and clk62M = '1') then
			locked_dly <= mmcm_main_locked;
			
			if(locked_dly = '0' and mmcm_main_locked = '1') then
				metadata_i(0) <= '1';
			else
				metadata_i(0) <= '0';
			end if;
		end if;
	end process;

	

    process
    begin
  
	wait;
    
    end process;
    
end test;