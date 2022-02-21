library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Dave Muscle

--Takes in the EOL and SOF signals from the fractal core
--Initializes a counter to the SOF signal and compares to an expected value
--to determine control path errors

entity fractal_sync_checker is
	generic(
		META_WIDTH   : integer := 4;
		h_active     : integer := 1920;
		v_active     : integer := 540
		);
	port(
	    clk            : in  std_logic;
		metadata_i     : in  std_logic_vector(META_WIDTH-1 downto 0);
		h_count_o      : out std_logic_vector(31 downto 0);
		v_count_o      : out std_logic_vector(31 downto 0);
		error_o        : out std_logic := '0'
        );
end fractal_sync_checker;

architecture arch of fractal_sync_checker is 

	signal h_count : integer := 0;
	signal v_count : integer := 0;

begin	

	process(clk)
	begin
		if(rising_edge(clk)) then
			--always default this to zero
			error_o <= '0';
	
			--increase the horizontal count each pixel clock
			h_count <= h_count + 1;
		
			--syncronize the horizontal count to the EOL signal
			if(metadata_i(1) = '1') then
				h_count <= 0;
				if(h_count /= h_active-1) then
					error_o <= '1';
				end if;
				v_count <= v_count + 1;
			end if;

			--syncronize the counters to the EOF signal
			if(metadata_i(2) = '1') then
				h_count <= 0;
				v_count <= 0;
				if(h_count /= h_active-1) then
					error_o <= '1';
				end if;
				if(v_count /= v_active-1) then
					error_o <= '1';
				end if;
			end if;
		end if;
	end process;

	h_count_o <= std_logic_vector(to_unsigned(h_count,32));
	v_count_o <= std_logic_vector(to_unsigned(v_count,32));

end arch;
