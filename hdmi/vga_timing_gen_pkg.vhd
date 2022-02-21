library IEEE;
use IEEE.std_logic_1164.all;

package vga_timing_gen_pkg is

-- --horizontal timings 
-- constant h_active 		: integer range 0 to 65535 := 1920;
-- constant h_frontporch 	: integer range 0 to 255   := 88;
-- constant h_syncwidth 	: integer range 0 to 255   := 44;
-- constant h_backporch    : integer range 0 to 255   := 148;
-- constant h_total        : integer range 0 to 65535 := 2200;

-- --vertical timings
-- constant v_active       : integer range 0 to 65535 := 1080;
-- constant v_frontporch 	: integer range 0 to 255   := 4;
-- constant v_syncwidth 	: integer range 0 to 255   := 5;
-- constant v_backporch 	: integer range 0 to 255   := 36;
-- constant v_total		: integer range 0 to 65535 := 1125;

--horizontal timings 
-- constant h_active 		: integer range 0 to 65535 := 1920;
-- constant h_frontporch 	: integer range 0 to 255   := 88;
-- constant h_syncwidth 	: integer range 0 to 255   := 44;
-- constant h_backporch    : integer range 0 to 255   := 148;
-- constant h_total        : integer range 0 to 65535 := 2200;

-- constant v_active       : integer range 0 to 65535 := 540;
-- constant v_frontporch 	: integer range 0 to 255   := 3;
-- constant v_syncwidth 	: integer range 0 to 255   := 3;
-- constant v_backporch 	: integer range 0 to 255   := 18;
-- constant v_total		: integer range 0 to 65535 := 576;
--uncomment the below for a viewable simulation

--constant h_active 		: integer range 0 to 65535 := 1920;
--constant h_frontporch 	: integer range 0 to 255   := 76;
--constant h_syncwidth 	: integer range 0 to 255   := 36;
--constant h_backporch    : integer range 0 to 255   := 128;
--constant h_total        : integer range 0 to 65535 := 2160;

--constant v_active       : integer range 0 to 65535 := 1080;
--constant v_frontporch 	: integer range 0 to 255   := 6;
--constant v_syncwidth 	: integer range 0 to 255   := 8;
--constant v_backporch 	: integer range 0 to 255   := 58;
--constant v_total		: integer range 0 to 65535 := 1152;


-- --horizontal timings 
-- constant h_active 		: integer range 0 to 65535 := 16;
-- constant h_frontporch 	: integer range 0 to 255   := 1;
-- constant h_syncwidth 	: integer range 0 to 255   := 1;
-- constant h_backporch    : integer range 0 to 255   := 2;
-- constant h_total        : integer range 0 to 65535 := 20;

-- --vertical timings
-- constant v_active       : integer range 0 to 65535 := 16;
-- constant v_frontporch 	: integer range 0 to 255   := 1;
-- constant v_syncwidth 	: integer range 0 to 255   := 1;
-- constant v_backporch 	: integer range 0 to 255   := 2;
-- constant v_total		: integer range 0 to 65535 := 20;

end package vga_timing_gen_pkg;