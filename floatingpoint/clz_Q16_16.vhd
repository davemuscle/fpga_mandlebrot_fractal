library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
	
--compute leading zeros in a 32 bit number, Q16_16 format

--outputs the unbiased floating point exponent as 5 bit signed

entity clz_Q16_16 is
	port(
		b : in std_logic_vector(31 downto 0);
		lz : out std_logic_vector(4 downto 0)
    );
end clz_Q16_16;

architecture arch of clz_Q16_16 is 

begin	
	process(b)
	begin
		case b is 
			when x"80000000" => lz <= "01111";
			when x"40000000" => lz <= "01110";
			when x"20000000" => lz <= "01101";
			when x"10000000" => lz <= "01100";
			when x"08000000" => lz <= "01011";
			when x"04000000" => lz <= "01010";
			when x"02000000" => lz <= "01001";
			when x"01000000" => lz <= "01000";
			when x"00800000" => lz <= "00111";
			when x"00400000" => lz <= "00110";
			when x"00200000" => lz <= "00101";
			when x"00100000" => lz <= "00100";
			when x"00080000" => lz <= "00011";
			when x"00040000" => lz <= "00010";
			when x"00020000" => lz <= "00001";
			when x"00010000" => lz <= "00000";
			when x"00008000" => lz <= "11111";
			when x"00004000" => lz <= "11110";
			when x"00002000" => lz <= "11101";
			when x"00001000" => lz <= "11100";
			when x"00000800" => lz <= "11011";
			when x"00000400" => lz <= "11010";
			when x"00000200" => lz <= "11001";
			when x"00000100" => lz <= "11000";
			when x"00000080" => lz <= "10111";
			when x"00000040" => lz <= "10110";
			when x"00000020" => lz <= "10101";
			when x"00000010" => lz <= "10100";
			when x"00000008" => lz <= "10011";
			when x"00000004" => lz <= "10010";
			when x"00000002" => lz <= "10001";
			when x"00000001" => lz <= "10000";
			when others      => lz <= "00000";
		end case;
	end process;
	
end arch;