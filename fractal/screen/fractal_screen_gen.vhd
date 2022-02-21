library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
--Dave Muscle

--Reads in zoom and pan inputs and outputs screen information
--Maintains a 16x4.5 aspect ratio for 1920x540 screen
--Outputs screen information at the start of the field (one field behind) for interlaced
 
 --Works off of a single point-of-interest, IE: the center
 --Panning is moving this POI
 --Zooming is changing the width of the complex plane, and the height auto adjusts
 -- It is designed to maintain the aspect ratio
 
entity fractal_screen_gen is
	generic(
		--for fractal slice data
		SIM : integer := 0;
		DATA_WIDTH  : integer := 32;
		QINT_WIDTH  : integer := 8;
		QFRAC_WIDTH : integer := 24;
		META_WIDTH  : integer := 1;
		
		h_active : integer := 1920;
		v_active : integer := 540

		);
	port(
	    clk            : in std_logic;
		field_marker   : in std_logic;
		
		pan_en        : in std_logic_vector(3 downto 0);
		zoom_en       : in std_logic_vector(1 downto 0);
		
		pan_step      : in std_logic_vector(DATA_WIDTH-1 downto 0);
		zoom_step     : in std_logic_vector(DATA_WIDTH-1 downto 0);
		
		metadata_o    : out std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
		scrn_q_o      : out std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0'); --screen coord real value
		scrn_i_o      : out std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0'); --screen coord imag value
	
		step_q_o      : out std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0'); --screen step real value
		step_i_o      : out std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0') --screen step imag value
		
        );
end fractal_screen_gen;

architecture arch of fractal_screen_gen is 

	--zoom and pan bit positions
	constant pan_left_BP : integer := 0;
	constant pan_right_BP : integer := 1;
	constant pan_up_BP : integer := 2;
	constant pan_down_BP : integer := 3;
	
	constant zoom_in_BP : integer := 0;
	constant zoom_out_BP : integer := 1;

	signal pan_en_reg : std_logic_vector(3 downto 0) := (others => '0');
	signal zoom_en_reg : std_logic_vector(1 downto 0) := (others => '0');

	--zoom and pan signals
	signal zoom_step_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal pan_step_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

	--division factors for setting up step values
	constant res_q_recip : integer := integer(real(2**QFRAC_WIDTH)/real(h_active));
	constant res_i_recip : integer := integer(real(2**QFRAC_WIDTH)/real(v_active));
	
	--aspect ratio for maintaining width and height
	constant aspect_ratio : integer := integer(real(2**QFRAC_WIDTH)*real(v_active)/real(h_active));

	--initialize to a screen width = 1
	signal scrn_width : std_logic_vector(DATA_WIDTH-1 downto 0) := std_logic_vector(to_unsigned(2**QFRAC_WIDTH,DATA_WIDTH));
	signal scrn_height_math : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	
	signal scrn_width_math : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal scrn_width_math_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal scrn_width_math_dly : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

	--center point for the screen
	signal poi_q : std_logic_vector(DATA_WIDTH-1 downto 0) := x"FE947AE2"; -- -1.42
	signal poi_i : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0'); -- 0
	
	signal poi_q_math : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal poi_i_math : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal poi_q_math_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal poi_i_math_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal poi_q_math_dly : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal poi_i_math_dly : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');	
	--how much to step the starting point by
	signal step_q : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal step_i : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

	--top left
	signal top_left_q : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal top_left_i : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	
	signal interlace : std_logic := '0';
	
	signal pan_l, pan_r, pan_d, pan_u : std_logic := '0';
	signal zoom_o, zoom_i : std_logic := '0';
	
	signal proc_en : std_logic_vector(7 downto 0) := (others => '0');
	
	signal scrn_q_o_pre : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal scrn_i_o_pre : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal step_q_o_pre : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal step_i_o_pre : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	
	signal metadata_o_pre : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	
	--reals for sim viewing
	signal top_left_q_real,
		   top_left_i_real,
		   poi_q_real,
		   poi_i_real,
		   poi_q_math_real,
		   poi_i_math_real,
		   scrn_width_real,
		   scrn_height_real
				: real := 0.0;

	
	
	
