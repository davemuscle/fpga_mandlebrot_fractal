library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
	

entity fixed2float is
	generic(
		NUM_LOD4_STAGES : integer := 8;
		DATA_WIDTH   : integer := 32;
		QFORMAT_FRAC : integer := 16;
		QFORMAT_INT  : integer := 16
	);
	port(
	    clk : in std_logic;
		fx  : in std_logic_vector(31 downto 0);
		fl  : out std_logic_vector(31 downto 0)
        );
end fixed2float;

architecture arch of fixed2float is 

	signal carry : std_logic_vector(DATA_WIDTH downto 0) := (others => '0');

	signal input : std_logic_vector(31 downto 0) := (others => '0');

	signal lod : std_logic_vector(31 downto 0) := (others => '0');
	signal lz : std_logic_vector(4 downto 0) := (others => '0');
	signal lz_n : std_logic_vector(4 downto 0) := (others => '0');
	signal lz_2scmp : std_logic_vector(4 downto 0) := (others => '0');
	signal exp : std_logic_vector(7 downto 0) := (others => '0');
	
	signal a_shift : std_logic_vector(31 downto 0) := (others => '0');
	signal mantissa : std_logic_vector(22 downto 0) := (others => '0');
	
	signal sign : std_logic := '0';
	
	signal dir : std_logic := '0';

begin	

	process(fx)
	begin
		if(signed(fx) < 0) then
			input <= std_logic_vector(signed(not fx) + 1);
		else
			input <= fx;
		end if;
	end process;

	carry(0) <= '0';

	--instantiate LOD4 array to calculate leading one of fixed point number
	GEN_LOD:
	for i in 1 to NUM_LOD4_STAGES generate
	
		lod4_inst : entity work.lod_4bit
		port map(
			c => carry(i-1),
			B => input((NUM_LOD4_STAGES-i+1)*4 - 1 downto (NUM_LOD4_STAGES-i)*4),
			L => lod((NUM_LOD4_STAGES-i+1)*4 - 1 downto (NUM_LOD4_STAGES-i)*4),
			v => carry(i)
		);
	
	end generate GEN_LOD;
	
	--count the zeros in the lod
	clz_inst : entity work.clz_Q16_16
	port map(
		b  => lod,
		lz => lz
	);
	
	--get the exponent by adding the bias
	exp <= std_logic_vector(signed(lz) + to_signed(127, exp'length));
	process(lz)
	begin
		lz_2scmp <= std_logic_vector(signed(not lz) + 1);
	end process;

	--shift the integer
	process(lz, input, lz_2scmp)
	begin
		if(signed(lz) >= 0) then
			a_shift <= std_logic_vector(shift_right(unsigned(input), to_integer(unsigned(lz))));
			dir <= '0';
		else
			a_shift <= std_logic_vector(shift_left(unsigned(input), to_integer(unsigned(lz_2scmp))));
			dir <= '1';
		end if;
	end process;

	mantissa <= a_shift(15 downto 0) & "0000000";

	sign <= fx(31);

	fl <= sign & exp & mantissa;

	process(clk)
	begin
		if(clk'event and clk = '1') then

	
		end if;
	end process;
	
end arch;