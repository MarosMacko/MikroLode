library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity MOUSE_top is
    Port(ps2_clock_pin : inout STD_LOGIC;
         ps2_data_pin  : inout STD_LOGIC;
         clk, rst      : in    STD_LOGIC;
         position_x    : out   STD_LOGIC_VECTOR(10 downto 0);
         position_y    : out   STD_LOGIC_VECTOR(9 downto 0);
         button_l      : out   STD_LOGIC;
         button_r      : out   STD_LOGIC;
         scroll_up     : out   STD_LOGIC;
         scroll_down   : out   STD_LOGIC);
end MOUSE_top;

architecture Behavioral of MOUSE_top is
    --iobuf signaly
    signal IN_SIG_cl, OUT_SIG_cl, T_ENABLE_cl    : std_logic;
    signal IN_SIG_dat, OUT_SIG_dat, T_ENABLE_dat : std_logic;

    --pomocne signaly
    signal ps2c_deb     : std_logic;    --vystup z debouncra pre ps2c
    signal ps2c_fall    : std_logic;    --detekovana sestupna hrana
    signal rx_en        : std_logic;    --enable pre citanie
    signal rx_done_en   : std_logic;    --uspesne nacitanie dat z mouse
    signal tx_en        : std_logic;    --enable pre zapis
    signal tx_done_en   : std_logic;    --uspesne odoslanie to mouse
    signal num_to_mouse : std_logic_vector(7 downto 0); -- znak posielany do mouse
    signal rx_data      : std_logic_vector(7 downto 0); -- precitane data z mouse

    component IOBUF
        port(I, T : in    std_logic;
             O    : out   std_logic;
             IO   : inout std_logic);
    end component;

    component debouncer is
        port(clk, ps2c : in  STD_LOGIC;
             ps2c_deb  : out STD_LOGIC);
    end component;

    component detec_falling_endge is
        port(ps2c_deb, clk, rst : in  STD_LOGIC;
             ps2c_fall          : out STD_LOGIC);
    end component;

    component ps2_tx is
        port(ps2c_fall, ps2d_out : in  STD_LOGIC;
             clk, rst            : in  STD_LOGIC;
             num_to_mouse        : in  std_logic_vector(7 downto 0);
             tx_en               : in  STD_LOGIC;
             ps2c_t_en, ps2c_in  : out STD_LOGIC;
             ps2d_t_en, ps2d_in  : out STD_LOGIC;
             tx_done_en          : out STD_LOGIC);
    end component;

    component ps2_rx is
        port(clk, rst        : in  STD_LOGIC;
             ps2d, ps2c_fall : in  STD_LOGIC;
             rx_en           : in  STD_LOGIC;
             rx_done_en      : out STD_LOGIC;
             ps2d_data       : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

    component state_log_m is
        Port(clk, rst                     : in  STD_LOGIC;
             tx_done_en, rx_done_en       : in  STD_LOGIC;
             rx_data                      : in  STD_LOGIC_VECTOR(7 downto 0);
             tx_en, rx_en                 : out STD_LOGIC;
             num_to_mouse                 : out STD_LOGIC_VECTOR(7 downto 0);
             button_l, button_r, button_m : out STD_LOGIC;
             position_x                   : out STD_LOGIC_VECTOR(10 downto 0);
             position_y                   : out STD_LOGIC_VECTOR(9 downto 0));
    end component;

begin
    ps2c_iobuf : IOBUF
        port map(I => OUT_SIG_cl, T => T_ENABLE_cl, O => IN_SIG_cl, IO => ps2_clock_pin);
    ps2d_iobuf : IOBUF
        port map(I => OUT_SIG_dat, T => T_ENABLE_dat, O => IN_SIG_dat, IO => ps2_data_pin);

    debounc_ps2c : debouncer
        port map(clk => clk, ps2c => IN_SIG_cl, ps2c_deb => ps2c_deb);

    detekovanie_falling_edge : detec_falling_endge
        port map(ps2c_deb => ps2c_deb, clk => clk, rst => rst, ps2c_fall => ps2c_fall);

    zapis_do_mouse : ps2_tx
        port map(ps2c_fall    => ps2c_fall, ps2d_out => IN_SIG_dat, clk => clk, rst => rst, num_to_mouse => num_to_mouse, tx_en => tx_en,
                 ps2c_t_en    => T_ENABLE_cl, ps2c_in => OUT_SIG_cl, ps2d_t_en => T_ENABLE_dat, ps2d_in => OUT_SIG_dat, tx_done_en => tx_done_en);

    citanie_z_mouse : ps2_rx
        port map(ps2c_fall  => ps2c_fall, ps2d => IN_SIG_dat, clk => clk, rst => rst, rx_en => rx_en, ps2d_data => rx_data,
                 rx_done_en => rx_done_en);

    hlavny_stav_automat : state_log_m
        port map(clk          => clk, rst => rst, tx_done_en => tx_done_en, rx_done_en => rx_done_en, rx_data => rx_data, tx_en => tx_en, rx_en => rx_en,
                 button_l     => button_l, button_r => button_r, button_m => scroll_up, position_x => position_x, position_y => position_y, num_to_mouse => num_to_mouse);

    scroll_down <= '0';

end Behavioral;
