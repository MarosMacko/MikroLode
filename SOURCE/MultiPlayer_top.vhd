library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MultiPlayer_top is

    port(clk, rst              : in  std_logic;
         -----------------------------------------  -- signals between MP_LOGIC & UART --
         tx_data               : out std_logic_vector(8 downto 0) := (others => '0');
         tx_send_CE            : out std_logic                    := '0';
         tx_busy               : in  std_logic;
         rx_data               : in  std_logic_vector(8 downto 0);
         rx_receive_CE         : in  std_logic;
         ----------------------------------------- -- signals between MP_LOGIC & GAME_LOGIC --
         turn                  : out std_logic                    := '0';
         game_type_want_CE     : in  std_logic;
         game_type_want        : in  std_logic;
         pl1_ready_out         : in  std_logic;
         pl2_ready_in          : out std_logic                    := '0';
         miss_in               : out std_logic                    := '0';
         hit_in                : out std_logic                    := '0';
         miss_out              : in  std_logic;
         hit_out               : in  std_logic;
         shoot_position_out    : in  std_logic_vector(8 downto 0);
         shoot_position_out_CE : in  std_logic;
         shoot_position_in     : out std_logic_vector(8 downto 0) := (others => '0')
        );
end entity MultiPlayer_top;

architecture RTL of MultiPlayer_top is

    type MPL_SM is (idle, game_type, game_init, my_turn, his_turn); -- MPL state machine data type --
    --   attribute enum_encoding                       : string;
    --   attribute enum_encoding of MPL_SM : type is "000 001 010 011 100 101"; -- encoding of MPL state machine --
    signal game_state, game_state_next                : MPL_SM                       := idle; -- MPL state machine --
    signal game_type_real, game_type_real_r           : std_logic                    := '0';
    signal ack_counter, ack_counter_r                 : unsigned(20 downto 0)        := (others => '0');
    signal pl1_ready, pl1_ready_r                     : std_logic                    := '0';
    signal pl2_ready, pl2_ready_r                     : std_logic                    := '0';
    signal ack_flag, ack_flag_r                       : std_logic                    := '0';
    signal turn_sig, turn_sig_r                       : std_logic                    := '0';
    signal shoot_position_save, shoot_position_save_r : std_logic_vector(8 downto 0) := (others => '0');
    signal hit_in_sig, hit_in_sig_r                   : std_logic                    := '0';
    signal miss_in_sig, miss_in_sig_r                 : std_logic                    := '0';
    signal help_counter, help_counter_r               : std_logic                    := '0';
    constant ack                                      : std_logic_vector             := "100111001";
    constant game_type_fast                           : std_logic_vector             := "100000001";
    constant game_type_slow                           : std_logic_vector             := "100000000";
    constant initialization                           : std_logic_vector             := "010000001";
    constant player_ready                             : std_logic_vector             := "010000001";
    constant hit                                      : std_logic_vector             := "001000001";
    constant miss                                     : std_logic_vector             := "001000000";

