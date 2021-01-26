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
    signal R_n, G_n, B_n       : STD_LOGIC_VECTOR(6 downto 0);
    signal R_int, G_int, B_int : STD_LOGIC_VECTOR(6 downto 0);

    -- Screen shake FX
    signal pixel_x_fx, pixel_y_fx                 : STD_LOGIC_VECTOR(10 downto 0);
    signal pixel_x_fx_n, pixel_y_fx_n             : STD_LOGIC_VECTOR(10 downto 0);
    signal shake_x, shake_x_n, shake_y, shake_y_n : STD_LOGIC_VECTOR(3 downto 0);
    signal shake_counter, shake_counter_n         : STD_LOGIC_VECTOR(4 downto 0);

    signal isHud, isHud_n : STD_LOGIC;

    -- RAM signals
    signal ram_clk                                : STD_LOGIC;
    signal field_data_ready, field_data_ready_n   : STD_LOGIC;
    signal global_data_ready, global_data_ready_n : STD_LOGIC;
    signal RAM_address_int_n, RAM_address_int     : STD_LOGIC_VECTOR(9 downto 0) := (others => '0');
    signal RAM_data_buf                           : STD_LOGIC_VECTOR(17 downto 0);

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

    signal re : std_logic := '1';
    type TilePaletteRom is array (0 to 47) of unsigned(7 downto 0);
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

    constant RAM_DELAY : unsigned := x"2";

    signal RAM_ready_delay, RAM_ready_delay_n : STD_LOGIC_VECTOR(1 downto 0);

begin

    re <= '1';                          -- ROM read enable
    --ram_clk <= clk;                   -- Make the RAM responding to the falling edge, so data is always ready

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

    Tile_tracker_comb : process(sprite_y, sprite_x, tile_x, tile_y, pixel_x, pixel_y, frame_tick, line_tick)
    begin
        tile_x_n   <= tile_x;
        tile_y_n   <= tile_y;
        sprite_x_n <= sprite_x;
        sprite_y_n <= sprite_y;

        if (pixel_x(5 downto 2) = "0000") then
            tile_x_n <= std_logic_vector(unsigned(tile_x) + 1);
        end if;

        if (pixel_y(5 downto 2) = "0000") then
            tile_y_n <= std_logic_vector(unsigned(tile_y) + 1);
        end if;

        -- 
        sprite_x_n <= std_logic_vector(unsigned(pixel_x(5 downto 2)));
        sprite_y_n <= std_logic_vector(unsigned(pixel_y(5 downto 2)));

        -- Reset
        if (frame_tick = '1') then
            tile_x_n <= (others => '0');
            tile_y_n <= (others => '0');
        end if;

        -- Reset
        if (line_tick = '1') then
            tile_x_n   <= (others => '0');
            sprite_x_n <= (others => '0');
            sprite_y_n <= (others => '0');
        end if;

    end process;

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
            RAM_ready_delay   <= (others => '0');
            RAM_data_buf      <= (others => '0');
        elsif (rising_edge(clk)) then
            RAM_data_buf      <= RAM_data;
            global_data       <= global_data_n;
            field_data        <= field_data_n;
            global_data_ready <= global_data_ready_n;
            field_data_ready  <= field_data_ready_n;
            RAM_address_int   <= RAM_address_int_n;
            isHud             <= isHud_n;
            RAM_ready_delay   <= RAM_ready_delay_n;
        end if;
    end process;

    RAM_comb : process(frame_tick, RAM_data_buf, field_data, global_data, global_data_ready, field_data_ready, RAM_address_int, isHud, tile_x, tile_y, sprite_x, RAM_ready_delay, RAM_ready_delay_n)
    begin
        global_data_n       <= global_data;
        field_data_n        <= field_data;
        global_data_ready_n <= global_data_ready;
        field_data_ready_n  <= field_data_ready;
        RAM_address_int_n   <= RAM_address_int;
        isHud_n             <= isHud;
        RAM_ready_delay_n   <= RAM_ready_delay;

        -- field data read
        if (field_data_ready = '1') then
            RAM_ready_delay_n <= std_logic_vector(unsigned(RAM_ready_delay_n) + 1);
            if (unsigned(RAM_ready_delay) = RAM_DELAY) then
                -- reset the flag
                field_data_ready_n <= '0';
                RAM_ready_delay_n  <= (others => '0');
                -- update field data
                field_data_n       <= unpack_field(RAM_data_buf);
                isHud_n            <= unpack_field(RAM_data_buf).HUD;
            end if;
        end if;

        -- global data read
        if (global_data_ready = '1') then
            RAM_ready_delay_n <= std_logic_vector(unsigned(RAM_ready_delay_n) + 1);
            if (unsigned(RAM_ready_delay) = RAM_DELAY) then
                -- reset the flag
                global_data_ready_n <= '0';
                RAM_ready_delay_n   <= (others => '0');
                -- update global data
                global_data_n       <= unpack_global(RAM_data_buf);
            end if;
        end if;

        -- ask for new field (sprite) data
        if (unsigned(sprite_x) = x"F" - RAM_DELAY) then --Maybe edit dis
            RAM_address_int_n  <= std_logic_vector((unsigned(tile_y) * 20) + unsigned(tile_x));
            -- rise the field flag
            field_data_ready_n <= '1';
        end if;

        -- ask for new global data
        -- higher priority than line tick
        if (frame_tick = '1') then
            RAM_address_int_n   <= std_logic_vector(to_unsigned(320, RAM_address_int_n'length));
            --rise the global flag and cancel field flag
            global_data_ready_n <= '1';
            field_data_ready_n  <= '0';
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

    ROM_comb : process(field_data.tile_data, sprite_x, sprite_y)
    begin
        --palette_index_tile_n <= palette_index_tile; <-- directly from ROM
        --palette_index_hud_n  <= palette_index_hud;  <-- directly from ROM

        -- Assemble the sprite vector (identical to sprite*16*16 + y*16 + x)
        ROM_addr_tile_n <= field_data.tile_data(5 downto 0) & sprite_y & sprite_x;
        ROM_addr_hud_n  <= field_data.tile_data(6 downto 0) & sprite_y & sprite_x;

    end process;

    -- RGB out
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

    -- Color preparation
    RGB_prep : process(isHud, palette_index_hud, palette_index_tile) --, palette_index_tile)
    begin
        if (isHud = '1') then
            --(3 downto 0) == mod 16
            R_n <= std_logic_vector(hud_palette(to_integer((unsigned(palette_index_hud) * 3) + 0)));
            G_n <= std_logic_vector(hud_palette(to_integer((unsigned(palette_index_hud) * 3) + 0)));
            B_n <= std_logic_vector(hud_palette(to_integer((unsigned(palette_index_hud) * 3) + 0)));
        else
            --(3 downto 0) == mod 16
            R_n <= std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_tile) * 3) + 0)));
            G_n <= std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_tile) * 3) + 1)));
            B_n <= std_logic_vector(tiles_palette(to_integer((unsigned(palette_index_tile) * 3) + 2)));
        end if;
    end process;

    R <= R_int;
    G <= G_int;
    B <= B_int;

end RTL;
