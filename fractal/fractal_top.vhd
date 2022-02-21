library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

use work.fractal_pkg.all;


entity fractal_top is 
	port(
		clk50M : in std_logic;
    	led0 : out std_logic;
		led1 : out std_logic;
		key1 : in std_logic;
		key2 : in std_logic;
		TMDS_clk_p  : out std_logic;
		TMDS_clk_n  : out std_logic;
		--2:0 are RGB (in order)
		TMDS_data_p : out std_logic_vector(2 downto 0);
		TMDS_data_n : out std_logic_vector(2 downto 0)
		
	);
end fractal_top;

architecture test of fractal_top is
    
	signal metadata_i : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	signal metadata_o : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	
	signal clk62M, clk74M : std_logic := '0';
	signal clk_core : std_logic := '0';
	signal clk148M, clk740M : std_logic := '0';

	signal locked_dly : std_logic_vector(31 downto 0) := (others => '1');

	signal hblank, vblank, hsync, vsync : std_logic := '0';

	signal core_i, core_o : fractal_slice_data := fractal_slice_data_init;
	signal load_en : std_logic := '0';
	
	signal core_coord_real_in, core_coord_imag_in : std_logic_vector(31 downto 0) := (others => '0');
	signal core_metadata_in : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	
	signal de : std_logic := '0';
	
	signal mmcm_main_fb, mmcm_main_locked : std_logic := '0';
	signal mmcm_core_fb, mmcm_core_locked : std_logic := '0';
	
	signal clk_count_start : integer := 0;
	signal start : std_logic := '0';
	
	--metadata flow:
	signal vid_ext_out_meta : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');	
	signal vid_deint_out_meta : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	signal vid_sync_gen_meta : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	
	--data flow:
	signal iter_count : std_logic_vector(9 downto 0) := (others => '0');
	signal vid_ext_out : std_logic_vector(11 downto 0) := (others => '0');
	signal vid_deint_out : std_logic_vector(11 downto 0) := (others => '0');
	signal vid_color_lut_out : std_logic_vector(23 downto 0) := (others => '0');
	signal vid_gblur_out : std_logic_vector(23 downto 0) := (others => '0');
	signal vid_sync_gen_in : std_logic_vector(23 downto 0) := (others => '0');
	signal vid_sync_gen_out : std_logic_vector(23 downto 0) := (others => '0');	
	signal vid_data : std_logic_vector(23 downto 0) := (others => '0');
	
	signal vid_color_lut_out_meta : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	signal vid_gblur_out_meta : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	
	signal smooth_o_int : std_logic_vector(9 downto 0) := (others => '0');
	signal smooth_o_frac : std_logic_vector(4 downto 0) := (others => '0');
	signal smooth_o : std_logic_vector(11 downto 0) := (others => '0');
	
	signal overflow, underflow : std_logic := '0';
	
	signal sof : std_logic := '0';
	
	
	signal pixel_count : integer := 0;
	
	signal h_count, v_count : integer := 0;
	signal h_count_slv, v_count_slv : std_logic_vector(31 downto 0) := (others => '0');
	
	signal start_core : std_logic := '0';
	
	signal key1_meta : std_logic := '0';
	signal key1_reg  : std_logic := '0';
	signal key1_dly  : std_logic := '0';
	signal key_release : std_logic := '0';
	signal key_count : integer := 0;
	signal key_en : std_logic := '0';
	
	signal key2_meta : std_logic := '0';
	signal key2_reg  : std_logic := '0';
	signal key2_dly  : std_logic := '0';
	signal key2_count : integer := 0;
	signal key2_en : std_logic := '0';
	

	
	signal smooth_passthrough : std_logic := '0';
	signal palette_select : integer := 0;
	
	COMPONENT ila_1
	PORT (
		clk : IN STD_LOGIC;
		probe0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe4 : IN STD_LOGIC_VECTOR( 3 DOWNTO 0); 
		probe5 : IN STD_LOGIC_VECTOR( 0 DOWNTO 0)
	);
	END COMPONENT  ;
	
	signal iter_ext : std_logic_vector(31 downto 0) := (others => '0');
	
	signal smooth_iter_ext : std_logic_vector(31 downto 0) := (others => '0');
	signal color_ext : std_logic_vector(31 downto 0) := (others => '0');
	
	signal gblur_enable : std_logic := '0';
	
	signal gblur_ext : std_logic_vector(31 downto 0) := (others => '0');
	
	signal scrn_q_o : std_logic_vector(31 downto 0) := (others => '0');
	signal scrn_i_o : std_logic_vector(31 downto 0) := (others => '0');
	signal step_q_o : std_logic_vector(31 downto 0) := (others => '0');
	signal step_i_o : std_logic_vector(31 downto 0) := (others => '0');
	
	COMPONENT zoom_pan_vio
	  PORT (
		clk : IN STD_LOGIC;
		probe_in0 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		probe_in1 : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
		probe_out0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		probe_out1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		probe_out2 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
		probe_out3 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
		probe_out4 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
		probe_out5 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
		probe_out6 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0);
		probe_out7 : OUT STD_LOGIC_VECTOR(0 DOWNTO 0)
	  );
	END COMPONENT;
	
	signal zoom_step, pan_step : std_logic_vector(31 downto 0) := (others => '0');

	signal zoom_en : std_logic_vector(1 downto 0) := (others => '0');
	signal pan_en : std_logic_vector(3 downto 0)  := (others => '0');
	
	signal pan_l, pan_r, pan_u, pan_d, zoom_i, zoom_o : std_logic := '0';
	
	signal vsync_reg, hsync_reg, de_reg : std_logic := '0';
	
	signal fractal_sync_checker_v_count, fractal_sync_checker_h_count : std_logic_vector(31 downto 0) := (others => '0');
	signal fractal_sync_checker_error : std_logic := '0';

	COMPONENT sync_checker_ila
	PORT (
		clk : IN STD_LOGIC;
		probe0 : IN STD_LOGIC_VECTOR(3 DOWNTO 0); 
		probe1 : IN STD_LOGIC_VECTOR(0 DOWNTO 0); 
		probe2 : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe3 : IN STD_LOGIC_VECTOR(31 DOWNTO 0)
	);
	END COMPONENT  ;
	
	signal core_i_iter_count_ext, core_o_iter_count_ext : std_logic_vector(31 downto 0);
	
	signal st_up_wr_addr, st_up_rd_addr : std_logic_vector(TPL_NP2 downto 0);
	signal st_dn_wr_addr, st_dn_rd_addr : std_logic_vector(TPL_NP2 downto 0);
	signal st_up_wr_addr_ext, st_up_rd_addr_ext : std_logic_vector(31 downto 0);
	signal st_dn_wr_addr_ext, st_dn_rd_addr_ext : std_logic_vector(31 downto 0);
	
	signal st_up_wr_en, st_up_rd_en : std_logic;
	signal st_dn_wr_en, st_dn_rd_en : std_logic;
	
	signal st_up_wr_buffer_sel, st_up_rd_buffer_sel : std_logic;
	signal st_dn_wr_buffer_sel, st_dn_rd_buffer_sel : std_logic;
	
	signal st_up_buffer_done, st_dn_buffer_done : std_logic;
	signal st_up_error, st_dn_error : std_logic;

	COMPONENT flowcontrol_ila
	PORT (
		clk     : IN STD_LOGIC;
		probe0  : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe1  : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe2  : IN STD_LOGIC_VECTOR( 0 DOWNTO 0); 
		probe3  : IN STD_LOGIC_VECTOR( 0 DOWNTO 0); 
		probe4  : IN STD_LOGIC_VECTOR( 0 DOWNTO 0); 
		probe5  : IN STD_LOGIC_VECTOR( 0 DOWNTO 0);
		probe6  : IN STD_LOGIC_VECTOR( 0 DOWNTO 0); 
		probe7  : IN STD_LOGIC_VECTOR( 0 DOWNTO 0);
		probe8  : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe9  : IN STD_LOGIC_VECTOR(31 DOWNTO 0); 
		probe10 : IN STD_LOGIC_VECTOR( 0 DOWNTO 0); 
		probe11 : IN STD_LOGIC_VECTOR( 0 DOWNTO 0); 
		probe12 : IN STD_LOGIC_VECTOR( 0 DOWNTO 0); 
		probe13 : IN STD_LOGIC_VECTOR( 0 DOWNTO 0);
		probe14 : IN STD_LOGIC_VECTOR( 0 DOWNTO 0); 
		probe15 : IN STD_LOGIC_VECTOR( 0 DOWNTO 0)
		
	);
	END COMPONENT  ;
	
	component clk_wiz
	port
	 (-- Clock in ports
	  -- Clock out ports
	  clk_out1          : out    std_logic;
	  clk_out2          : out    std_logic;
	  clk_out3          : out    std_logic;
	  clk_out4          : out    std_logic;
	  -- Status and control signals
	  locked            : out    std_logic;
	  clk_in1           : in     std_logic
	 );
	end component;
	
	signal clk50M_ibuf, clk50M_bufg : std_logic := '0';
	
	COMPONENT screen_setter_vio
	  PORT (
		clk : IN STD_LOGIC;
		probe_out0 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		probe_out1 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		probe_out2 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
		probe_out3 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
		
	  );
	END COMPONENT;
	
	
