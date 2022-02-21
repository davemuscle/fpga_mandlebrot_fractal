library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
	
use work.fractal_pkg.all;
	
--Dave Muscle
--Processing slice for the fractal engine

--Math structure is:
--input = x, y, r2
--  Get x^2, y^2, and 2xy
--  Calculate:
--		x  = x^2 - y^2 + c_real
--      y  = 2xy + c_imag
--		r2 = x^2 + y^2;
--  Where c depends on the fractal (Mandlebrot vs Julia)
--	Compare r2 to the escape value
--output = x, y, r2


entity fractal_slice is
	generic(
		USE_SQ_LOGIC     : integer := 1
	);
	port(
		--clocking
	    clk      : in std_logic;
		
		--escape is the comparison value for the radius
		--this is typically constant for all fractal calculations
		escape  : in std_logic_vector(QFORMAT_INT-1 downto 0);

		slice_port_i : in  fractal_slice_data := fractal_slice_data_init;
		slice_port_o : out fractal_slice_data := fractal_slice_data_init
		
        );
end fractal_slice;

architecture arch of fractal_slice is 

	constant NUM_DSP_DLY : integer := 4; -- was 4 

	--registers for input and output ports
	signal slice_port_i_reg : fractal_slice_data := fractal_slice_data_init;
	signal slice_port_o_reg : fractal_slice_data := fractal_slice_data_init;
	
	--slv for pipelining, the idea is we infer an srl for each bit, saving ffs
	--the slv length is the depth of the srl
	--the array length is how many bits we have
	constant COORD_DLY : integer range 0 to 15 := 7; --was 7
	type     coord_slv_slr is array (0 to DATA_WIDTH-1) of std_logic_vector(COORD_DLY-1 downto 0);
	signal   coord_real_slr : coord_slv_slr := (others => (others => '0'));
	signal   coord_imag_slr : coord_slv_slr := (others => (others => '0'));
	signal   math_r_slr     : coord_slv_slr := (others => (others => '0'));

	constant META_DLY : integer range 0 to 15 := 8; --was 8
	type     meta_slv_slr is array (0 to META_WIDTH-1) of std_logic_vector(META_DLY-1 downto 0);
	signal   meta_slr : meta_slv_slr := (others => (others => '0'));

	constant LOCK_DLY : integer range 0 to 15 := COORD_DLY;
	signal   lock_slr : std_logic_vector(LOCK_DLY-1 downto 0) := (others => '0');
	
	constant ITER_DLY : integer range 0 to 15 := COORD_DLY;
	type     iter_slv_slr is array (0 to ITER_WIDTH-1) of std_logic_vector(ITER_DLY-1 downto 0);
	signal   iter_slr : iter_slv_slr := (others => (others => '0'));
	
	--delayed signals
	signal coord_real : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal coord_imag : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal lock       : std_logic := '0';
	signal math_r_dly : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal iter_count : std_logic_vector(ITER_WIDTH-1 downto 0) := (others => '0'); 
	
	attribute shreg_extract : string;
	attribute srl_style : string;
	
	--instruct Vivado to infer SRL for the shift registers regardless of length
	attribute shreg_extract of coord_real_slr, 
							   coord_imag_slr,
							   math_r_slr,
							   meta_slr,
							   lock_slr,
							   iter_slr : signal is "yes";
							   
	--instruct Vivado to not place registers before or after the shift reg, since I've already handled it
	attribute srl_style of coord_real_slr, 
							   coord_imag_slr,
							   math_r_slr,
							   meta_slr,
							   lock_slr,
							   iter_slr : signal is "srl";
	
	--adder signals
	signal adder_xx_sub_yy : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal adder_xx_pls_yy : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal adder_xy2       : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

	--multiplier signals
	signal a_pre, b_pre : std_logic_vector(  DATA_WIDTH-1 downto 0) := (others => '0');
	signal m            : std_logic_vector(2*DATA_WIDTH-1 downto 0) := (others => '0');
	
	--squarer signals
	signal squarer_x_o : std_logic_vector(2*DATA_WIDTH-1 downto 0) := (others => '0');
	signal squarer_y_o : std_logic_vector(2*DATA_WIDTH-1 downto 0) := (others => '0');
	signal squarer_x_i : std_logic_vector(DATA_WIDTH-1 downto 0)   := (others => '0');
	signal squarer_y_i : std_logic_vector(DATA_WIDTH-1 downto 0)   := (others => '0');	
	
	--math signals
	signal math_x, math_y, math_r : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	