begin

    ----------------------------
    --    SEQUENTIAL LOGIC    --
    ----------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            game_state          <= idle;
            ack_counter         <= (others => '0');
            pl1_ready           <= '0';
            pl2_ready           <= '0';
            game_type_real      <= '0';
            turn_sig            <= '0';
            shoot_position_save <= (others => '0');
            miss_in_sig         <= '0';
            hit_in_sig          <= '0';
            ack_flag            <= '0';
            help_counter        <= '0';
        elsif rising_edge(clk) then
            game_state          <= game_state_next; -- MPL state machine register --    
            ack_counter         <= ack_counter_r;
            pl1_ready           <= pl1_ready_r;
            pl2_ready           <= pl2_ready_r;
            game_type_real      <= game_type_real_r;
            turn_sig            <= turn_sig_r;
            shoot_position_save <= shoot_position_save_r;
            hit_in_sig          <= hit_in_sig_r;
            miss_in_sig         <= miss_in_sig_r;
            ack_flag            <= ack_flag_r;
            help_counter        <= help_counter_r;
        end if;
    end process;

    ----------------------------
    --   MPL STATE MACHINE    --
    ----------------------------
    process(game_state, rx_data, rx_receive_CE, tx_busy, game_type_want, game_type_want_CE, ack_counter, pl1_ready_out, ack_flag, pl1_ready, pl2_ready, game_type_real, turn_sig, shoot_position_out, shoot_position_out_CE, shoot_position_save, hit_in_sig, miss_in_sig, hit_out, miss_out, help_counter)
    begin
        tx_data               <= (others => '0');
        tx_send_CE            <= '0';
        pl2_ready_in          <= pl2_ready;
        turn                  <= '0';
        miss_in               <= '0';
        hit_in                <= '0';
        shoot_position_in     <= (others => '0');
        game_state_next       <= game_state;
        game_type_real_r      <= game_type_real;
        ack_flag_r            <= ack_flag;
        ack_counter_r         <= ack_counter;
        miss_in_sig_r         <= miss_in_sig;
        turn_sig_r            <= turn_sig;
        pl2_ready_r           <= pl2_ready;
        pl1_ready_r           <= pl1_ready;
        shoot_position_save_r <= shoot_position_save;
        hit_in_sig_r          <= hit_in_sig;
        help_counter_r        <= help_counter;

        case game_state is
            when idle =>                -- initialization -- 
                if (tx_busy = '0') then
                    tx_data    <= "000010000";
                    tx_send_CE <= '1';
                else
                    game_state_next <= idle;
                end if;
                if (rx_receive_CE = '1') then
                    if (rx_data = "000010000") then
                        game_state_next <= game_type;
                    else
                        game_state_next <= idle;
                    end if;
                end if;

            when game_type =>           -- game type -> fast or slow --
                if (game_type_want_CE = '1') then -- jestli v GL nebude CE sign�l registrovan�, tak si ho mus�m ulo�it, aby se jeho hodnota nezm�nila d��v, ne� se ode�lou data atd. -- 
                    turn_sig_r       <= '1'; -- kdo prvn� zvol� typ hry, ten za��n� -- 
                    game_type_real_r <= game_type_want;
                    ack_counter_r    <= (others => '0');
                    if (tx_busy = '0' and help_counter = '0') then
                        tx_data        <= ("10000000" & game_type_want);
                        tx_send_CE     <= '1';
                        help_counter_r <= '1';
                    end if;
                    if (ack_counter < 125000) then -- wait max 2,5ms for the ack --
                        ack_counter_r <= ack_counter + 1;
                        if (rx_receive_CE = '1') then
                            if (rx_data = ack) then
                                game_state_next <= game_init;
                                ack_counter_r   <= (others => '0');
                            end if;
                        end if;
                    else
                        help_counter_r <= '0';
                    end if;

                elsif (rx_receive_CE = '1') then
                    if (rx_data = game_type_slow) or (rx_data = game_type_fast) then
                        game_type_real_r <= rx_data(0);
                        turn_sig_r       <= '0';
                        if (tx_busy = '0') then
                            tx_data         <= ack;
                            tx_send_CE      <= '1';
                            game_state_next <= game_init;
                        end if;
                    end if;
                end if;

            when game_init =>
                if (pl1_ready_out = '1' and help_counter = '0') then
                    ack_counter_r <= (others => '0');
                    if (tx_busy = '0') then
                        tx_data        <= initialization;
                        tx_send_CE     <= '1';
                        help_counter_r <= '1';
                    end if;
                end if;

                if (ack_counter < 125000) then -- wait max 2,5ms for the ack --
                    ack_counter_r <= ack_counter + 1;
                    if (rx_receive_CE = '1') then
                        if (rx_data = "110111011") then
                            pl1_ready_r   <= '1';
                            ack_counter_r <= (others => '0');
                        end if;
                    end if;
                else
                    help_counter_r <= '0';
                end if;

                if (rx_receive_CE = '1') then
                    if (rx_data = initialization) then
                        if (tx_busy = '0') then
                            tx_data     <= "110111011";
                            tx_send_CE  <= '1';
                            pl2_ready_r <= '1';
                        end if;
                    end if;
                end if;

                if (pl1_ready = '1' and pl2_ready = '1') then
                    if (turn_sig = '1') then
                        game_state_next <= my_turn;
                        help_counter_r  <= '0';
                    else
                        game_state_next <= his_turn;
                        help_counter_r  <= '0';
                    end if;
                end if;

                pl2_ready_in <= pl2_ready;

            when my_turn =>
                turn <= '1';
                if (shoot_position_out_CE = '1') then
                    shoot_position_save_r <= shoot_position_out;
                    ack_counter_r         <= (others => '0');
                    if (tx_busy = '0' and help_counter = '0' and ack_flag <= '0') then
                        tx_data        <= shoot_position_out;
                        tx_send_CE     <= '1';
                        help_counter_r <= '1';
                    end if;
                    if (ack_counter < 125000) then -- wait max 2,5ms for the ack --
                        ack_counter_r <= ack_counter + 1;
                        if (rx_receive_CE = '1') then
                            if (rx_data = ack) then
                                ack_flag_r    <= '1';
                                ack_counter_r <= (others => '0');
                            end if;
                        end if;
                    else
                        help_counter_r <= '0';
                    end if;
                end if;

                if (ack_flag = '1') then
                    if (rx_receive_CE = '1') then
                        if (rx_data = hit) then
                            hit_in_sig_r <= '1';
                            if (tx_busy = '0') then
                                tx_data    <= ack;
                                tx_send_CE <= '1';
                            end if;
                            if (game_type_real = '1') then
                                game_state_next <= my_turn;
                            else
                                game_state_next <= his_turn;
                            end if;
                        elsif (rx_data = miss) then
                            miss_in_sig_r   <= '1';
                            if (tx_busy = '0') then
                                tx_data    <= ack;
                                tx_send_CE <= '1';
                            end if;
                            game_state_next <= his_turn;
                        end if;

                    end if;
                end if;
                hit_in  <= hit_in_sig;
                miss_in <= miss_in_sig;

            when his_turn =>
                turn       <= '0';
                ack_flag_r <= '0';

                if (rx_receive_CE = '1') then
                    if not (rx_data = ack or rx_data = game_type_fast or rx_data = game_type_slow or rx_data = player_ready or rx_data = hit or rx_data = miss) then --upravit!!!--
                        shoot_position_in <= rx_data; -- data na shoot_position_in jsou jenom po dobu trv�n� rx_CE, pak se vyma�ou => kdyby byl probl�m, p�idat registr -- 
                        if (tx_busy = '0') then
                            tx_data    <= ack;
                            tx_send_CE <= '1';
                        end if;
                    end if;
                end if;

                if (hit_out = '1') then
                    ack_counter_r <= (others => '0');
                    if (tx_busy = '0') then
                        tx_data    <= hit;
                        tx_send_CE <= '1';
                    end if;
                    if (ack_counter < 125000) then -- wait max 2,5ms for the ack --
                        ack_counter_r <= ack_counter + 1;
                        if (rx_receive_CE = '1') then
                            if (rx_data = ack) then
                                ack_flag_r    <= '1';
                                ack_counter_r <= (others => '0');
                            end if;
                        end if;
                    end if;
                    if (ack_flag = '1') then
                        if (game_type_real = '1') then
                            game_state_next <= his_turn;
                        else
                            game_state_next <= my_turn;
                        end if;
                    end if;
                elsif (miss_out = '1') then
                    ack_counter_r <= (others => '0');
                    if (tx_busy = '0' and help_counter = '0') then
                        tx_data        <= miss;
                        tx_send_CE     <= '1';
                        help_counter_r <= '1';
                    end if;
                    if (ack_counter < 125000) then -- wait max 2,5ms for the ack --
                        ack_counter_r <= ack_counter + 1;
                        if (rx_receive_CE = '1') then
                            if (rx_data = "100111001") then
                                ack_flag_r    <= '1';
                                ack_counter_r <= (others => '0');
                            end if;
                        end if;
                    else
                        help_counter_r <= '0';
                    end if;

                    if (ack_flag = '1') then
                        game_state_next <= my_turn;
                    end if;
                end if;
        end case;
    end process;

end architecture RTL;
