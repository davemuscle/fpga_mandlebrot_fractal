library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

--Dave Muscle
	--Takes a continuous stream of pixels in at the final pixel clock (including blanking)
	--Uses the SOF signal attached to the pixel to reset counters
	
entity video_sync_gen is
	generic(
		
		DATA_WIDTH : integer := 10;
		META_WIDTH : integer := 4;
		
		SYNC_POL_BP : integer := 0;
		
		SOF_BP : integer := 0;
		EOL_BP : integer := 1;
		
        h_active 	 : integer := 1920;
		h_frontporch : integer := 88;
		h_syncwidth  : integer := 44;
		h_backporch  : integer := 148;
        h_total      : integer := 2200;
		
        v_active     : integer := 540;
		v_frontporch : integer := 2;
		v_syncwidth  : integer := 3;
		v_backporch  : integer := 18;
        v_total		 : integer := 563
		
		
		
		);
	port(
	    clk : in std_logic;
		pixel_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
		metadata_in : in std_logic_vector(META_WIDTH-1 downto 0);
		
		hsync  : out std_logic := '0';
		vsync  : out std_logic := '0';
		hblank : out std_logic := '0'; --1 during blanking period
		vblank : out std_logic := '0';
		de     : out std_logic := '0'; --1 during active period
		
		pixel_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
		
        );
end video_sync_gen;

architecture arch of video_sync_gen is 
	
	constant SYNC_POL : std_logic_vector(1 downto 0) := (0 => '0', 1 => '1');
	
	signal v_count : integer := 0;
	signal h_count : integer := 0;
	
	signal pixel : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	signal pixel_dly : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
	
	signal en : std_logic := '0';
	
	signal hblank_int, vblank_int : std_logic := '0';
	
begin	
	
	process(clk)
	begin
		if(rising_edge(clk)) then
			--regsiter the input
			pixel <= pixel_in;
		
			--register the output
			pixel_out <= pixel;
		
			--make sure the start of frame aligns with the counters
			if(metadata_in(SOF_BP) = '1') then
				en <= '1';
			end if;
			
			if(en = '1') then
				--increase the counters
				if(h_count = h_total-1) then
					h_count <= 0;
					if(v_count = v_total-1) then
						v_count <= 0;
					else
						v_count <= v_count + 1;
					end if;
				else
					h_count <= h_count + 1;
				end if;
			end if;
			--write out the blanking signals and sync markers
			if(h_count < h_active) then
				hblank_int <= '0';
				hsync  <= not SYNC_POL(SYNC_POL_BP);
			elsif(h_count < h_active + h_frontporch) then
				hblank_int <= '1';
				hsync <= not SYNC_POL(SYNC_POL_BP);
			elsif(h_count < h_active + h_frontporch + h_syncwidth) then
				hblank_int <= '1';
				hsync <= SYNC_POL(SYNC_POL_BP);
			else
				hblank_int <= '1';
				hsync <= not SYNC_POL(SYNC_POL_BP);
			end if;
		
			if(v_count < v_active) then
				vblank_int <= '0';
				vsync  <= not SYNC_POL(SYNC_POL_BP);
			elsif(v_count < v_active + v_frontporch) then
				vblank_int <= '1';
				vsync <= not SYNC_POL(SYNC_POL_BP);
			elsif(v_count < v_active + v_frontporch + v_syncwidth) then
				vblank_int <= '1';
				vsync <= SYNC_POL(SYNC_POL_BP);
			else
				vblank_int <= '1';
				vsync <= not SYNC_POL(SYNC_POL_BP);
			end if;
	
		end if;
	end process;


	hblank <= hblank_int;
	vblank <= vblank_int;
	de <= not hblank_int and not vblank_int;

	
end arch;
