library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

--Inferred block RAM with output pipeline registers
--Can initialize with a textfile of bitvectors

entity inferred_tdpbram is
	generic(
		gDEPTH     : integer := 2;      --nextpow2 of BRAM length
		gWIDTH     : integer := 16;     --datawidth
		gOREGS     : integer := 2;      --number of input regs >= 1
		gINITFILE  : string             --string to init file
	);
	port(
		a_clk  : in  std_logic;
		a_wr   : in  std_logic;
		a_en   : in  std_logic;
		a_di   : in  std_logic_vector(gWIDTH-1 downto 0);
		a_do   : out std_logic_vector(gWIDTH-1 downto 0);
		a_addr : in  std_logic_vector(gDEPTH-1 downto 0);

        b_clk  : in  std_logic;
		b_wr   : in  std_logic;
		b_en   : in  std_logic;
		b_di   : in  std_logic_vector(gWIDTH-1 downto 0);
		b_do   : out std_logic_vector(gWIDTH-1 downto 0);
		b_addr : in  std_logic_vector(gDEPTH-1 downto 0)
	);
end inferred_tdpbram;

architecture bhv of inferred_tdpbram is 
    
	--ram type
    type ram_type is array ((2**gDEPTH)-1 downto 0) of bit_vector(gWIDTH-1 downto 0);

	--initializing RAM to text file or zeros
	impure function ram_init(filename : string) return ram_type is
	  file ram_file : text open read_mode is filename;
	  variable ram_line : line;
	  variable ram_value : bit_vector(63 downto 0);
	  variable temp : ram_type;
	  variable zeros : ram_type := (others => (others => '0'));
	begin
		for ram_index in 0 to 2**gDEPTH - 1 loop
			readline(ram_file, ram_line);
			read(ram_line, ram_value);
			temp(ram_index) := (ram_value);
		end loop;
		return temp;
	end function;
	
	--shared variable for bram
	shared variable bram : ram_type := ram_init(filename => gINITFILE);
	
	--pipelining registers
	type oregs_t is array(0 to gOREGS) of std_logic_vector(gWIDTH-1 downto 0);
	signal a_oregs : oregs_t := (others => (others => '0'));
	signal b_oregs : oregs_t := (others => (others => '0'));	
	
begin

    --port A
	process(a_clk)
	begin
		if(rising_edge(a_clk)) then	

			for i in 1 to gOREGS loop
				a_oregs(i) <= a_oregs(i-1);
			end loop;
		
			if(a_en = '1') then
				a_oregs(0) <= (to_StdLogicVector(bram(to_integer(unsigned(a_addr)))));
			end if;
			
			if(a_wr = '1') then
				bram(to_integer(unsigned(a_addr))) := to_BitVector(a_di);
			end if;
		end if;
	end process;

	--assign the output
	a_do <= a_oregs(gOREGS);

    --port B
	process(b_clk)
	begin
		if(rising_edge(b_clk)) then
		
			for i in 1 to gOREGS loop
				b_oregs(i) <= b_oregs(i-1);
			end loop;
		
			if(b_en = '1') then
				b_oregs(0) <= (to_StdLogicVector(bram(to_integer(unsigned(b_addr)))));
			end if;
			
			if(b_wr = '1') then
				bram(to_integer(unsigned(b_addr))) := to_BitVector(b_di);
			end if;
		end if;
	end process;
	
	--assign the output
	b_do <= b_oregs(gOREGS);

end bhv;		

