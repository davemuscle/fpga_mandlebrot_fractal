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

entity vga_box_demo is
	generic(
		h_active : integer := 200;
		v_active : integer := 100
	);
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


	signal h_count : integer range 0 to h_active-1 := 1;
	signal v_count : integer range 0 to v_active-1 := 1;
	
	type bar_t is array(0 to 7) of integer;
	signal bar : bar_t := (0 => 240, 
						   1 => 480,
						   2 => 720,
						   3 => 960,
						   4 => 1200,
						   5 => 1440,
						   6 => 1680,
						   7 => 1920);
	
	
	signal bar0 : integer := 240;
	signal bar1 : integer := 480;
	signal bar2 : integer := 720;
	signal bar3 : integer := 960;
	signal bar4 : integer := 1200;
	signal bar5 : integer := 1440;
	signal bar6 : integer := 1680;
	signal bar7 : integer := 1920;
	
begin

	process(clk)
	begin
		
		if(clk'event and clk = '1') then
			
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
		
			if(v_count < 270) then
				red <= x"00";
				if(h_count >= bar(0) and h_count < bar(1)) then
					red <= x"FF";
				elsif(h_count >= bar(2) and h_count < bar(3)) then
					red <= x"FF";
				elsif(h_count >= bar(4) and h_count < bar(5)) then
					red <= x"FF";
				elsif(h_count >= bar(6) and h_count < bar(7)) then
					red <= x"FF";
				end if;
			else
				red <= x"FF";
				if(h_count >= bar(0) and h_count < bar(1)) then
					red <= x"00";
				elsif(h_count >= bar(2) and h_count < bar(3)) then
					red <= x"00";
				elsif(h_count >= bar(4) and h_count < bar(5)) then
					red <= x"00";
				elsif(h_count >= bar(6) and h_count < bar(7)) then
					red <= x"00";
				end if;
			end if;
			
			-- if(v_count < v_active/2) then
				-- red <= x"00";
			-- else
				-- red <= x"FF";
			-- end if;
			if(en = '1') then
				if(h_count = 0 and v_count = 0) then
					sof <= '1';		
				else
					sof <= '0';
				end if;
				
				if(h_count = h_active-1 and v_count = v_active-1) then
					for i in 0 to 7 loop 
						if(bar(i) >= h_active) then
							bar(i) <= 0;
						else
							bar(i) <= bar(i) + 4;
						end if;
					end loop;
					
				end if;
				
				
			else
				sof <= '0';
			end if;
		
		end if;
		
	end process;


end str;