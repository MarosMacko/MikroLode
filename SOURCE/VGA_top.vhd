library IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_top is
    Port(clk, rst            : in  std_logic;
         VGA_R, VGA_G, VGA_B : out std_logic_vector(6 downto 0);
         VGA_VS, VGA_HS      : out std_logic;
         RAM_address         : out STD_LOGIC_VECTOR(10 downto 0);
         RAM_data            : in  STD_LOGIC_VECTOR(10 downto 0)
        );
end VGA_top;

architecture Behavioral of VGA_top is

    component VGA_pixel_gen
        port(
            clk      : in  STD_LOGIC;
            pixel_x  : in  STD_LOGIC_VECTOR(10 downto 0);
            pixel_y  : in  STD_LOGIC_VECTOR(10 downto 0);
            video_on : in  STD_LOGIC;
            R, G, B  : out STD_LOGIC_VECTOR(6 downto 0)
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

    signal pixel_x    : STD_LOGIC_VECTOR(10 downto 0);
    signal pixel_y    : STD_LOGIC_VECTOR(10 downto 0);
    signal video_on   : STD_LOGIC;
    signal frame_tick : STD_LOGIC;
    signal line_tick  : STD_LOGIC;

begin

    pixel_gen : VGA_pixel_gen
        port map(
            clk      => clk,
            pixel_x  => pixel_x,
            pixel_y  => pixel_y,
            video_on => video_on,
            R        => VGA_R,
            G        => VGA_G,
            B        => VGA_B
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

end Behavioral;

