library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Audio_top is
	port(
		clk, rst   : in  std_logic;
		sound_type : in  STD_LOGIC_VECTOR(1 downto 0);
		audio_out  : out STD_LOGIC_VECTOR(7 downto 0)
	);
end entity Audio_top;

architecture Behavioral of Audio_top is

	constant miss_sound  : integer := 1;
	constant hit_sound   : integer := 2;
	constant shoot_sound : integer := 3;

begin

end architecture Behavioral;
