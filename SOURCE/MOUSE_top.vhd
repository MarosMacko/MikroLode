library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.NUMERIC_STD.ALL;

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
    signal IN_SIG_cl, OUT_SIG_cl, T_ENABLE_cl    : std_logic;
    signal IN_SIG_dat, OUT_SIG_dat, T_ENABLE_dat : std_logic;

    component IOBUF
        port(I, T : in    std_logic;
             O    : out   std_logic;
             IO   : inout std_logic);
    end component;

begin

    position_x  <= (others => '0');
    position_y  <= (others => '0');
    button_l    <= '0';
    button_r    <= '0';
    scroll_up   <= '0';
    scroll_down <= '0';

    ps2_clock_pin <= 'Z';
    ps2_data_pin  <= 'Z';

end Behavioral;
