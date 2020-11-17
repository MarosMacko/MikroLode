----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

entity TOP is
    Port(clk, rst_button     : in    STD_LOGIC;
         ps2_clock_pin       : inout STD_LOGIC;
         ps2_data_pin        : inout STD_LOGIC;
         uart_tx             : out   STD_LOGIC;
         uart_rx             : in    STD_LOGIC;
         vga_R, vga_G, vga_B : out   STD_LOGIC_VECTOR(6 downto 0);
         vga_VS, vga_HS      : out   STD_LOGIC;
         audio_out           : out   STD_LOGIC_VECTOR(7 downto 0);
         buttons             : in    STD_LOGIC_VECTOR(7 downto 0);
         buzzer              : out   STD_LOGIC);
end TOP;

architecture TOP of TOP is

    signal clk_buf : std_logic;

    -- PS/2 signals
    signal mouse_x                      : STD_LOGIC_VECTOR(10 downto 0);
    signal mouse_y                      : STD_LOGIC_VECTOR(9 downto 0);
    signal button_l, button_r, button_m : STD_LOGIC;
    signal scroll_up, scroll_down       : STD_LOGIC;

    -- UART signals and constants
    constant clk_f       : integer := 50_000_000;
    constant baud_rate   : integer := 115_200;
    constant os_rate     : integer := 16;
    constant data_width  : integer := 8;
    signal tx_data       : std_logic_vector(data_width - 1 downto 0);
    signal tx_send_CE    : std_logic;
    signal tx_busy       : std_logic;
    signal rx_data       : std_logic_vector(data_width - 1 downto 0);
    signal rx_receive_CE : std_logic;

    -- Multi-Player logic signals
    signal turn               : std_logic;
    signal game_type_want     : std_logic;
    signal game_type_real     : std_logic;
    signal miss_in            : std_logic;
    signal hit_in             : std_logic;
    signal miss_out           : std_logic;
    signal hit_out            : std_logic;
    signal shoot_position_out : std_logic_vector(8 downto 0);
    signal shoot_position_in  : std_logic_vector(8 downto 0);

    -- Sound unit signals
    signal sound_type : STD_LOGIC_VECTOR(1 downto 0);

    -- Game_logic signals

    -- VGA clock
    signal clk_vga : STD_LOGIC;

    --======================================================
    --             108MHz VGA clock generator                                 
    --======================================================
    component VGA_clock_gen is
        port(U1_CLKIN_IN        : in  std_logic;
             U1_RST_IN          : in  std_logic;
             U1_CLKIN_IBUFG_OUT : out std_logic;
             U1_CLK2X_OUT       : out std_logic;
             U1_STATUS_OUT      : out std_logic_vector(7 downto 0);
             U2_CLKFX_OUT       : out std_logic;
             U2_CLK0_OUT        : out std_logic;
             U2_LOCKED_OUT      : out std_logic;
             U2_STATUS_OUT      : out std_logic_vector(7 downto 0)
            );
    end component;

    --======================================================
    --        2 port RAM between game logic and VGA                               
    --======================================================
    component RAM_2port
        port(
            clk_GL, clk_VGA : in  STD_LOGIC;
            we_GL           : in  STD_LOGIC;
            addr_GL         : in  STD_LOGIC_VECTOR(9 downto 0);
            addr_VGA        : in  STD_LOGIC_VECTOR(9 downto 0);
            data_in_GL      : in  STD_LOGIC_VECTOR(17 downto 0);
            data_out_GL     : out STD_LOGIC_VECTOR(17 downto 0);
            data_out_VGA    : out STD_LOGIC_VECTOR(17 downto 0)
        );
    end component RAM_2port;

    signal gameRAM_we                                                 : STD_LOGIC;
    signal gameRAM_addr_GL, gameRAM_addr_VGA                          : STD_LOGIC_VECTOR(9 downto 0);
    signal gameRAM_data_in, gameRAM_data_out_GL, gameRAM_data_out_VGA : STD_LOGIC_VECTOR(17 downto 0);

    --======================================================
    --                  TOP COMPONENTS                                   
    --======================================================

    -- PS2 component 
    component MOUSE_top is
        port(
            ps2_clock_pin : inout STD_LOGIC;
            ps2_data_pin  : inout STD_LOGIC;
            clk, rst      : in    STD_LOGIC;
            position_x    : out   STD_LOGIC_VECTOR(10 downto 0);
            position_y    : out   STD_LOGIC_VECTOR(9 downto 0);
            button_l      : out   STD_LOGIC;
            button_r      : out   STD_LOGIC;
            scroll_up     : out   STD_LOGIC;
            scroll_down   : out   STD_LOGIC);
    end component MOUSE_top;

    -- UART component
    component UART_top
        generic(
            clk_f      : integer;
            baud_rate  : integer;
            os_rate    : integer;
            data_width : integer
        );
        port(
            clk, rst      : in  std_logic;
            tx_data       : in  std_logic_vector(data_width - 1 downto 0);
            tx_send_CE    : in  std_logic;
            tx_busy       : out std_logic;
            rx_data       : out std_logic_vector(data_width - 1 downto 0);
            rx_receive_CE : out std_logic;
            RxD           : in  std_logic;
            TxD           : out std_logic
        );
    end component UART_top;

    -- MultiPlayer component 
    component MultiPlayer_top
        generic(data_width : integer);
        port(
            clk, rst           : in  std_logic;
            tx_data            : out std_logic_vector(data_width - 1 downto 0);
            tx_send_CE         : out std_logic;
            tx_busy            : in  std_logic;
            rx_data            : in  std_logic_vector(data_width - 1 downto 0);
            rx_receive_CE      : in  std_logic;
            turn               : out std_logic;
            game_type_want     : in  std_logic;
            game_type_real     : out std_logic;
            miss_in            : out std_logic;
            hit_in             : out std_logic;
            miss_out           : in  std_logic;
            hit_out            : in  std_logic;
            shoot_position_out : in  std_logic_vector(8 downto 0);
            shoot_position_in  : out std_logic_vector(8 downto 0)
        );
    end component MultiPlayer_top;

    -- VGA component
    component VGA_top
        port(
            clk, rst            : in  std_logic;
            mouse_x_in          : in  STD_LOGIC_VECTOR(10 downto 0);
            mouse_y_in          : in  STD_LOGIC_VECTOR(9 downto 0);
            VGA_R, VGA_G, VGA_B : out std_logic_vector(6 downto 0);
            VGA_VS, VGA_HS      : out std_logic;
            RAM_address         : out STD_LOGIC_VECTOR(9 downto 0);
            RAM_data            : in  STD_LOGIC_VECTOR(17 downto 0)
        );
    end component VGA_top;

    -- Sound component
    component Audio_top
        port(clk, rst   : in  STD_LOGIC;
             sound_type : in  STD_LOGIC_VECTOR(1 downto 0);
             audio_out  : out STD_LOGIC_VECTOR(7 downto 0)
            );
    end component Audio_top;

    -- Game logic component

    component Game_logic_top
        port(
            pos_x                                            : in  STD_LOGIC_VECTOR(10 downto 0);
            pos_y                                            : in  STD_LOGIC_VECTOR(9 downto 0);
            button_r_ce, button_l_ce, scroll_up, scroll_down : in  STD_LOGIC;
            clk                                              : in  STD_LOGIC;
            rst                                              : in  STD_LOGIC;
            turn                                             : in  STD_LOGIC;
            miss_in, hit_in                                  : in  STD_LOGIC;
            game_type_real                                   : in  STD_LOGIC;
            shoot_position_in                                : in  STD_LOGIC_VECTOR(8 downto 0);
            shoot_position_out                               : out STD_LOGIC_VECTOR(8 downto 0);
            hit_out, miss_out                                : out STD_LOGIC;
            game_type_want                                   : out STD_LOGIC;
            data_read_ram                                    : in  STD_LOGIC_VECTOR(17 downto 0);
            data_write_ram                                   : out STD_LOGIC_VECTOR(17 downto 0);
            we_A                                             : out STD_LOGIC;
            addr_A                                           : out STD_LOGIC_VECTOR(9 downto 0)
        );
    end component Game_logic_top;

    -- Internal reset logic
    signal rst_int, rst : STD_LOGIC := '0';

    -- Misc
    component MISC_prng
        port(
            clk, rst      : in  STD_LOGIC;
            random_output : out STD_LOGIC_VECTOR(31 downto 0)
        );
    end component MISC_prng;

