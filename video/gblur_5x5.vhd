library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
--Dave Muscle

--Applies 5x5 Gaussian Blur Kernel:
--(1/256)*[1,4,6,4,1;4,16,24,16,4;6,24,36,24,6;4,16,24,16,4;1,4,6,4,1]

--Uses inferred dsp to apply the kernel

--Designed to be used after blanking time has been added

entity gblur_5x5 is
	generic(
		META_WIDTH   : integer := 1;
		h_active    : integer := 1920;
		h_total     : integer := 2160;
		v_active    : integer := 1080;
		v_total     : integer := 1176
		

		);
	port(
	    clk          : in std_logic;
		reset        : in std_logic;
		passthrough  : in std_logic;
	
		metadata_i   : in std_logic_vector(META_WIDTH-1 downto 0);
		color_i      : in std_logic_vector(23 downto 0);
		
		metadata_o   : out std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
		color_o      : out std_logic_vector(23 downto 0)           := (others => '0')
		
        );
end gblur_5x5;

architecture arch of gblur_5x5 is 
	
    type kernel_t is array(0 to 24) of std_logic_vector(7 downto 0);									
	--reciprocals to multiply with
	constant kernel_mult : kernel_t := (0  => std_logic_vector(to_signed(to_integer(256.0*( 1.0/256.0)))),
										1  => std_logic_vector(to_signed(to_integer(256.0*( 4.0/256.0)))),
										2  => std_logic_vector(to_signed(to_integer(256.0*( 6.0/256.0)))),
										3  => std_logic_vector(to_signed(to_integer(256.0*( 4.0/256.0)))),
										4  => std_logic_vector(to_signed(to_integer(256.0*( 1.0/256.0)))),
										
										5  => std_logic_vector(to_signed(to_integer(256.0*( 4.0/256.0)))),
										6  => std_logic_vector(to_signed(to_integer(256.0*(16.0/256.0)))),
										7  => std_logic_vector(to_signed(to_integer(256.0*(24.0/256.0)))),
										8  => std_logic_vector(to_signed(to_integer(256.0*(16.0/256.0)))),
										9  => std_logic_vector(to_signed(to_integer(256.0*( 4.0/256.0)))),
										
										10 => std_logic_vector(to_signed(to_integer(256.0*( 6.0/256.0)))),
										11 => std_logic_vector(to_signed(to_integer(256.0*(24.0/256.0)))),
										12 => std_logic_vector(to_signed(to_integer(256.0*(36.0/256.0)))),
										13 => std_logic_vector(to_signed(to_integer(256.0*(24.0/256.0)))),
										14 => std_logic_vector(to_signed(to_integer(256.0*( 6.0/256.0)))),
										
										15 => std_logic_vector(to_signed(to_integer(256.0*( 4.0/256.0)))),
										16 => std_logic_vector(to_signed(to_integer(256.0*(16.0/256.0)))),
										17 => std_logic_vector(to_signed(to_integer(256.0*(24.0/256.0)))),
										18 => std_logic_vector(to_signed(to_integer(256.0*(16.0/256.0)))),
										19 => std_logic_vector(to_signed(to_integer(256.0*( 4.0/256.0)))),
										
										20 => std_logic_vector(to_signed(to_integer(256.0*( 1.0/256.0)))),
										21 => std_logic_vector(to_signed(to_integer(256.0*( 4.0/256.0)))),
										22 => std_logic_vector(to_signed(to_integer(256.0*( 6.0/256.0)))),
										23 => std_logic_vector(to_signed(to_integer(256.0*( 4.0/256.0)))),
										24 => std_logic_vector(to_signed(to_integer(256.0*( 1.0/256.0)))));
										
    
	constant NUM_LINE_BUFFERS : integer := 5;
	constant BUFFER_SIZE : integer := h_total;
	constant BUFFER_SIZE_LOG2 : integer := integer(ceil(log2(real(BUFFER_SIZE))));
	constant RAM_WIDTH : integer := 24+META_WIDTH;
	
	signal ram_addr : std_logic_vector(BUFFER_SIZE_LOG2-1 downto 0) := (others => '0');
	
	type ram_data_t is array(0 to NUM_LINE_BUFFERS-1) of std_logic_vector(RAM_WIDTH-1 downto 0);
	signal ram_rd_data : ram_data_t := (others => (others => '0'));
	signal ram_wr_data : std_logic_vector(RAM_WIDTH-1 downto 0) := (others => '0');
	signal ram_rd_en : std_logic_vector(NUM_LINE_BUFFERS-1 downto 0) := (others => '0');
	signal ram_wr_en : std_logic_vector(NUM_LINE_BUFFERS-1 downto 0) := (others => '0');
	
	signal ram_wr_sel : integer range 0 to NUM_LINE_BUFFERS-1 := 0;
	
	signal enable : std_logic := '0';
	signal enable_dly : std_logic := '0';
	
	signal metadata_i_reg : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	signal color_i_reg    : std_logic_vector(23 downto 0) := (others => '0');
	
	signal h_count : integer range 0 to h_total-1 := 0;
	signal h_count_wr_dly : integer range 0 to h_total-1 := 0;
	signal v_count : integer range 0 to v_total-1 := 0;
	
	signal ram_wr_sel_dly1 : integer range 0 to NUM_LINE_BUFFERS-1 := 0;
	signal ram_wr_sel_dly2 : integer range 0 to NUM_LINE_BUFFERS-1 := 0;
	signal ram_wr_sel_dly3 : integer range 0 to NUM_LINE_BUFFERS-1 := 0;

	--start the calc sel one ahead of the wr sel
	signal ram_calc_sel      : integer range 0 to NUM_LINE_BUFFERS-1 := 1;
	signal ram_calc_sel_dly1 : integer range 0 to NUM_LINE_BUFFERS-1 := 0;
	signal ram_calc_sel_dly2 : integer range 0 to NUM_LINE_BUFFERS-1 := 0;
	signal ram_calc_sel_dly3 : integer range 0 to NUM_LINE_BUFFERS-1 := 0;
	signal ram_calc_sel_dly4 : integer range 0 to NUM_LINE_BUFFERS-1 := 0;
	
	type color_data is array(0 to 2) of std_logic_vector(7 downto 0);
	
	--kernelxy x = row, y = column
	signal kernel_00 : color_data := (others => (others => '0'));
	signal kernel_10 : color_data := (others => (others => '0'));
	signal kernel_20 : color_data := (others => (others => '0'));
	signal kernel_01 : color_data := (others => (others => '0'));
	signal kernel_11 : color_data := (others => (others => '0'));
	signal kernel_21 : color_data := (others => (others => '0'));
	signal kernel_02 : color_data := (others => (others => '0'));
	signal kernel_12 : color_data := (others => (others => '0'));
	signal kernel_22 : color_data := (others => (others => '0'));

	signal kernel_03 : color_data := (others => (others => '0'));
	signal kernel_13 : color_data := (others => (others => '0'));
	signal kernel_23 : color_data := (others => (others => '0'));
	
	signal kernel_04 : color_data := (others => (others => '0'));
	signal kernel_14 : color_data := (others => (others => '0'));
	signal kernel_24 : color_data := (others => (others => '0'));

	--multiplies
	signal shft_00 : color_data := (others => (others => '0'));
	signal shft_10 : color_data := (others => (others => '0'));
	signal shft_20 : color_data := (others => (others => '0'));
	signal shft_01 : color_data := (others => (others => '0'));
	signal shft_11 : color_data := (others => (others => '0'));
	signal shft_21 : color_data := (others => (others => '0'));
	signal shft_02 : color_data := (others => (others => '0'));
	signal shft_12 : color_data := (others => (others => '0'));
	signal shft_22 : color_data := (others => (others => '0'));
	
	signal shft_03 : color_data := (others => (others => '0'));
	signal shft_13 : color_data := (others => (others => '0'));
	signal shft_23 : color_data := (others => (others => '0'));
	
	signal shft_04 : color_data := (others => (others => '0'));
	signal shft_14 : color_data := (others => (others => '0'));
	signal shft_24 : color_data := (others => (others => '0'));
	
	signal metadata_pre  : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	signal metadata_dly1 : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	signal metadata_dly2 : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	signal metadata_dly3 : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');

	--pass through delays
	signal passthrough_reg1 : color_data := (others => (others => '0'));
    signal passthrough_reg2 : color_data := (others => (others => '0'));
    signal passthrough_reg3 : color_data := (others => (others => '0'));
    signal passthrough_reg4 : color_data := (others => (others => '0'));
	signal passthrough_reg5 : color_data := (others => (others => '0'));

	signal sum     : color_data := (others => (others => '0'));
	signal sum_reg : color_data := (others => (others => '0'));
	signal metadata_o_pre : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	
	signal math_out : std_logic_vector(23 downto 0) := (others => '0');
	
	signal h_count_out : integer range 0 to h_total-1 := 0;
	signal v_count_out : integer range 0 to v_total-1 := 0;
	
	signal out_enable : std_logic := '0';
	signal pre_concat : std_logic_vector(23 downto 0) := (others => '0');
	signal pre_out : std_logic_vector(23 downto 0) := (others => '0');