begin	
	

	process(clk)
	begin
		if(rising_edge(clk)) then

			--register the input
			slice_port_i_reg <= slice_port_i;
			
			-----------------------------------------------------------------------------------------
			--delay the coordinates, infer slr
			for i in 0 to DATA_WIDTH-1 loop
				
				coord_real_slr(i)(COORD_DLY-1 downto 0) <= coord_real_slr(i)(COORD_DLY-2 downto 0) & 
														   slice_port_i_reg.coord_real(i);
				coord_imag_slr(i)(COORD_DLY-1 downto 0) <= coord_imag_slr(i)(COORD_DLY-2 downto 0) & 
														   slice_port_i_reg.coord_imag(i);
				math_r_slr(i)(COORD_DLY-1 downto 0)     <= math_r_slr(i)(COORD_DLY-2 downto 0) & 
														   slice_port_i_reg.math_r(i); 
			end loop;
			
			--delay the metadata, infer slr
			for i in 0 to META_WIDTH-1 loop
				meta_slr(i)(META_DLY-1 downto 0) <= meta_slr(i)(META_DLY-2 downto 0) & 
												    slice_port_i_reg.metadata(i);
			end loop;
			
			--delay the lock signal, infer slr
			lock_slr(LOCK_DLY-1 downto 0) <= lock_slr(LOCK_DLY-2 downto 0) & 
								             slice_port_i_reg.lock;
	
			--delay the iteration count, infer slr
			for i in 0 to ITER_WIDTH-1 loop
			iter_slr(i)(ITER_DLY-1 downto 0) <= iter_slr(i)(ITER_DLY-2 downto 0) &
											    slice_port_i_reg.iter_count(i);
			end loop;
			-----------------------------------------------------------------------------------------
			
		
		    -----------------------------------------------------------------------------------------
			--add x^2 and y^2
			--subtract x^2 and y^2
			adder_xx_pls_yy <= std_logic_vector(
							   signed(squarer_x_o(QFORMAT_FRAC+DATA_WIDTH-1 downto QFORMAT_FRAC)) + 
							   signed(squarer_y_o(QFORMAT_FRAC+DATA_WIDTH-1 downto QFORMAT_FRAC)));
			adder_xx_sub_yy <= std_logic_vector(
							   signed(squarer_x_o(QFORMAT_FRAC+DATA_WIDTH-1 downto QFORMAT_FRAC)) - 
							   signed(squarer_y_o(QFORMAT_FRAC+DATA_WIDTH-1 downto QFORMAT_FRAC)));		
			--multiply x*y by 2
			adder_xy2 <= std_logic_vector(m(QFORMAT_FRAC + DATA_WIDTH-2 downto QFORMAT_FRAC)) & '0';

			--take out the coordinate data and previous radius
			for i in 0 to DATA_WIDTH-1 loop
				coord_real(i) <= coord_real_slr(i)(COORD_DLY-1);
				coord_imag(i) <= coord_imag_slr(i)(COORD_DLY-1);
				math_r(i)     <= math_r_slr(i)(COORD_DLY-1);
			end loop;
			
			--take out the lock
			lock <= lock_slr(LOCK_DLY-1);
			
			--take out the iteration count
			for i in 0 to ITER_WIDTH-1 loop
				iter_count(i) <= iter_slr(i)(ITER_DLY-1);
			end loop;
			-----------------------------------------------------------------------------------------
			
			
			-----------------------------------------------------------------------------------------
			--add x^2 - y^2 + real
			--add 2xy + imag
			--assign radius based on lock 
			--increase the iteration count
			slice_port_o_reg.math_x <= std_logic_vector(signed(adder_xx_sub_yy) + signed(coord_real));
			slice_port_o_reg.math_y <= std_logic_vector(signed(adder_xy2)       + signed(coord_imag));
			
			if(lock = '0') then
				--assign new radius
				slice_port_o_reg.math_r <= adder_xx_pls_yy;
				--increase iter count
				slice_port_o_reg.iter_count <= std_logic_vector(unsigned(iter_count) + 1);					
				--check if the new radius is lock-worthy
				if(adder_xx_pls_yy(DATA_WIDTH-1 downto QFORMAT_FRAC) >= escape) then
					slice_port_o_reg.lock <= '1';
				else
					slice_port_o_reg.lock <= '0';
				end if;
			
			else
				--we have already locked, just pass through
				slice_port_o_reg.iter_count <= iter_count;
				slice_port_o_reg.math_r <= math_r;
				slice_port_o_reg.lock <= lock;
			
			end if;
			
			--assign the delayed coordinates
			slice_port_o_reg.coord_real <= coord_real;
			slice_port_o_reg.coord_imag <= coord_imag;
			
			--assign output metadata
			for i in 0 to META_WIDTH-1 loop
				slice_port_o_reg.metadata(i) <= meta_slr(i)(META_DLY-1);
			end loop;
			-----------------------------------------------------------------------------------------
			
			--register the output
			slice_port_o <= slice_port_o_reg;
			
		end if;
	end process;

	
	--place two's complement logic in front of squarers
	--this should get optimized away if the logic squarers aren't used
	process(slice_port_i_reg.math_x, slice_port_i_reg.math_y)
	begin
		if(slice_port_i_reg.math_x(31) = '1') then
			squarer_x_i <= std_logic_vector(unsigned(not slice_port_i_reg.math_x) + 1);
		else
			squarer_x_i <= slice_port_i_reg.math_x;
		end if;	
		
		if(slice_port_i_reg.math_y(31) = '1') then
			squarer_y_i <= std_logic_vector(unsigned(not slice_port_i_reg.math_y) + 1);
		else
			squarer_y_i <= slice_port_i_reg.math_y;
		end if;	
	end process;
		
	PLACE_LOGIC_SQUARERS: if USE_SQ_LOGIC = 1 generate

		--instantiate x squarer
		x_square : entity work.squarer_32bit
		generic map(
			N => DATA_WIDTH
		)
		port map(
			clk => clk,
			a => squarer_x_i,
			p => squarer_x_o
		);	

		--instantiate y squarer
		y_square : entity work.squarer_32bit
		generic map(
			N => DATA_WIDTH
		)
		port map(
			clk => clk,
			a => squarer_y_i,
			p => squarer_y_o
		);
	end generate PLACE_LOGIC_SQUARERS;	

	PLACE_DSP_SQUARERS: if USE_SQ_LOGIC = 0 generate
		--infer DSP for x*x
		x_square : entity work.inferred_dsp
		generic map(
			DATA_WIDTH  => DATA_WIDTH,
			NUM_DSP_DLY => NUM_DSP_DLY
		)
		port map(
			clk => clk,
			a => slice_port_i_reg.math_x,
			b => slice_port_i_reg.math_x,
			m => squarer_x_o
		);		
	
		--infer DSP for y*y
		y_square : entity work.inferred_dsp
		generic map(
			DATA_WIDTH  => DATA_WIDTH,
			NUM_DSP_DLY => NUM_DSP_DLY
		)
		port map(
			clk => clk,
			a => slice_port_i_reg.math_y,
			b => slice_port_i_reg.math_y,
			m => squarer_y_o
		);			

	end generate PLACE_DSP_SQUARERS;

	--always use a dsp for the x*y multiplication
	dsp : entity work.inferred_dsp
	generic map(
		DATA_WIDTH  => DATA_WIDTH,
		NUM_DSP_DLY => NUM_DSP_DLY
	)
	port map(
		clk => clk,
		a => slice_port_i_reg.math_x,
		b => slice_port_i_reg.math_y,
		m => m
	);	
end arch;