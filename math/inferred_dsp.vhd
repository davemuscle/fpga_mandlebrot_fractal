library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
	
entity inferred_dsp is
	generic(
		DATA_WIDTH  : integer := 32;
		NUM_DSP_DLY : integer := 4
	);
	port(
	    clk : in  std_logic;
		a   : in  std_logic_vector(  DATA_WIDTH-1 downto 0);
		b   : in  std_logic_vector(  DATA_WIDTH-1 downto 0);
		m   : out std_logic_vector(2*DATA_WIDTH-1 downto 0)
        );
end inferred_dsp;

architecture arch of inferred_dsp is 

	--multiplier signals
	signal a_reg, b_reg : signed(  DATA_WIDTH-1 downto 0) := (others => '0');
	signal m_reg        : signed(2*DATA_WIDTH-1 downto 0) := (others => '0');

	--output pipelining
	--add pipelining until the registers dissapear from the netlist and are pulled into the DSP unit
	type p_reg_t is array(0 to NUM_DSP_DLY) of signed(2*DATA_WIDTH-1 downto 0); 
	signal p_reg : p_reg_t := (others => (others => '0'));
	
begin	
	process(clk)
	begin
		if(rising_edge(clk)) then
			--Inferred DSP unit
			---------------------------------
		
			--A and B input registers
			a_reg <= signed(a);
			b_reg <= signed(b);
			
			--Multiplication, MREG
			m_reg <= a_reg*b_reg;
			
			--Output pipelining
			p_reg(0) <= m_reg;
			
			--Extra pipelining registers
			--If there aren't enough registers on the output then a warning will get issued
			--while generating the bitstream, mentioning DSP performance
			--Increase the number of output registers until that warning goes away
			
			--Place extra registers on the output to be pulled into the DSP block
			for j in 1 to NUM_DSP_DLY loop
				p_reg(j) <= p_reg(j-1);
			end loop;
			
			--for NUM_DSP_DLY = 4:
				--p_reg(1)(i) <= p_reg(0)(i)
				--p_reg(2)(i) <= p_reg(1)(i)
				--p_reg(3)(i) <= p_reg(2)(i)
				--p_reg(4)(i) <= p_reg(3)(i)
			--------------------------------------
		end if;
	end process;
	
	--assign the output
	m <= std_logic_vector(p_reg(NUM_DSP_DLY));
	
end arch;