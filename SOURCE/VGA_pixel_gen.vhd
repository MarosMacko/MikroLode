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
    signal R_n, G_n, B_n            : STD_LOGIC_VECTOR(6 downto 0);
    signal sprite_x_fx, sprite_y_fx : STD_LOGIC_VECTOR(3 downto 0);

    -- Screen shake FX
    signal sprite_x_fx_n, sprite_y_fx_n           : STD_LOGIC_VECTOR(3 downto 0);
    signal shake_x, shake_x_n, shake_y, shake_y_n : STD_LOGIC_VECTOR(3 downto 0);
    signal shake_counter, shake_counter_n         : STD_LOGIC_VECTOR(4 downto 0);

    signal isHud, isHud_n : STD_LOGIC;

    -- RAM signals
    signal field_data_ready, field_data_ready_n   : STD_LOGIC;
    signal global_data_ready, global_data_ready_n : STD_LOGIC;
    signal RAM_ready, RAM_ready_n                 : STD_LOGIC;
    signal RAM_address_n, RAM_address_int         : STD_LOGIC_VECTOR(9 downto 0) := (others => '0');

    -- ROM signals
    signal ROM_addr_tile_n, ROM_addr_tile           : STD_LOGIC_VECTOR(13 downto 0);
    signal ROM_addr_hud_n, ROM_addr_hud             : STD_LOGIC_VECTOR(14 downto 0);
    signal palette_index_hud, palette_index_hud_n   : STD_LOGIC_VECTOR(3 downto 0);
    signal palette_index_tile, palette_index_tile_n : STD_LOGIC_VECTOR(3 downto 0);

    -- Internal counters to know where we are
    signal tile_x, tile_y         : STD_LOGIC_VECTOR(4 downto 0);
    signal tile_x_n, tile_y_n     : STD_LOGIC_VECTOR(4 downto 0);
    signal sprite_x, sprite_y     : STD_LOGIC_VECTOR(3 downto 0);
    signal sprite_x_n, sprite_y_n : STD_LOGIC_VECTOR(3 downto 0);

    component VGA_ROM is
        Port(clk, re     : in  STD_LOGIC;
             addr_tile   : in  STD_LOGIC_VECTOR(13 downto 0);
             addr_hud    : in  STD_LOGIC_VECTOR(14 downto 0);
             output_hud  : out STD_LOGIC_VECTOR(3 downto 0);
             output_tile : out STD_LOGIC_VECTOR(3 downto 0));
    end component;

    type ShakeSequence is array (0 to 31) of unsigned(3 downto 0);
    constant shake_x_seq : ShakeSequence := (x"D", x"6", x"5", x"2", x"2", x"A", x"A", x"D", x"A", x"C", x"7", x"8", x"1", x"1", x"F", x"E", x"0", x"1", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0");
    constant shake_y_seq : ShakeSequence := (x"4", x"B", x"4", x"C", x"8", x"B", x"C", x"9", x"D", x"D", x"8", x"7", x"2", x"C", x"3", x"0", x"1", x"F", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0", x"0");

    --signal R_int, G_int, B_int : STD_LOGIC_VECTOR(7 downto 0) := (others => '0');
    signal re : std_logic := '1';
    --type TileRom is array (0 to 4479) of unsigned(7 downto 0);
    type TilePaletteRom is array (0 to 47) of unsigned(7 downto 0);
    --type HudRom is array (0 to 15615) of unsigned(7 downto 0);
    type HudPaletteRom is array (0 to 47) of unsigned(7 downto 0);

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
        result.taken     := arg(13);
        result.grey_p1   := arg(12);
        result.ship      := arg(11);
        result.HUD       := arg(10);
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

    constant tiles_palette : TilePaletteRom := (
        x"59", x"62", x"de", x"70", x"96", x"e6", x"00", x"78", x"4a", x"00", x"46", x"2b", x"e3", x"e3", x"00", x"f3", x"92", x"41", x"a9", x"0c", x"00", x"e3", x"10", x"10", x"ea", x"ea", x"ea", x"cc", x"cc", x"cc", x"af", x"af", x"af", x"93", x"93", x"93", x"82", x"82", x"82", x"7b", x"7b", x"7b", x"71", x"71", x"71", x"61", x"61", x"61"
    );

    constant hud_palette : HudPaletteRom := (
        x"82", x"82", x"82",
        x"00", x"00", x"00",
        x"e3", x"10", x"10",
        x"92", x"92", x"92",
        x"64", x"6b", x"ff",
        x"61", x"61", x"61",
        x"00", x"00", x"90",
        x"51", x"51", x"d3",
        x"71", x"92", x"e3",
        x"ee", x"ea", x"00",
        x"e9", x"a1", x"30",
        x"b2", x"00", x"00",
        x"f3", x"f3", x"f3",
        x"b2", x"b2", x"b2",
        x"9a", x"9a", x"9a",
        x"8a", x"8a", x"8a"
    );

begin

    re <= '1';                          -- ROM read enable

    ROM : VGA_ROM
        port map(
            clk         => clk,
            re          => re,
            addr_tile   => ROM_addr_tile,
            addr_hud    => ROM_addr_hud,
            output_hud  => palette_index_hud_n,
            output_tile => palette_index_tile_n
        );

    RAM_address <= RAM_address_int;

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

    Tile_tracker_comb : process(frame_tick, line_tick, sprite_y, sprite_x, tile_x, tile_y, pixel_x(1 downto 0), pixel_y(1 downto 0))
    begin
        tile_x_n   <= tile_x;
        tile_y_n   <= tile_y;
        sprite_x_n <= sprite_x;
        sprite_y_n <= sprite_y;

        if (line_tick = '1') then
            -- Increment current sprite's y position
            -- Mod 4 (quadruple each pixel)
            if (pixel_y(1 downto 0) = "00") then
                sprite_y_n <= std_logic_vector(unsigned(sprite_y) + 1);
                if (sprite_y = x"F") then
                    -- Increment current tile position
                    tile_y_n <= std_logic_vector(unsigned(tile_y) + 1);
                end if;
            end if;

        end if;
        -- Reset at the end of frame
        if (frame_tick = '1') then
            sprite_y_n <= (others => '0');
        end if;

        -- Increment current sprite's x position
        -- Always mod 4 (quadruple each pixel)
        if (pixel_x(1 downto 0) = "00") then
            sprite_x_n <= std_logic_vector(unsigned(sprite_x) + 1);
            if (sprite_x = x"F") then
                -- Increment current tile position
                tile_x_n <= std_logic_vector(unsigned(tile_x) + 1);
            end if;
        end if;

        -- Reset at the end of line
        if (line_tick = '1') then
            sprite_x_n <= (others => '0');
        end if;

    end process;

    -- Screen modificators (Shake)
    Mods_seq : process(rst, clk)
    begin
        if (rst = '1') then
            sprite_y_fx   <= (others => '0');
            sprite_x_fx   <= (others => '0');
            shake_x       <= (others => '0');
            shake_y       <= (others => '0');
            shake_counter <= (others => '0');
        elsif (rising_edge(clk)) then
            sprite_y_fx   <= sprite_y_fx_n;
            sprite_x_fx   <= sprite_x_fx_n;
            shake_x       <= shake_x_n;
            shake_y       <= shake_y_n;
            shake_counter <= shake_counter_n;
        end if;
    end process;

    Mods_comb : process(shake_counter, shake_x, shake_y, frame_tick, RAM_data, sprite_x, sprite_y)
    begin
        shake_counter_n <= shake_counter;
        shake_x_n       <= shake_x;
        shake_y_n       <= shake_y;
        sprite_x_fx_n   <= std_logic_vector(signed(sprite_x) + resize(signed(shake_x), sprite_x'length));
        sprite_y_fx_n   <= std_logic_vector(signed(sprite_y) + resize(signed(shake_y), sprite_y'length));

        if (frame_tick = '1' and (unpack_global(RAM_data).shake = '1')) then
            -- start animation
            shake_counter_n <= "00001";
        else
            if (unsigned(shake_counter) > 0) then
                shake_counter_n <= std_logic_vector(unsigned(shake_counter) + 1);
                -- do animation
                shake_x_n       <= std_logic_vector(shake_x_seq(to_integer(unsigned(shake_counter) + 1)));
                shake_y_n       <= std_logic_vector(shake_y_seq(to_integer(unsigned(shake_counter) + 1)));
            end if;
            if (shake_counter = "11111") then
            end if;
        end if;
    end process;

    -- Get new sprite from RAM
    Sprite_seq : process(rst, clk)
    begin
        if (rst = '1') then
            global_data       <= ('0', '0', '0', '0');
            field_data        <= ('0', '0', '0', '0', '0', '0', '0', (others => '0')); -- :(
            global_data_ready <= '0';
            field_data_ready  <= '0';
            RAM_address_int   <= (others => '0');
            RAM_ready         <= '0';
            isHud             <= '0';
        elsif (rising_edge(clk)) then
            global_data       <= global_data_n;
            field_data        <= field_data_n;
            global_data_ready <= global_data_ready_n;
            field_data_ready  <= field_data_ready_n;
            RAM_address_int   <= RAM_address_n;
            RAM_ready         <= RAM_ready_n;
            isHud             <= isHud_n;
        end if;
    end process;

    Sprite_comb : process(frame_tick, line_tick, RAM_data, field_data, global_data, global_data_ready, field_data_ready, RAM_address_int, RAM_ready, isHud, tile_x, tile_y, sprite_x)
    begin
        global_data_n       <= global_data;
        field_data_n        <= field_data;
        global_data_ready_n <= global_data_ready;
        field_data_ready_n  <= field_data_ready;
        RAM_address_n       <= RAM_address_int;
        isHud_n             <= isHud;
        RAM_ready_n         <= RAM_ready;

        -- data will be ready on the next clock
        if (((global_data_ready = '1') or (global_data_ready = '1')) and (RAM_ready = '0')) then
            RAM_ready_n <= '1';
        end if;

        -- global data read
        if ((global_data_ready = '1') and (RAM_ready = '1')) then
            global_data_n       <= unpack_global(RAM_data);
            global_data_ready_n <= '0';
            RAM_ready_n         <= '0';
        end if;

        -- field data read
        if ((field_data_ready = '1') and (RAM_ready = '1')) then
            field_data_n       <= unpack_field(RAM_data);
            field_data_ready_n <= '0';
            RAM_ready_n        <= '0';
            isHud_n            <= unpack_field(RAM_data).HUD;
        end if;

        -- ask for new field (sprite) data
        if ((line_tick = '1') or (sprite_x = x"F")) then --Maybe edit dis
            RAM_address_n      <= std_logic_vector(unsigned(tile_x) + (unsigned(tile_y) * 20));
            field_data_ready_n <= '1';
            RAM_ready_n        <= '0';
        end if;

        -- ask for new global data
        -- higher priority than line tick
        if (frame_tick = '1') then
            RAM_address_n       <= "0101000000"; -- 320
            global_data_ready_n <= '1';
            RAM_ready_n         <= '0';
        end if;
    end process;

    -- ROM
    ROM_seq : process(rst, clk)
    begin
        if (rst = '1') then
            ROM_addr_tile      <= (others => '0');
            ROM_addr_hud       <= (others => '0');
            palette_index_hud  <= (others => '0');
            palette_index_tile <= (others => '0');
        elsif (rising_edge(clk)) then
            ROM_addr_tile      <= ROM_addr_tile_n;
            ROM_addr_hud       <= ROM_addr_hud_n;
            palette_index_hud  <= palette_index_hud_n;
            palette_index_tile <= palette_index_tile_n;
        end if;
    end process;

    ROM_comb : process(field_data.tile_data, sprite_x_fx, sprite_y_fx)
    begin
        --palette_index_tile_n <= palette_index_tile; <-- directly from ROM
        --palette_index_hud_n  <= palette_index_hud;  <-- directly from ROM

        -- Assemble the sprite vector (identical to tile*16*16 + y*16 + x)
        ROM_addr_tile_n <= field_data.tile_data(5 downto 0) & sprite_y_fx & sprite_x_fx;
        ROM_addr_hud_n  <= field_data.tile_data(6 downto 0) & sprite_y_fx & sprite_x_fx;

    end process;

    -- RGB out
    RGB_out : process(clk)
    begin
        if (rising_edge(clk)) then
            if (re = '1') then
                R <= R_n;
                G <= G_n;
                B <= B_n;
            end if;
        end if;
    end process;

    -- Color preparation
    RGB_prep : process(isHud, palette_index_hud, palette_index_tile)
    begin
        if (isHud = '1') then
            --(3 downto 0) == mod 16
            R_n <= std_logic_vector(resize(hud_palette(to_integer(unsigned(palette_index_hud) * 3 + 0)), 7));
            G_n <= std_logic_vector(resize(hud_palette(to_integer(unsigned(palette_index_hud) * 3 + 1)), 7));
            B_n <= std_logic_vector(resize(hud_palette(to_integer(unsigned(palette_index_hud) * 3 + 2)), 7));
        else
            --(3 downto 0) == mod 16
            R_n <= std_logic_vector(resize(tiles_palette(to_integer(unsigned(palette_index_tile) * 3 + 0)), 7));
            G_n <= std_logic_vector(resize(tiles_palette(to_integer(unsigned(palette_index_tile) * 3 + 1)), 7));
            B_n <= std_logic_vector(resize(tiles_palette(to_integer(unsigned(palette_index_tile) * 3 + 2)), 7));
        end if;
    end process;

end RTL;

