library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
	
--Dave Muscle
--6/7/20

--Simple DFF

entity dff is
	generic(
		DATA_WIDTH : integer := 32
		);
	port(
		clk : in  std_logic;
		d   : in  std_logic_vector(DATA_WIDTH-1 downto 0);
		q   : out std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0')

        );
end dff;

architecture arch of dff is 
	
begin
	
	process(clk)
	begin
		if(rising_edge(clk)) then
			q <= d;
		end if;
	end process;
	
end arch;
