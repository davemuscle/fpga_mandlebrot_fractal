library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.math_real.all;

library unisim;
use unisim.vcomponents.all;

use work.fractal_pkg.all;

entity fractal_core_tb is 

end fractal_core_tb;

architecture test of fractal_core_tb is
    constant NUM_DSP_SLICES : integer := 2;
	constant NUM_LUT_SLICES : integer := 2;
	
	constant NUM_SLICES   : integer := NUM_DSP_SLICES+NUM_LUT_SLICES;   --number of slices to place in the pipe
	constant NUM_LOOPS    : integer := 8;   --number of times to send the same coord thru the pipe
	
	--for the engine, total pipe length
	constant TPL : integer := (SLICE_LATENCY)*(NUM_SLICES); --magic 4 determined from sim
	constant TPL_NP2 : integer := integer(ceil(log2(real(TPL))));
	
	
	
	signal locked, clkfb, clk_fb : std_logic := '0';
	signal clk_count : integer := 0;
	signal clk_100Mcount : integer := 0;
	signal clk_300Mcount : integer := 0;
	signal clk50M, clk100M, clk300M : std_logic := '0';

	signal engine_i, engine_o : fractal_slice_data := fractal_slice_data_init;

	signal load_en : std_logic := '0';
	signal load_start : std_logic := '0';
	signal load_finished : std_logic := '0';
	signal load_data, load_real, load_imag : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal load_cnt : integer := 0;
	
	signal input_real : real := -1.5;
	signal input_imag : real := -0.2;
	
	signal metadata : std_logic_vector(3 downto 0) := (others => '0');
	
	signal checker : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	
	signal checker_bad : std_logic := '0';
	
	signal coord_o_real_dly, coord_o_imag_dly : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal coord_o_real_dly2, coord_o_imag_dly2 : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

	signal clk_fb1 : std_logic := '0';
	
	signal checker_start : std_logic := '0';
	
	--upstream flow control status
	signal st_up_wr_addr       : std_logic_vector(TPL_NP2 downto 0);
	signal st_up_rd_addr       : std_logic_vector(TPL_NP2 downto 0);
	signal st_up_wr_en         : std_logic;
	signal st_up_rd_en         : std_logic;
	signal st_up_wr_buffer_sel : std_logic;
	signal st_up_rd_buffer_sel : std_logic;
	signal st_up_buffer_done   : std_logic;
	signal st_up_error         : std_logic;
	
	--downstream flow control status
	signal st_dn_wr_addr        : std_logic_vector(TPL_NP2 downto 0);
	signal st_dn_rd_addr        : std_logic_vector(TPL_NP2 downto 0);
	signal st_dn_wr_en          : std_logic;
	signal st_dn_rd_en          : std_logic;
	signal st_dn_wr_buffer_sel  : std_logic;
	signal st_dn_rd_buffer_sel  : std_logic;
	signal st_dn_buffer_done    : std_logic;
	signal st_dn_error          : std_logic;	
	
	signal metadly : std_logic := '0';
	
begin

	
    fractal_core_inst : entity work.fractal_core
	generic map(
		NUM_DSP_SLICES => NUM_DSP_SLICES,
		NUM_LUT_SLICES => NUM_LUT_SLICES,
		NUM_SLICES => NUM_SLICES,
		DATA_WIDTH => DATA_WIDTH,
		QFORMAT_INT => QFORMAT_INT,
		QFORMAT_FRAC => QFORMAT_FRAC,
		BRAM_LATENCY => BRAM_LATENCY,
		TPL => TPL,
		TPL_NP2 => TPL_NP2
	)
	port map(
		clk_pixel => clk100M,
		clk_core  => clk300M,
		escape    => x"04",
		enable    => load_en,
		core_port_i => engine_i,
		core_port_o => engine_o,
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

	mmcm_adv_inst: unisim.vcomponents.MMCME2_ADV
		generic map(
		  BANDWIDTH => "OPTIMIZED",
		  CLKFBOUT_MULT_F => 59.375000,
		  CLKFBOUT_PHASE => 0.000000,
		  CLKFBOUT_USE_FINE_PS => false,
		  CLKIN1_PERIOD => 20.000000,
		  CLKIN2_PERIOD => 0.000000,
		  CLKOUT0_DIVIDE_F => 2.5000000,
		  CLKOUT0_DUTY_CYCLE => 0.500000,
		  CLKOUT0_PHASE => 0.000000,
		  CLKOUT0_USE_FINE_PS => false,
		  CLKOUT1_DIVIDE => 20,
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
		  CLKFBIN => clk_fb,
		  CLKFBOUT => clk_fb,
		  CLKFBOUTB => open,
		  CLKFBSTOPPED => open,
		  CLKIN1 => clk50M,
		  CLKIN2 => '0',
		  CLKINSEL => '1',
		  CLKINSTOPPED => open,
		  CLKOUT0 => clk300M,
		  CLKOUT0B => open,
		  CLKOUT1 => clk100M,
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
	
	clk_stim : process
	begin
		clk50M <= '0';
		wait for 10 ns;
		clk50M <= '1';
		wait for 10 ns;
	end process;
	
	fill_bram : process(clk100M)
	begin
		if(clk100M'event and clk100M = '1') then
			clk_100Mcount <= clk_100Mcount + 1;
			if(clk_100Mcount = 20) then
				load_start <= '1';
			end if;
			if(load_start = '1') then
				load_en  <= '1';
			
				engine_i.metadata(0) <= '1';
				
				engine_i.coord_real <= std_logic_vector(unsigned(engine_i.coord_real)+1);
				engine_i.coord_imag <= std_logic_vector(unsigned(engine_i.coord_imag)+1);
			
			
			end if;
			
			coord_o_real_dly <= engine_o.coord_real;
			coord_o_imag_dly <= engine_o.coord_imag;
			
			coord_o_real_dly2 <= coord_o_real_dly;
			coord_o_imag_dly2 <= coord_o_imag_dly;
			
			metadly <= engine_o.metadata(0);
			
			if(engine_o.metadata(0) = '1' and metadly = '0') then
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

	

    process
    begin
  
	wait;
    
    end process;
    
end test;