begin


	process(clk62M)
	begin
		if(rising_edge(clk62M)) then

			if(clk_count_start = 50) then
				start <= '1';
			else
				clk_count_start <= clk_count_start + 1;
			end if;
			
			if(start = '1') then
				sof <= '0';
				if(h_count = 1920-1) then
					h_count <= 0;
					if(v_count = 540-1) then
						v_count <= 0;
						sof <= '1';
					else
						v_count <= v_count + 1;
					end if;
				else
					h_count <= h_count + 1;
				end if;
			end if;
		end if;
	end process;

	h_count_slv <= std_logic_vector(to_unsigned(h_count,32));
	v_count_slv <= std_logic_vector(to_unsigned(v_count,32));
	
	zoom_pan_vio_inst: zoom_pan_vio
	  PORT MAP (
		clk => clk62M,
		probe_in0  => (others => '0'),
		probe_in1  => (others => '0'),
		probe_out0 => zoom_step,
		probe_out1 => pan_step,
		probe_out2(0) => pan_l,
		probe_out3(0) => pan_r,
		probe_out4(0) => pan_u,
		probe_out5(0) => pan_d,
		probe_out6(0) => zoom_o,
		probe_out7(0) => zoom_i
	  );
	
	pan_en <= pan_d & pan_u & pan_r & pan_l;
	zoom_en <= zoom_o & zoom_i;
	
	fractal_screen_gen_inst : entity work.fractal_screen_gen
	generic map(
		SIM => 0,
		DATA_WIDTH  => DATA_WIDTH,
		QINT_WIDTH  => QFORMAT_INT,
		QFRAC_WIDTH => QFORMAT_FRAC,
		META_WIDTH  => META_WIDTH,
		h_active    => 1920,
		v_active    => 540
	)
	port map(
		clk          => clk62M,
		field_marker => sof,
		pan_en       => pan_en,
		zoom_en      => zoom_en,
		pan_step     => pan_step,
		zoom_step    => zoom_step,
		metadata_o   => metadata_i,
		scrn_q_o     => scrn_q_o,
		scrn_i_o     => scrn_i_o,
		step_q_o     => step_q_o,
		step_i_o     => step_i_o
	);
	
	
	-- screen_setter_vio_inst: screen_setter_vio
    -- PORT MAP (
	-- clk => clk62M,
	-- probe_out0 => scrn_q_o,
	-- probe_out1 => scrn_i_o,
	-- probe_out2 => step_q_o,
	-- probe_out3 => step_i_o

    -- );
	-- metadata_i(0) <= sof;
	
	ila_coords : ila_1
	PORT MAP (
		clk        => clk62M,
		probe0     => scrn_q_o,
		probe1     => scrn_i_o,
		probe2     => step_q_o,
		probe3     => step_i_o,
		probe4     => metadata_i,
		probe5     => (others => '0')

	);

	fractal_coord_gen_inst : entity work.fractal_coord_gen
	generic map(
		DATA_WIDTH   => DATA_WIDTH,
		META_WIDTH   => META_WIDTH,
		h_active     => 1920,
		v_active     => 540
		)
	port map(
		clk           => clk62M,
		metadata_i    => metadata_i,
		screen_real_i => scrn_q_o,
		screen_imag_i => scrn_i_o,
		screen_step_x => step_q_o,
		screen_step_y => step_i_o,
		metadata_o    => core_metadata_in,
		coord_real_o  => core_coord_real_in,
		coord_imag_o  => core_coord_imag_in
	);
	
	process(clk62M)
	begin
		if(rising_edge(clk62M)) then
			if(core_metadata_in(0) = '1') then
				start_core <= '1';
			end if;
			
			core_i.metadata   <= core_metadata_in;
			core_i.coord_real <= core_coord_real_in;
			core_i.coord_imag <= core_coord_imag_in;
			
		end if;
	end process;

	core_i_iter_count_ext <= std_logic_vector(resize(unsigned(core_i.iter_count),32));

	process(clk62M)
	begin
		if(rising_edge(clk62M)) then
			key1_meta <= key1;
			key1_reg <= key1_meta;
			key1_dly <= key1_reg;
			
			key_count <= 0;
			
			if(key1_dly = '1' and key1_reg = '0') then
				key_en <= '1';
			end if;

			if(key_en = '1') then
				key_count <= key_count + 1;
				if(key_count = 40*(10**6)) then
					
					--start_core <= '1';
					key_en <= '0';
				end if;
			end if;

		end if;
	end process;

    fractal_core_inst : entity work.fractal_core
	generic map(
		NUM_DSP_SLICES => NUM_DSP_SLICES,
		NUM_LUT_SLICES => NUM_LUT_SLICES,
		NUM_SLICES   => NUM_SLICES,
		DATA_WIDTH   => DATA_WIDTH,
		QFORMAT_INT  => QFORMAT_INT,
		QFORMAT_FRAC => QFORMAT_FRAC,
		BRAM_LATENCY => BRAM_LATENCY,
		TPL          => TPL,
		TPL_NP2      => TPL_NP2,
		DRY_RUN      => 0
	)
	port map(
		clk_pixel           => clk62M,
		clk_core            => clk_core,
		escape              => x"04",
		enable              => start_core,
		core_port_i         => core_i,
		core_port_o         => core_o,
		st_up_wr_addr       => st_up_wr_addr,
		st_up_rd_addr       => st_up_rd_addr,
		st_up_wr_en         => st_up_wr_en,
		st_up_rd_en         => st_up_rd_en,
		st_up_wr_buffer_sel => st_up_wr_buffer_sel,
		st_up_rd_buffer_sel => st_up_rd_buffer_sel,
		st_up_buffer_done   => st_up_buffer_done,
		st_up_error         => st_up_error,
		st_dn_wr_addr       => st_dn_wr_addr,
		st_dn_rd_addr       => st_dn_rd_addr,
		st_dn_wr_en         => st_dn_wr_en,
		st_dn_rd_en         => st_dn_rd_en,
		st_dn_wr_buffer_sel => st_dn_wr_buffer_sel,
		st_dn_rd_buffer_sel => st_dn_rd_buffer_sel,
		st_dn_buffer_done   => st_dn_buffer_done,
		st_dn_error         => st_dn_error        
	);

	st_up_wr_addr_ext <= std_logic_vector(resize(unsigned(st_up_wr_addr),32));
	st_up_rd_addr_ext <= std_logic_vector(resize(unsigned(st_up_rd_addr),32));
	st_dn_wr_addr_ext <= std_logic_vector(resize(unsigned(st_dn_wr_addr),32));
	st_dn_rd_addr_ext <= std_logic_vector(resize(unsigned(st_dn_rd_addr),32));

	-- flowcontrol_ila_inst : flowcontrol_ila
	-- PORT MAP (
		-- clk        => clk_core,
		-- probe0     => st_up_wr_addr_ext,
		-- probe1     => st_up_rd_addr_ext,
		-- probe2(0)  => st_up_wr_en,
		-- probe3(0)  => st_up_rd_en,
		-- probe4(0)  => st_up_wr_buffer_sel,
		-- probe5(0)  => st_up_rd_buffer_sel,
		-- probe6(0)  => st_up_buffer_done,
		-- probe7(0)  => st_up_error,
		-- probe8     => st_dn_wr_addr_ext,
		-- probe9     => st_dn_rd_addr_ext,
		-- probe10(0) => st_dn_wr_en,
		-- probe11(0) => st_dn_rd_en,
		-- probe12(0) => st_dn_wr_buffer_sel,
		-- probe13(0) => st_dn_rd_buffer_sel,
		-- probe14(0) => st_dn_buffer_done,
		-- probe15(0) => st_dn_error

	-- );

	smooth_o <= (others => '1') when core_o.lock = '1' else (others => '0');
	metadata_o <= core_o.metadata;
	
	core_o_iter_count_ext <= std_logic_vector(resize(unsigned(core_o.iter_count),32));
	
	ila_fractal_output : ila_1
	PORT MAP (
		clk        => clk62M,
		probe0     => core_o_iter_count_ext,
		probe1     => core_o.coord_real,
		probe2     => core_o.coord_imag,
		probe3     => core_o.math_r,
		probe4     => core_o.metadata,
		probe5(0)  => core_o.lock

	);
	
	fractal_sync_checker_inst : entity work.fractal_sync_checker
	generic map(
		META_WIDTH   => META_WIDTH,
		h_active     => 1920,
		v_active     => 540
		)
	port map(
		clk           => clk62M,
		metadata_i    => metadata_o,
		h_count_o     => fractal_sync_checker_h_count,
		v_count_o     => fractal_sync_checker_v_count,
		error_o       => fractal_sync_checker_error
	);
	
	ila_fractal_sync_checker : sync_checker_ila
	PORT MAP (
		clk        => clk62M,
		probe0     => metadata_o,
		probe1(0)  => fractal_sync_checker_error,
		probe2     => fractal_sync_checker_h_count,
		probe3     => fractal_sync_checker_v_count
	);
	
	-- fractal_smooth_count_inst : entity work.fractal_smooth_count
	-- generic map(
		-- ITER_WIDTH => 10,
		-- RAD_WIDTH  => 8,
		-- META_WIDTH => 1,
		
		-- INT_WIDTH  => 3,
		-- FRAC_WIDTH => 5,
		
		-- INIT_FILE => "C:/Users/Dave/Desktop/FPGA/Projects/BigusShapus/fractal/fractal_smooth_lut.data"
		-- )
	-- port map(
		-- clk => clk62M,
		-- passthrough => smooth_passthrough,
		-- lock_i => core_o.lock,
		-- metadata_i => core_o.metadata,
		-- iter_i => core_o.iter_count,
		-- rad_i => core_o.math_r(31 downto 24),
		-- metadata_o => metadata_o,
		-- smooth_o_int => smooth_o_int,
		-- smooth_o_frac => smooth_o_frac
		
	-- );	

	--smooth_o <= smooth_o_int(6 downto 0) & smooth_o_frac(4 downto 0);

	-- process(clk62M)
	-- begin
		-- if(clk62M'event and clk62M = '1') then
			-- key2_meta <= key2;
			-- key2_reg <= key2_meta;
			-- key2_dly <= key2_reg;
			
			-- key2_count <= 0;
			
			-- if(key2_dly = '1' and key2_reg = '0') then
				-- key2_en <= '1';
			-- end if;

			-- if(key2_en = '1') then
				-- key2_count <= key2_count + 1;
				-- if(key2_count = 100*(10**6)) then
						
					-- smooth_passthrough <= not smooth_passthrough;
							
					-- key2_en <= '0';
				-- end if;
			-- end if;

		-- end if;
	-- end process;
	
    video_pclk_extender_inst : entity work.video_pclk_extender
	generic map(
		DEBUG => 1,
		DATA_WIDTH   => 12,
		META_WIDTH   => 4,
		SCALE_MULT   => 1,
		SCALE_DIV    => 1,
		SOF_BP       => 0,
		EOL_BP       => 1,
        h_active 	 => 1920,
		h_blanking   => 240,
        h_total      => 2160,
        v_active     => 540,
		v_blanking   => 36,
        v_total		 => 576
	)
	port map(
		clk_a => clk62M,
		pixel_a => smooth_o,
		metadata_a => metadata_o,
		
		clk_b => clk74M,
		pixel_b => vid_ext_out,
		metadata_b => vid_ext_out_meta,
		
		overflow => overflow,
		underflow => underflow
	);

	led0 <= not overflow;
	led1 <= not underflow;

	-- process(clk148M)
	-- begin
		-- if(clk148M'event and clk148M = '1') then
			-- key1_meta <= key1;
			-- key1_reg <= key1_meta;
			-- key1_dly <= key1_reg;
			
			-- key_count <= 0;
			
			-- if(key1_dly = '1' and key1_reg = '0') then
				-- key_en <= '1';
			-- end if;

			-- if(key_en = '1') then
				-- key_count <= key_count + 1;
				-- if(key_count = 100*(10**6)) then
					
					
					-- if(palette_select = 0) then
						-- palette_select <= 1;
					-- else
						-- palette_select <= 0;
					-- end if;
					
					-- gblur_enable <= not gblur_enable;
					
					-- key_en <= '0';
				-- end if;
			-- end if;

		-- end if;
	-- end process;

	-- smooth_iter_ext <= std_logic_vector(resize(unsigned(vid_deint_out),smooth_iter_ext'length));

	-- -- ila_color : ila_1
	-- -- PORT MAP (
		-- -- clk        => clk148M,
		-- -- probe0     => smooth_iter_ext,
		-- -- probe1     => color_ext,
		-- -- probe2     => gblur_ext,
		-- -- probe3     => (others => '0'),
		-- -- probe4     => vid_deint_out_meta,
		-- -- probe5     => vid_gblur_out_meta

	-- -- );

	-- color_ext <= std_logic_vector(resize(unsigned(vid_sync_gen_in),smooth_iter_ext'length));

	-- fractal_color_lut_inst : entity work.fractal_color_lut
	-- generic map(
		-- ITER_WIDTH => 12,
		-- COLOR_DEPTH => 8,
		-- META_WIDTH => 1,
		-- NUM_COLORS => 80*32,
		-- NUM_PALETTES => 2,
		-- INIT_FILE => "C:/Users/Dave/Desktop/FPGA/Projects/BigusShapus/fractal/fractal_color_lut.data"
		-- )
	-- port map(
		-- clk => clk74M,
		-- palette_select => 0,
		-- metadata_i => vid_deint_out_meta,
		-- iter_i => vid_deint_out,
		-- metadata_o => vid_color_lut_out_meta,
		-- color_o => vid_color_lut_out
	-- );

	-- gblur_3x3_inst : entity work.gblur_3x3
	-- generic map(
		-- META_WIDTH => 1,
		-- h_active   => 1920,
		-- h_total    => 2160,
		-- v_active   => 540,
		-- v_total    => 576
		-- )
	-- port map(
		-- clk => clk74M,
		-- reset => '0',
		-- passthrough => gblur_enable,
		
		-- metadata_i => vid_color_lut_out_meta,
		-- color_i => vid_color_lut_out,
		
		-- metadata_o => vid_gblur_out_meta,
		-- color_o => vid_gblur_out
	-- );
	
	-- gblur_ext <= x"00" & vid_gblur_out;
	
	-- vid_sync_gen_in <= vid_gblur_out;
	-- vid_sync_gen_meta <= vid_gblur_out_meta;
	
	vid_sync_gen_in <= (others => '1') when vid_ext_out(0) = '1' else (others => '0');
	vid_sync_gen_meta <= vid_ext_out_meta;
	
	--sync marker generation
    video_sync_gen_inst : entity work.video_sync_gen
	generic map(
		DATA_WIDTH   => 24,
		META_WIDTH   => 4,
		SYNC_POL_BP  => 1,
		SOF_BP       => 0,
		EOL_BP       => 1,
        h_active 	 => 1920,
		h_frontporch => 76,
		h_syncwidth  => 36,
		h_backporch  => 128,
        h_total      => 2160,
        v_active     => 540,
		v_frontporch => 3,
		v_syncwidth  => 4,
		v_backporch  => 29,
        v_total		 => 576
		
	)
	port map(
		clk => clk74M,
		pixel_in => vid_sync_gen_in,
		metadata_in => vid_sync_gen_meta,
		hsync => hsync,
		vsync => vsync,
		hblank => open,
		vblank => open,
		de => de,
		pixel_out => vid_sync_gen_out
	);


	process(clk74M)
	begin
		if(rising_edge(clk74M)) then
			locked_dly(0) <= not mmcm_main_locked;
			locked_dly(31 downto 1) <= locked_dly(30 downto 0);
			
			hsync_reg <= hsync;
			vsync_reg <= vsync;
			de_reg <= de;
			vid_data <= vid_sync_gen_out;
			
			
		end if;
	end process;	
	
	hdmi_if_inst : entity work.hdmi_if
	port map(
		pclk     => clk74M, 
		pclk5x   => clk740M, 
		rst      => locked_dly(31),
		hsync    => hsync_reg,
		vsync    => vsync_reg,
		de       => de_reg,   
		video_in => vid_data,
		TMDS_clk_p  => TMDS_clk_p, 
		TMDS_clk_n  => TMDS_clk_n, 
		TMDS_data_p => TMDS_data_p,
		TMDS_data_n => TMDS_data_n
	);

	IBUF_inst : IBUF
	generic map(
		IBUF_LOW_PWR => FALSE,
		IOSTANDARD => "LVCMOS33"
	)
	port map(
		O => clk50M_ibuf,
		I => clk50M
	);
	
	BUFG_inst : BUFG
	port map(
		O => clk50M_bufg,
		I => clk50M_ibuf
	);
	

	clk_wiz_inst: clk_wiz
	   port map ( 
	  -- Clock out ports  
	   clk_out1 => clk62M,
	   clk_out2 => clk74M,
	   clk_out3 => clk_core,
	   clk_out4 => clk740M,
	  -- Status and control signals                
	   locked => mmcm_main_locked,
	   -- Clock in ports
	   clk_in1 => clk50M_bufg
	 );


	-- mmcm_main_inst: unisim.vcomponents.MMCME2_ADV
		-- generic map(
		  -- BANDWIDTH => "OPTIMIZED",
		  -- CLKFBOUT_MULT_F => 29.875000,
		  -- CLKFBOUT_PHASE => 0.000000,
		  -- CLKFBOUT_USE_FINE_PS => false,
		  -- CLKIN1_PERIOD => 20.000000,
		  -- CLKIN2_PERIOD => 0.000000,
		  -- CLKOUT0_DIVIDE_F => 12.00000,
		  -- CLKOUT0_DUTY_CYCLE => 0.500000,
		  -- CLKOUT0_PHASE => 0.000000,
		  -- CLKOUT0_USE_FINE_PS => false,
		  -- CLKOUT1_DIVIDE => 10,
		  -- CLKOUT1_DUTY_CYCLE => 0.500000,
		  -- CLKOUT1_PHASE => 0.000000,
		  -- CLKOUT1_USE_FINE_PS => false,
		  -- CLKOUT2_DIVIDE => 3,
		  -- CLKOUT2_DUTY_CYCLE => 0.500000,
		  -- CLKOUT2_PHASE => 0.000000,
		  -- CLKOUT2_USE_FINE_PS => false,
		  -- CLKOUT3_DIVIDE => 2,
		  -- CLKOUT3_DUTY_CYCLE => 0.500000,
		  -- CLKOUT3_PHASE => 0.000000,
		  -- CLKOUT3_USE_FINE_PS => false,
		  -- CLKOUT4_CASCADE => false,
		  -- CLKOUT4_DIVIDE => 1,
		  -- CLKOUT4_DUTY_CYCLE => 0.500000,
		  -- CLKOUT4_PHASE => 0.000000,
		  -- CLKOUT4_USE_FINE_PS => false,
		  -- CLKOUT5_DIVIDE => 1,
		  -- CLKOUT5_DUTY_CYCLE => 0.500000,
		  -- CLKOUT5_PHASE => 0.000000,
		  -- CLKOUT5_USE_FINE_PS => false,
		  -- CLKOUT6_DIVIDE => 1,
		  -- CLKOUT6_DUTY_CYCLE => 0.500000,
		  -- CLKOUT6_PHASE => 0.000000,
		  -- CLKOUT6_USE_FINE_PS => false,
		  -- COMPENSATION => "ZHOLD",
		  -- DIVCLK_DIVIDE => 2,
		  -- IS_CLKINSEL_INVERTED => '0',
		  -- IS_PSEN_INVERTED => '0',
		  -- IS_PSINCDEC_INVERTED => '0',
		  -- IS_PWRDWN_INVERTED => '0',
		  -- IS_RST_INVERTED => '0',
		  -- REF_JITTER1 => 0.010000,
		  -- REF_JITTER2 => 0.010000,
		  -- SS_EN => "FALSE",
		  -- SS_MODE => "CENTER_HIGH",
		  -- SS_MOD_PERIOD => 10000,
		  -- STARTUP_WAIT => false
		-- )
			-- port map (
		  -- CLKFBIN => mmcm_main_fb,
		  -- CLKFBOUT => mmcm_main_fb,
		  -- CLKFBOUTB => open,
		  -- CLKFBSTOPPED => open,
		  -- CLKIN1 => clk50M,
		  -- CLKIN2 => '0',
		  -- CLKINSEL => '1',
		  -- CLKINSTOPPED => open,
		  -- CLKOUT0 => clk62M,
		  -- CLKOUT0B => open,
		  -- CLKOUT1 => clk74M,
		  -- CLKOUT1B => open,
		  -- CLKOUT2  => clk_core,
		  -- CLKOUT2B => open,
		  -- CLKOUT3  => clk740M,
		  -- CLKOUT3B => open,
		  -- CLKOUT4  => open,
		  -- CLKOUT5  => open,
		  -- CLKOUT6  => open,
		  -- DADDR(6 downto 0) => b"0000000",
		  -- DCLK => '0',
		  -- DEN => '0',
		  -- DI(15 downto 0) => B"0000000000000000",
		  -- DO              => open,
		  -- DRDY => open,
		  -- DWE => '0',
		  -- LOCKED => mmcm_main_locked,
		  -- PSCLK => '0',
		  -- PSDONE => open,
		  -- PSEN => '0',
		  -- PSINCDEC => '0',
		  -- PWRDWN => '0',
		  -- RST => '0'
    -- );

	
    
end test;