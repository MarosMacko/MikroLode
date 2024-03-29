library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_pixel_gen is
    Port(clk, rst    : in  STD_LOGIC;
         pixel_x     : in  STD_LOGIC_VECTOR(10 downto 0);
         pixel_y     : in  STD_LOGIC_VECTOR(10 downto 0);
         line_tick   : in  STD_LOGIC;
         frame_tick  : in  STD_LOGIC;
         RAM_address : out STD_LOGIC_VECTOR(9 downto 0);
         RAM_data    : in  STD_LOGIC_VECTOR(17 downto 0);
         R, G, B     : out STD_LOGIC_VECTOR(6 downto 0));
end VGA_pixel_gen;

architecture RTL of VGA_pixel_gen is

    -- RGB registers
    signal R_n, G_n, B_n       : STD_LOGIC_VECTOR(6 downto 0) := (others => '0');
    signal R_int, G_int, B_int : STD_LOGIC_VECTOR(6 downto 0) := (others => '0');

    -- Maybe another time, my friend :/
    -- Screen shake FX
    --signal pixel_x_fx, pixel_y_fx                 : STD_LOGIC_VECTOR(10 downto 0);
    --signal pixel_x_fx_n, pixel_y_fx_n             : STD_LOGIC_VECTOR(10 downto 0);
    --signal shake_x, shake_x_n, shake_y, shake_y_n : STD_LOGIC_VECTOR(3 downto 0);
    --signal shake_counter, shake_counter_n         : STD_LOGIC_VECTOR(4 downto 0);

    signal isHud, isHud_n   : STD_LOGIC;
    signal isShip, isShip_n : STD_LOGIC;

    -- RAM signals
    signal field_data_ready, field_data_ready_n   : STD_LOGIC;
    signal global_data_ready, global_data_ready_n : STD_LOGIC;
    signal RAM_address_int_n, RAM_address_int     : STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
    signal RAM_data_buf                           : STD_LOGIC_VECTOR(17 downto 0);

    -- ROM signals
    signal ROM_addr_tile_n, ROM_addr_tile           : STD_LOGIC_VECTOR(11 downto 0);
    signal ROM_addr_hud_n, ROM_addr_hud             : STD_LOGIC_VECTOR(14 downto 0);
    signal ROM_addr_ship_n, ROM_addr_ship           : STD_LOGIC_VECTOR(12 downto 0);
    signal palette_index_hud, palette_index_hud_n   : STD_LOGIC_VECTOR(3 downto 0);
    signal palette_index_tile, palette_index_tile_n : STD_LOGIC_VECTOR(3 downto 0);
    signal palette_index_ship, palette_index_ship_n : STD_LOGIC_VECTOR(3 downto 0);

    -- Internal counters to know where we are
    signal tile_x, tile_y         : STD_LOGIC_VECTOR(4 downto 0);
    signal tile_x_n, tile_y_n     : STD_LOGIC_VECTOR(4 downto 0);
    signal sprite_x, sprite_y     : STD_LOGIC_VECTOR(3 downto 0);
    signal sprite_x_n, sprite_y_n : STD_LOGIC_VECTOR(3 downto 0);

    component VGA_ROM
        port(
            clk, re     : in  STD_LOGIC;
            addr_tile   : in  STD_LOGIC_VECTOR(11 downto 0);
            addr_ship   : in  STD_LOGIC_VECTOR(12 downto 0);
            addr_hud    : in  STD_LOGIC_VECTOR(14 downto 0);
            output_hud  : out STD_LOGIC_VECTOR(3 downto 0);
            output_tile : out STD_LOGIC_VECTOR(3 downto 0);
            output_ship : out STD_LOGIC_VECTOR(3 downto 0)
        );
    end component VGA_ROM;

    -- Maybe another time, my friend :/
    --type ShakeSequence is array (0 to 31) of unsigned(3 downto 0);
    --constant shake_x_seq : ShakeSequence := (x"D", x"6", x"5", x"2", x"2", x"A", x"A", x"D", x"A", x"C", x"7", x"8", x"1", x"1", x"F", x"E", x"0", x"1", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0");
    --constant shake_y_seq : ShakeSequence := (x"4", x"B", x"4", x"C", x"8", x"B", x"C", x"9", x"D", x"D", x"8", x"7", x"2", x"C", x"3", x"0", x"1", x"F", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0");

    signal re : STD_LOGIC := '1';
    type PaletteRom is array (0 to 47) of unsigned(7 downto 0);

    type ram_data_field_t is record
        red_p2    : STD_LOGIC;
        grey_p2   : STD_LOGIC;
        taken     : STD_LOGIC;
        red_p1    : STD_LOGIC;
        grey_p1   : STD_LOGIC;
        ship      : STD_LOGIC;
        HUD       : STD_LOGIC;
        tile_data : STD_LOGIC_VECTOR(10 downto 0);
    end record ram_data_field_t;

    type ram_data_global_t is record
        player  : STD_LOGIC;
        shake   : STD_LOGIC;
        fadein  : STD_LOGIC;
        fadeout : STD_LOGIC;
    end record ram_data_global_t;

    signal field_data, field_data_n   : ram_data_field_t;
    signal global_data, global_data_n : ram_data_global_t;

    function unpack_field(arg : std_logic_vector(17 downto 0)) return ram_data_field_t is
        variable result : ram_data_field_t;
    begin
        result.red_p2    := arg(17);
        result.grey_p2   := arg(16);
        result.taken     := arg(15);
        result.red_p1    := arg(14);
        result.grey_p1   := arg(13);
        result.ship      := arg(12);
        result.HUD       := arg(11);
        result.tile_data := arg(10 downto 0);
        return result;
    end function unpack_field;

    function unpack_global(arg : std_logic_vector(3 downto 0)) return ram_data_global_t is
        variable result : ram_data_global_t;
    begin
        result.player  := arg(0);
        result.shake   := arg(1);
        result.fadein  := arg(2);
        result.fadeout := arg(3);
        return result;
    end function unpack_global;

    constant tiles_palette : PaletteRom := (
        x"59", x"62", x"de",
        x"70", x"96", x"e6",
        x"00", x"78", x"4a",
        x"00", x"46", x"2b",
        x"e3", x"e3", x"00",
        x"f3", x"92", x"41",
        x"a9", x"0c", x"00",
        x"e3", x"10", x"10",
        x"ea", x"ea", x"ea",
        x"cc", x"cc", x"cc",
        x"af", x"af", x"af",
        x"93", x"93", x"93",
        x"82", x"82", x"82",
        x"7b", x"7b", x"7b",
        x"71", x"71", x"71",
        x"61", x"61", x"61"
    );

    constant hud_palette : PaletteRom := (
        x"00", x"00", x"90",
        x"51", x"51", x"d3",
        x"64", x"6b", x"ff",
        x"71", x"92", x"e3",
        x"ee", x"ea", x"00",
        x"e9", x"a1", x"30",
        x"b2", x"00", x"00",
        x"e3", x"10", x"10",
        x"f9", x"f9", x"f9",
        x"b2", x"b2", x"b2",
        x"9a", x"9a", x"9a",
        x"92", x"92", x"92",
        x"8a", x"8a", x"8a",
        x"82", x"82", x"82",
        x"61", x"61", x"61",
        x"00", x"00", x"00"
    );

    -- fade counter 5 bit = 32 frames of fading in / out
    signal fade, fade_n : STD_LOGIC_VECTOR(4 downto 0) := (others => '1');

    signal ram_delayed, ram_delayed_n : STD_LOGIC_VECTOR(1 downto 0);

begin

    RAM_address <= RAM_address_int;
    re          <= '1';                 -- ROM read enable

    ROM : VGA_ROM
        port map(
            clk         => clk,
            re          => re,
            addr_tile   => ROM_addr_tile,
            addr_ship   => ROM_addr_ship,
            addr_hud    => ROM_addr_hud,
            output_hud  => palette_index_hud_n,
            output_tile => palette_index_tile_n,
            output_ship => palette_index_ship_n
        );

    -- Count where we are on the display
    Tile_tracker_seq : process(rst, clk)
    begin
        if (rst = '1') then
            tile_x   <= (others => '0');
            tile_y   <= (others => '0');
            sprite_x <= (others => '0');
            sprite_y <= (others => '0');
        elsif (rising_edge(clk)) then
            tile_x   <= tile_x_n;
            tile_y   <= tile_y_n;
            sprite_x <= sprite_x_n;
            sprite_y <= sprite_y_n;
        end if;
    end process;

    Tile_tracker_comb : process(sprite_y, sprite_x, tile_x, tile_y, pixel_x, pixel_y, line_tick)
    begin
        tile_x_n   <= tile_x;
        tile_y_n   <= tile_y;
        sprite_x_n <= sprite_x;
        sprite_y_n <= sprite_y;

        -- sprite_N  = (N / 4) mod 16
        -- / 4 -> Pixel quadrupling (16px sprite in ROM, 64px sprine on display)
        -- mod 16 -> 16px per sprite
        sprite_x_n <= std_logic_vector(unsigned(pixel_x(5 downto 2)));
        sprite_y_n <= std_logic_vector(unsigned(pixel_y(5 downto 2)));

        -- last pixel
        if (unsigned(pixel_y) >= 1024) then
            -- Reset
            tile_x_n <= (others => '0');
            tile_y_n <= (others => '0');
        elsif (unsigned(pixel_x) >= 1280) then -- reset X at the end of the line
            tile_x_n <= (others => '0');
        else
            -- Increase tile X every 64px
            if (pixel_x(5 downto 0) <= "000000") then
                tile_x_n <= std_logic_vector(unsigned(tile_x) + 1);
            end if;
            -- Increase tile Y every 64px
            if (pixel_y(5 downto 0) = "111111") and line_tick = '1' then
                tile_y_n <= std_logic_vector(unsigned(tile_y) + 1);
            end if;
        end if;

    end process;

    --
    --  RAM SEQ
    --
    -- Get new sprite from RAM
    RAM_seq : process(rst, clk)
    begin
        if (rst = '1') then
            global_data       <= ('0', '0', '0', '0');
            field_data        <= ('0', '0', '0', '0', '0', '0', '0', (others => '0'));
            global_data_ready <= '0';
            field_data_ready  <= '0';
            RAM_address_int   <= (others => '0');
            isHud             <= '0';
            isShip            <= '0';
            fade              <= (others => '1');
            RAM_data_buf      <= (others => '0');
            ram_delayed       <= "00";
        elsif (rising_edge(clk)) then
            RAM_data_buf      <= RAM_data;
            global_data       <= global_data_n;
            field_data        <= field_data_n;
            global_data_ready <= global_data_ready_n;
            field_data_ready  <= field_data_ready_n;
            RAM_address_int   <= RAM_address_int_n;
            isHud             <= isHud_n;
            isShip            <= isShip_n;
            fade              <= fade_n;
            ram_delayed       <= ram_delayed_n;
        end if;
    end process;

    --
    --  RAM COMB
    --
    RAM_comb : process(frame_tick, RAM_data_buf, field_data, global_data, global_data_ready, field_data_ready, RAM_address_int, isHud, tile_x, tile_y, sprite_x, isShip, fade, ram_delayed)
    begin
        global_data_n       <= global_data;
        field_data_n        <= field_data;
        global_data_ready_n <= global_data_ready;
        field_data_ready_n  <= field_data_ready;
        RAM_address_int_n   <= RAM_address_int;
        isHud_n             <= isHud;
        isShip_n            <= isShip;
        fade_n              <= fade;
        ram_delayed_n       <= ram_delayed;

        -- global data read
        if (global_data_ready = '1') then
            if (ram_delayed = "11") then
                -- reset the flag
                global_data_ready_n <= '0';
                ram_delayed_n       <= "00";
                -- update global data
                global_data_n       <= unpack_global(RAM_data_buf(3 downto 0));
            else
                ram_delayed_n <= std_logic_vector(unsigned(ram_delayed) + 1);
            end if;

        -- field data read
        elsif (field_data_ready = '1') then
            -- reset the flag
            field_data_ready_n <= '0';
            ram_delayed_n      <= "00";
            -- update field data
            field_data_n       <= unpack_field(RAM_data_buf);
            isHud_n            <= unpack_field(RAM_data_buf).HUD;
            isShip_n           <= unpack_field(RAM_data_buf).ship;
        end if;

        -- ask for new global data
        -- higher priority than line tick
        if (frame_tick = '1') then
            RAM_address_int_n   <= std_logic_vector(to_unsigned(320, RAM_address_int_n'length));
            -- rise the global flag
            global_data_ready_n <= '1';

            -- step the fade function (forwards or backwards) based on old data (no problem)
            if (global_data.fadeout = '1') and (unsigned(fade) > 0) then
                fade_n <= std_logic_vector(unsigned(fade) - 1);
            elsif (unsigned(fade) < "11111") then
                fade_n <= std_logic_vector(unsigned(fade) + 1);
            end if;
        -- ask for new field (sprite) data
        elsif (unsigned(sprite_x) = x"F") then
            RAM_address_int_n  <= std_logic_vector((unsigned(tile_y) * 20) + unsigned(tile_x));
            -- rise the field flag
            field_data_ready_n <= '1';
        end if;

    end process;

    --
    --   ROM
    --
    ROM_seq : process(rst, clk)
    begin
        if (rst = '1') then
            ROM_addr_tile      <= (others => '0');
            ROM_addr_hud       <= (others => '0');
            ROM_addr_ship      <= (others => '0');
            palette_index_hud  <= (others => '0');
            palette_index_tile <= (others => '0');
            palette_index_ship <= (others => '0');
        elsif (rising_edge(clk)) then
            ROM_addr_tile      <= ROM_addr_tile_n;
            ROM_addr_hud       <= ROM_addr_hud_n;
            ROM_addr_ship      <= ROM_addr_ship_n;
            palette_index_hud  <= palette_index_hud_n;
            palette_index_tile <= palette_index_tile_n;
            palette_index_ship <= palette_index_ship_n;
        end if;
    end process;

    ROM_comb : process(field_data.tile_data, sprite_x, sprite_y, isHud, isShip, ROM_addr_hud, ROM_addr_tile, global_data.player, ROM_addr_ship)
    begin
        -- palette_index_n <= palette_index; <-- directly from ROM
        ROM_addr_hud_n  <= ROM_addr_hud;
        ROM_addr_tile_n <= ROM_addr_tile;
        ROM_addr_ship_n <= ROM_addr_ship;

        -- Assemble the sprite vector (identical to sprite*16*16 + y*16 + x)
        if (isHud = '1') then
            ROM_addr_hud_n <= field_data.tile_data(6 downto 0) & sprite_y & sprite_x;
        else
            if (global_data.player = '1') then
                if (isShip = '1') then
                    ROM_addr_ship_n <= field_data.tile_data(4 downto 0) & sprite_y & sprite_x;
                else
                    ROM_addr_tile_n <= field_data.tile_data(3 downto 0) & sprite_y & sprite_x;
                end if;
            else
                ROM_addr_tile_n <= field_data.tile_data(10 downto 7) & sprite_y & sprite_x;
            end if;
        end if;

    end process;

    -- Color preparation
    RGB_prep : process(isHud, palette_index_hud, palette_index_tile, isShip, palette_index_ship, fade, field_data.grey_p1, field_data.grey_p2, field_data.red_p1, field_data.red_p2, global_data.player)
    begin
        -- HUD pallete, no FX
        if (isHud = '1') then
            R_n <= std_logic_vector(hud_palette(to_integer((unsigned(palette_index_hud) * 3) + 0))(7 downto 1));
            G_n <= std_logic_vector(hud_palette(to_integer((unsigned(palette_index_hud) * 3) + 1))(7 downto 1));
            B_n <= std_logic_vector(hud_palette(to_integer((unsigned(palette_index_hud) * 3) + 2))(7 downto 1));
        else
            -- Grey tint
            if (global_data.player = '1' and field_data.grey_p1 = '1') or (global_data.player = '0' and field_data.grey_p2 = '1') then
                if (isShip = '0' or global_data.player = '0') then
                    R_n <= std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_tile) * 3) + 1))(7 downto 1)) AND (fade & "11");
                    G_n <= std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_tile) * 3) + 1))(7 downto 1)) AND (fade & "11");
                    B_n <= std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_tile) * 3) + 1))(7 downto 1)) AND (fade & "11");
                else
                    R_n <= std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_ship) * 3) + 1))(7 downto 1)) AND (fade & "11");
                    G_n <= std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_ship) * 3) + 1))(7 downto 1)) AND (fade & "11");
                    B_n <= std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_ship) * 3) + 1))(7 downto 1)) AND (fade & "11");
                end if;
            -- Red tint
            elsif (global_data.player = '1' and field_data.red_p1 = '1') or (global_data.player = '0' and field_data.red_p2 = '1') then
                if (isShip = '0' or global_data.player = '0') then
                    R_n <= ("1" & std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_tile) * 3) + 0))(7 downto 2))) AND (fade & "11");
                    G_n <= ("0" & std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_tile) * 3) + 1))(5 downto 0))) AND (fade & "11");
                    B_n <= ("0" & std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_tile) * 3) + 2))(5 downto 0))) AND (fade & "11");
                else
                    R_n <= ("1" & std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_ship) * 3) + 0))(7 downto 2))) AND (fade & "11");
                    G_n <= ("0" & std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_ship) * 3) + 1))(5 downto 0))) AND (fade & "11");
                    B_n <= ("0" & std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_ship) * 3) + 2))(5 downto 0))) AND (fade & "11");
                end if;
            -- Normal stuff
            else
                if (isShip = '0' or global_data.player = '0') then
                    R_n <= std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_tile) * 3) + 0))(7 downto 1)) AND (fade & "11");
                    G_n <= std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_tile) * 3) + 1))(7 downto 1)) AND (fade & "11");
                    B_n <= std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_tile) * 3) + 2))(7 downto 1)) AND (fade & "11");
                else
                    R_n <= std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_ship) * 3) + 0))(7 downto 1)) AND (fade & "11");
                    G_n <= std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_ship) * 3) + 1))(7 downto 1)) AND (fade & "11");
                    B_n <= std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_ship) * 3) + 2))(7 downto 1)) AND (fade & "11");
                end if;
            end if;
        end if;
    end process;

    -- RGB out seq
    RGB_out : process(clk)
    begin
        if (rising_edge(clk)) then
            if (re = '1') then
                R_int <= R_n;
                G_int <= G_n;
                B_int <= B_n;
            end if;
        end if;
    end process;

    R <= R_int;
    G <= G_int;
    B <= B_int;

end RTL;
