library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_cursor_gen is
    Port(clk, rst   : in  STD_LOGIC;
         pixel_x    : in  STD_LOGIC_VECTOR(10 downto 0);
         pixel_y    : in  STD_LOGIC_VECTOR(10 downto 0);
         mouse_x    : in  STD_LOGIC_VECTOR(10 downto 0);
         mouse_y    : in  STD_LOGIC_VECTOR(9 downto 0);
         frame_tick : in  STD_LOGIC;
         R, G, B    : out STD_LOGIC_VECTOR(6 downto 0);
         cursorOn   : out STD_LOGIC);
end VGA_cursor_gen;

architecture RTL of VGA_cursor_gen is

    signal cursor_change, cursor_change_n : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal cursor_sprite, cursor_sprite_n : STD_LOGIC_VECTOR(1 downto 0) := (others => '0');
    signal cursor_x, cursor_y             : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal cursor_x_n, cursor_y_n         : STD_LOGIC_VECTOR(3 downto 0) := (others => '0');
    signal R_n, G_n, B_n                  : STD_LOGIC_VECTOR(6 downto 0);
    signal R_int, G_int, B_int            : STD_LOGIC_VECTOR(6 downto 0);

    signal cursorVisible, cursorVisible_n : STD_LOGIC;

    signal cursorInRange, cursorInRange_n : STD_LOGIC;

    constant cursorSize : integer := 32; -- Screen size, not sprite size
    
    type CursorColor is array (0 to 255) of unsigned(3 downto 0);
    
	constant cursor : CursorColor :=(
		x"F", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"F", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"7", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"7", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"7", x"0", x"7", x"7", x"0", x"0", x"0", x"0", x"7", x"7", x"7", x"7", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"7", x"7", x"7", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"7",  
		x"F", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"F", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"7", x"7", x"7", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"7", x"7", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"7", x"7", x"0", x"0", x"0", x"0", x"0", x"0", x"7", x"7", x"0", x"0", x"0", x"0", x"0", x"0", x"7", x"7", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"7", x"7",  
		x"F", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"F", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"7", x"7", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"7", x"7", x"7", x"7", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"7", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"7", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"7", x"7", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"7",  
		x"F", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"F", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"7", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"7", x"7", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"7", x"7", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"7", x"7", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0"
	);
    
    -- Cursor size : 64*16 => 4 sprites (16*16) 
    type CursorConstant is array (0 to 1023) of unsigned(7 downto 0);

    constant r_rom : CursorConstant := (
        X"00", X"03", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"03", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"03", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"03", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"27", X"27", X"5e", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"27", X"27", X"5e", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"27", X"27", X"27", X"27", X"5e", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"27", X"27", X"5e", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"6b", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"27", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"27", X"27", X"27", X"5e", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"27", X"27", X"5e", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"10", X"00", X"00", X"13", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"27", X"5e", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"27", X"03", X"03", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"03", X"03", X"6b", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"13", X"13", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"03", X"6b", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"13", X"13", X"00", X"00", X"00", X"13", X"13", X"13", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"13", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"1a", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"13", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"00", X"1a", X"13", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"13", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"1a", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"13", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"03", X"13", X"03", X"03", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"13", X"13", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"13", X"03", X"03", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"13", X"13", X"13", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"13", X"5e", X"5e", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"1a", X"13", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"13", X"5e", X"5e", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"13", X"1a", X"13", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"13", X"5e", X"5e", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"03", X"13", X"03", X"03", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"5e", X"5e", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"1a", X"00", X"03", X"13", X"03", X"03", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"27", X"27", X"13", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"13", X"5e", X"5e", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"13", X"27", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"13", X"5e", X"5e", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"13", X"13", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"13", X"5e", X"5e", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"13", X"27", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"13", X"5e", X"5e", X"13", X"13", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"13", X"13", X"13", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"27", X"13", X"13", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"13", X"13", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"27", X"27", X"00", X"13", X"13", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"13", X"13", X"13", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00"
    );

    constant g_rom : CursorConstant := (
        X"10", X"1a", X"0d", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"10", X"44", X"10", X"10", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"1a", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"1a", X"0d", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"1a", X"0d", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"00", X"10", X"10", X"4e", X"4e", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"10", X"44", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"10", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"44", X"10", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"4e", X"4e", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"4e", X"4e", X"4e", X"4e", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"4e", X"4e", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"7c", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"4e", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"4e", X"4e", X"4e", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"4e", X"4e", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"44", X"44", X"27", X"00", X"5b", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"4e", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"4e", X"1a", X"1a", X"44", X"00", X"00", X"1a", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"1a", X"1a", X"7c", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"44", X"5b", X"5b", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"1a", X"7c", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"5b", X"5b", X"10", X"27", X"00", X"5b", X"5b", X"5b", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"5b", X"44", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"10", X"55", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"5b", X"44", X"00", X"00", X"1a", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"44", X"10", X"55", X"5b", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"27", X"00", X"5b", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"55", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"10", X"27", X"00", X"5b", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"1a", X"5b", X"1a", X"1a", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"44", X"5b", X"5b", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"5b", X"1a", X"1a", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"5b", X"5b", X"5b", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"0d", X"5b", X"72", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"55", X"5b", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"5b", X"72", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"44", X"5b", X"55", X"5b", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"0d", X"5b", X"72", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"1a", X"5b", X"1a", X"1a", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"72", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"55", X"10", X"1a", X"5b", X"1a", X"1a", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"4e", X"4e", X"5b", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"5b", X"72", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"5b", X"4e", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"5b", X"72", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"5b", X"5b", X"0d", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"5b", X"72", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"5b", X"4e", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"5b", X"72", X"72", X"5b", X"5b", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"5b", X"5b", X"5b", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"4e", X"5b", X"5b", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"5b", X"5b", X"1a", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"4e", X"4e", X"00", X"5b", X"5b", X"1a", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"0d", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"5b", X"5b", X"5b", X"1a", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"0d", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"0d", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"0d", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"0d", X"10"
    );

    constant b_rom : CursorConstant := (
        X"10", X"16", X"09", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"10", X"3e", X"10", X"10", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"16", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"16", X"09", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"16", X"09", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"00", X"10", X"10", X"47", X"47", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"10", X"3e", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"10", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"3e", X"10", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"47", X"47", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"47", X"47", X"47", X"47", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"47", X"47", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"78", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"47", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"47", X"47", X"47", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"47", X"47", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"3e", X"3e", X"23", X"00", X"55", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"47", X"72", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"47", X"16", X"16", X"3e", X"00", X"00", X"16", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"16", X"16", X"78", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"3e", X"55", X"55", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"16", X"78", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"55", X"55", X"10", X"23", X"00", X"55", X"55", X"55", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"55", X"3e", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"10", X"51", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"55", X"3e", X"00", X"00", X"16", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"3e", X"10", X"51", X"55", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"23", X"00", X"55", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"51", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"10", X"23", X"00", X"55", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"16", X"55", X"16", X"16", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"3e", X"55", X"55", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"55", X"16", X"16", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"55", X"55", X"55", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"09", X"55", X"6f", X"6f", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"51", X"55", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"55", X"6f", X"6f", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"3e", X"55", X"51", X"55", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"09", X"55", X"6f", X"6f", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"16", X"55", X"16", X"16", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"6f", X"6f", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"51", X"10", X"16", X"55", X"16", X"16", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"47", X"47", X"55", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"55", X"6f", X"6f", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"55", X"47", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"55", X"6f", X"6f", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"55", X"55", X"09", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"55", X"6f", X"6f", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"55", X"47", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"55", X"6f", X"6f", X"55", X"55", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"55", X"55", X"55", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"10", X"47", X"55", X"55", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"55", X"55", X"16", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"47", X"47", X"00", X"55", X"55", X"16", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"09", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"55", X"55", X"55", X"16", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"09", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"09", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"09", X"10", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"00", X"09", X"10"
    );

