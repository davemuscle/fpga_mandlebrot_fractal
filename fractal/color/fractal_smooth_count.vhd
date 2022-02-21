library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
--Dave Muscle

--Input the iteration count, get a smoothened fractional count value back

--For radius >= escape, calculates: out = count - log2(log2(r)*3/20)
--Also shifts the output based on the FRAC_WIDTH scaling the colors later

entity fractal_smooth_count is
	generic(
		--for fractal slice data
		ITER_WIDTH   : integer := 10; --this has to have a bit for the sign
		RAD_WIDTH    : integer := 8;
		META_WIDTH   : integer := 1;
		
		--for rom data
		INT_WIDTH    : integer := 3; --includes sign
		FRAC_WIDTH   : integer := 5; --this should match the scale
	
		INIT_FILE    : string


		);
	port(
	    clk            : in std_logic;
		
		passthrough    : in std_logic;
		
		lock_i         : in std_logic;
		metadata_i     : in std_logic_vector(META_WIDTH-1 downto 0);
		iter_i         : in std_logic_vector(ITER_WIDTH-1 downto 0);
		rad_i          : in std_logic_vector(RAD_WIDTH-1 downto 0);
		
		metadata_o     : out std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
		
		smooth_o_int   : out std_logic_vector(ITER_WIDTH-1 downto 0) := (others => '0');
		smooth_o_frac  : out std_logic_vector(FRAC_WIDTH-1 downto 0) := (others => '0')

		
        );
end fractal_smooth_count;

architecture arch of fractal_smooth_count is 

	signal metadata_reg1 : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	signal metadata_reg2 : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	signal metadata_reg3 : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	
	signal lock_reg1 : std_logic := '0';
	signal lock_reg2 : std_logic := '0';
	signal lock_reg3 : std_logic := '0';
	
	signal iter_reg1 : std_logic_vector(ITER_WIDTH-1 downto 0) := (others => '0');
	signal iter_reg2 : std_logic_vector(ITER_WIDTH-1 downto 0) := (others => '0');
	signal iter_reg3 : std_logic_vector(ITER_WIDTH-1 downto 0) := (others => '0');
	
	signal rom_data  : std_logic_vector(INT_WIDTH+FRAC_WIDTH-1 downto 0) := (others => '0');
	signal math_data : std_logic_vector(ITER_WIDTH+FRAC_WIDTH-1 downto 0) := (others => '0');
	
	signal iter_ext : std_logic_vector(ITER_WIDTH+FRAC_WIDTH-1 downto 0) := (others => '0');
	
	signal pre_out : std_logic_vector(ITER_WIDTH+FRAC_WIDTH-1 downto 0) := (others => '0');
	
	signal metadata_reg4 : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	signal iter_reg4 : std_logic_vector(ITER_WIDTH-1 downto 0) := (others => '0');
	
	signal metadata_pre : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	signal smooth_pre_int  : std_logic_vector(ITER_WIDTH-1 downto 0) := (others => '0');
	signal smooth_pre_frac : std_logic_vector(FRAC_WIDTH-1 downto 0) := (others => '0');
	
	
begin	

	--instantiate rom
	--this rom does: log2(log2(x)*3/20) from MATLAB
    calc_rom : entity work.inferred_rom
	generic map(
		gDEPTH    => RAD_WIDTH,
		gWIDTH    => INT_WIDTH+FRAC_WIDTH,
		gOREGS    => 2,
		gINITFILE => INIT_FILE
	)
	port map(
		clk  => clk,
		en   => '1',
		do   => rom_data,
		addr => rad_i
	);
	
	--delays to get data out of the rom
	process(clk)
	begin
		if(rising_edge(clk)) then
			--one clock to get the data out of the rom
			metadata_reg1 <= metadata_i;
			lock_reg1 <= lock_i;
			iter_reg1 <= iter_i;
			
			--two clocks for the registers
			metadata_reg2 <= metadata_reg1;
			metadata_reg3 <= metadata_reg2;
			
			lock_reg2 <= lock_reg1;
			lock_reg3 <= lock_reg2;
			
			iter_reg2 <= iter_reg1;
			iter_reg3 <= iter_reg2;
			
		end if;
	end process;
	
	--sign extend the rom data

	math_data(ITER_WIDTH+FRAC_WIDTH-1 downto INT_WIDTH+FRAC_WIDTH) <= (others => rom_data(rom_data'length-1));
	math_data(INT_WIDTH+FRAC_WIDTH-1 downto 0) <= rom_data;
	
	--line up the integer count, set fractional part to zero
	iter_ext(ITER_WIDTH+FRAC_WIDTH-1 downto FRAC_WIDTH) <= iter_reg3;
	iter_ext(FRAC_WIDTH-1 downto 0) <= (others => '0');
	

	--do the subtraction or muxing
	process(clk)
	begin
		if(rising_edge(clk)) then
		
			if(lock_reg3 = '0') then
				--no lock, no calculation
				pre_out <= (others => '0');
				iter_reg4 <= (others => '0');
				
			else
				--locked, do the smooth count
				pre_out <= std_logic_vector(signed(iter_ext) - signed(math_data));
				iter_reg4 <= iter_i;
			end if;
		
			metadata_reg4 <= metadata_reg3;

		end if;
	end process;

	--setup the output, add a mux for the passthrough
	process(clk)
	begin
		if(rising_edge(clk)) then
			if(passthrough = '1') then
				smooth_pre_int  <= iter_reg4;
				smooth_pre_frac <= (others => '0');
			else		
				smooth_pre_int <= pre_out(pre_out'length-1 downto FRAC_WIDTH);
				smooth_pre_frac <= pre_out(FRAC_WIDTH-1 downto 0);
				
			end if;
			
			metadata_pre <= metadata_reg4;
			
		end if;
	end process;
	
	metadata_o <= metadata_pre;
	smooth_o_frac <= smooth_pre_frac;
	smooth_o_int <= smooth_pre_int;
	
end arch;
