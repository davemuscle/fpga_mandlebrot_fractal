-- Code your design here
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--draws vertical color bars

entity color_bars is
	generic(
		h_active : integer := 1920;
		v_active : integer := 1080;
		h_blanking : integer := 76+36+128;
		v_blanking : integer := 6+8+58;
		include_blanking : integer := 0
	);
	port(
		clk : in std_logic;

		en : in std_logic;		
		
		red : out std_logic_vector(7 downto 0);
		grn : out std_logic_vector(7 downto 0);
		blu : out std_logic_vector(7 downto 0);

		sof : out std_logic := '0'

        );
end color_bars;

architecture str of color_bars is 

	--eight bars
	constant bar_length : integer := h_active/8;
	
	signal h_count : integer := 0;
	signal v_count : integer := 0;
	

	
begin

	process(clk)
	begin
		
		if(clk'event and clk = '1') then
			
			--position counters
			if(en = '1') then
				if(include_blanking = 0) then
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
				else
					if(h_count = h_active+h_blanking-1) then
						h_count <= 0;
						if(v_count = v_active+v_blanking-1) then
							v_count <= 0;
						else
							v_count <= v_count + 1;
						end if;
					else
						h_count <= h_count + 1;
					end if;
				end if;
			end if;

			--start of frame
			if(en = '1') then
				if(h_count = 0 and v_count = 0) then
					sof <= '1';
				else
					sof <= '0';
				end if;
			end if;
			--write color based on position
			if(v_count < v_active) then
				
				if(h_count < h_active) then
					
					if(h_count < bar_length*1) then
						--white
						red <= x"EB";
						grn <= x"EB";
						blu <= x"EB";
					elsif(h_count < bar_length*2) then
						--yellow
						red <= x"EB";
						grn <= x"EB";
						blu <= x"10";
					elsif(h_count < bar_length*3) then
						--cyan
						red <= x"10";
						grn <= x"EB";
						blu <= x"EB";
					elsif(h_count < bar_length*4) then
						--green
						red <= x"10";
						grn <= x"EB";
						blu <= x"10";
					elsif(h_count < bar_length*5) then
						--magenta
						red <= x"EB";
						grn <= x"10";
						blu <= x"EB";
					elsif(h_count < bar_length*6) then
						--red
						red <= x"EB";
						grn <= x"10";
						blu <= x"10";
					elsif(h_count < bar_length*7) then
						--blue
						red <= x"10";
						grn <= x"10";
						blu <= x"EB";
					else
						--black
						red <= x"10";
						grn <= x"10";
						blu <= x"10";			
					end if;
					
					
				else
					--in horz blanking period
					red <= (others => '0');
					grn <= (others => '0');
					blu <= (others => '0');		
				end if;
				
			
			else
				--in vert blanking period
				red <= (others => '0');
				grn <= (others => '0');
				blu <= (others => '0');
			
			end if;



		end if;
		
	end process;


end str;