begin

    seq : process(clk, rst)
    begin
        if (rst = '1') then
            R_int         <= (others => '0');
            G_int         <= (others => '0');
            B_int         <= (others => '0');
            cursor_x      <= (others => '0');
            cursor_y      <= (others => '0');
            cursorVisible <= '0';
        elsif (rising_edge(clk)) then
            R_int         <= R_n;
            G_int         <= G_n;
            B_int         <= B_n;
            cursorInRange <= cursorInRange_n;
            cursor_x      <= cursor_x_n;
            cursor_y      <= cursor_y_n;
            cursorVisible <= cursorVisible_n;
        end if;
    end process;

    -- Cursor selector
    cursor_selector : process(clk, rst)
    begin
        if (rst = '1') then
            cursor_change <= (others => '0');
            cursor_sprite <= (others => '0');
        elsif (rising_edge(clk) and frame_tick = '1') then
            cursor_change <= cursor_change_n;
            cursor_sprite <= cursor_sprite_n;
        end if;
    end process;

    -- Cursor valid x/y for displaying
    validator : process(pixel_x, pixel_y, mouse_x, mouse_y)
    begin
        cursorInRange_n <= '0';
        if (unsigned(mouse_x) + cursorSize > unsigned(pixel_x)) and (unsigned(mouse_x) < unsigned(pixel_x)) then
            if (unsigned(mouse_y) + cursorSize > unsigned(pixel_y)) and (unsigned(mouse_y) < unsigned(pixel_y)) then
                cursorInRange_n <= '1';
            end if;
        end if;
    end process;

    cursor_pos : process(mouse_x, mouse_y, pixel_x, pixel_y, cursor_change, cursor_sprite)
    begin
        cursor_sprite_n <= cursor_sprite;

        cursor_x_n <= std_logic_vector(resize((unsigned(pixel_x) - unsigned(mouse_x)) / 2, 4));
        cursor_y_n <= std_logic_vector(resize((unsigned(pixel_y) - unsigned(mouse_y)) / 2, 4));

        -- Count up every frame (and allow to overflow)
        cursor_change_n <= std_logic_vector(unsigned(cursor_change) + 1);

        -- Change cursor sprite when cursor_change overflowed
        if (cursor_change = "000") then
            cursor_sprite_n <= std_logic_vector(unsigned(cursor_sprite) + 1);
        end if;

    end process;

    ROM : process(cursor_x, cursor_y, cursor_sprite, B_int, G_int, R_int)
    begin
        R_n <= std_logic_vector(r_rom(to_integer(unsigned(cursor_y & cursor_sprite & cursor_x)))(7 downto 1));
        G_n <= std_logic_vector(g_rom(to_integer(unsigned(cursor_y & cursor_sprite & cursor_x)))(7 downto 1));
        B_n <= std_logic_vector(b_rom(to_integer(unsigned(cursor_y & cursor_sprite & cursor_x)))(7 downto 1));

        -- Black (=0) => transparent cursor
        if ((unsigned(R_int) = 0) and (unsigned(G_int) = 0) and (unsigned(B_int) = 0)) then
            cursorVisible_n <= '0';
        else
            cursorVisible_n <= '1';
        end if;

    end process;

    cursorOn <= cursorInRange and cursorVisible;

    R <= R_int;
    G <= G_int;
    B <= B_int;

end RTL;

