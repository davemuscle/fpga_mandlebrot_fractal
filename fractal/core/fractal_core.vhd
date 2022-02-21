library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
	
use work.fractal_pkg.all;
	
--Dave Muscle
--Main core of the fractal processor


entity fractal_core is
	generic(
		NUM_DSP_SLICES : integer := NUM_DSP_SLICES;
		NUM_LUT_SLICES : integer := NUM_LUT_SLICES;
		NUM_SLICES     : integer := NUM_SLICES;
		DATA_WIDTH     : integer := DATA_WIDTH;
		QFORMAT_INT    : integer := QFORMAT_INT;
		QFORMAT_FRAC   : integer := QFORMAT_FRAC;
		BRAM_LATENCY   : integer := BRAM_LATENCY;
		TPL            : integer := TPL;
		TPL_NP2        : integer := TPL_NP2;
		DRY_RUN        : integer := 0
		);
	port(
	    clk_pixel    : in  std_logic;                                --slow clock
		clk_core     : in  std_logic;                                --fast clock
		escape       : in  std_logic_vector(QFORMAT_INT-1 downto 0); --fractal parameters
		enable       : in  std_logic;                                --core start signal
		core_port_i  : in  fractal_slice_data;		                 --fractal input data
		core_port_o  : out fractal_slice_data;		                 --fractal output data
		
		--upstream flow control status
		st_up_wr_addr        : out std_logic_vector(TPL_NP2 downto 0);
		st_up_rd_addr        : out std_logic_vector(TPL_NP2 downto 0);
		st_up_wr_en          : out std_logic;
		st_up_rd_en          : out std_logic;
		st_up_wr_buffer_sel  : out std_logic;
		st_up_rd_buffer_sel  : out std_logic;
		st_up_buffer_done    : out std_logic;
		st_up_error          : out std_logic;
		
		--downstream flow control status
		st_dn_wr_addr        : out std_logic_vector(TPL_NP2 downto 0);
		st_dn_rd_addr        : out std_logic_vector(TPL_NP2 downto 0);
		st_dn_wr_en          : out std_logic;
		st_dn_rd_en          : out std_logic;
		st_dn_wr_buffer_sel  : out std_logic;
		st_dn_rd_buffer_sel  : out std_logic;
		st_dn_buffer_done    : out std_logic;
		st_dn_error          : out std_logic	
		
        );
end fractal_core;

architecture arch of fractal_core is 
	
	--upstream write signals
	signal upstream_buffer_done : std_logic := '0';
	signal upstream_write_data : std_logic_vector(2*DATA_WIDTH + META_WIDTH-1 downto 0) := (others => '0');
	signal upstream_write_en : std_logic := '0';
	
	--upstream read signals
	signal upstream_read_data : std_logic_vector(2*DATA_WIDTH + META_WIDTH-1 downto 0) := (others => '0');
	signal upstream_read_en   : std_logic := '0';
	signal upstream_buffer_done_meta : std_logic := '0';
	signal upstream_buffer_done_sync : std_logic := '0';
	signal upstream_buffer_done_dly  : std_logic := '0';
	
	--engine signals
	signal datapath_i : fractal_slice_data := fractal_slice_data_init;
	signal datapath_o : fractal_slice_data := fractal_slice_data_init;
	signal hold : std_logic := '1'; --has to initialize to 1
	
	--downstream write signals
	signal downstream_write_en : std_logic := '0';
	--needs to hold coord_real, coord_imag, math_r, iter_count, and the locking signal
	signal downstream_write_data : std_logic_vector(3*DATA_WIDTH + META_WIDTH + ITER_WIDTH downto 0) := (others => '0');
	signal downstream_buffer_done : std_logic := '0';
	signal downstream_buffer_done_stretch : std_logic := '0';

	--downstream read signals
	signal downstream_read_en : std_logic := '0';
	signal downstream_read_data : std_logic_vector(3*DATA_WIDTH + META_WIDTH + ITER_WIDTH downto 0) := (others => '0');
	signal downstream_buffer_done_reg : std_logic := '0';
	signal downstream_buffer_done_meta : std_logic := '0';
	signal downstream_buffer_done_sync : std_logic := '0';

	attribute ASYNC_REG : string;
	attribute ASYNC_REG of upstream_buffer_done_meta, upstream_buffer_done_sync, upstream_buffer_done_dly : signal is "true";
	attribute ASYNC_REG of downstream_buffer_done_sync, downstream_read_en : signal is "true"; 


	
	--state machine signals
	signal sm_enable : std_logic := '0';
	signal sm_switch : std_logic := '0';
	signal sm_count  : integer range 0 to TPL := 0;
	signal sm_switch_slv : std_logic_vector(BRAM_LATENCY downto 0) := (others => '0');
	
	signal sm_switch_1, sm_switch_2 : std_logic := '0';

