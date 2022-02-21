library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

--Dave Muscle
	--Continuous stream of pixels in, continuous stream of pixels out
	--The input pixels are expected to not have any blanking, but to have sync markers
	--embedded in the metadata
	
	--clk_a < clk_b
	
entity video_pclk_extender is
	generic(
		DEBUG : integer := 0;
		DATA_WIDTH : integer := 10;
		META_WIDTH : integer := 4;
		
		SCALE_MULT  : integer    := 4;
		SCALE_DIV : integer := 1;
		SOF_BP : integer := 0;
		EOL_BP : integer := 1;
		
        h_active 	 : integer := 1920;
		h_blanking   : integer := 280;
        h_total      : integer := 2200;
        v_active     : integer := 540;
		v_blanking   : integer := 23;
        v_total		 : integer := 563
		
		
		
		);
	port(
	    clk_a : in std_logic;
		pixel_a : in std_logic_vector(DATA_WIDTH-1 downto 0);
		metadata_a : in std_logic_vector(META_WIDTH-1 downto 0);
		
		clk_b : in std_logic;
		pixel_b : out std_logic_vector(DATA_WIDTH-1 downto 0);
		metadata_b : out std_logic_vector(META_WIDTH-1 downto 0);
		
		overflow : out std_logic;
		underflow : out std_logic
		
        );
end video_pclk_extender;

architecture arch of video_pclk_extender is 
	
	signal pixel_a_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal metadata_a_reg : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	
	--ping pong buffer length
	--constant buffer_depth : integer := h_active;
	constant buffer_depth : integer := 32;

	constant buffer_depth_log2 : integer := integer(ceil(log2(real(buffer_depth))));
	
	--extended read side buffer
	constant fifo_size : integer := SCALE_MULT*h_total*v_blanking/SCALE_DIV;
	constant fifo_buffer_depth_log2 : integer := integer(ceil(log2(real(fifo_size))));
	constant fifo_buffer_depth : integer := 2**fifo_buffer_depth_log2;

	
	constant prog_full : integer := h_total*v_blanking + h_total;
	
	signal load_a : std_logic := '0';
	
	signal start_a : std_logic := '0';
	signal start_meta : std_logic := '0';
	signal start_sync : std_logic := '0';
	signal start_b : std_logic := '0';
	
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
	
	signal pp_wr_h_count : integer := 0;
	signal pp_wr_v_count : integer := 0;
	signal pp_rd_h_count : integer := 0;
	signal pp_rd_v_count : integer := 0;
	
	signal pp_rd_en_dly, pp_rd_en_dly1, pp_rd_en_dly2 : std_logic := '0';
	
	
	signal fifo_full, fifo_empty : std_logic := '0';
	signal fifo_wr_en, fifo_rd_en : std_logic := '0';
	signal fifo_wr_data, fifo_rd_data : std_logic_vector(DATA_WIDTH+META_WIDTH-1 downto 0);
	signal fifo_en : std_logic := '0';
	
	signal ff_rd_v_count : integer := 0;
	signal ff_rd_h_count : integer := 0;
	
	signal stall : std_logic := '0';
	signal stall_reg : std_logic := '0';
	signal stall_dly : std_logic := '0';
	
	signal mux_data : std_logic_vector(DATA_WIDTH+META_WIDTH-1 downto 0) := (others => '0');
	
	signal fifo_count : std_logic_vector(31 downto 0) := (others => '0');
	
	signal overflow_sticky, underflow_sticky : std_logic := '0';
	signal overflow_u, underflow_u : std_logic := '0';
	
	signal ff_rd_v_count_slv : std_logic_vector(15 downto 0) := (others => '0');
	signal ff_rd_h_count_slv : std_logic_vector(15 downto 0) := (others => '0');
	
	
	-- COMPONENT fifo_Ila
	-- PORT (
		-- clk : IN STD_LOGIC;
		-- probe0 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
		-- probe1 : IN STD_LOGIC_VECTOR(15 DOWNTO 0); 
		-- probe2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		-- probe3 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
		-- probe4 : IN STD_LOGIC_VECTOR(8 DOWNTO 0); 
		-- probe5 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
		-- probe6 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
		-- probe7 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
		-- probe8 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
		-- probe9 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
		-- probe10 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
		-- probe11 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
		-- probe12 : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
		-- probe13 : IN STD_LOGIC_VECTOR(0 downto 0);
		-- probe14 : IN STD_LOGIC_VECTOR(0 downto 0)
	-- );
	-- END COMPONENT  ;
	
