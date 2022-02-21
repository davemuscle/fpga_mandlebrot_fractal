library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Dave Muscle

--Give this block a top-left coodinate, a step_x and a step_y value
--Also give it an enable signal

--It will generate a coordinate each pixel clock to go through the fractal core

--It's expected that each inputted frame is actually a field for interlacing

entity fractal_coord_gen is
	generic(
		DATA_WIDTH   : integer := 32;
		META_WIDTH   : integer := 4;

		h_active     : integer := 1920;
		v_active     : integer := 540
		);
	port(
	    clk : in std_logic;
		
		metadata_i : in std_logic_vector(META_WIDTH-1 downto 0);
		
		screen_real_i : in std_logic_vector(DATA_WIDTH-1 downto 0);
		screen_imag_i : in std_logic_vector(DATA_WIDTH-1 downto 0);
		
		screen_step_x : in std_logic_vector(DATA_WIDTH-1 downto 0);
		screen_step_y : in std_logic_vector(DATA_WIDTH-1 downto 0);
		
		metadata_o : out std_logic_vector(META_WIDTH-1 downto 0);
		
		coord_real_o : out std_logic_vector(DATA_WIDTH-1 downto 0);
		coord_imag_o : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
end fractal_coord_gen;

architecture arch of fractal_coord_gen is 

	signal en : std_logic := '0';

	signal real_i_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal imag_i_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal meta_i_reg : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');

	signal real_s_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal imag_s_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');

	signal step_x_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal step_y_reg : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	

	signal h_count : integer range 0 to h_active-1 := 0;
	signal v_count : integer range 0 to v_active-1 := 0;
	
	signal meta_o_reg : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	
	signal interlace_flip : std_logic := '0';

begin	

	process(clk)
	begin
		if(rising_edge(clk)) then

			--poll the SOF in the metadata
			if(metadata_i(0) = '1') then
				--the first time we see this signal enable the block
				en <= '1';
				
				--lock in the data on the input port
				real_i_reg <= screen_real_i;
				imag_i_reg <= screen_imag_i;
				
				--lock in the step values
				step_x_reg <= screen_step_x;
				step_y_reg <= screen_step_y;
			end if;
			
			--delay the metadata
			meta_i_reg(0) <= metadata_i(0);
	
			--increase the count values
			if(en = '1') then
				if(h_count = h_active-1) then
		
					h_count <= 0;
					
					if(v_count = v_active-1) then
						v_count <= 0;	
					else
						v_count <= v_count + 1;
					end if;
				else
					h_count <= h_count + 1;
				end if;
				
			end if;
	
			--assign the output based off where are are on the screen
			if(h_count = 0) then
				real_s_reg <= real_i_reg;
				imag_s_reg <= std_logic_vector(signed(imag_s_reg) - signed(step_y_reg));
			else
				real_s_reg <= std_logic_vector(signed(real_s_reg) + signed(step_x_reg));
			end if;

			if(v_count = 0) then
				interlace_flip <= not interlace_flip;
				if(interlace_flip = '0') then
					imag_s_reg <= std_logic_vector(signed(imag_i_reg) - signed('0' & step_y_reg(31 downto 1)));
				else
					imag_s_reg <= imag_i_reg;
				end if;
			end if;
			
			--generate the EOL signal
			if(h_count = h_active-1) then
				meta_o_reg(1) <= '1';
			else
				meta_o_reg(1) <= '0';
			end if;
			
			if(h_count = h_active-1 and v_count = v_active-1) then
				meta_o_reg(2) <= '1';
			else
				meta_o_reg(2) <= '0';
			end if;
	
			meta_o_reg(0) <= meta_i_reg(0);

		
		end if;
	end process;

	metadata_o <= meta_o_reg;
	coord_real_o <= real_s_reg;
	coord_imag_o <= imag_s_reg;

end arch;