begin	
	
	--upstream write signals
	upstream_write_data <= core_port_i.metadata & core_port_i.coord_imag & core_port_i.coord_real;
	upstream_write_en <= enable;
	
	--upstream flow control
	upstream_ctrl_inst : entity work.fractal_flow_control
	generic map(
		f_DEPTH => TPL,
		f_ORDER => TPL_NP2,
		f_WIDTH => 2*DATA_WIDTH + META_WIDTH,
		f_OREGS => BRAM_LATENCY
	)
	port map(
		wr_clk           => clk_pixel,
		wr_data          => upstream_write_data,
		wr_en            => upstream_write_en,
		rd_clk           => clk_core,
		rd_data          => upstream_read_data,
		rd_en            => upstream_read_en,
		buffer_done      => upstream_buffer_done,
		st_wr_addr       => st_up_wr_addr,
		st_rd_addr       => st_up_rd_addr,
		st_wr_en         => st_up_wr_en,
		st_rd_en         => st_up_rd_en,
		st_wr_buffer_sel => st_up_wr_buffer_sel,
		st_rd_buffer_sel => st_up_rd_buffer_sel,
		st_buffer_done   => st_up_buffer_done,
		st_error         => st_up_error
	);

	--upstream read signals
	datapath_i.coord_real <= upstream_read_data(  DATA_WIDTH-1            downto            0);
	datapath_i.coord_imag <= upstream_read_data(2*DATA_WIDTH-1            downto   DATA_WIDTH);
	datapath_i.metadata   <= upstream_read_data(2*DATA_WIDTH+META_WIDTH-1 downto 2*DATA_WIDTH);
	datapath_i.math_x <= (others => '0');
	datapath_i.math_y <= (others => '0');
	datapath_i.iter_count <= (others => '0');
	datapath_i.lock <= '0';
	
	
	--add cdc for the upstream done signal
	process(clk_core)
	begin
		if(rising_edge(clk_core)) then	
			upstream_buffer_done_meta <= upstream_buffer_done;
			upstream_buffer_done_sync <= upstream_buffer_done_meta;
			upstream_buffer_done_dly  <= upstream_buffer_done_sync;
		end if;
	end process;
	
	--upstream read enable is the sm enable
	upstream_read_en <= sm_enable;
	
	--state machine process, this is the control path
	process(clk_core)
	begin
		if(rising_edge(clk_core)) then
			--if we're on a rising edge of the upstream done, enable the state machine
			if(upstream_buffer_done_dly = '0' and upstream_buffer_done_sync = '1') then
				sm_enable <= '1';
			end if;
	
			--if the state machine is one, count up
			if(sm_enable = '1') then
				sm_count <= sm_count + 1;
			else
				sm_count <= 0;
			end if;	
			
			--if we have filled the fractal engine with data, turn off the state machine
			if(sm_count >= TPL-1) then
				sm_enable <= '0';
			end if;
			
			--add delays for the sm enable to account for block ram latency
			sm_switch_slv(0) <= sm_enable;
			sm_switch_slv(BRAM_LATENCY downto 1) <= sm_switch_slv(BRAM_LATENCY-1 downto 0);
			
		end if;
	end process;
	
	--take the mux control as the last index of shift reg
	sm_switch <= sm_switch_slv(BRAM_LATENCY);
	
	--instantiate the datapath
	datapath_inst : entity work.fractal_datapath
	generic map(
		NUM_DSP_SLICES => NUM_DSP_SLICES,
		NUM_LUT_SLICES => NUM_LUT_SLICES,
		NUM_SLICES     => NUM_SLICES
		
	)
	port map(
		clk        => clk_core,
		escape     => escape,
		load       => sm_switch,
		datapath_i => datapath_i,
		datapath_o => datapath_o
	);	

	
	
	downstream_write_en <= sm_switch;
	
	--slice out the engine output data
	downstream_write_data(  DATA_WIDTH-1                       downto                       0) <= datapath_o.coord_real;
	downstream_write_data(2*DATA_WIDTH-1                       downto              DATA_WIDTH) <= datapath_o.coord_imag;
	downstream_write_data(3*DATA_WIDTH-1                       downto            2*DATA_WIDTH) <= datapath_o.math_r;
	downstream_write_data(3*DATA_WIDTH+META_WIDTH-1            downto            3*DATA_WIDTH) <= datapath_o.metadata;
	downstream_write_data(3*DATA_WIDTH+META_WIDTH+ITER_WIDTH-1 downto 3*DATA_WIDTH+META_WIDTH) <= datapath_o.iter_count;
	
	downstream_write_data(3*DATA_WIDTH+META_WIDTH+ITER_WIDTH) <= datapath_o.lock;
	--downstream flow control
	downstream_ctrl_inst : entity work.fractal_flow_control
	generic map(
		f_DEPTH => TPL,
		f_ORDER => TPL_NP2,
		f_WIDTH => 3*DATA_WIDTH+META_WIDTH+ITER_WIDTH+1,
		f_OREGS => BRAM_LATENCY
		
	)
	port map(
		wr_clk           => clk_core,
		wr_data          => downstream_write_data,
		wr_en            => downstream_write_en,
		rd_clk           => clk_pixel,
		rd_data          => downstream_read_data,
		rd_en            => downstream_read_en,
		buffer_done      => downstream_buffer_done,
		
		st_wr_addr       => st_dn_wr_addr,
		st_rd_addr       => st_dn_rd_addr,
		st_wr_en         => st_dn_wr_en,
		st_rd_en         => st_dn_rd_en,
		st_wr_buffer_sel => st_dn_wr_buffer_sel,
		st_rd_buffer_sel => st_dn_rd_buffer_sel,
		st_buffer_done   => st_dn_buffer_done,
		st_error         => st_dn_error
	);
	
	process(clk_core)
	begin
		if(rising_edge(clk_core)) then
		
			if(downstream_buffer_done = '1') then
				downstream_buffer_done_reg <= '1';
			end if;
			
		end if;
	end process;
	
	process(clk_pixel)
	begin
		if(rising_edge(clk_pixel)) then
			downstream_buffer_done_sync <= downstream_buffer_done_reg;
			downstream_read_en <= downstream_buffer_done_sync;
		end if;
	end process;
	
	--slice out the downstream read data
	core_port_o.coord_real <= downstream_read_data(  DATA_WIDTH-1                       downto                       0);
	core_port_o.coord_imag <= downstream_read_data(2*DATA_WIDTH-1                       downto              DATA_WIDTH);
	core_port_o.math_r     <= downstream_read_data(3*DATA_WIDTH-1                       downto            2*DATA_WIDTH);
	core_port_o.metadata   <= downstream_read_data(3*DATA_WIDTH+META_WIDTH-1            downto            3*DATA_WIDTH);
	core_port_o.iter_count <= downstream_read_data(3*DATA_WIDTH+META_WIDTH+ITER_WIDTH-1 downto 3*DATA_WIDTH+META_WIDTH);
	core_port_o.lock       <= downstream_read_data(3*DATA_WIDTH+META_WIDTH+ITER_WIDTH);
	
end arch;
