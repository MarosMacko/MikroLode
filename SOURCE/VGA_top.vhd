library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_top is
    Port(clk, rst            : in  std_logic;
         mouse_x_in          :     STD_LOGIC_VECTOR(10 downto 0);
         mouse_y_in          :     STD_LOGIC_VECTOR(9 downto 0);
         VGA_R, VGA_G, VGA_B : out std_logic_vector(6 downto 0);
         VGA_VS, VGA_HS      : out std_logic;
         RAM_address         : out STD_LOGIC_VECTOR(9 downto 0);
         RAM_data            : in  STD_LOGIC_VECTOR(17 downto 0)
        );
end VGA_top;

architecture TOP of VGA_top is

    component VGA_pixel_gen
        port(
            clk         : in  STD_LOGIC;
            pixel_x     : in  STD_LOGIC_VECTOR(10 downto 0);
            pixel_y     : in  STD_LOGIC_VECTOR(10 downto 0);
            frame_tick  : in  STD_LOGIC;
            RAM_address : out STD_LOGIC_VECTOR(9 downto 0);
            RAM_data    : in  STD_LOGIC_VECTOR(17 downto 0);
            R, G, B     : out STD_LOGIC_VECTOR(6 downto 0)
        );
    end component VGA_pixel_gen;

    component VGA_sync
        port(
            clk, rst              : in  STD_LOGIC;
            pixel_x, pixel_y      : out STD_LOGIC_VECTOR(10 downto 0);
            video_on              : out STD_LOGIC;
            hsync, vsync          : out STD_LOGIC;
            frame_tick, line_tick : out STD_LOGIC
        );
    end component VGA_sync;

    component VGA_cursor_gen
        port(
            clk, rst   : in  STD_LOGIC;
            pixel_x    : in  STD_LOGIC_VECTOR(10 downto 0);
            pixel_y    : in  STD_LOGIC_VECTOR(10 downto 0);
            mouse_x    : in  STD_LOGIC_VECTOR(10 downto 0);
            mouse_y    : in  STD_LOGIC_VECTOR(9 downto 0);
            frame_tick : in  STD_LOGIC;
            R, G, B    : out STD_LOGIC_VECTOR(6 downto 0);
            cursorOn   : out STD_LOGIC
        );
    end component VGA_cursor_gen;

    signal pixel_x    : STD_LOGIC_VECTOR(10 downto 0);
    signal pixel_y    : STD_LOGIC_VECTOR(10 downto 0);
    signal video_on   : STD_LOGIC;
    signal frame_tick : STD_LOGIC;
    signal line_tick  : STD_LOGIC;

    signal mouse_x_meta, mouse_x_sync : STD_LOGIC_VECTOR(10 downto 0);
    signal mouse_y_meta, mouse_y_sync : STD_LOGIC_VECTOR(9 downto 0);

    attribute keep : boolean;
    attribute keep of mouse_x_meta : signal is true;
    attribute keep of mouse_y_meta : signal is true;
    attribute keep of mouse_x_sync : signal is true;
    attribute keep of mouse_y_sync : signal is true;

    signal cursor_R, cursor_G, cursor_B : STD_LOGIC_VECTOR(6 downto 0);
    signal pixel_R, pixel_G, pixel_B    : STD_LOGIC_VECTOR(6 downto 0);

    signal cursor_on, HUD_on : STD_LOGIC;

begin

    -- Clock domain change (50MHz to VGA's 108MHz)
    process(clk)
    begin
        if (rising_edge(clk)) then
            mouse_x_meta <= mouse_x_in;
            mouse_x_sync <= mouse_x_meta;
            mouse_y_meta <= mouse_y_in;
            mouse_y_sync <= mouse_y_meta;
        end if;
    end process;

    pixel_gen : VGA_pixel_gen
        port map(
            clk         => clk,
            pixel_x     => pixel_x,
            pixel_y     => pixel_y,
            frame_tick  => frame_tick,
            RAM_address => RAM_address,
            RAM_data    => RAM_data,
            R           => pixel_R,
            G           => pixel_G,
            B           => pixel_B
        );

    cursor_gen : VGA_cursor_gen
        port map(
            clk        => clk,
            rst        => rst,
            pixel_x    => pixel_x,
            pixel_y    => pixel_y,
            mouse_x    => mouse_x_sync,
            mouse_y    => mouse_y_sync,
            frame_tick => frame_tick,
            R          => cursor_R,
            G          => cursor_G,
            B          => cursor_B,
            cursorOn   => cursor_on
        );

    vga_sync_module : VGA_sync
        port map(
            clk        => clk,
            rst        => rst,
            pixel_x    => pixel_x,
            pixel_y    => pixel_y,
            video_on   => video_on,
            hsync      => VGA_HS,
            vsync      => VGA_VS,
            frame_tick => frame_tick,
            line_tick  => line_tick
        );

    process(cursor_on, video_on, cursor_B, cursor_G, cursor_R, pixel_B, pixel_G, pixel_R, HUD_on)
    begin
        if cursor_on = '1' then
            VGA_R <= cursor_R;
            VGA_G <= cursor_G;
            VGA_B <= cursor_B;
        elsif HUD_on = '1' then
            VGA_R <= cursor_R;
            VGA_G <= cursor_G;
            VGA_B <= cursor_B;
        elsif video_on = '1' then
            VGA_R <= pixel_R;
            VGA_G <= pixel_G;
            VGA_B <= pixel_B;
        else
            VGA_R <= (others => '0');
            VGA_G <= (others => '0');
            VGA_B <= (others => '0');
        end if;
    end process;

end TOP;

