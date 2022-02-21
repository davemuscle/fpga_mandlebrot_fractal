library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use ieee.math_real.all;

library unisim;
use unisim.vcomponents.all;

entity gblur_3x3_tb is 

end gblur_3x3_tb;

architecture test of gblur_3x3_tb is
    
	signal clk50M : std_logic := '0';
	signal clk_count : integer := 0;
	
	constant h_active : integer := 6;
	constant h_total  : integer := 8;
	constant v_active : integer := 4;
	constant v_total  : integer := 5;
	
	signal metadata_i, metadata_o : std_logic_vector(0 downto 0) := (others => '0');
	signal color_i, color_o : std_logic_vector(7 downto 0) := (others => '0');
	signal color_mux : std_logic_vector(23 downto 0) := (others => '0');
	signal color_i_cat, color_o_cat : std_logic_vector(23 downto 0) := (others => '0');
	
	signal color_red_int, color_blue_int, color_green_int : integer := 0;
	
	signal enable : std_logic := '0';
	signal h_count, h_count_dly : integer := 0;
	signal v_count, v_count_dly : integer := 0;
	signal enable_dly : std_logic := '0';
	signal color_int : integer := 0;
	
begin

	gblur_3x3_inst : entity work.gblur_3x3
	generic map(
		META_WIDTH => 1,
		h_active   => 1920,
		h_total    => 2160,
		v_active   => 1080,
		v_total    => 1152	
		)
	port map(
		clk => clk50M,
		reset => '0',
		passthrough => '0',
		
		metadata_i => metadata_i,
		color_i => color_mux,
		
		metadata_o => open,
		color_o => color_o_cat
	);

	process(clk50M)
	begin
		if(clk50M'event and clk50M = '1') then
			if(clk_count = 20) then
				metadata_i <= "1";
			else
				metadata_i <= "0";
			end if;
			
			if(clk_count >= 20 - 1 + 2160*1152) then
				clk_count <= 20;
			else
				clk_count <= clk_count + 1;
			end if;
			
		end if;
	end process;

	-- gblur_3x3_inst : entity work.gblur_3x3
	-- generic map(
		-- META_WIDTH => 1,
		-- h_active   => h_active,
		-- h_total    => h_total,
		-- v_active   => v_active,
		-- v_total    => v_total
		-- )
	-- port map(
		-- clk => clk50M,
		-- reset => '0',
		-- passthrough => '0',
		
		-- metadata_i => metadata_i,
		-- color_i => color_mux,
		
		-- metadata_o => open,
		-- color_o => color_o_cat
	-- );


	-- process(clk50M)
	-- begin
		-- if(clk50M'event and clk50M = '1') then
			-- if(clk_count >= 20 + h_total*v_total) then
				-- clk_count <= 20;
			-- else	
				-- clk_count <= clk_count + 1;
			-- end if;
			
			-- metadata_i <= "0";
			
			-- if(clk_count = 20) then
				-- enable <= '1';
			-- end if;
			
			-- if(enable = '1') then
				-- if(h_count = h_total-1) then
					-- h_count <= 0;
					-- if(v_count = v_total-1) then
						-- v_count <= 0;
					-- else	
						-- v_count <= v_count + 1;
					-- end if;
				-- else
					-- h_count <= h_count + 1;
				-- end if;
			-- end if;
			
			-- enable_dly <= enable;
			
			-- if(enable = '1') then
			
				-- if((h_count < h_active) and (v_count < v_active)) then
					-- color_i <= std_logic_vector(unsigned(color_i)+1);
				-- end if;
			
				-- if(h_count = 0 and v_count = 0) then
					-- metadata_i <= "1";

					-- color_i <= (others => '0');
					-- color_i(0) <= '1';
				-- else
					-- metadata_i <= "0";
				-- end if;
				

				
			-- else
				-- metadata_i <= "0";
				-- color_i <= (others => '0');
			-- end if;
			
			-- h_count_dly <= h_count;
			-- v_count_dly <= v_count;
			
		-- end if;
	-- end process;

	-- color_i_cat <= color_i & color_i & color_i;
	
	-- color_mux <= color_i_cat when((h_count_dly < h_active) and (v_count_dly < v_active)) else (others => '0');
	
	-- color_red_int <= to_integer(unsigned(color_o_cat(23 downto 16)));
	-- color_green_int <= to_integer(unsigned(color_o_cat(15 downto 8)));
	-- color_blue_int <= to_integer(unsigned(color_o_cat(7 downto 0)));

	
	clk_stim : process
	begin
		clk50M <= '0';
		wait for 10 ns;
		clk50M <= '1';
		wait for 10 ns;
	end process;

    process
    begin
  
	wait;

    end process;
    
end test;