library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

library unisim;
use unisim.vcomponents.all;

use work.fractal_pkg.all;

entity fractal_engine_flow_control_tb is 

end fractal_engine_flow_control_tb;

architecture test of fractal_engine_flow_control_tb is
    
	constant DATA_WIDTH : integer := 32;
	
	signal locked, clkfb : std_logic := '0';
	signal clk_count : integer := 0;
	signal clk_100Mcount : integer := 0;
	signal clk_300Mcount : integer := 0;
	signal clk50M, clk100M, clk300M : std_logic := '0';

	signal engine_i, engine_o : fractal_slice_data := fractal_slice_data_init;
	
	signal rd_en, wr_en : std_logic := '0';
	
	signal load_en : std_logic := '0';
	signal load_start : std_logic := '0';
	signal load_finished : std_logic := '0';
	signal load_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal load_cnt : integer := 0;
	signal load_addr, read_addr : std_logic_vector(TPL_NP2-1 downto 0) := (others => '0');
	
	signal read_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	
	signal hold : std_logic := '1';
	
	signal load_reg, load_dly : std_logic := '0';
	
	signal up_buffer_done, dwn_buffer_done : std_logic := '0';
	
	signal downstream_done : std_logic := '0';
	signal wr_en_prev : std_logic := '0';
	
	signal out_en, out_rdy : std_logic := '0';
	signal out_data : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal stretch : std_Logic := '0';
	signal out_ack : std_logic := '0';
	signal out_sync : std_logic := '0';
	
	signal up_buffer_done_meta, up_buffer_done_sync : std_logic := '0';
	
