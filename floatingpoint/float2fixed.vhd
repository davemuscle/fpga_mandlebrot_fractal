library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
	

entity float2fixed is
	port(
	    clk : in std_logic;
		fl  : in std_logic_vector(31 downto 0);
		fx  : out std_logic_vector(31 downto 0)
        );
end float2fixed;

architecture arch of float2fixed is 

	signal exp : std_logic_vector(8 downto 0) := (others => '0');
	signal mantissa : std_logic_vector(23 downto 0) := (others => '0');
	signal sign : std_logic := '0';
	
	signal exp_bias : std_logic_vector(8 downto 0) := (others => '0');
	
	signal exp_abs : std_logic_vector(8 downto 0) := (others => '0');
	
	signal dir : std_logic := '0'; -- 0 for left, 1 for right

	signal mantissa_ext : std_logic_vector(47 downto 0) := (others => '0');
	signal mantissa_shift : std_logic_vector(47 downto 0) := (others => '0');
	signal mantissa_final : std_logic_vector(31 downto 0) := (others => '0');

	signal fx_2scmp : std_logic_vector(31 downto 0) := (others => '0');
	
begin	

	exp <= '0' & fl(30 downto 23);
	mantissa <= '1' & fl(22 downto 0);
	sign <= fl(31);
	
	exp_bias <= std_logic_vector(signed(exp) - to_signed(127, exp_bias'length));


	process(exp_bias)
	begin
		if(exp_bias(8) = '0') then
			dir <= '0';
			exp_abs <= exp_bias;
		else
			dir <= '1';
			exp_abs <= std_logic_vector(signed(not exp_bias) + 1);
		end if;
	end process;

	mantissa_ext <= x"0000" & mantissa & x"00";
	
	process(exp_abs, dir, mantissa_ext)
	begin
		if(dir = '0') then
			mantissa_shift <= std_logic_vector(shift_left(unsigned(mantissa_ext), to_integer(signed(exp_abs))));
		else
			mantissa_shift <= std_logic_vector(shift_right(unsigned(mantissa_ext), to_integer(signed(exp_abs))));
		end if;
	end process;
	
	mantissa_final <= '0' & mantissa_shift(45 downto 15);
	
	fx_2scmp <= mantissa_final;
	
	process(sign, fx_2scmp)
	begin
	if(sign = '1') then
		fx <= std_logic_vector(signed(not fx_2scmp) + 1);
	else
		fx <= fx_2scmp;
	end if;
	end process;
	process(clk)
	begin
		if(clk'event and clk = '1') then

				

		end if;
	end process;

	
end arch;