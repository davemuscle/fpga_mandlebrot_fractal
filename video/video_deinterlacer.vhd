library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

--Dave Muscle
	--Deinterlaces video line by line
	--Simplest way to deinterlace is just double the line
	
	--clk_b = 2*clk_a
	
entity video_deinterlacer is
	generic(
		DATA_WIDTH : integer := 10;
		META_WIDTH : integer := 4;
		
		SOF_BP : integer := 0;
		EOL_BP : integer := 1;
		
        line_width : integer := 1920
	
		);
	port(
	    clk_a      : in std_logic;
		pixel_a    : in std_logic_vector(DATA_WIDTH-1 downto 0);
		metadata_a : in std_logic_vector(META_WIDTH-1 downto 0);
		
		clk_b      : in std_logic;
		pixel_b    : out std_logic_vector(DATA_WIDTH-1 downto 0);
		metadata_b : out std_logic_vector(META_WIDTH-1 downto 0)
		
        );
end video_deinterlacer;

architecture arch of video_deinterlacer is 
	
	--ping pong buffer length
	constant buffer_depth : integer := line_width;
	constant buffer_depth_log2 : integer := integer(ceil(log2(real(buffer_depth))));
	
	signal load_a : std_logic := '0';
	
	signal start_a : std_logic := '0';
	signal start_meta : std_logic := '0';
	signal start_sync : std_logic := '0';
	signal start_b : std_logic := '0';
	
	signal interlace_count : std_logic := '0';
	
	--pingpong signals
	signal pp_rd_addr : std_logic_vector(buffer_depth_log2-1 downto 0) := (others => '0');
	signal pp_wr_addr : std_logic_vector(buffer_depth_log2-1 downto 0) := (others => '0');
	signal pp_rd_data : std_logic_vector(DATA_WIDTH+META_WIDTH-1 downto 0) := (others => '0');
	signal pp_wr_data : std_logic_vector(DATA_WIDTH+META_WIDTH-1 downto 0) := (others => '0');
	signal pp_rd_en   : std_logic := '0';
	signal pp_wr_en   : std_logic := '0';
	
	signal pp_rd_sel  : std_logic := '0';
	signal pp_wr_sel  : std_logic := '0';
	
	signal pp_rd_full_addr : std_logic_vector(buffer_depth_log2 downto 0) := (others => '0');
	signal pp_wr_full_addr : std_logic_vector(buffer_depth_log2 downto 0) := (others => '0');
	
	signal pp_wr_count : integer := 0;
	signal pp_rd_count : integer := 0;
	
	signal metadata_mux : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');

begin	
	
	process(clk_a)
	begin
		if(clk_a'event and clk_a = '1') then
			--load the block ram up from the write side
			--signal downstream when full
			--use the SOF signal to sync
			if(metadata_a(SOF_BP) = '1') then
				load_a <= '1';
				pp_wr_en <= '1';
			end if;
			
			pp_wr_data <= metadata_a & pixel_a;
			
			if(load_a = '1') then
				if(pp_wr_count = line_width-1) then
					pp_wr_count <= 0;
					pp_wr_sel <= not pp_wr_sel;
					pp_wr_addr <= (others => '0');
					start_a <= '1';
					
				else
					pp_wr_count <= pp_wr_count + 1;
					pp_wr_sel <= pp_wr_sel;
					pp_wr_addr <= std_logic_vector(unsigned(pp_wr_addr)+1);
					start_a <= '0';
				end if;
			end if;
		end if;
	end process;

	process(clk_b)
	begin
		if(clk_b'event and clk_b = '1') then
		
			--dfs the sync signal
			start_meta <= start_a;
			start_sync <= start_meta;
		
			if(start_sync = '1') then
				start_b <= '1';
				pp_rd_en <= '1';
			end if;
			
			--read from the block ram at double the speed
			if(start_b = '1') then
				if(pp_rd_count = line_width-1) then
					if(interlace_count = '1') then
						--switch to the next ram
						pp_rd_sel <= not pp_rd_sel;
					end if;
					
					interlace_count <= not interlace_count;
					
					pp_rd_addr <= (others => '0');
					pp_rd_count <= 0;
				else
					pp_rd_addr <= std_logic_vector(unsigned(pp_rd_addr) + 1);
					pp_rd_count <= pp_rd_count + 1;
				end if;
			end if;
		end if;
	end process;
	
	pixel_b    <= pp_rd_data(DATA_WIDTH-1 downto 0);
	metadata_mux <= pp_rd_data(pp_rd_data'length-1 downto DATA_WIDTH);
	
	--mux the SOF metadata 
	process(metadata_mux, interlace_count)
	begin
		metadata_b <= metadata_mux;
		if(interlace_count = '0') then
			metadata_b(SOF_BP) <= metadata_mux(SOF_BP);
		else
			metadata_b(SOF_BP) <= '0';
		end if;
	end process;
	
	pp_rd_full_addr <= pp_rd_sel & pp_rd_addr;
	pp_wr_full_addr <= pp_wr_sel & pp_wr_addr;
	
	--instantiate a buffer for holding a line of video (two for flipping)
	pp_inst : entity work.inferred_tdpbram_n_init
	generic map(
		gDEPTH => buffer_depth_log2+1,
		gWIDTH => DATA_WIDTH+META_WIDTH,
		gOREGS => 2
	)
	port map(
		a_clk  => clk_a,
		a_wr   => pp_wr_en,
		a_en   => '0',
		a_di   => pp_wr_data,
		a_do   => open,
		a_addr => pp_wr_full_addr,
		b_clk  => clk_b,
		b_wr   => '0',
		b_en   => pp_rd_en,
		b_di   => (others => '0'),
		b_do   => pp_rd_data,
		b_addr => pp_rd_full_addr
	);


end arch;