begin

	mmcm_adv_inst: unisim.vcomponents.MMCME2_ADV
		generic map(
		  BANDWIDTH => "OPTIMIZED",
		  CLKFBOUT_MULT_F => 18.000,
		  CLKFBOUT_PHASE => 0.000000,
		  CLKFBOUT_USE_FINE_PS => false,
		  CLKIN1_PERIOD => 20.000000,
		  CLKIN2_PERIOD => 0.000000,
		  CLKOUT0_DIVIDE_F => 27.000000,
		  CLKOUT0_DUTY_CYCLE => 0.500000,
		  CLKOUT0_PHASE => 0.000000,
		  CLKOUT0_USE_FINE_PS => false,
		  CLKOUT1_DIVIDE => 3,
		  CLKOUT1_DUTY_CYCLE => 0.500000,
		  CLKOUT1_PHASE => 0.000000,
		  CLKOUT1_USE_FINE_PS => false,
		  CLKOUT2_DIVIDE => 1,
		  CLKOUT2_DUTY_CYCLE => 0.500000,
		  CLKOUT2_PHASE => 0.000000,
		  CLKOUT2_USE_FINE_PS => false,
		  CLKOUT3_DIVIDE => 1,
		  CLKOUT3_DUTY_CYCLE => 0.500000,
		  CLKOUT3_PHASE => 0.000000,
		  CLKOUT3_USE_FINE_PS => false,
		  CLKOUT4_CASCADE => false,
		  CLKOUT4_DIVIDE => 1,
		  CLKOUT4_DUTY_CYCLE => 0.500000,
		  CLKOUT4_PHASE => 0.000000,
		  CLKOUT4_USE_FINE_PS => false,
		  CLKOUT5_DIVIDE => 1,
		  CLKOUT5_DUTY_CYCLE => 0.500000,
		  CLKOUT5_PHASE => 0.000000,
		  CLKOUT5_USE_FINE_PS => false,
		  CLKOUT6_DIVIDE => 1,
		  CLKOUT6_DUTY_CYCLE => 0.500000,
		  CLKOUT6_PHASE => 0.000000,
		  CLKOUT6_USE_FINE_PS => false,
		  COMPENSATION => "ZHOLD",
		  DIVCLK_DIVIDE => 1,
		  IS_CLKINSEL_INVERTED => '0',
		  IS_PSEN_INVERTED => '0',
		  IS_PSINCDEC_INVERTED => '0',
		  IS_PWRDWN_INVERTED => '0',
		  IS_RST_INVERTED => '0',
		  REF_JITTER1 => 0.010000,
		  REF_JITTER2 => 0.010000,
		  SS_EN => "FALSE",
		  SS_MODE => "CENTER_HIGH",
		  SS_MOD_PERIOD => 10000,
		  STARTUP_WAIT => false
		)
			port map (
		  CLKFBIN => clkfb,
		  CLKFBOUT => clkfb,
		  CLKFBOUTB => open,
		  CLKFBSTOPPED => open,
		  CLKIN1 => clk50M,
		  CLKIN2 => '0',
		  CLKINSEL => '1',
		  CLKINSTOPPED => open,
		  CLKOUT0 => clk100M,
		  CLKOUT0B => open,
		  CLKOUT1 => clk300M,
		  CLKOUT1B => open,
		  CLKOUT2  => open,
		  CLKOUT2B => open,
		  CLKOUT3  => open,
		  CLKOUT3B => open,
		  CLKOUT4  => open,
		  CLKOUT5  => open,
		  CLKOUT6  => open,
		  DADDR(6 downto 0) => b"0000000",
		  DCLK => '0',
		  DEN => '0',
		  DI(15 downto 0) => B"0000000000000000",
		  DO              => open,
		  DRDY => open,
		  DWE => '0',
		  LOCKED => locked,
		  PSCLK => '0',
		  PSDONE => open,
		  PSEN => '0',
		  PSINCDEC => '0',
		  PWRDWN => '0',
		  RST => '0'
    );

	clk_stim : process
	begin
		clk50M <= '0';
		wait for 10 ns;
		clk50M <= '1';
		wait for 10 ns;
	end process;
	
	fill_bram : process(clk100M)
	begin
		if(clk100M'event and clk100M = '1') then
			clk_100Mcount <= clk_100Mcount + 1;
			if(clk_100Mcount = 20) then
				load_start <= '1';
			end if;
			if(load_start = '1') then
				load_en <= '1';
				load_data <= std_logic_vector(unsigned(load_data)+1);
				load_cnt <= load_cnt + 1;
			end if;
			if(load_en = '1') then
				load_addr <= std_logic_vector(unsigned(load_addr)+1);
			end if;
			if(load_cnt = TPL) then
				load_en <= '0';
				load_start <= '0';
				load_finished <= '1';
				load_addr <= (others => '0');
			end if;
			if(load_finished = '1') then
				clk_100Mcount <= 0;
			end if;
			
			if(up_buffer_done = '1') then
				load_start <= '1';
			end if;
			
		end if;
	end process;
	
	engine_i.coord_real <= read_data(31 downto 0);
	engine_i.coord_imag <= read_data(31 downto 0);
	engine_i.math_x <= read_data(31 downto 0);
	engine_i.math_y <= read_data(31 downto 0);
	
	upstream_ctrl_inst : entity work.fractal_flow_control
	generic map(
		f_DEPTH => TPL,
		f_ORDER => TPL_NP2,
		f_WIDTH => DATA_WIDTH,
		f_OREGS => BRAM_LATENCY
		
	)
	port map(
		wr_clk      => clk100M,
		wr_data     => load_data,
		wr_en       => load_en,
		rd_clk      => clk300M,
		rd_data     => read_data,
		rd_en       => rd_en,
		buffer_done => up_buffer_done
	);
	
	process(clk300M)
	begin
		if(clk300M'event and clk300M = '1') then
			up_buffer_done_meta <= up_buffer_done;
			up_buffer_done_sync <= up_buffer_done_meta;
			
			if(up_buffer_done_sync = '1') then
				hold <= '0';
			end if;
		end if;
	end process;

	downstream_ctrl_inst : entity work.fractal_flow_control
	generic map(
		f_DEPTH => TPL,
		f_ORDER => TPL_NP2,
		f_WIDTH => DATA_WIDTH,
		f_OREGS => BRAM_LATENCY
		
	)
	port map(
		wr_clk      => clk300M,
		wr_data     => engine_o.coord_real,
		wr_en       => wr_en,
		rd_clk      => clk100M,
		rd_data     => out_data,
		rd_en       => out_en,
		buffer_done => out_rdy
	);
	
	--pulse stretch
	process(clk300M)
	begin
		if(clk300M'event and clk300M = '1') then
			if(up_buffer_done = '1') then
				stretch <= '1';
			end if;
			if(out_ack = '1') then
				stretch <= '0';
			end if;
		end if;
	end process;
	
	process(clk100M)
	begin
		if(clk100M'event and clk100M = '1') then
			out_ack <= '0';
			out_sync <= '0';
			if(stretch = '1') then
				out_ack <= '1';
				out_sync <= '1';
			end if;
			if(out_sync = '1') then
				out_en <= '1';
			end if;
		end if;
	end process;
	
	--testbench stimulus
	-- process(clk300M)
	-- begin
		-- if(clk300M'event and clk300M = '1') then
			-- --engine_i <= fractal_slice_data_init;
			
			-- clk_count <= clk_count + 1;
			
			-- if(rd_en = '1') then
				-- -- if(clk_count = 301) then		
					-- -- --test the coordinate delay
					-- -- engine_i.coord_real <= x"00001234";
					-- -- engine_i.coord_imag <= x"00004321";
					-- -- engine_i.math_x <= x"00001234";
					-- -- engine_i.math_y <= x"00004321";
					-- -- engine_i.metadata <= "1010";
				-- -- end if;
				
				-- -- if(clk_count = 302) then
					-- -- engine_i.coord_real <= x"00002626";
					-- -- engine_i.coord_imag <= x"00006262";
					-- -- engine_i.math_x <= x"00001234";
					-- -- engine_i.math_y <= x"00004321";
				-- -- end if;
				
				-- if(clk_count = 301) then
					-- engine_i.coord_real <= x"00011313";
					-- engine_i.coord_imag <= x"00013131";
					-- engine_i.math_x <= x"00011313";
					-- engine_i.math_y <= x"00013131";
					-- engine_i.metadata <= "1010";
				-- end if;
				
				-- if(clk_count = 302) then
					-- engine_i.coord_real <= x"00015A5A"; 
					-- engine_i.coord_imag <= x"0001A5A5";
					-- engine_i.math_x <= x"00015A5A"; 
					-- engine_i.math_y <= x"0001A5A5";
					-- engine_i.metadata <= "0000";
				-- end if;
				
				-- if(clk_count = 303) then
					-- engine_i <= fractal_slice_data_init;
					-- engine_i.metadata <= "0101";
					-- clk_count <= 301;
				-- end if;
			-- else
				-- clk_count <= 301;
			-- end if;
			-- -- if(clk_count = 306) then
				-- -- clk_count <= 301;
			-- -- end if;
			
		-- end if;
	-- end process;

    process
    begin
  
	wait;
    
    end process;
    
end test;