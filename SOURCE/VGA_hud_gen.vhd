library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_pixel_gen is
    Port(clk        : in  STD_LOGIC;
         pixel_x    : in  STD_LOGIC_VECTOR(10 downto 0);
         pixel_y    : in  STD_LOGIC_VECTOR(10 downto 0);
         frame_tick : in  STD_LOGIC;
         HUD_on     : out STD_LOGIC;
         R, G, B    : out STD_LOGIC_VECTOR(6 downto 0));
end VGA_pixel_gen;

architecture RTL of VGA_pixel_gen is

begin

    R <= (others => '0');
    G <= (others => '0');
    B <= (others => '0');

    HUD_on <= '0';

end RTL;

