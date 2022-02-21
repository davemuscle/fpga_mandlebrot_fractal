library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
	
--Dave Muscle
-- Pingpong Buffers Masked as FIFOs

--At the start of the architecture, PING is filled with upstream data
--The buffer_done signal is driven high, and PING is made available for reading

--Then, PONG is filled with upstream data
--The buffer_done signal is driven high, annd PONG is made available for reading

entity fractal_flow_control is
	generic(
		f_DEPTH : integer := 37; --how deep the buffers are
		f_ORDER : integer := 6;  --nextpow2(f_DEPTH)
		f_WIDTH : integer := 64; --data width
		f_OREGS : integer := 2   --output pipelining for block rams
		);
	port(
		--write side (upstream)
		wr_clk    : in  std_logic;
		wr_data   : in  std_logic_vector(f_WIDTH-1 downto 0);
		wr_en     : in  std_logic;
		
		--read side (downstream)
	    rd_clk    : in  std_logic;
		rd_data   : out std_logic_vector(f_WIDTH-1 downto 0);
		rd_en     : in  std_logic;

		--buffer flip (on wr clk domain)
		buffer_done : out std_logic := '0';
		
		--status signals for hardware debugging
		st_wr_addr        : out std_logic_vector(f_ORDER downto 0);
		st_rd_addr        : out std_logic_vector(f_ORDER downto 0);
		st_wr_en          : out std_logic;
		st_rd_en          : out std_logic;
		st_wr_buffer_sel  : out std_logic;
		st_rd_buffer_sel  : out std_logic;
		st_buffer_done    : out std_logic;
		st_error          : out std_logic
		
        );
end fractal_flow_control;

architecture arch of fractal_flow_control is 
	
	--address signals
	signal wr_addr      : std_logic_vector(f_ORDER-1 downto 0) := (others => '0');
	signal rd_addr      : std_logic_vector(f_ORDER-1 downto 0) := (others => '0');
	signal wr_addr_full : std_logic_vector(f_ORDER downto 0) := (others => '0');  
	signal rd_addr_full : std_logic_vector(f_ORDER downto 0) := (others => '0');
	
	--buffer signaling
	signal buffer_done_int : std_logic := '0';
	
	--initialize these to the same value
	signal rd_buffer_sel : std_logic := '0';
	signal wr_buffer_sel : std_logic := '0';
	signal rd_buffer_sel_inv : std_logic := '0';
	signal wr_buffer_sel_inv : std_logic := '0';
	
	
	signal ping_wr_en : std_logic := '0';
	signal ping_rd_en : std_logic := '0';
	signal pong_wr_en : std_logic := '0';
	signal pong_rd_en : std_logic := '0';	
	
	signal ping_rd_data : std_logic_vector(f_WIDTH-1 downto 0) := (others => '0');
	signal pong_rd_data : std_logic_vector(f_WIDTH-1 downto 0) := (others => '0');
	
	signal rd_buffer_sel_dly : std_logic_vector(f_OREGS downto 0) := (others => '0');
	
	--the write side will fill up first and flip, then the read side will start
	
	--error signaling
	signal error    : std_logic := '0';
	
begin	

	--write side
	process(wr_clk)
	begin
		if(rising_edge(wr_clk)) then
			buffer_done_int <= '0';
			--increase address on the write side, check for if writing has finished to flip buffers
			if(wr_en = '1') then
				if(wr_addr = std_logic_vector(to_unsigned(f_DEPTH-1, wr_addr'length))) then
					wr_addr <= (others => '0');
					wr_buffer_sel <= not wr_buffer_sel;
					buffer_done_int <= '1';
				else
					wr_addr <= std_logic_vector(unsigned(wr_addr)+1);
				end if;
			end if;
		end if;
	end process;
	
	--read side
	process(rd_clk)
	begin
		if(rising_edge(rd_clk)) then
			if(rd_en = '1') then
				if(rd_addr = std_logic_vector(to_unsigned(f_DEPTH-1, rd_addr'length))) then
					rd_addr <= (others => '0');
					rd_buffer_sel <= not rd_buffer_sel;	
				else
					rd_addr <= std_logic_vector(unsigned(rd_addr)+1);
				end if;
			end if;
			
			rd_buffer_sel_dly <= rd_buffer_sel_dly(f_OREGS-1 downto 0) & rd_buffer_sel;
			
		end if;
	end process;

	buffer_done <= buffer_done_int;

	rd_addr_full <= rd_buffer_sel & rd_addr;
	wr_addr_full <= wr_buffer_sel & wr_addr;

	wr_buffer_sel_inv <= not wr_buffer_sel;
	rd_buffer_sel_inv <= not rd_buffer_sel;

	ping_wr_en <= wr_en and wr_buffer_sel;
	ping_rd_en <= rd_en and rd_buffer_sel;
	
	pong_wr_en <= wr_en and wr_buffer_sel_inv;
	pong_rd_en <= rd_en and rd_buffer_sel_inv;
	
	rd_data <= ping_rd_data when rd_buffer_sel_dly(f_OREGS) = '1' else pong_rd_data;
	
	--instantiate ping buffer
	ping_inst : entity work.inferred_tdpbram_n_init
	generic map(
		gDEPTH => f_ORDER,
		gWIDTH => f_WIDTH,
		gOREGS => f_OREGS
	)
	port map(
		a_clk  => wr_clk,
		a_wr   => ping_wr_en,
		a_en   => '0',
		a_di   => wr_data,
		a_do   => open,
		a_addr => wr_addr,
		b_clk  => rd_clk,
		b_wr   => '0',
		b_en   => ping_rd_en,
		b_di   => (others => '0'),
		b_do   => ping_rd_data,
		b_addr => rd_addr
	);
	
	--instantiate pong buffer
	pingpong_inst : entity work.inferred_tdpbram_n_init
	generic map(
		gDEPTH => f_ORDER,
		gWIDTH => f_WIDTH,
		gOREGS => f_OREGS
	)
	port map(
		a_clk  => wr_clk,
		a_wr   => pong_wr_en,
		a_en   => '0',
		a_di   => wr_data,
		a_do   => open,
		a_addr => wr_addr,
		b_clk  => rd_clk,
		b_wr   => '0',
		b_en   => pong_rd_en,
		b_di   => (others => '0'),
		b_do   => pong_rd_data,
		b_addr => rd_addr
	);
	
		
	process(rd_en, wr_en, rd_addr_full, wr_addr_full)
	begin
		if(rd_en = '1' and wr_en = '1') then
			if(rd_addr_full = wr_addr_full) then
				error <= '1';
			else
				error <= '0';
			end if;
		else
			error <= '0';
		end if;
	end process;
	
	--assign status outputs
	st_wr_addr <= wr_addr_full;
	st_rd_addr <= rd_addr_full;
	st_wr_en <= wr_en;
	st_rd_en <= rd_en;
	st_buffer_done <= buffer_done_int;
	st_wr_buffer_sel <= wr_buffer_sel;
	st_rd_buffer_sel <= rd_buffer_sel;
	st_error <= error;
	
end arch;
