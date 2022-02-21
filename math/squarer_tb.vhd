library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.math_real.all;

-- library unisim;
-- use unisim.vcomponents.all;

entity squarer_tb is 

end squarer_tb;


architecture test of squarer_tb is
	
	signal clk50M, clk100M, clk300M : std_logic := '0';
	signal locked, clkfb : std_logic := '0';
	signal clk_count : integer := 0;
	signal valid : std_logic := '0';
	
	signal count_en : std_logic := '0';
	signal a : std_logic_vector(31 downto 0) := (others => '0');
	signal p_exp, p_act : std_logic_vector(63 downto 0) := (others => '0');
	signal p_xor : std_logic := '0';
	signal p_xor_latch : std_logic := '0';
	signal p_vec_xor : std_logic_vector(63 downto 0) := (others => '0');

	signal p_xor_smart : std_logic := '0';
	signal p_xor_smart_reg : std_logic := '0';
	
	constant smart_N : integer := 32;
	signal p_smart, p_smart_cmp : std_logic_vector(2*smart_N-1 downto 0) := (others => '0');
	signal p_exp_trimmed : std_logic_vector(31 downto 0) := (others => '0');
	signal p_act_trimmed : std_logic_vector(31 downto 0) := (others => '0');
	
	signal p_exp_int, p_act_int : integer;
	
	signal a_frac : std_logic_vector(7 downto 0) := (others => '0');
	signal a_int  : std_logic_vector(7 downto 0) := (others => '0');
	
	file out_act : text open write_mode is "out_act.txt";
	file out_exp : text open write_mode is "out_exp.txt";
	
	signal counter : std_logic_vector(14 downto 0) := (others => '0');

begin
	
    -- squarer_4bit_gates_inst : entity work.squarer_4bit_gates
	-- generic map(
		-- n => 4
	-- )
	-- port map(
		-- clk => clk50M,
		-- a => a,
		-- p => p_act
	-- );
	
    squarer_smart_inst : entity work.squarer_32bit
	generic map(
		N => smart_N
	)
	port map(
		clk => clk50M,
		a => a(31 downto 0),
		p => p_smart
	);
	

	-- mmcm_adv_inst: unisim.vcomponents.MMCME2_ADV
		-- generic map(
		  -- BANDWIDTH => "OPTIMIZED",
		  -- CLKFBOUT_MULT_F => 18.000,
		  -- CLKFBOUT_PHASE => 0.000000,
		  -- CLKFBOUT_USE_FINE_PS => false,
		  -- CLKIN1_PERIOD => 20.000000,
		  -- CLKIN2_PERIOD => 0.000000,
		  -- CLKOUT0_DIVIDE_F => 9.000000,
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
		  -- DIVCLK_DIVIDE => 1,
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
		  -- CLKOUT0 => clk100M,
		  -- CLKOUT0B => open,
		  -- CLKOUT1 => open,
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
		  -- LOCKED => locked,
		  -- PSCLK => '0',
		  -- PSDONE => open,
		  -- PSEN => '0',
		  -- PSINCDEC => '0',
		  -- PWRDWN => '0',
		  -- RST => '0'
    -- );
	
	clk_stim : process
	begin
		clk50M <= '0';
		wait for 1 ns;
		clk50M <= '1';
		wait for 1 ns;
	end process;

	process(clk50M)
		variable out_line : line;
	begin
		if(clk50M'event and clk50M = '1') then
			clk_count <= clk_count + 1;

			if(clk_count = 50) then
				count_en <= '1';
			end if;
			
			if(count_en = '1') then
				--a <= std_logic_vector(unsigned(a) + 1);
				a_frac <= std_logic_vector(unsigned(a_frac)+1);
				if(a_frac = x"FF") then
					a_frac <= (others => '0');
					if(a_int = x"0A") then
						report "Finished Sim" severity failure;
					else
						a_int <= std_logic_vector(unsigned(a_int)+1);
					end if;
				end if;

				
			end if;
			
			if(count_en = '1') then
				write(out_line, p_exp_int);
				writeline(out_exp, out_line);
				
				write(out_line, p_act_int);
				writeline(out_act, out_line);
			end if;
		end if;
	end process;
	
	-- p_exp <= std_logic_vector(unsigned(a)*unsigned(a));

	-- process(p_exp, p_act)
	-- begin
		-- if(p_exp /= p_act) then
			-- p_xor <= '1';
		-- else
			-- p_xor <= '0';
		-- end if;
		
		-- p_vec_xor <= p_exp xor p_act;
		
		
	-- end process;
	
	a <= a_int & a_frac & x"0000";
	
	p_smart_cmp <= std_logic_vector(unsigned(a(smart_N-1 downto 0))*unsigned(a(smart_N-1 downto 0)));
	p_exp_trimmed <= p_smart_cmp(55 downto 24);
	p_act_trimmed <= p_smart(55 downto 24);


	p_exp_int <= to_integer(unsigned(p_exp_trimmed));
	p_act_int <= to_integer(unsigned(p_act_trimmed));

	
	
	process(p_smart_cmp, p_smart)
	begin
		if(p_smart_cmp /= p_smart) then
			p_xor_smart <= '1';
		else
			p_xor_smart <= '0';
		end if;
	end process;
	
	process(clk50M)
	begin
		if(clk50M'event and clk50M = '1') then
			if(p_xor_smart = '1') then
				p_xor_smart_reg <= '1';
			end if;
		end if;
	end process;
	
    process
    begin

	wait;
    
    end process;
    
end test;