library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity one_bit_adder is
    Port ( a,b,c_in : in  STD_LOGIC;
           s,c_out  : out  STD_LOGIC);
end one_bit_adder;

architecture Behavioral of one_bit_adder is

begin

	s <= a xor b xor c_in;
	c_out <= (a and b) or (c_in and (a xor b));

end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity scitac_11bit is
    Port ( a, b : in  STD_LOGIC_VECTOR (10 downto 0);
           y : out  STD_LOGIC_VECTOR (10 downto 0));
end scitac_11bit;

architecture Behavioral of scitac_11bit is
	signal c_pom_one: std_logic;
	signal c_pom_two: std_logic;
	signal c_pom_three, c_pom_four, c_pom_five, c_pom_six, c_pom_seven, c_pom_eight, c_pom_nine, c_pom_ten, c_out: std_logic;
	signal y_pom: std_logic_vector (10 downto 0);

	component one_bit_adder is
		Port ( a,b,c_in : in  STD_LOGIC;
				s,c_out  : out  STD_LOGIC);
	end component;

begin
	first_bit: one_bit_adder
		port map(a=>a(0), b=>b(0), c_in=>'0', s=>y_pom(0), c_out=>c_pom_one);
	second_bit: one_bit_adder
		port map(a=>a(1), b=>b(1), c_in=>c_pom_one, s=>y_pom(1), c_out=>c_pom_two);
	third_bit: one_bit_adder
		port map(a=>a(2), b=>b(2), c_in=>c_pom_two, s=>y_pom(2), c_out=>c_pom_three);
	fourth_bit: one_bit_adder
		port map(a=>a(3), b=>b(3), c_in=>c_pom_three, s=>y_pom(3), c_out=>c_pom_four);
	fifth_bit: one_bit_adder
		port map(a=>a(4), b=>b(4), c_in=>c_pom_four, s=>y_pom(4), c_out=>c_pom_five);
	sixth_bit: one_bit_adder
		port map(a=>a(5), b=>b(5), c_in=>c_pom_five, s=>y_pom(5), c_out=>c_pom_six);
	seventh_bit: one_bit_adder
		port map(a=>a(6), b=>b(6), c_in=>c_pom_six, s=>y_pom(6), c_out=>c_pom_seven);
	eighth_bit: one_bit_adder
		port map(a=>a(7), b=>b(7), c_in=>c_pom_seven, s=>y_pom(7), c_out=>c_pom_eight);
	ninth_bit: one_bit_adder
		port map(a=>a(8), b=>b(8), c_in=>c_pom_eight, s=>y_pom(8), c_out=>c_pom_nine);
	ten_bit: one_bit_adder
		port map(a=>a(9), b=>b(9), c_in=>c_pom_nine, s=>y_pom(9), c_out=>c_pom_ten);
	eleven_bit: one_bit_adder
		port map(a=>a(10), b=>b(10), c_in=>c_pom_ten, s=>y_pom(10), c_out=> c_out);
		
--osetrenie pretecenia
process (b,c_out,y_pom,a)
begin
	if (b(8) = '0') then
		if (c_out = '1') then
			y <= (others => '1');	
		else
			y <= y_pom;
		end if;
	else 
		if ((unsigned(a)) < (unsigned(not (std_logic_vector((unsigned (b))-1))))) then
			y <= (others => '0');
		else
			y <= y_pom;
		end if;
	end if;
end process;

end Behavioral;

