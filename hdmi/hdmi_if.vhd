--Dave Muscle
--HDMI OutputInterface
--Accepts VGA as an input

--7/10/20
--Made for real-time fractal project

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library unisim;
use unisim.vcomponents.all;

entity hdmi_if is
	port(
		--pixel clock and serdes clock
		pclk     : in std_logic;
		pclk5x   : in std_logic;
		
		--reset for serdes, connect it to a delayed inverted locked (active high reset)
		rst : in std_logic;
		
		--sync markers and active video
		hsync    : in std_logic;
		vsync    : in std_logic;
		de       : in std_logic;
		
		--[23:16] is RED, [15:8] is GRN, [7:0] is BLU
		video_in : in std_logic_vector(23 downto 0);
		
		--[2] is RED, [1] is GRN, [0] is BLU
		TMDS_clk_p  : out std_logic;
		TMDS_clk_n  : out std_logic;
		TMDS_data_p : out std_logic_vector(2 downto 0);
		TMDS_data_n : out std_logic_vector(2 downto 0)
		
        );
end hdmi_if;

architecture str of hdmi_if is 

	--29:20 is RED encoded, 19:10 is GRN encoded, 9:0 is BLU encoded
	signal tmds_encoded : std_logic_vector(29 downto 0) := (others => '0');
	--5:4 is RED control, 3:2 is GRN control, 1:0 is BLU control
	signal control : std_logic_vector(5 downto 0) := (others => '0');

	--oserdes wizard component
	component oserdes_10x1_ddr_tmds
		generic(
		  SYS_W       : integer := 1;
		  DEV_W       : integer := 10
		);
		port
		(
		  -- From the device out to the system
		  data_out_from_device    : in    std_logic_vector(DEV_W-1 downto 0);
		  data_out_to_pins_p      : out   std_logic_vector(SYS_W-1 downto 0);
		  data_out_to_pins_n      : out   std_logic_vector(SYS_W-1 downto 0);
		-- Clock and reset signals
		  clk_in                  : in    std_logic;  
		  clk_div_in              : in    std_logic; 
		  -- Reset signal for IO circuit
		  io_reset                : in    std_logic 
		);                  
	end component;

	begin

	control(1 downto 0) <= vsync & hsync;
	control(3 downto 2) <= "00";
	control(5 downto 6) <= "00";

	--tmds encoders and oserdes generate
	TMDS_DATA_GEN: for i in 0 to 2 generate
	
		--tmds encoders generate
		--Using TMDS encoder from Digikey
		data_encoder : entity work.tmds_encoder
		port map(
			clk      => pclk,
			disp_ena => de,
			control  => control(2*(i+1)-1 downto 2*i),
			d_in     => video_in(8*(i+1)-1 downto 8*i),
			q_out    => tmds_encoded(10*(i+1)-1 downto 10*i)
		);
	
	
		--oserdes generate
		data_oserdes : oserdes_10x1_ddr_tmds
		generic map(
			SYS_W => 1,
			DEV_W => 10
		)
		port map(
		   data_out_from_device  => tmds_encoded(10*(i+1)-1 downto 10*i),
		   data_out_to_pins_p(0) => TMDS_data_p(i),
		   data_out_to_pins_n(0) => TMDS_data_n(i),
		   clk_in                => pclk5x,                            
		   clk_div_in            => pclk,                        
		   io_reset              => rst
		);
	
	end generate TMDS_DATA_GEN;

	--output the clock on the oserdes lines
	--input is just 5 ones then 5 zeros
	clk_oserdes : oserdes_10x1_ddr_tmds
	   generic map(
			SYS_W => 1,
			DEV_W => 10
	   )
	   port map 
	   ( 
	   data_out_from_device  => "1111100000",
	   data_out_to_pins_p(0) => TMDS_clk_p,
	   data_out_to_pins_n(0) => TMDS_clk_n,
	   clk_in                => pclk5x,                            
	   clk_div_in            => pclk,                        
	   io_reset              => rst
	);

end str;