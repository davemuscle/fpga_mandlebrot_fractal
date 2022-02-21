library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.math_real.all;

library unisim;
use unisim.vcomponents.all;

entity squarer_top is 
	port(
		clk50M : in std_logic
		
	);
end squarer_top;


architecture test of squarer_top is
	
	signal clk100M : std_logic := '0';
	signal locked, clkfb : std_logic := '0';
	
	COMPONENT vio_0
	  PORT (
		clk : IN STD_LOGIC;
		probe_in0 : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
		probe_out0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
	  );
	END COMPONENT;
	
	signal a : std_logic_vector(31 downto 0) := (others => '0');
	signal b : std_logic_vector(63 downto 0) := (others => '0');
	
	constant baba : integer := integer(ceil(log2(real(7))));
	
	signal a_reg_i, a_reg_o, a_reg_dly : std_logic_vector(31 downto 0) := (others => '0');
	signal b_reg_i, b_reg_o : std_logic_vector(63 downto 0) := (others => '0');
begin
	
    -- squarer_smart_inst : entity work.squarer_32bit
	-- generic map(
		-- N => 32
	-- )
	-- port map(
		-- clk => clk100M,
		-- a => a_reg_dly,
		-- p => b
	-- );

    squarer_smart_inst : entity work.squarer_32bit
	generic map(
		N => 32
	)
	port map(
		clk => clk100M,
		a => a,
		p => b
	);

	bababee : vio_0
	PORT MAP (
	clk => clk50M,
	probe_in0 => b,
	probe_out0 => a
	);
	
	-- process(clk50M)
	-- begin
		-- if(clk50M'event and clk50M = '1') then
			-- a_reg_i <= a;
			-- b_reg_o <= b_reg_i;
		-- end if;
	-- end process;
	
	-- process(clk100M)
	-- begin
		-- if(clk100M'event and clk100M = '1') then
			-- a_reg_o <= a_reg_i;
			-- a_reg_dly <= a_reg_o;
			-- b_reg_i <= b;
		-- end if;
	-- end process;	
	
	mmcm_adv_inst: unisim.vcomponents.MMCME2_ADV
	generic map(
	  BANDWIDTH => "OPTIMIZED",
	  CLKFBOUT_MULT_F => 17.7500,
	  CLKFBOUT_PHASE => 0.000000,
	  CLKFBOUT_USE_FINE_PS => false,
	  CLKIN1_PERIOD => 20.000000,
	  CLKIN2_PERIOD => 0.000000,
	  CLKOUT0_DIVIDE_F => 2.5000,
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
	  CLKOUT0 => clk100M,
	  CLKOUT0B => open,
	  CLKOUT1 => open,
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
	
    
end test;