begin

    -- 2xDCM VGA clock gen (50MHz to 108MHz)
    VGA_clock : VGA_clock_gen
        port map(
            U1_CLKIN_IN        => clk,
            U1_RST_IN          => '0',
            U1_CLKIN_IBUFG_OUT => clk_buf,
            U1_CLK2X_OUT       => open,
            U1_STATUS_OUT      => open,
            U2_CLKFX_OUT       => clk_vga,
            U2_CLK0_OUT        => open,
            U2_LOCKED_OUT      => open,
            U2_STATUS_OUT      => open
        );

    two_port_RAM : RAM_2port
        port map(
            clk_GL       => clk_buf,
            clk_VGA      => clk_vga,
            we_GL        => gameRAM_we,
            addr_GL      => gameRAM_addr_GL,
            addr_VGA     => gameRAM_addr_VGA,
            data_in_GL   => gameRAM_data_in,
            data_out_GL  => gameRAM_data_out_GL,
            data_out_VGA => gameRAM_data_out_VGA
        );

    -- PS2 component
    MOUSE_module : MOUSE_top
        port map(
            ps2_clock_pin => ps2_clock_pin,
            ps2_data_pin  => ps2_data_pin,
            clk           => clk_buf,
            rst           => rst_button,
            position_x    => mouse_x,
            position_y    => mouse_y,
            button_l      => button_l,
            button_r      => button_r,
            scroll_up     => scroll_up,
            scroll_down   => scroll_down
        );

    -- UART component 
    UART_module : UART_top
        generic map(
            clk_f      => clk_f,
            baud_rate  => baud_rate,
            os_rate    => os_rate,
            data_width => data_width
        )
        port map(
            clk           => clk_buf,
            rst           => rst,
            tx_data       => tx_data,
            tx_send_CE    => tx_send_CE,
            tx_busy       => tx_busy,
            rx_data       => rx_data,
            rx_receive_CE => rx_receive_CE,
            RxD           => uart_rx,
            TxD           => uart_tx
        );

    -- MultiPlayer component
    MultiPlayer_module : MultiPlayer_top
        generic map(
            data_width => data_width
        )
        port map(
            clk                => clk_buf,
            rst                => rst,
            tx_data            => tx_data,
            tx_send_CE         => tx_send_CE,
            tx_busy            => tx_busy,
            rx_data            => rx_data,
            rx_receive_CE      => rx_receive_CE,
            turn               => turn,
            game_type_want     => game_type_want,
            game_type_real     => game_type_real,
            miss_in            => miss_in,
            hit_in             => hit_in,
            miss_out           => miss_out,
            hit_out            => hit_out,
            shoot_position_out => shoot_position_out,
            shoot_position_in  => shoot_position_in
        );

    -- VGA component
    VGA_module : VGA_top
        port map(
            clk         => clk_vga,
            rst         => rst,
            mouse_x_in  => mouse_x,
            mouse_y_in  => mouse_y,
            VGA_R       => vga_R,
            VGA_G       => vga_G,
            VGA_B       => vga_B,
            VGA_VS      => vga_VS,
            VGA_HS      => vga_HS,
            RAM_address => gameRAM_addr_VGA,
            RAM_data    => gameRAM_data_out_VGA
        );

    -- Sound component
    Audio_module : Audio_top
        port map(
            clk        => clk_buf,
            rst        => rst,
            sound_type => sound_type,
            audio_out  => audio_out
        );

    -- Game logic component
    Game_logic_module : Game_logic_top
        port map(
            pos_x              => mouse_x,
            pos_y              => mouse_y,
            button_r_ce        => button_r,
            button_l_ce        => button_l,
            scroll_up          => scroll_up,
            scroll_down        => scroll_down,
            clk                => clk_buf,
            rst                => rst,
            turn               => turn,
            miss_in            => miss_in,
            hit_in             => hit_in,
            game_type_real     => game_type_real,
            shoot_position_in  => shoot_position_in,
            shoot_position_out => shoot_position_out,
            hit_out            => hit_out,
            miss_out           => miss_out,
            game_type_want     => game_type_want,
            data_read_ram      => gameRAM_data_out_GL,
            data_write_ram     => gameRAM_data_in,
            we_A               => gameRAM_we,
            addr_A             => gameRAM_addr_GL
        );

    -- Internal RST logic
    process(rst_button, rst_int)
    begin
        if (rst_button = '1') or (rst_int = '1') then
            -- TODO: Hold RST for few cycles, then release it!
            rst <= '1';
        else
            rst <= '0';
        end if;
    end process;

    -- Misc
    PRNG : MISC_prng
        port map(
            clk           => clk_buf,
            rst           => rst,
            random_output => open
        );

    -- Temp, till component will be ready
    buzzer <= '0';

end TOP;