begin	
	
	--this process sets up the counting and time structure
	process(clk)
	begin
		if(clk'event and clk = '1') then
		
			--enable the counters for keeping track of time
			if(metadata_i(0) = '1') then
				enable <= '1';
			end if;
			
			enable_dly <= enable;
		
			--delay the inputs by a clock
			metadata_i_reg <= metadata_i;
			color_i_reg <= color_i;
		
			--reset the counters on rising edge of enable signal
			if(enable_dly = '0' and enable = '1') then
				h_count <= 0;
				v_count <= 0;
			end if;
		
			--if enabled, count through the frame
			if(enable = '1') then
				if(h_count = h_total-1) then
					h_count <= 0;
					if(v_count = v_total-1) then
						v_count <= 0;
					else
						v_count <= v_count + 1;
					end if;
				else
					h_count <= h_count + 1;
				end if;
			end if;
			
			--turn off the enable through an AH reset signal
			if(reset = '1') then
				enable <= '0';
			end if;
		end if;
	end process;
	
	--this process handles reading and writing to the rams
	process(clk)
	begin
		if(clk'event and clk = '1') then
			
			--if we start the enable signal, reset the wr select to zero
			if(enable_dly = '0' and enable = '1') then
				ram_wr_sel <= 0;
			end if;
			
			--if we're at the end of the line, increment the line count
			if(h_count = h_active-1) then
				if(ram_wr_sel = NUM_LINE_BUFFERS-1) then
					ram_wr_sel <= 0;
				else
					ram_wr_sel <= ram_wr_sel + 1;
				end if;
				
				if(ram_calc_sel = NUM_LINE_BUFFERS-1) then
					ram_calc_sel <= 0;
				else
					ram_calc_sel <= ram_calc_sel + 1;
				end if;
			end if;

			h_count_wr_dly <= h_count;
		
			--assign the ram address
			ram_addr <= std_logic_vector(to_unsigned(h_count,ram_addr'length));
			
			--setup the data 
			ram_wr_data <= metadata_i_reg & color_i_reg;
		
			--delay the write select for when the read data is ready
			ram_wr_sel_dly1 <= ram_wr_sel;
			ram_wr_sel_dly2 <= ram_wr_sel_dly1;
			ram_wr_sel_dly3 <= ram_wr_sel_dly2;
			
			ram_calc_sel_dly1 <= ram_calc_sel;
			ram_calc_sel_dly2 <= ram_calc_sel_dly1;
			ram_calc_sel_dly3 <= ram_calc_sel_dly2;
			ram_calc_sel_dly4 <= ram_calc_sel_dly3;
		
		end if;
	end process;
	
	--setup the write enable signal to the rams, this should be a compare and some muxes
	process(ram_wr_sel_dly1, h_count_wr_dly)
	begin
		ram_wr_en <= (others => '0');
		if(h_count_wr_dly < h_active) then
			ram_wr_en(ram_wr_sel_dly1) <= '1';
		end if;
	end process;
	
	--mux the data from the rams into a better format for applying the kernel
	process(ram_calc_sel_dly4, ram_rd_data)
	begin
		-- for i in 0 to 2 loop
			-- case ram_calc_sel_dly4 is 
			-- when 0 =>
				-- kernel_00(i) <= ram_rd_data(2)(((i+1)*8)-1 downto i*8);
				-- kernel_10(i) <= ram_rd_data(0)(((i+1)*8)-1 downto i*8);
				-- kernel_20(i) <= ram_rd_data(1)(((i+1)*8)-1 downto i*8);
			-- when 1 =>
				-- kernel_00(i) <= ram_rd_data(0)(((i+1)*8)-1 downto i*8);
				-- kernel_10(i) <= ram_rd_data(1)(((i+1)*8)-1 downto i*8);
				-- kernel_20(i) <= ram_rd_data(2)(((i+1)*8)-1 downto i*8);
			-- when 2 =>
				-- kernel_00(i) <= ram_rd_data(1)(((i+1)*8)-1 downto i*8);
				-- kernel_10(i) <= ram_rd_data(2)(((i+1)*8)-1 downto i*8);
				-- kernel_20(i) <= ram_rd_data(0)(((i+1)*8)-1 downto i*8);
			-- end case;
		-- end loop;
	
		for i in 0 to 4 loop
			case ram_calc_sel_dly4 is 
			when 0 =>
				kernel_00(i) <= ram_rd_data(2)(((i+1)*8)-1 downto i*8);
				kernel_10(i) <= ram_rd_data(0)(((i+1)*8)-1 downto i*8);
				kernel_20(i) <= ram_rd_data(1)(((i+1)*8)-1 downto i*8);
			when 1 =>
				kernel_00(i) <= ram_rd_data(0)(((i+1)*8)-1 downto i*8);
				kernel_10(i) <= ram_rd_data(1)(((i+1)*8)-1 downto i*8);
				kernel_20(i) <= ram_rd_data(2)(((i+1)*8)-1 downto i*8);
			when 2 =>
				kernel_00(i) <= ram_rd_data(1)(((i+1)*8)-1 downto i*8);
				kernel_10(i) <= ram_rd_data(2)(((i+1)*8)-1 downto i*8);
				kernel_20(i) <= ram_rd_data(0)(((i+1)*8)-1 downto i*8);
			when 3 =>
				kernel_00(i) <= ram_rd_data(1)(((i+1)*8)-1 downto i*8);
				kernel_10(i) <= ram_rd_data(2)(((i+1)*8)-1 downto i*8);
				kernel_20(i) <= ram_rd_data(0)(((i+1)*8)-1 downto i*8);
			when 4 =>
				kernel_00(i) <= ram_rd_data(1)(((i+1)*8)-1 downto i*8);
				kernel_10(i) <= ram_rd_data(2)(((i+1)*8)-1 downto i*8);
				kernel_20(i) <= ram_rd_data(0)(((i+1)*8)-1 downto i*8);
			end case;
		end loop;
	
		metadata_pre <= ram_rd_data(ram_calc_sel_dly4)(24 downto 24);
		
	end process;
	
	process(clk)
	begin
		if(clk'event and clk = '1') then
		
			for i in 0 to 2 loop
			

		
				--delay the read kernel data into columns
				kernel_01(i) <= kernel_00(i);
				kernel_11(i) <= kernel_10(i);
				kernel_21(i) <= kernel_20(i);
				
				kernel_02(i) <= kernel_01(i);
				kernel_12(i) <= kernel_11(i);
				kernel_22(i) <= kernel_21(i);
				
				--setup the shift vectors
				shft_00(i) <= std_logic_vector(shift_right(unsigned(kernel_00(i)),kernel_srl(0)));
				shft_10(i) <= std_logic_vector(shift_right(unsigned(kernel_10(i)),kernel_srl(3)));
				shft_20(i) <= std_logic_vector(shift_right(unsigned(kernel_20(i)),kernel_srl(6)));
				shft_01(i) <= std_logic_vector(shift_right(unsigned(kernel_01(i)),kernel_srl(1)));
				shft_11(i) <= std_logic_vector(shift_right(unsigned(kernel_11(i)),kernel_srl(4)));
				shft_21(i) <= std_logic_vector(shift_right(unsigned(kernel_21(i)),kernel_srl(7)));
				shft_02(i) <= std_logic_vector(shift_right(unsigned(kernel_02(i)),kernel_srl(2)));
				shft_12(i) <= std_logic_vector(shift_right(unsigned(kernel_12(i)),kernel_srl(5)));
				shft_22(i) <= std_logic_vector(shift_right(unsigned(kernel_22(i)),kernel_srl(8)));
				
				-- shft_00(i) <= kernel_00(i);
				-- shft_10(i) <= kernel_10(i);
				-- shft_20(i) <= kernel_20(i);
				-- shft_01(i) <= kernel_01(i);
				-- shft_11(i) <= kernel_11(i);
				-- shft_21(i) <= kernel_21(i);
				-- shft_02(i) <= kernel_02(i);
				-- shft_12(i) <= kernel_12(i);
				-- shft_22(i) <= kernel_22(i);
		
				--delay the pass through data
				passthrough_reg1(i) <= kernel_11(i);
				passthrough_reg2(i) <= passthrough_reg1(i);
				passthrough_reg3(i) <= passthrough_reg2(i);
		
				--sum up the shift vectors
				sum(i) <= std_logic_vector(unsigned(shft_00(i)) + 
										   unsigned(shft_10(i)) + 
										   unsigned(shft_20(i)) + 
										   unsigned(shft_01(i)) + 
										   unsigned(shft_11(i)) + 
										   unsigned(shft_21(i)) + 
										   unsigned(shft_02(i)) + 
										   unsigned(shft_12(i)) + 
										   unsigned(shft_22(i))); 
		
			end loop;
			
			--delay the metadata
			metadata_dly1 <= metadata_pre;
			metadata_dly2 <= metadata_dly1;
			metadata_dly3 <= metadata_dly2;

			--enable the output counting
			if(metadata_dly3(0) = '1') then
				out_enable <= '1';
			end if;

			sum_reg <= sum;
			metadata_o_pre <= metadata_dly3;
			
			if(out_enable = '1') then
				if(h_count_out = h_total-1) then
					h_count_out <= 0;
					if(v_count_out = v_total-1) then
						v_count_out <= 0;
					else
						v_count_out <= v_count_out + 1;
					end if;
				else
					h_count_out <= h_count_out + 1;
				end if;
			end if;
	
		end if;
	end process;
	
	metadata_o <= metadata_o_pre;
	math_out <= sum_reg(2) & sum_reg(1) & sum_reg(0);
	pre_concat <= passthrough_reg3(2) & passthrough_reg3(1) & passthrough_reg3(0);
	
	pre_out <= math_out when passthrough = '0' else pre_concat;
	
	color_o <= pre_out when ((h_count_out < h_active) and (v_count_out < v_active)) else (others => '0');
	
	LINE_BUFFER_GEN : for i in 0 to NUM_LINE_BUFFERS-1 generate
	
		line_buffers : entity work.inferred_tdpbram_n_init
		generic map(
			gDEPTH => BUFFER_SIZE_LOG2,
			gWIDTH => RAM_WIDTH,
			gOREGS => 2
		)
		port map(
			a_clk  => clk,
			a_wr   => ram_wr_en(i),
			a_en   => '1',
			a_di   => ram_wr_data,
			a_do   => ram_rd_data(i),
			a_addr => ram_addr,
			b_clk  => '0',
			b_wr   => '0',
			b_en   => '0',
			b_di   => (others => '0'),
			b_do   => open,
			b_addr => (others => '0')
		);
		
	end generate LINE_BUFFER_GEN;
	
end arch;