begin	

	process(clk)
		variable scrn_width_mult : std_logic_vector(2*DATA_WIDTH-1 downto 0);
		variable step_q_mult : std_logic_vector(2*DATA_WIDTH-1 downto 0);
		variable step_i_mult : std_logic_vector(2*DATA_WIDTH-1 downto 0);
	begin
		if(rising_edge(clk)) then
		
			metadata_o_pre <= (others => '0');
		
			proc_en(0) <= '0';
		
			--start of process on a new frame
			--field marker should be held for only one cycle
			if(field_marker = '1') then
				--field marker should be held for only one cycle
				proc_en(0) <= '1';
				
				--register in the input signals
				zoom_step_reg <= zoom_step;
				pan_step_reg <= pan_step;
				
				--pan signals
				pan_l <= pan_en(pan_left_BP);
				pan_r <= pan_en(pan_right_BP);
				pan_u <= pan_en(pan_up_BP);
				pan_d <= pan_en(pan_down_BP);

				--zoom signals
				zoom_i <= zoom_en(zoom_in_BP);
				zoom_o <= zoom_en(zoom_out_BP);

				pan_en_reg <= pan_en;
				zoom_en_reg <= zoom_en;
			
			end if;
			
			proc_en(proc_en'length-1 downto 1) <= proc_en(proc_en'length-2 downto 0);
			
			--read the zoom and pan settings, modify the width and POI
			if(proc_en(0) = '1') then
				
				--register the POI through, check the pan settings
				poi_q_math <= poi_q;
				poi_i_math <= poi_i;
			
				--register the width through, check the zoom settings
				scrn_width_math <= scrn_width;
				
				--pan_en_reg is: [down up right left]
				case pan_en_reg is 
				when "0001" => --pan left
					poi_q_math <= std_logic_vector(signed(poi_q) - signed(pan_step_reg));
				when "0010" => --pan right
					poi_q_math <= std_logic_vector(signed(poi_q) + signed(pan_step_reg));
				when "0100" => --pan up
					poi_i_math <= std_logic_vector(signed(poi_i) + signed(pan_step_reg));
				when "1000" => --pan down
					poi_i_math <= std_logic_vector(signed(poi_i) - signed(pan_step_reg));
				when "0101" => --pan up and left
					poi_q_math <= std_logic_vector(signed(poi_q) - signed(pan_step_reg));
					poi_i_math <= std_logic_vector(signed(poi_i) + signed(pan_step_reg));
				when "0110" => --pan up and right
					poi_q_math <= std_logic_vector(signed(poi_q) + signed(pan_step_reg));
					poi_i_math <= std_logic_vector(signed(poi_i) + signed(pan_step_reg));
				when "1001" => --pan down and left
					poi_q_math <= std_logic_vector(signed(poi_q) - signed(pan_step_reg));
					poi_i_math <= std_logic_vector(signed(poi_i) - signed(pan_step_reg));
				when "1010" => --pan down and right
					poi_q_math <= std_logic_vector(signed(poi_q) + signed(pan_step_reg));
					poi_i_math <= std_logic_vector(signed(poi_i) - signed(pan_step_reg));
				when others => --do nothing
				end case;
			
				--zoom_en_reg is: [out, in]
				case zoom_en_reg is
				when "01" => --zoom in
					scrn_width_math <= std_logic_vector(signed(scrn_width) - signed(zoom_step_reg));
				when "10" => --zoom out
					scrn_width_math <= std_logic_vector(signed(scrn_width) + signed(zoom_step_reg));
				when others => --do nothing
				end case;
				
			end if;
				
			--multiply the width by the aspect ratio to get the height width
			if(proc_en(1) = '1') then
				scrn_width_mult := std_logic_vector(signed(scrn_width_math) * to_signed(aspect_ratio,DATA_WIDTH));
				scrn_height_math <= scrn_width_mult(2*DATA_WIDTH-QINT_WIDTH-1 downto DATA_WIDTH-QINT_WIDTH);
			
				poi_q_math_reg <= poi_q_math;
				poi_i_math_reg <= poi_i_math;
			
				scrn_width_math_reg <= scrn_width_math;
			end if;
			
			--calculate the top left coordinate and the step values
			if(proc_en(2) = '1') then
				top_left_q <= std_logic_vector(signed(poi_q_math_reg) - signed('0' & scrn_width_math(31 downto 1)));
				top_left_i <= std_logic_vector(signed(poi_i_math_reg) + signed('0' & scrn_height_math(31 downto 1)));
				
				step_q_mult := std_logic_vector(signed(scrn_width_math_reg) * to_signed(res_q_recip,DATA_WIDTH));
				step_q <= step_q_mult(2*DATA_WIDTH-QINT_WIDTH-1 downto DATA_WIDTH-QINT_WIDTH);
				
				step_i_mult := std_logic_vector(signed(scrn_height_math) * to_signed(res_i_recip,DATA_WIDTH));
				step_i <= step_i_mult(2*DATA_WIDTH-QINT_WIDTH-1 downto DATA_WIDTH-QINT_WIDTH);
			
				poi_q_math_dly <= poi_q_math_reg;
				poi_i_math_dly <= poi_i_math_reg;
			
				scrn_width_math_dly <= scrn_width_math_reg;
			
			end if;
			
			step_q_o_pre <= (others => '0');
			step_i_o_pre <= (others => '0');
			scrn_q_o_pre <= (others => '0');
			scrn_i_o_pre <= (others => '0');
			
			if(proc_en(3) = '1') then
				--assign the output
				step_q_o_pre <= step_q;
				step_i_o_pre <= step_i;
				
				scrn_q_o_pre <= top_left_q;
				scrn_i_o_pre <= top_left_i;
			
				--loopback for the next frame
				poi_q <= poi_q_math_dly;
				poi_i <= poi_i_math_dly;
				
				scrn_width <= scrn_width_math_dly;
				
				--signal that it's a start of the frame
				metadata_o_pre(0) <= '1';
				
			end if;
			
		end if;
	end process;
	
	metadata_o <= metadata_o_pre;
	
	step_q_o <= step_q_o_pre;
	step_i_o <= step_i_o_pre;
	
	scrn_q_o <= scrn_q_o_pre;
	scrn_i_o <= scrn_i_o_pre;
	
	
	--convert vectors to reals for the sims for easy viewing
	SIM_GEN : if(SIM = 1) generate
		top_left_q_real <= real(to_integer(signed(top_left_q)))/real(2**24);
		top_left_i_real <= real(to_integer(signed(top_left_i)))/real(2**24);

		poi_q_real <= real(to_integer(signed(poi_q)))/real(2**24);
		poi_i_real <= real(to_integer(signed(poi_i)))/real(2**24);

		scrn_width_real <= real(to_integer(signed(scrn_width_math_reg)))/real(2**24);
		scrn_height_real <= real(to_integer(signed(scrn_height_math)))/real(2**24);

	end generate SIM_GEN;
	
end arch;
