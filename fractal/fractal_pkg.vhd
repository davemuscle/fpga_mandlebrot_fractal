library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

package fractal_pkg is

	--constants
	constant NUM_DSP_SLICES : integer := 19;
	constant NUM_LUT_SLICES : integer := 0;
	constant NUM_SLICES     : integer := NUM_DSP_SLICES+NUM_LUT_SLICES; --number of slices to place in the pipe

	constant DATA_WIDTH   : integer := 32; --data width for math 
	constant QFORMAT_INT  : integer := 8;  --integer part
	constant QFORMAT_FRAC : integer := 24; --fractional part, FRAC + INT = DATA_WIDTH
	constant META_WIDTH   : integer := 4;  --width of metadata to pass through
	constant ITER_WIDTH   : integer := 10; --width of slv for iteration count
	
	constant BRAM_LATENCY : integer := 2;   --number of output registers on the BRAM
	constant SLICE_LATENCY : integer := 11; --number of clocks to get data out of a slice
	
	--for the engine, total pipe length
	--constant TPL : integer := SLICE_LATENCY*NUM_SLICES + BRAM_LATENCY + 4; --magic 4 determined from sim
	constant TPL : integer := (SLICE_LATENCY)*(NUM_SLICES);
	constant TPL_NP2 : integer := integer(ceil(log2(real(TPL))));

	--record for fractal data
	type fractal_slice_data is record
		lock       : std_logic;
		metadata   : std_logic_vector(META_WIDTH-1 downto 0);
		iter_count : std_logic_vector(ITER_WIDTH-1 downto 0);
		coord_real : std_logic_vector(DATA_WIDTH-1 downto 0);
		coord_imag : std_logic_vector(DATA_WIDTH-1 downto 0);
		math_x     : std_logic_vector(DATA_WIDTH-1 downto 0);
		math_y     : std_logic_vector(DATA_WIDTH-1 downto 0);
		math_r     : std_logic_vector(DATA_WIDTH-1 downto 0);
	end record fractal_slice_data;
	
	--initialization for the fractal data record
	constant fractal_slice_data_init : fractal_slice_data := 
	( 
	  lock       => '0',
	  metadata   => (others => '0'),
	  iter_count => (others => '0'),
	  coord_real => (others => '0'),
	  coord_imag => (others => '0'),
	  math_x     => (others => '0'),
	  math_y     => (others => '0'),
	  math_r     => (others => '0')
	);
	
end fractal_pkg;