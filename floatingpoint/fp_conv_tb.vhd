library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.math_real.all;

library unisim;
use unisim.vcomponents.all;

entity fp_conv_tb is 

end fp_conv_tb;

architecture test of fp_conv_tb is
	
	signal clk50M, clk100M, clk300M : std_logic := '0';
	signal locked, clkfb : std_logic := '0';
	signal clk_count : integer := 0;
	signal valid : std_logic := '0';
	
	signal a, b, c : std_logic_vector(31 downto 0) := (others => '0');
	signal a_f, b_f, c_f : real := 0.0;
	
	signal fx_in, fx_out, fl : std_logic_vector(31 downto 0) := (others => '0');
	
begin

	
    fixed2float_inst : entity work.fixed2float
	port map(
		clk => clk100M,
		fx   => fx_in,
		fl   => fl
	);
	
	float2fixed_inst : entity work.float2fixed
	port map(
		clk => clk100M,
		fl => fl,
		fx => fx_out
	);

	mmcm_adv_inst: unisim.vcomponents.MMCME2_ADV
		generic map(
		  BANDWIDTH => "OPTIMIZED",
		  CLKFBOUT_MULT_F => 18.000,
		  CLKFBOUT_PHASE => 0.000000,
		  CLKFBOUT_USE_FINE_PS => false,
		  CLKIN1_PERIOD => 20.000000,
		  CLKIN2_PERIOD => 0.000000,
		  CLKOUT0_DIVIDE_F => 9.000000,
		  CLKOUT0_DUTY_CYCLE => 0.500000,
		  CLKOUT0_PHASE => 0.000000,
		  CLKOUT0_USE_FINE_PS => false,
		  CLKOUT1_DIVIDE => 3,
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
	
	clk_stim : process
	begin
		clk50M <= '0';
		wait for 10 ns;
		clk50M <= '1';
		wait for 10 ns;
	end process;
	
	-- a <= std_logic_vector(to_signed(integer(a_f), a'length));
	-- b <= std_logic_vector(to_signed(integer(b_f), a'length));
	-- c <= std_logic_vector(to_signed(integer(c_f), a'length));
	process(clk100M)
	begin
		if(clk100M'event and clk100M = '1') then
			clk_count <= clk_count + 1;

				if(clk_count = 50) then
					fx_in <= x"000451EB"; --4.72 or something
				
			
				end if;
				
				if(clk_count = 51) then
					fx_in <= x"000011EB"; --0.07
					
		
				end if;
				
				if(clk_count = 52) then
					fx_in <= x"FFFFDD71"; -- -0.135
				end if;

			-- if(clk_count = 50) then
							
				-- a <= x"3fc00000"; -- 1.5
				-- b <= x"3f333333"; -- 0.7
				-- --c should be 3f866666 = 1.05
			-- end if;
			
			-- if(clk_count = 51) then
			
				-- a <= x"C1266666"; -- -10.4
				-- b <= x"40975C29"; -- 4.73
				-- --c should be 0xc244c49c = -49.192

			-- end if;
			
			-- if(clk_count = 52) then
				
				-- a <= x"B9B531A6"; -- -0.0003456
				-- b <= x"370006E5"; -- 0.000007631
				-- --c should be 0xB1353b68 = -0.0000000026372736
			-- end if;

			-- if(clk_count = 53) then
				-- a <= (others => '0');
				-- b <= (others => '0');
			
				-- clk_count <= 50;
			-- end if;
			
		end if;
	end process;
	
    process
    begin

	wait;
    
    end process;
    
end test;