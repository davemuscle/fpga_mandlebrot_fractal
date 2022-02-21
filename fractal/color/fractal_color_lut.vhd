library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use ieee.math_real.all;
--Dave Muscle

--Input the iteration count to get a color out

entity fractal_color_lut is
	generic(
		ITER_WIDTH   : integer := 32;
		COLOR_DEPTH  : integer := 1;
		META_WIDTH   : integer := 1;
	
		NUM_COLORS   : integer := 256;
		NUM_PALETTES : integer := 1;
		
		INIT_FILE    : string


		);
	port(
	    clk            : in std_logic;
		palette_select : in integer; --pallete numbering starts from zero
		
		metadata_i     : in std_logic_vector(META_WIDTH-1 downto 0);
		iter_i         : in std_logic_vector(ITER_WIDTH-1 downto 0);
		
		metadata_o     : out std_logic_vector(META_WIDTH-1 downto 0);
		color_o        : out std_logic_vector(COLOR_DEPTH*3-1 downto 0)
		
        );
end fractal_color_lut;

architecture arch of fractal_color_lut is 

	constant NUM_COLORS_NPOW2   : integer := integer(ceil(log2(real(NUM_COLORS))));
	constant NUM_PALETTES_NPOW2 : integer := integer(ceil(log2(real(NUM_PALETTES))));
	
	signal rom_addr : std_logic_vector(NUM_COLORS_NPOW2 + NUM_PALETTES_NPOW2 - 1 downto 0) := (others => '0');
	signal rom_data : std_logic_vector(COLOR_DEPTH*3-1 downto 0) := (others => '0');
	
	signal iter_resized : std_logic_vector(NUM_COLORS_NPOW2 - 1 downto 0) := (others => '0');

	signal metadata_reg1 : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	signal metadata_reg2 : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');
	signal metadata_reg3 : std_logic_vector(META_WIDTH-1 downto 0) := (others => '0');

begin	

	--resize vectors
	iter_resized <= std_logic_vector(resize(unsigned(iter_i),iter_resized'length));
	rom_addr <= std_logic_vector(to_unsigned(palette_select,NUM_PALETTES_NPOW2)) & iter_resized;

	--instantiate rom
    color_rom : entity work.inferred_rom
	generic map(
		gDEPTH    => NUM_COLORS_NPOW2 + NUM_PALETTES_NPOW2,
		gWIDTH    => COLOR_DEPTH*3,
		gOREGS    => 2,
		gINITFILE => INIT_FILE
	)
	port map(
		clk  => clk,
		en   => '1',
		do   => rom_data,
		addr => rom_addr
	);
	
	--delay metadata
	process(clk)
	begin
		if(rising_edge(clk)) then
			--one clock to get the data out of the rom
			metadata_reg1 <= metadata_i;
			metadata_reg2 <= metadata_reg1;
			metadata_reg3 <= metadata_reg2;
			
		end if;
	end process;
	
	--assign outputs
	color_o <= rom_data;
	metadata_o <= metadata_reg3;
	
end arch;
