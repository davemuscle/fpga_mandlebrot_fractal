library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity squarer_32bit is
	generic(
		N : integer := 32
	);
	port(
		clk : in  std_logic;
	    a   : in  std_logic_vector(  N-1 downto 0);
		p   : out std_logic_vector(2*N-1 downto 0) := (others => '0')
	);
end squarer_32bit;

architecture arch of squarer_32bit is 

	--partial products std logic vectors
	--slv width for each vector of partial products:
	--for 2 < i < N, odd_width = i/2, even_width = i/2+1
	--for N <= i < 2*N, odd_width = (2*N-i)/2, even_width = (2*N-i)/2+1
	
	--even below 32
	signal pp24 : std_logic_vector((24/2) downto 0) := (others => '0'); 
	signal pp26 : std_logic_vector((26/2) downto 0) := (others => '0'); 
	signal pp28 : std_logic_vector((28/2) downto 0) := (others => '0'); 
	signal pp30 : std_logic_vector((30/2) downto 0) := (others => '0');
	
	--odd below 32
	signal pp25 : std_logic_vector((25/2)-1 downto 0) := (others => '0');
	signal pp27 : std_logic_vector((27/2)-1 downto 0) := (others => '0');
	signal pp29 : std_logic_vector((29/2)-1 downto 0) := (others => '0');
	signal pp31 : std_logic_vector((31/2)-1 downto 0) := (others => '0'); 

	--even above 32
	signal pp32 : std_logic_vector((2*N-32)/2 downto 0) := (others => '0');
	signal pp34 : std_logic_vector((2*N-34)/2 downto 0) := (others => '0'); 
	signal pp36 : std_logic_vector((2*N-36)/2 downto 0) := (others => '0'); 
	signal pp38 : std_logic_vector((2*N-38)/2 downto 0) := (others => '0'); 
	signal pp40 : std_logic_vector((2*N-40)/2 downto 0) := (others => '0');
	signal pp42 : std_logic_vector((2*N-42)/2 downto 0) := (others => '0'); 
	signal pp44 : std_logic_vector((2*N-44)/2 downto 0) := (others => '0'); 
	signal pp46 : std_logic_vector((2*N-46)/2 downto 0) := (others => '0'); 
	signal pp48 : std_logic_vector((2*N-48)/2 downto 0) := (others => '0');
	signal pp50 : std_logic_vector((2*N-50)/2 downto 0) := (others => '0'); 
	signal pp52 : std_logic_vector((2*N-52)/2 downto 0) := (others => '0'); 
	signal pp54 : std_logic_vector((2*N-54)/2 downto 0) := (others => '0'); 

	
	--odd above 32
	signal pp33 : std_logic_vector(((2*N-33)/2)-1 downto 0) := (others => '0'); 
	signal pp35 : std_logic_vector(((2*N-35)/2)-1 downto 0) := (others => '0'); 
	signal pp37 : std_logic_vector(((2*N-37)/2)-1 downto 0) := (others => '0'); 
	signal pp39 : std_logic_vector(((2*N-39)/2)-1 downto 0) := (others => '0'); 
	signal pp41 : std_logic_vector(((2*N-41)/2)-1 downto 0) := (others => '0'); 
	signal pp43 : std_logic_vector(((2*N-43)/2)-1 downto 0) := (others => '0'); 
	signal pp45 : std_logic_vector(((2*N-45)/2)-1 downto 0) := (others => '0'); 
	signal pp47 : std_logic_vector(((2*N-47)/2)-1 downto 0) := (others => '0'); 
	signal pp49 : std_logic_vector(((2*N-49)/2)-1 downto 0) := (others => '0'); 
	signal pp51 : std_logic_vector(((2*N-51)/2)-1 downto 0) := (others => '0'); 
	signal pp53 : std_logic_vector(((2*N-53)/2)-1 downto 0) := (others => '0'); 
	signal pp55 : std_logic_vector(((2*N-55)/2)-1 downto 0) := (others => '0'); 


	

	--array of 5 bit vectors for the zeroth stage, just to register the rom sums
	type stg0_t is array(24 to 55) of std_logic_vector(4 downto 0);
	signal stg0, stg0_pre, stg0_pre_pre : stg0_t := (others => (others => '0'));
	
	
	attribute EXTRACT_RESET : string;
	attribute EXTRACT_RESET of stg0, stg0_pre : signal is "no";
	attribute EXTRACT_RESET of pp24,
	                           pp25,
	                           pp26,
	                           pp27,
	                           pp28,
	                           pp29,
	                           pp30,
	                           pp31,
	                           pp32,
	                           pp33,
	                           pp34,
	                           pp35,
	                           pp36,
	                           pp37,
	                           pp38,
	                           pp39,
	                           pp40,
	                           pp41,
	                           pp42,
	                           pp43,
	                           pp44,
	                           pp45,
	                           pp46,
	                           pp47,
	                           pp48,
	                           pp49,
	                           pp50,
	                           pp51,
	                           pp52,
	                           pp53,
	                           pp54,
	                           pp55 : signal is "no";	
							   
	--array of 8 bit vectors for the first adding stage
	--5 bits gets expanded to 7 bits for the two shfits, then one extra bit for the carry
	type stg1_t is array(0 to 11) of std_logic_vector(7 downto 0);
	signal stg1 : stg1_t := (others => (others => '0'));	
	
	--array of 13 bit vectors for the second adding stage
	--8 bits gets expanded to 13 bits, no carries
	--shift over successive vectors by three bits
	--can optimize the widths here
	type stg2_t is array(0 to 3) of std_logic_vector(12 downto 0);
	signal stg2 : stg2_t := (others => (others => '0'));
	
	--array of 22 bit vectors for the third stage
	type stg3_t is array(0 to 1) of std_logic_vector(21 downto 0);
	signal stg3 : stg3_t := (others => (others => '0'));
	
	--array of 11 bit vectors for the final summing stage
	--type stg4_t is array(0 to 1) of std_logic_vector(10 downto 0);
	--signal stg4 : stg4_t := (others => (others => '0'));
	signal stg4 : std_logic_vector(31 downto 0) := (others => '0');
	
	--get the odd partial products for odd output bits < N
	--odd partial products are:
	-- x(0:idx/2-1) AND x(idx/2+1:idx)
	function get_odd_pp_ltN(x : std_logic_vector; idx : natural) 
	return std_logic_vector is
		variable v : std_logic_vector(idx/2-1 downto 0) := (others => '0');
	begin
		for i in 0 to (idx/2)-1 loop
			v(i) := x(i) and x(idx-i-1);
		end loop;
		return v;
	end function get_odd_pp_ltN;
	
	--get the even partial products for even output bits < N
	--even partial products are:
	-- x(0:idx/2-1) AND x(idx/2:idx-1)
	-- x(idx/2)
	function get_even_pp_ltN(x : std_logic_vector; idx : natural) 
	return std_logic_vector is
		variable v : std_logic_vector(idx/2 downto 0) := (others => '0');
	begin
		v(idx/2) := x(idx/2);
		for i in 0 to (idx/2)-1 loop
			v(i) := x(i) and x(idx-i-1);
		end loop;
		return v;
	end function get_even_pp_ltN;
	
	--get the odd partial products for odd output bits >= N
	--odd partial products are:
	-- x(idx-N:idx/2-1) AND x(idx/2+1:N-1)
	function get_odd_pp_gteN(x : std_logic_vector; idx : natural) 
	return std_logic_vector is
		variable v : std_logic_vector((2*N-idx)/2-1 downto 0) := (others => '0');
	begin
		for i in 0 to ((2*N-idx)/2)-1 loop
			v(i) := x(idx-N+i) and x(N-i-1);
		end loop;
		return v;
	end function get_odd_pp_gteN;
	
	--get the even partial products for even output bits >= N
	--even partial products are:
	-- x(idx-N:idx/2-1) AND x(idx/2:N-1)
	-- x(idx/2)
	function get_even_pp_gteN(x : std_logic_vector; idx : natural) 
	return std_logic_vector is
		variable v : std_logic_vector((2*N-idx)/2 downto 0) := (others => '0');
	begin
		v((2*N-idx)/2) := x(idx/2);
		for i in 0 to ((2*N-idx)/2)-1 loop
			v(i) := x(idx-N+i) and x(N-i-1);
		end loop;
		return v;
	end function get_even_pp_gteN;	

	--add all the bits in an slv and return the sum in an slv (unsigned)
	function adder(x : std_logic_vector) 
	return std_logic_vector is
		variable v: natural := 0;
	begin
		for i in 0 to x'length-1 loop
			-- if(x(i) = '1') then
				-- v := v + 1;
			-- end if;
			v := v + to_integer(unsigned(x(i downto i)));
		end loop;
		--return std_logic_vector(to_unsigned(v, x'length));
		return std_logic_vector(to_unsigned(v,5));
	end function adder;

	function z_vec(x : integer)
	return std_logic_vector is
	begin
		return std_logic_vector(to_unsigned(0,x));
	end function z_vec;
	
	function concat(x : std_logic_vector; y : std_logic_vector)
	return std_logic_vector is
		variable z : std_logic_vector(x'length + y'length - 1 downto 0);
	begin
		z := x & y;
		return z;
	end function;

	signal stg4_int : integer := 0;
	
	signal temp1, temp2, temp3 : std_Logic_vector(31 downto 0) := (others => '0');
	
	signal a_reg : std_logic_vector(31 downto 0) := (others => '0');
	
begin	

	process(clk)
	begin
		if(rising_edge(clk)) then
			a_reg <= a;
			
			--get partial products
			pp24 <= get_even_pp_ltN(a_reg,24); 
			pp26 <= get_even_pp_ltN(a_reg,26); 
			pp28 <= get_even_pp_ltN(a_reg,28); 
			pp30 <= get_even_pp_ltN(a_reg,30);

			pp25 <= get_odd_pp_ltN(a_reg,25);
			pp27 <= get_odd_pp_ltN(a_reg,27);
			pp29 <= get_odd_pp_ltN(a_reg,29);
			pp31 <= get_odd_pp_ltN(a_reg,31);

			pp32 <= get_even_pp_gteN(a_reg,32);
			pp34 <= get_even_pp_gteN(a_reg,34); 
			pp36 <= get_even_pp_gteN(a_reg,36); 
			pp38 <= get_even_pp_gteN(a_reg,38); 
			pp40 <= get_even_pp_gteN(a_reg,40);
			pp42 <= get_even_pp_gteN(a_reg,42); 
			pp44 <= get_even_pp_gteN(a_reg,44); 
			pp46 <= get_even_pp_gteN(a_reg,46); 
			pp48 <= get_even_pp_gteN(a_reg,48);
			pp50 <= get_even_pp_gteN(a_reg,50); 
			pp52 <= get_even_pp_gteN(a_reg,52); 
			pp54 <= get_even_pp_gteN(a_reg,54); 

			pp33 <= get_odd_pp_gteN(a_reg,33); 
			pp35 <= get_odd_pp_gteN(a_reg,35); 
			pp37 <= get_odd_pp_gteN(a_reg,37); 
			pp39 <= get_odd_pp_gteN(a_reg,39); 
			pp41 <= get_odd_pp_gteN(a_reg,41); 
			pp43 <= get_odd_pp_gteN(a_reg,43); 
			pp45 <= get_odd_pp_gteN(a_reg,45); 
			pp47 <= get_odd_pp_gteN(a_reg,47); 
			pp49 <= get_odd_pp_gteN(a_reg,49); 
			pp51 <= get_odd_pp_gteN(a_reg,51); 
			pp53 <= get_odd_pp_gteN(a_reg,53); 
			pp55 <= get_odd_pp_gteN(a_reg,55); 
	
			stg0(24) <= adder(pp24);
			stg0(25) <= adder(pp25);
			stg0(26) <= adder(pp26);
			stg0(27) <= adder(pp27);
			stg0(28) <= adder(pp28);
			stg0(29) <= adder(pp29);
			stg0(30) <= adder(pp30);
			stg0(31) <= adder(pp31);
			stg0(32) <= adder(pp32);
			stg0(33) <= adder(pp33);
			stg0(34) <= adder(pp34);
			stg0(35) <= adder(pp35);
			stg0(36) <= adder(pp36);
			stg0(37) <= adder(pp37);
			stg0(38) <= adder(pp38);
			stg0(39) <= adder(pp39);
			stg0(40) <= adder(pp40);
			stg0(41) <= adder(pp41);
			stg0(42) <= adder(pp42);
			stg0(43) <= adder(pp43);
			stg0(44) <= adder(pp44);
			stg0(45) <= adder(pp45);
			stg0(46) <= adder(pp46);
			stg0(47) <= adder(pp47);
			stg0(48) <= adder(pp48);
			stg0(49) <= adder(pp49);
			stg0(50) <= adder(pp50);
			stg0(51) <= adder(pp51);
			stg0(52) <= adder(pp52);
			stg0(53) <= adder(pp53);
			stg0(54) <= adder(pp54);
			stg0(55) <= adder(pp55);
				
			for i in 24 to 55 loop
				--stg0(i) <= stg0_pre(i);
			end loop;
			
			-- stg0(24) <= "00001";
			-- stg0(25) <= "00001";
			-- stg0(26) <= "00001";
			-- stg0(27) <= "00001";
			-- stg0(28) <= "00001";
			-- stg0(29) <= "00001";
			-- stg0(30) <= "00001";
			-- stg0(31) <= "00001";
			-- stg0(32) <= "00001";
			-- stg0(33) <= "00001";
			-- stg0(34) <= "00001";
			-- stg0(35) <= "00001";
			-- stg0(36) <= "00001";
			-- stg0(37) <= "00001";
			-- stg0(38) <= "00001";
			-- stg0(39) <= "00001";
			-- stg0(40) <= "00001";
			-- stg0(41) <= "00001";
			-- stg0(42) <= "00001";
			-- stg0(43) <= "00001";
			-- stg0(44) <= "00001";
			-- stg0(45) <= "00001";
			-- stg0(46) <= "00001";
			-- stg0(47) <= "00001";
			-- stg0(48) <= "00001";
			-- stg0(49) <= "00001";
			-- stg0(50) <= "00001";
			-- stg0(51) <= "00001";
			-- stg0(52) <= "00001";
			-- stg0(53) <= "00001";
			-- stg0(54) <= "00001";
			-- stg0(55) <= "00001";
		
			--first stage, sum up 10 5x5x5 vectors, expand the remaining two vectors to 8 bits
			for i in 0 to 9 loop
				stg1(i) <= std_logic_vector(
						   resize(unsigned(concat(stg0(i*3 + 0 + 24), z_vec(0))), stg1(i)'length) +        
						   resize(unsigned(concat(stg0(i*3 + 1 + 24), z_vec(1))), stg1(i)'length) + 
						   resize(unsigned(concat(stg0(i*3 + 2 + 24), z_vec(2))), stg1(i)'length) );
			end loop;

			stg1(10) <= std_logic_vector(resize(unsigned(stg0(54)),stg1(10)'length));
			stg1(11) <= std_logic_vector(resize(unsigned(stg0(55)),stg1(11)'length));

			--second stage, sum of 4 13x13x13 vectors, none left over
			--maybe optimize out bits that don't need to be summed
			for i in 0 to 2 loop
				stg2(i) <= std_logic_vector(
						   resize(unsigned(concat(stg1(i*3 + 0), z_vec(0))), stg2(i)'length) +        
						   resize(unsigned(concat(stg1(i*3 + 1), z_vec(3))), stg2(i)'length) + 
						   resize(unsigned(concat(stg1(i*3 + 2), z_vec(6))), stg2(i)'length) );
			end loop;
			
			--the last sum in stage 2 is different
			stg2(3) <= std_logic_vector(
					   resize(unsigned(concat(stg1( 9), z_vec(0))), stg2(3)'length) +        
					   resize(unsigned(concat(stg1(10), z_vec(3))), stg2(3)'length) + 
					   resize(unsigned(concat(stg1(11), z_vec(4))), stg2(3)'length) );
			
			--third stage, sum of 2 22x22 vectors, none left over
			--optimize later
			for i in 0 to 1 loop
				stg3(i) <= std_logic_vector(
						   resize(unsigned(concat(stg2(i*2 + 0), z_vec(0))), stg3(i)'length) +        
						   resize(unsigned(concat(stg2(i*2 + 1), z_vec(9))), stg3(i)'length) );
			end loop;
			
			--fourth and final stage, sum of overlapped vectors
			stg4 <= std_logic_vector(
					resize(unsigned(concat(stg3(0), z_vec( 0))), stg4'length) +        
					resize(unsigned(concat(stg3(1), z_vec(18))), stg4'length) );


		end if;
	end process;

	p(55 downto 24) <= stg4;
	--stg4_int <= to_integer(unsigned(stg4));
	
end arch;