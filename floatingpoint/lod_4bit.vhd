library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
	
--4 bit leading ones detector

entity lod_4bit is
	port(
		c : in std_logic; --carry
		B : in std_logic_vector(3 downto 0); --input vector
		L : out std_logic_vector(3 downto 0); --output vector
		v : out std_logic --output carry
    );
end lod_4bit;

architecture arch of lod_4bit is 

	signal cB : std_logic_vector(4 downto 0) := (others => '0');

begin	

	cB <= c & B;

	process(cB)
	begin
		case cB is 
			when "00000" => L <= "0000"; v <= '0';
			when "00001" => L <= "0001"; v <= '1';
			when "00010" => L <= "0010"; v <= '1';
			when "00011" => L <= "0010"; v <= '1';
			when "00100" => L <= "0100"; v <= '1';
			when "00101" => L <= "0100"; v <= '1';
			when "00110" => L <= "0100"; v <= '1';
			when "00111" => L <= "0100"; v <= '1';
			when "01000" => L <= "1000"; v <= '1';
			when "01001" => L <= "1000"; v <= '1';
			when "01010" => L <= "1000"; v <= '1';
			when "01011" => L <= "1000"; v <= '1';
			when "01100" => L <= "1000"; v <= '1';
			when "01101" => L <= "1000"; v <= '1';
			when "01110" => L <= "1000"; v <= '1';
			when "01111" => L <= "1000"; v <= '1';
			when others  => L <= "0000"; v <= '1';
		end case;
	end process;
	
end arch;