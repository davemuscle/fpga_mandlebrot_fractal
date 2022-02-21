library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Simple Synchronous FIFO that uses block ram

entity sync_fifo_simple is
	generic(
		gDEPTH     : integer := 2;      --nextpow2 of BRAM length
		gLENGTH    : integer := 4;      --length of fifo
		gWIDTH     : integer := 16;     --datawidth
		gOREGS     : integer := 2;       --number of input regs >= 1
		prog_full  : integer := 10;
		prog_empty : integer := 10

	);
	port(
		clk       : in std_logic;
		
		full      : out std_logic := '0';
		empty     : out std_logic := '1';
		af        : out std_logic := '0';
		ae        : out std_logic := '1';
		pf        : out std_logic := '0';
		pe        : out std_logic := '1';
		overflow  : out std_logic := '0';
		underflow : out std_logic := '0';
		overflow_s : out std_logic := '0';
		underflow_s : out std_logic := '0';
		
		fifo_count_o : out std_logic_vector(31 downto 0);
		
		wr_en     : in std_logic;
		wr_data   : in std_logic_vector(gWIDTH-1 downto 0);
		
		rd_en     : in std_logic;
		rd_data   : out std_logic_vector(gWIDTH-1 downto 0)
		
	);
end sync_fifo_simple;

architecture bhv of sync_fifo_simple is 
    
	signal wr_addr : std_logic_vector(gDEPTH-1 downto 0) := (others => '0');
	signal rd_addr : std_logic_vector(gDEPTH-1 downto 0) := (others => '0');
	
	signal fifo_count : integer range 0 to gLENGTH-1 := 0;

	signal overflow_int, underflow_int : std_logic := '0';
	signal overflow_int_s, underflow_int_s : std_logic := '0';
	

begin

	process(clk)
	begin
		if(rising_edge(clk)) then
		
			if(fifo_count = gLENGTH-1) then
				full <= '1';
				af <= '1';
				ae <= '0';
				empty <= '0';
				pf <= '1';
				pe <= '0';
			elsif(fifo_count = 0) then
				full <= '0';
				empty <= '1';
				ae <= '1';
				af <= '0';
				pf <= '0';
				pe <= '1';
			elsif(fifo_count < 4) then
				full <= '0';
				ae <= '1';
				empty <= '0';
				af <= '0';
				pf <= '0';
				pe <= '0';
			elsif(fifo_count >= gLENGTH-4) then
				af <= '1';
				full <= '0';
				ae <= '0';
				empty <= '0';
				pf <= '1';
				pe <= '0';
			elsif(fifo_count >= prog_full) then
				af <= '0';
				full <= '0';
				ae <= '0';
				empty <= '0';
				pf <= '1';
				pe <= '0';
			elsif(fifo_count < prog_empty) then
				af <= '0';
				full <= '0';
				ae <= '0';
				empty <= '0';
				pf <= '0';
				pe <= '1';
			else
				full <= '0';
				empty <= '0';
				af <= '0';
				ae <= '0';
				pf <= '0';
				pe <= '0';
			end if;
		
			if(wr_en = '1') then
				if(wr_addr = std_logic_vector(to_unsigned(gLENGTH-1, wr_addr'length))) then
					wr_addr <= (others => '0');
				else
					wr_addr <= std_logic_vector(unsigned(wr_addr)+1);
				end if;
			end if;
			
			if(rd_en = '1') then
				if(rd_addr = std_logic_vector(to_unsigned(gLENGTH-1, rd_addr'length))) then
					rd_addr <= (others => '0');
				else
					rd_addr <= std_logic_vector(unsigned(rd_addr)+1);
				end if;
			end if;
			
			if(wr_en = '1' and rd_en = '1') then
				--no change
				underflow_int <= '0';
				overflow_int <= '0';
			elsif(wr_en = '1' and rd_en = '0') then
				if(fifo_count = gLENGTH-1) then
					overflow_int <= '1';
					fifo_count <= gLENGTH-1;
				else
					overflow_int <= '0';
					fifo_count <= fifo_count + 1;
				end if;
			elsif(wr_en = '0' and rd_en = '1') then
				if(fifo_count = 0) then
					underflow_int <= '1';
					fifo_count <= 0;
				else
					underflow_int <= '0';
					fifo_count <= fifo_count - 1;
				end if;
			else
				fifo_count <= fifo_count;
			end if;
			
			
			if(overflow_int = '1') then
				overflow_int_s <= '1';
			end if;
			
			if(underflow_int = '1') then
				underflow_int_s <= '1';
			end if;
			
		end if;
	end process;

	overflow_s <= overflow_int_s;
	underflow_s <= underflow_int_s;

	overflow <= overflow_int;
	underflow <= underflow_int;

	fifo_count_o <= std_logic_vector(to_unsigned(fifo_count,32));

	fifo_bram_inst : entity work.inferred_tdpbram_n_init
	generic map(
		gDEPTH => gDEPTH,
		gWIDTH => gWIDTH,
		gOREGS => gOREGS
	)
	port map(
		a_clk  => clk,
		a_wr   => wr_en,
		a_en   => '0',
		a_di   => wr_data,
		a_do   => open,
		a_addr => wr_addr,
		b_clk  => clk,
		b_wr   => '0',
		b_en   => rd_en,
		b_di   => (others => '0'),
		b_do   => rd_data,
		b_addr => rd_addr
	);




end bhv;		

