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

architecture Behavioral of TOP is

    type game_state_enum is (init, start, placement, wait4player, local_turn, remote_turn, lost, won);
    signal game_state : game_state_enum := init;

    -- PS/2 signals
    signal mouse_x                      : STD_LOGIC_VECTOR(10 downto 0);
    signal mouse_y                      : STD_LOGIC_VECTOR(9 downto 0);
    signal button_l, button_r, button_m : STD_LOGIC;
    signal ps2_newdata_flag             : STD_LOGIC;

    -- Multi-player logic signals
    signal data_mp_out    : STD_LOGIC_VECTOR(8 downto 0);
    signal data_mp_out_en : STD_LOGIC;
    signal data_mp_in     : STD_LOGIC_VECTOR(8 downto 0);
    signal data_mp_in_en  : STD_LOGIC;

    -- Sound unit signals
    signal sound_play : STD_LOGIC_VECTOR(1 downto 0);

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
    component RAM_2port is
        port(
            clk_GL, clk_VGA : in  STD_LOGIC;
            we              : in  STD_LOGIC;
            addr_GL         : in  STD_LOGIC_VECTOR(10 downto 0);
            addr_VGA        : in  STD_LOGIC_VECTOR(10 downto 0);
            data_in         : in  STD_LOGIC_VECTOR(8 downto 0);
            data_out_GL     : out STD_LOGIC_VECTOR(8 downto 0);
            data_out_VGA    : out STD_LOGIC_VECTOR(8 downto 0)
        );
    end component;

    signal gameRAM_we                                                 : STD_LOGIC;
    signal gameRAM_addr_GL, gameRAM_addr_VGA                          : STD_LOGIC_VECTOR(10 downto 0);
    signal gameRAM_data_in, gameRAM_data_out_GL, gameRAM_data_out_VGA : STD_LOGIC_VECTOR(8 downto 0);

    --======================================================
    --                  TOP COMPONENTS                                   
    --======================================================

    -- PS2 component 

    -- UART / MultiPlayer component

    -- VGA component
    component VGA_top
        port(
            clk, rst            : in  std_logic;
            mouse_x_in          : in  STD_LOGIC_VECTOR(10 downto 0);
            mouse_y_in          : in  STD_LOGIC_VECTOR(9 downto 0);
            VGA_R, VGA_G, VGA_B : out std_logic_vector(6 downto 0);
            VGA_VS, VGA_HS      : out std_logic;
            RAM_address         : out STD_LOGIC_VECTOR(10 downto 0);
            RAM_data            : in  STD_LOGIC_VECTOR(8 downto 0)
        );
    end component VGA_top;

    -- Sound component

    -- Game logic component

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
            U1_CLKIN_IBUFG_OUT => open,
            U1_CLK2X_OUT       => open,
            U1_STATUS_OUT      => open,
            U2_CLKFX_OUT       => clk_vga,
            U2_CLK0_OUT        => open,
            U2_LOCKED_OUT      => open,
            U2_STATUS_OUT      => open
        );

    two_port_RAM : RAM_2port
        port map(
            clk_GL       => clk,
            clk_VGA      => clk_vga,
            we           => gameRAM_we,
            addr_GL      => gameRAM_addr_GL,
            addr_VGA     => gameRAM_addr_VGA,
            data_in      => gameRAM_data_in,
            data_out_GL  => gameRAM_data_out_GL,
            data_out_VGA => gameRAM_data_out_VGA
        );

    -- PS2 component
    -- port map here

    -- UART / MultiPlayer component
    -- port map here

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
    -- port map here

    -- Game logic component
    -- port map here

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
            clk           => clk,
            rst           => rst,
            random_output => open
        );

    -- Temp, till component will be ready
    mouse_x(10 downto 8) <= (others => '0');
    mouse_y(9 downto 8)  <= (others => '0');
    mouse_x(7 downto 0)  <= buttons;
    mouse_y(7 downto 0)  <= buttons;
    audio_out            <= (others => '0');
    uart_tx              <= '0';
    buzzer               <= '0';

end Behavioral;

