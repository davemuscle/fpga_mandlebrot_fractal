library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
	

entity fp_mult is
	port(
		--clocking
	    clk      : in std_logic;
		
		a : in std_logic_vector(31 downto 0);
		b : in std_logic_vector(31 downto 0);
		c : out std_logic_vector(31 downto 0);
		
		a_o : out std_logic_vector(31 downto 0);
		b_o : out std_logic_vector(31 downto 0)
		
        );
end fp_mult;

architecture arch of fp_mult is 

	signal a_exp, b_exp, c_exp : std_logic_vector(8 downto 0) := (others => '0');
	signal a_sign1, b_sign1 : std_logic := '0';
	signal a_sign2, b_sign2 : std_logic := '0';
	signal a_sign, b_sign, c_sign : std_logic := '0';
	signal a_mantissa, b_mantissa : unsigned(23 downto 0) := (others => '0');
	signal c_mantissa : std_logic_vector(22 downto 0) := (others => '0');
	
	signal exp_sum1 : std_logic_vector(8 downto 0) := (others => '0');
	signal exp_sum2 : std_logic_vector(8 downto 0) := (others => '0');
	
	signal mantissa_mult : unsigned(47 downto 0) := (others => '0');
	signal mantissa_dly : std_logic_vector(22 downto 0) := (others => '0');
	signal mantissa_exp : std_logic_vector(1 downto 0) := (others => '0');
	
	signal a_dly1, b_dly1 : std_logic_vector(31 downto 0) := (others => '0');
	signal a_dly2, b_dly2 : std_logic_vector(31 downto 0) := (others => '0');
	signal a_dly3, b_dly3 : std_logic_vector(31 downto 0) := (others => '0');
	signal a_dly4, b_dly4 : std_logic_vector(31 downto 0) := (others => '0');
	
	signal err : std_logic := '0';

begin	

	process(clk)
	begin
		if(clk'event and clk = '1') then

				
			--clock one
			a_exp <= '0' & a(30 downto 23);
			b_exp <= '0' & b(30 downto 23);
			a_sign <= a(31);
			b_sign <= b(31);
			a_mantissa <= unsigned('1' & a(22 downto 0));
			b_mantissa <= unsigned('1' & b(22 downto 0));
			
			a_dly1 <= a;
			b_dly1 <= b;
			
			--clock two
			exp_sum1 <= std_logic_vector(signed(a_exp) + signed(b_exp));
			
			mantissa_mult <= a_mantissa * b_mantissa;
			
			a_sign1 <= a_sign;
			b_sign1 <= b_sign;
			
			a_dly2 <= a_dly1;
			b_dly2 <= b_dly1;
			
			--clock three
			--exp_sum2 <= std_logic_vector(signed(exp_sum1) + to_signed(-127, exp_sum2'length));
			exp_sum2 <= exp_sum1;
			
			mantissa_dly <= std_logic_vector(mantissa_mult(45 downto 23));
			mantissa_exp <= std_logic_vector(mantissa_mult(47 downto 46));
			
			a_sign2 <= a_sign1;
			b_sign2 <= b_sign1;
			
			a_dly3 <= a_dly2;
			b_dly3 <= b_dly2;
			
			--clock four
			--normalize
			
			if(mantissa_exp(1) = '1') then
				c_exp <= std_logic_vector(signed(exp_sum2) + to_signed(-126, c_exp'length));
				c_mantissa <= '0' & mantissa_dly(22 downto 1);
			else
				c_exp <= std_logic_vector(signed(exp_sum2) + to_signed(-127, c_exp'length));
				c_mantissa <= mantissa_dly;
			end if;

			
			c_sign <= a_sign2 xor b_sign2;
			
			a_dly4 <= a_dly3;
			b_dly4 <= b_dly3;
			
		end if;
	end process;

	c <= c_sign & c_exp(7 downto 0) & c_mantissa;
	
	a_o <= a_dly4;
	b_o <= b_dly4;
	
end arch;