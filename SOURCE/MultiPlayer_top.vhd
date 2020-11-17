library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MultiPlayer_top is

    generic(data_width : integer := 8); -- data bus width --

    port(clk, rst           : in  std_logic;
         -----------------------------------------	-- signals between MP_LOGIC & UART --
         tx_data            : out std_logic_vector(data_width - 1 downto 0);
         tx_send_CE         : out std_logic;
         tx_busy            : in  std_logic;
         rx_data            : in  std_logic_vector(data_width - 1 downto 0);
         rx_receive_CE      : in  std_logic;
         ----------------------------------------- -- signals between MP_LOGIC & GAME_LOGIC --
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
end entity MultiPlayer_top;

architecture RTL of MultiPlayer_top is

begin

    tx_data           <= (others => '0');
    tx_send_CE        <= '0';
    turn              <= '0';
    game_type_real    <= '0';
    miss_in           <= '0';
    hit_in            <= '0';
    shoot_position_in <= (others => '0');

end architecture RTL;
