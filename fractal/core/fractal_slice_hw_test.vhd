library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

library unisim;
use unisim.vcomponents.all;

use work.fractal_pkg.all;

entity fractal_slice_hw_test is 
port(
	clk50M : in std_logic
);
end fractal_slice_hw_test;

architecture test of fractal_slice_hw_test is
    
	constant META_WIDTH   : integer := 1;
	constant DATA_WIDTH   : integer := 32;
	constant QFORMAT_FRAC : integer := 24;
	constant QFORMAT_INT  : integer := 8;
	
	signal clkfb : std_logic := '0';
	signal locked : std_logic := '0';

	signal clk100M : std_logic := '0';

	signal slice_i, slice_o : fractal_slice_data := fractal_slice_data_init;

	signal clk_count : integer := 0;
	
	signal clk50M_ibuf, clk50M_bufg : std_logic := '0';

	
	COMPONENT fractal_slice_hw_test_ila

	PORT (
		clk : IN STD_LOGIC;
		probe0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe4 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe5 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe6 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe7 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe8 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe9 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe10 : IN STD_LOGIC_VECTOR(9 DOWNTO 0); 
		probe11 : IN STD_LOGIC_VECTOR(9 DOWNTO 0); 
		probe12 : IN STD_LOGIC_VECTOR(3 DOWNTO 0); 
		probe13 : IN STD_LOGIC_VECTOR(3 DOWNTO 0); 
		probe14 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
		probe15 : IN STD_LOGIC_VECTOR(0 DOWNTO 0)
	);
	END COMPONENT  ;
	
begin

	
    fractal_slice_inst : entity work.fractal_slice
	generic map(
		DATA_WIDTH   => DATA_WIDTH,
		QFORMAT_INT  => QFORMAT_INT,
		QFORMAT_FRAC => QFORMAT_FRAC,
		SLICE_LATENCY => SLICE_LATENCY,
		USE_SQ_LOGIC => 1
	)
	port map(
		--clocking
	    clk      => clk100M,
		escape  => x"04",
		slice_port_i => slice_i,
		slice_port_o => slice_o

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
	
	mmcm_adv_inst: unisim.vcomponents.MMCME2_ADV
		generic map(
		  BANDWIDTH => "OPTIMIZED",
		  CLKFBOUT_MULT_F => 29.875000,
		  CLKFBOUT_PHASE => 0.000000,
		  CLKFBOUT_USE_FINE_PS => false,
		  CLKIN1_PERIOD => 20.000000,
		  CLKIN2_PERIOD => 0.000000,
		  CLKOUT0_DIVIDE_F => 2.000000,
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
		  CLKIN1 => clk50M_bufg,
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
	
	ila : fractal_slice_hw_test_ila
		PORT MAP(
		clk => clk100M,
		probe0  => slice_i.math_x, 
		probe1  => slice_i.math_y, 
		probe2  => slice_i.math_r, 
		probe3  => slice_o.math_x,
		probe4  => slice_o.math_y,
		probe5  => slice_o.math_r,
		probe6  => slice_i.coord_real, 
		probe7  => slice_i.coord_imag, 
		probe8  => slice_o.coord_real, 
		probe9  => slice_o.coord_imag, 
		probe10 => slice_i.iter_count, 
		probe11 => slice_o.iter_count, 
		probe12 => (others => '0'),
		probe13 => (others => '0'),
		probe14(0) => slice_i.lock,
		probe15(0) => slice_o.lock
		);
	
	--mirrors the testbench stimulus
	process(clk100M)
	begin
		if(clk100M'event and clk100M = '1') then
			slice_i <= fractal_slice_data_init;
			
			clk_count <= clk_count + 1;
			
			if(clk_count = 50) then
				--test the escape radius
				slice_i.math_x <= x"02000000";
				slice_i.math_y <= x"03000000";
				slice_i.math_r <= x"05000000";
				slice_i.metadata <= "0101";
				
				--test the coordinate delay
				slice_i.coord_real <= x"00000001";
				slice_i.coord_imag <= x"00000001";
				
				--looking for:
				--coordinate data, math data delayed
				--lock signal high
				--no change in the iteration count

			end if;
			
			if(clk_count = 51) then
				--test the incoming lock signal
				slice_i.lock <= '1';
				
				slice_i.math_x <= x"07000000";
				slice_i.math_y <= x"08000000";
				slice_i.math_r <= x"01000000";
				slice_i.metadata <= "1";
				
				--test the coordinate delay
				slice_i.coord_real <= x"00000002";
				slice_i.coord_imag <= x"00000003";
				
				slice_i.iter_count <= "0000000011";
				
				--looking for:
				--coordinate data, math data delayed
				--lock signal delayed
				--no change in iteration count
			end if;
			
			if(clk_count = 52) then
				--test the math
				slice_i.math_x <= x"04000000";
				slice_i.math_y <= x"05000000";
				slice_i.coord_real <= x"01000000";
				slice_i.coord_imag <= x"01000000";
				
				slice_i.metadata <= "1";
				--inputs:
					--x = 4
					--y = 5
					--c_real = 1
					--c_imag = 1
				--outputs:
					--x_next = x*x - y*y + c_real = 16 - 25 + 1 = -8
					--y_next = 2*x*y + c_imag = 40+1 = 41
					--r = x*x + y*y = 16+25 = 41
				
				slice_i.iter_count <= "0000000101";
				--the iteration should also increase
				
			end if;
			
			if(clk_count = 53) then
				--test the math again
				slice_i.math_x <= x"00600000"; -- 0.375 -> x^2 = 0.140625
				slice_i.math_y <= x"FFFCC000"; --  -0.0127 -> y^2 = 0.00016129
				slice_i.coord_real <= x"02000000"; -- 2
				slice_i.coord_imag <= x"01000000"; -- 1
				
				--x^2 - y^2 = 0x000023F5
				--2xy = 0xFFFFFD90
				
				slice_i.metadata <= "1";
				
				slice_i.iter_count <= "0000000110";
				
			end if;
			
			if(clk_count = 54) then
				slice_i.metadata <= "1";
				clk_count <= 50;
			end if;
			
			
		end if;
	end process;

end test;