begin	
	
	--load up data from the slow clock domain
	process(clk_a)
	begin
		if(rising_edge(clk_a)) then

			--wait for a SOF
			if(metadata_a(SOF_BP) = '1') then
				--start
				load_a <= '1';
			end if;

			pp_wr_data <= metadata_a & pixel_a;

			if(load_a = '1') then
				if(pp_wr_addr = std_logic_vector(to_unsigned(buffer_depth-1, pp_wr_addr'length))) then
					pp_wr_addr <= (others => '0');
					pp_wr_sel <= not pp_wr_sel;
					start_a <= '1';
				else
					pp_wr_addr <= std_logic_vector(unsigned(pp_wr_addr) + 1);
					start_a <= '0';
				end if;
			end if;

		end if;
	end process;

	--read it out in the fast domain
	process(clk_b)
	begin
		if(rising_edge(clk_b)) then

			--sync the upstream signal
			start_meta <= start_a;
			start_sync <= start_meta;
			
			--start the reading process
			if(start_sync = '1') then
				start_b <= '1';
				pp_rd_en <= '1';
			end if;
			
			--read out the right amount of pixels
			if(start_b = '1') then
				if(pp_rd_h_count = buffer_depth-1) then
					start_b <= '0';
					pp_rd_addr <= (others => '0');
					pp_rd_h_count <= 0;
					pp_rd_en <= '0';
					pp_rd_sel <= not pp_rd_sel;
				else
					pp_rd_h_count <= pp_rd_h_count + 1;
					pp_rd_addr <= std_logic_vector(unsigned(pp_rd_addr) + 1);
				end if;
			end if;
			
			
		end if;
	end process;

	--fifo process
	process(clk_b)
	begin
		if(rising_edge(clk_b)) then
			--fill up the fifo when data is ready
			pp_rd_en_dly <= pp_rd_en;
			pp_rd_en_dly1 <= pp_rd_en_dly;
			
			fifo_wr_en <= pp_rd_en_dly1;
			
			--if the fifo is full, start reading from it
			if(fifo_full = '1') then
				fifo_en <= '1';
			end if;
			
			--place the blanking after the active period
			if(fifo_en = '1') then
				if(ff_rd_v_count < v_active) then
					if(ff_rd_h_count < h_active) then
						--active period, read from fifo
						fifo_rd_en <= '1';
					else
						fifo_rd_en <= '0';
					end if;
				else
					fifo_rd_en <= '0';
				end if;
			end if;
			
			--once the fifo has been loaded up, we can start the counters
			if(fifo_en = '1') then
				--if we are at the end of the line
				if(ff_rd_h_count = h_total-1) then
					--reset the horz count
					ff_rd_h_count <= 0;
					--increase or reset the vert count
					if(ff_rd_v_count = v_total-1) then
						ff_rd_v_count <= 0;
					else
						ff_rd_v_count <= ff_rd_v_count + 1;
					end if;
					
				else
					ff_rd_h_count <= ff_rd_h_count + 1;
				end if;
			end if;
			
			stall <= fifo_rd_en;
			stall_reg <= stall;
			stall_dly <= stall_reg;
			
		end if;
	end process;
	
	fifo_wr_data <= pp_rd_data;
	
	mux_data <= fifo_rd_data when stall_dly = '1' else (others => '0');

	pixel_b <= mux_data(DATA_WIDTH-1 downto 0);
	metadata_b <= mux_data(mux_data'length-1 downto DATA_WIDTH);
	
	pp_rd_full_addr <= pp_rd_sel & pp_rd_addr;
	pp_wr_full_addr <= pp_wr_sel & pp_wr_addr;
	
	--pp_wr_data <= metadata_a & pixel_a;
	
	pp_wr_en <= load_a;
	
	
	
	--instantiate a buffer for holding as many rows as we have blanking
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


	overflow <= overflow_sticky;
	underflow <= underflow_sticky;

	fifo_inst : entity work.sync_fifo_simple
	generic map(
		gDEPTH  => fifo_buffer_depth_log2,
		gLENGTH => fifo_buffer_depth,
		gWIDTH  => DATA_WIDTH+META_WIDTH,
		gOREGS  => 2,
		prog_full => prog_full,
		prog_empty => 20
	)
	port map(
		clk          => clk_b,
		full         => open,
		empty        => open,
		af           => open,
		ae           => open,
		pf           => fifo_full,
		pe           => fifo_empty,
		overflow     => overflow_u,
		underflow    => underflow_u,
		overflow_s   => overflow_sticky,
		underflow_s  => underflow_sticky,
		fifo_count_o => fifo_count,
		wr_en        => fifo_wr_en,
		wr_data      => fifo_wr_data,
		rd_en        => fifo_rd_en,
		rd_data      => fifo_rd_data
	);

	
	ff_rd_h_count_slv <= std_logic_vector(to_unsigned(ff_rd_h_count,16));
	ff_rd_v_count_slv <= std_logic_vector(to_unsigned(ff_rd_v_count,16));

	-- ILA_GEN : if(DEBUG = 1) generate
		-- ila : fifo_Ila
		-- PORT MAP (
			-- clk => clk_b,
			-- probe0     => ff_rd_h_count_slv, 
			-- probe1     => ff_rd_v_count_slv, 
			-- probe2     => fifo_count, 
			-- probe3(0)  => fifo_rd_en, 
			-- probe4     => mux_data,
			-- probe5(0)  => overflow_u, 
			-- probe6(0)  => underflow_u, 
			-- probe7(0)  => overflow_sticky, 
			-- probe8(0)  => underflow_sticky, 
			-- probe9(0)  => fifo_full, 
			-- probe10(0) => fifo_empty, 
			-- probe11(0) => start_b,
			-- probe12(0) => fifo_wr_en,
			-- probe13(0) => load_a,
			-- probe14(0) => fifo_en
		-- );
	-- end generate ILA_GEN;
end arch;
