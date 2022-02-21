-- Code your design here
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--draw different boxes on the screen, make sure vga port works

--inputs: 
	--blanking period signal
	--pixel clock
--outputs:
	--color


use work.vga_timing_gen_pkg.all;

entity vga_box_demo is
	port(
		clk : in std_logic;

		en : in std_logic;

		red : out std_logic_vector(7 downto 0);
		grn : out std_logic_vector(7 downto 0);
		blu : out std_logic_vector(7 downto 0);

		sof : out std_logic := '0'

        );
end vga_box_demo;

architecture str of vga_box_demo is 

	type state_type is ( waitforframe, pushpixels, waitforline, pollbox, movebox );
	signal state : state_type := waitforframe;
	
	constant box_dim : integer range 0 to 1023 := 50;
	
	signal tick_dly : std_logic := '0';
	
	--0 for left, 1 for right
	--0 for down, 1 for up
	signal x_dir : std_logic := '0';
	signal y_dir : std_logic := '0';
	
	
	signal lfsr : std_logic_vector(15 downto 0) := x"BABA";
	
	--box position
	signal box_x1 : integer range 0 to h_active-1 := 80;
	signal box_x2 : integer range 0 to h_active-1 := 80 + box_dim;
	signal box_y1 : integer range 0 to 2*v_active-1 := 80;
	signal box_y2 : integer range 0 to 2*v_active-1 := 80 + box_dim;
	
	signal dly : std_logic := '0';
	signal ready_dly : std_logic := '0';
	
	signal red_prc : std_logic_vector(7 downto 0) := (others => '0');
	signal grn_prc : std_logic_vector(7 downto 0) := (others => '0');
	signal blu_prc : std_logic_vector(7 downto 0) := (others => '0');
	
	signal red_reg : std_logic_vector(7 downto 0) := (others => '1');
	signal grn_reg : std_logic_vector(7 downto 0) := (others => '0');
	signal blu_reg : std_logic_vector(7 downto 0) := (others => '0');
	
	signal vblank_dly : std_logic := '0';
	signal hblank_dly : std_logic := '0';

	signal h_count : integer range 0 to h_active-1 := 0;
	signal v_count : integer range 0 to 2*v_active-1 := 0;
	
	constant move_x : integer := 10;
	constant move_y : integer := 10;
	
	signal interlace_flip : std_logic := '0';
	signal sof_pre : std_logic := '0';
	
begin

	red <= red_prc;
	grn <= grn_prc;
	blu <= blu_prc;

	process(clk)
	begin
		
		if(clk'event and clk = '1') then
			
			lfsr(15 downto 1) <= lfsr(14 downto 0);
			lfsr(0) <= lfsr(11) xor lfsr(9) xor lfsr(8) xor lfsr(7) xor lfsr(3) xor lfsr(2);

			if(en = '1') then
				--increase the counters
				if(h_count = h_active-1) then
					h_count <= 0;
					if(v_count >= (2*v_active)-2) then
						if(interlace_flip = '0') then
							v_count <= 0;
						else
							v_count <= 1;
						end if;
						interlace_flip <= not interlace_flip;
						
						
						--update the box direction and color
						--check if we're on an edge of the screen
						if(box_x1 = 0 or box_x2 = h_active-1 or box_y1 = 0 or box_y2 = 2*v_active-1) then
							
							--update direction
							x_dir <= lfsr(1);
							y_dir <= lfsr(14);
							
							
							red_reg <= lfsr(8 downto 1);
							grn_reg <= lfsr(11 downto 4);
							blu_reg <= lfsr(15 downto 8);
						end if;
						
						
						--update the box location
						--moving top-left
						if(x_dir = '0' and y_dir = '0') then
							if((box_x1 >= move_x) and (box_y1 >= move_y)) then
								box_x1 <= box_x1 - move_x;
								box_x2 <= box_x2 - move_x;
								box_y1 <= box_y1 - move_y;
								box_y2 <= box_y2 - move_y;
							elsif(box_x1 > 0 and box_y1 > 0) then
								box_x1 <= box_x1 - 1;
								box_x2 <= box_x2 - 1;
								box_y1 <= box_y1 - 1;
								box_y2 <= box_y2 - 1;
							end if;
							
						--move box top-right
						elsif(x_dir = '1' and y_dir = '0') then
							if((box_x2 < h_active-move_x) and (box_y1 >= move_y)) then
								box_x1 <= box_x1 + move_x;
								box_x2 <= box_x2 + move_x;
								box_y1 <= box_y1 - move_y;
								box_y2 <= box_y2 - move_y;
							elsif(box_x2 < h_active-1 and box_y1 > 0) then
								box_x1 <= box_x1 + 1;
								box_x2 <= box_x2 + 1;
								box_y1 <= box_y1 - 1;
								box_y2 <= box_y2 - 1;
							end if;
						
						--move box bottom-left
						elsif(x_dir = '0' and y_dir = '1') then
							if((box_x1 >= move_x) and (box_y2 < 2*v_active-move_y)) then
								box_x1 <= box_x1 - move_x;
								box_x2 <= box_x2 - move_x;
								box_y1 <= box_y1 + move_y;
								box_y2 <= box_y2 + move_y;
							elsif(box_x1 > 0 and box_y2 < 2*v_active-1) then
								box_x1 <= box_x1 - 1;
								box_x2 <= box_x2 - 1;
								box_y1 <= box_y1 + 1;
								box_y2 <= box_y2 + 1;
							end if;
						
						--move box bottom-right
						elsif(x_dir = '1' and y_dir = '1') then
							if((box_x2 < h_active-move_x) and (box_y2 < 2*v_active-move_y)) then
								box_x1 <= box_x1 + move_x;
								box_x2 <= box_x2 + move_x;
								box_y1 <= box_y1 + move_y;
								box_y2 <= box_y2 + move_y;
							elsif(box_x2 < h_active-1 and box_y2 < 2*v_active-1) then
								box_x1 <= box_x1 + 1;
								box_x2 <= box_x2 + 1;
								box_y1 <= box_y1 + 1;
								box_y2 <= box_y2 + 1;
							end if;
						
						end if;
					else
						v_count <= v_count + 2;
					end if;
				else
					h_count <= h_count + 1;
				end if;
			end if;		
			
			--release the color for the box
			if((h_count >= box_x1 and h_count <= box_x2) and (v_count >= box_y1 and v_count <= box_y2)) then
				red_prc <= red_reg;
				grn_prc <= grn_reg;
				blu_prc <= blu_reg;
			else
				red_prc <= (others => '0');
				grn_prc <= (others => '0');
				blu_prc <= (others => '0');
			end if;
					
			--signal the start of the frame
			if(h_count = 0 and (v_count = 0 or v_count = 1)) then
				sof <= '1';
			else
				sof <= '0';
			end if;
			
		
		
		end if;
		
	end process;


end str;