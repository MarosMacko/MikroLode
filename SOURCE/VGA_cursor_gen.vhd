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
    signal cursor_x, cursor_y             : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal cursor_x_n, cursor_y_n         : STD_LOGIC_VECTOR(2 downto 0) := (others => '0');
    signal R_n, G_n, B_n                  : STD_LOGIC_VECTOR(6 downto 0);
    signal R_int, G_int, B_int            : STD_LOGIC_VECTOR(6 downto 0);

    signal cursorVisible, cursorVisible_n : STD_LOGIC;

    signal cursorInRange, cursorInRange_n : STD_LOGIC;

    constant cursorSize : integer := 32; -- Screen size, not sprite size

    type CursorColor is array (0 to 255) of unsigned(2 downto 0);

    constant cursor : CursorColor := (
        "010", "100", "101", "101", "101", "101", "101", "101", "100", "011", "101", "000", "000", "101", "101", "101", "101", "001", "010", "001", "010", "000", "101", "101", "101", "101", "101", "101", "001", "001", "101", "101", "101", "101", "101", "101", "010", "000", "101", "101", "101", "101", "101", "101", "001", "001", "101", "101", "101", "101", "101", "101", "101", "000", "011", "100", "101", "101", "101", "101", "101", "101", "100", "011",
        "010", "100", "101", "101", "101", "101", "101", "101", "100", "011", "010", "101", "101", "101", "101", "101", "101", "101", "010", "001", "101", "101", "101", "101", "101", "101", "000", "010", "000", "101", "101", "101", "101", "101", "101", "001", "010", "001", "000", "101", "101", "101", "101", "101", "000", "010", "010", "101", "101", "101", "101", "101", "101", "101", "011", "100", "101", "101", "101", "101", "101", "101", "100", "011",
        "010", "100", "101", "101", "101", "101", "101", "101", "100", "011", "101", "101", "101", "101", "101", "101", "101", "101", "010", "001", "000", "001", "101", "101", "101", "101", "000", "010", "010", "010", "000", "101", "101", "101", "101", "101", "000", "001", "010", "000", "101", "101", "101", "101", "101", "101", "010", "000", "101", "101", "101", "101", "101", "101", "011", "100", "101", "101", "101", "101", "101", "101", "100", "011",
        "010", "100", "101", "101", "101", "101", "101", "101", "100", "011", "101", "000", "000", "101", "101", "101", "101", "001", "010", "001", "010", "000", "101", "101", "101", "101", "101", "101", "001", "001", "000", "101", "101", "101", "101", "101", "101", "000", "010", "101", "101", "101", "101", "101", "101", "101", "001", "000", "101", "101", "101", "101", "101", "101", "011", "100", "101", "101", "101", "101", "101", "101", "100", "011"
    );

    type Palette is array (0 to 5) of unsigned(2 downto 0);

    constant r_pal : Palette := (
        "010", "011", "111", "101", "100", "000"
    );
    constant g_pal : Palette := (
        "010", "100", "111", "101", "100", "000"
    );
    constant b_pal : Palette := (
        "110", "111", "111", "101", "100", "000"
    );

    signal cursorIndex, cursorIndex_n : STD_LOGIC_VECTOR(2 downto 0);

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
            cursorInRange <= '0';
            cursorIndex   <= (others => '0');
        elsif (rising_edge(clk)) then
            R_int         <= R_n;
            G_int         <= G_n;
            B_int         <= B_n;
            cursor_x      <= cursor_x_n;
            cursor_y      <= cursor_y_n;
            cursorVisible <= cursorVisible_n;
            cursorInRange <= cursorInRange_n;
            cursorIndex   <= cursorIndex_n;
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

    -- Should be cursor visible based on x/y
    validator : process(pixel_x, pixel_y, mouse_x, mouse_y)
    begin
        cursorInRange_n <= '0';
        if (unsigned(mouse_x) + cursorSize > unsigned(pixel_x)) and (unsigned(mouse_x) < unsigned(pixel_x)) then
            if (unsigned(mouse_y) + cursorSize > unsigned(pixel_y)) and (unsigned(mouse_y) < unsigned(pixel_y)) then
                cursorInRange_n <= '1';
            end if;
        end if;
    end process;

    -- Cursor position calculator
    cursor_pos : process(mouse_x, mouse_y, pixel_x, pixel_y, cursor_change, cursor_sprite)
    begin
        cursor_sprite_n <= cursor_sprite;

        cursor_x_n <= std_logic_vector(shift_right((unsigned(pixel_x) - unsigned(mouse_x)), 2)(2 downto 0));
        cursor_y_n <= std_logic_vector(shift_right((unsigned(pixel_y) - unsigned(mouse_y)), 2)(2 downto 0));

        -- Count up every frame (and allow to overflow)
        cursor_change_n <= std_logic_vector(unsigned(cursor_change) + 1);

        -- Change cursor sprite when cursor_change overflowed
        if (cursor_change = "000") then
            cursor_sprite_n <= std_logic_vector(unsigned(cursor_sprite) + 1);
        end if;

    end process;

    ROM : process(cursor_x, cursor_y, cursor_sprite, cursorIndex, cursorInRange)
    begin
        cursorIndex_n <= std_logic_vector(cursor(to_integer(unsigned(cursor_sprite & cursor_y & cursor_x))));

        R_n(6 downto 4) <= std_logic_vector(r_pal(to_integer(unsigned(cursorIndex))));
        G_n(6 downto 4) <= std_logic_vector(g_pal(to_integer(unsigned(cursorIndex))));
        B_n(6 downto 4) <= std_logic_vector(b_pal(to_integer(unsigned(cursorIndex))));
        R_n(4 downto 0) <= (others => '0');
        G_n(4 downto 0) <= (others => '0');
        B_n(4 downto 0) <= (others => '0');

        -- transparent cursor = pallete index 5
        if (cursorIndex > "100" or cursorInRange = '0') then
            cursorVisible_n <= '0';
        else
            cursorVisible_n <= '1';
        end if;

    end process;

    cursorOn <= cursorVisible;

    R <= R_int;
    G <= G_int;
    B <= B_int;

end RTL;

