library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;
use IEEE.math_real.all;

library unisim;
use unisim.vcomponents.all;

use work.fractal_pkg.all;

entity fractal_slice_tb is 

end fractal_slice_tb;

architecture test of fractal_slice_tb is

	signal clk : std_logic := '0';

	signal slice_i, slice_o : fractal_slice_data := fractal_slice_data_init;

	signal clk_count : integer := 0;

begin

	
    fractal_slice_inst : entity work.fractal_slice
	generic map(
		USE_SQ_LOGIC => 1
	)
	port map(
		--clocking
	    clk          => clk,
		escape       => x"04",
		slice_port_i => slice_i,
		slice_port_o => slice_o

	);

	clk_stim : process
	begin
		clk <= '0';
		wait for 10 ns;
		clk <= '1';
		wait for 10 ns;
	end process;
	

	
	--testbench stimulus
	process(clk)
	begin
		if(clk'event and clk = '1') then
		
			slice_i <= fractal_slice_data_init;
			clk_count <= clk_count + 1;
			
			--test cases:
			--[1] = simple data delay
			--[2] = input an x and y that give x^2 + y^2 > 4, lock should be high
			--[3] = input a high lock and a random radius, should have no change in lock/radius
			--[4] = input simple values and see the iteration count go up
			--[5] = test math with fractional and negative count values and see iter count go up
			
			---------------------------------------------------------------------------
			--test case inputs 
			---------------------------------------------------------------------------
			--[1]
			if(clk_count = 20) then
				slice_i.metadata <= (0 => '1', others => '0');
				slice_i.lock <= '1';
				slice_i.coord_real <= x"55AA55AA";
				slice_i.coord_imag <= x"AA55AA55";
			end if;
			
			--[2]
			if(clk_count = 21) then
				slice_i.metadata <= (1 => '1', others => '0');
				slice_i.math_x <= x"03000000";
				slice_i.math_y <= x"02000000";
			end if;
			
			--[3]
			if(clk_count = 22) then
				slice_i.lock <= '1';
				slice_i.metadata <= "0011";
				slice_i.math_r <= x"37000000";
			end if;
			
			--[4] 
			if(clk_count = 23) then
				slice_i.coord_real <= x"01800000"; -- pos 1.5
				slice_i.coord_imag <= x"01000000"; -- pos 1
				slice_i.metadata   <= "0100";
				slice_i.iter_count <= "0000000100"; -- 4
				slice_i.math_x     <= x"00800000"; -- pos 0.5
				slice_i.math_y     <= x"01000000"; -- pos 1
			end if;
			
			--[5]
			if(clk_count = 24) then
				slice_i.coord_real <= x"FF000000"; -- neg 1
				slice_i.coord_imag <= x"02000000"; -- pos 2
				slice_i.math_x     <= x"FFE00000"; -- neg 0.125
				slice_i.math_y     <= x"FF800000"; -- neg 0.5
				slice_i.iter_count <= "0000001010"; -- 10
			end if;
			
			
			---------------------------------------------------------------------------
			--test case outputs 
			---------------------------------------------------------------------------
			--[1] check the delayed data
			if(clk_count = 20 + SLICE_LATENCY+1) then
				if(slice_o.metadata /= "0001") then
					assert false report "[1] Delay Metadata Mismatch" severity error;
				end if;
				
				if(slice_o.lock /= '1') then
					assert false report "[1] Delay Lock Mismatch" severity error;
				end if;
				
				if(slice_o.coord_real /= x"55AA55AA") then
					assert false report "[1] Delay Coord Real Mismatch" severity error;
				end if;
				
				if(slice_o.coord_imag /= x"AA55AA55") then
					assert false report "[1] Delay Coord Imag Mismatch" severity error;
				end if;
			end if;
			
			--[2] the output lock should be high, the radius should be the x^2 + y^2
			if(clk_count = 21 + SLICE_LATENCY+1) then
				if(slice_o.lock /= '1') then
					assert false report "[2] Locking not working on big radius" severity error;
				end if;
				
				if(slice_o.math_r /= x"0D000000") then
					assert false report "[2] Big radius calculation mismatch" severity error;
				end if;
				
				if(slice_o.metadata /= "0010") then
					assert false report "[2] Metadata mismatch" severity error;
				end if;
			end if;
			
			--[3] the output lock and radius should equal the input lock and radius
			if(clk_count = 22 + SLICE_LATENCY+1) then
				if(slice_o.lock /= '1') then
					assert false report "[3] Input lock passthrough not working" severity error;
				end if;
				
				if(slice_o.math_r /= x"37000000") then
					assert false report "[3] Input radius passthrough not working" severity error;
				end if;
				
				if(slice_o.metadata /= "0011") then
					assert false report "[3] Metadata mismatch" severity error;
				end if;
			end if;
			
			--[4] 
			if(clk_count = 23 + SLICE_LATENCY+1) then
				if(slice_o.lock /= '0') then
					assert false report "[4] Lock mismatch" severity error;
				end if;
				
				if(slice_o.math_r /= x"01400000") then
					assert false report "[4] Radius mismatch" severity error;
				end if;
				
				if(slice_o.metadata /= "0100") then
					assert false report "[4] Metadata mismatch" severity error;
				end if;
				
				if(slice_o.math_y /= x"02000000") then
					assert false report "[4] Math Y mismatch" severity error;
				end if;
				
				if(slice_o.math_x /= x"00C00000") then
					assert false report "[4] Math X mismatch" severity error;
				end if;
				
				if(slice_o.iter_count /= "0000000101") then
					assert false report "[4] Count increase mismatch" severity error;
				end if;
			end if;
			
			--[5] 
			if(clk_count = 24 + SLICE_LATENCY+1) then
				if(slice_o.lock /= '0') then
					assert false report "[5] Lock mismatch" severity error;
				end if;
				
				if(slice_o.math_r /= x"00440000") then
					assert false report "[5] Radius mismatch" severity error;
				end if;
				
				if(slice_o.math_y /= x"02200000") then
					assert false report "[5] Math Y mismatch" severity error;
				end if;
				
				if(slice_o.math_x /= x"FEC40000") then
					assert false report "[5] Math X mismatch" severity error;
				end if;
				
				if(slice_o.iter_count /= "0000001011") then
					assert false report "[5] Count increase mismatch" severity error;
				end if;
			end if;
			
			if(clk_count = 20 + 200) then
				clk_count <= 20;
			end if;
			
			
		end if;
	end process;

    process
    begin
  
	wait;
    
    end process;
    
end test;