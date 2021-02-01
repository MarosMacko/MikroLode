library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MultiPlayer_top is

    port(clk, rst                   : in  std_logic;
         -----------------------------------------  -- signals between MP_LOGIC & UART --
         tx_data                    : out std_logic_vector(8 downto 0) := (others => '0');
         tx_send_CE                 : out std_logic                    := '0';
         tx_busy                    : in  std_logic;
         rx_data                    : in  std_logic_vector(8 downto 0);
         rx_receive_CE              : in  std_logic;
         ----------------------------------------- -- signals between MP_LOGIC & GAME_LOGIC --
         turn                       : out std_logic                    := '0';
         game_type_want_CE          : in  std_logic;
         game_type_want             : in  std_logic;
         pl1_ready_out              : in  std_logic;
         pl2_ready_in               : out std_logic                    := '0';
         miss_in                    : out std_logic                    := '0';
         hit_in                     : out std_logic                    := '0';
         miss_out                   : in  std_logic;
         hit_out                    : in  std_logic;
         fast_game                  : out std_logic                    := '0';
         slow_game                  : out std_logic                    := '0';
         shoot_position_out         : in  std_logic_vector(8 downto 0);
         shoot_position_in          : out std_logic_vector(8 downto 0) := (others => '0');
         led_1, led_2, led_3, led_8 : out std_logic
        );
end entity MultiPlayer_top;

architecture RTL of MultiPlayer_top is

    type MPL_SM is (idle, game_type, game_init, my_turn, his_turn, acknowledge); -- MPL state machine data type --
    signal game_state, game_state_next        : MPL_SM                       := idle; -- MPL state machine --
    signal game_type_real, game_type_real_r   : std_logic                    := '0';
    signal ack_counter, ack_counter_r         : unsigned(20 downto 0)        := (others => '0');
    signal pl1_ready, pl1_ready_r             : std_logic                    := '0';
    signal pl2_ready, pl2_ready_r             : std_logic                    := '0';
    signal ack_flag, ack_flag_r               : std_logic                    := '0';
    signal turn_sig, turn_sig_r               : std_logic                    := '0';
    signal turn_out, turn_out_r               : std_logic                    := '0';
    signal hit_in_sig, hit_in_sig_r           : std_logic                    := '0';
    signal miss_in_sig, miss_in_sig_r         : std_logic                    := '0';
    signal data_sent_index, data_sent_index_r : std_logic                    := '0';
    signal state_index, state_index_r         : std_logic_vector(2 downto 0) := (others => '0');
    signal kundovinka, kundovinka_r           : std_logic                    := '0'; -- TODO: zmìnit název :D --
    signal fast, fast_r                       : std_logic                    := '0';
    signal slow, slow_r                       : std_logic                    := '0';
    constant initialization                   : std_logic_vector             := "000010000";
    constant game_type_fast                   : std_logic_vector             := "100000001";
    constant game_type_slow                   : std_logic_vector             := "100000000";
    constant player_ready                     : std_logic_vector             := "010000001";
    constant hit                              : std_logic_vector             := "001000001";
    constant miss                             : std_logic_vector             := "001000000";
    constant ack                              : std_logic_vector             := "100111001";

begin

    ----------------------------
    --    SEQUENTIAL LOGIC    --
    ----------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            game_state      <= idle;
            ack_counter     <= (others => '0');
            pl1_ready       <= '0';
            pl2_ready       <= '0';
            game_type_real  <= '0';
            turn_sig        <= '0';
            miss_in_sig     <= '0';
            hit_in_sig      <= '0';
            ack_flag        <= '0';
            data_sent_index <= '0';
            state_index     <= (others => '0');
            kundovinka      <= '0';
            fast            <= '0';
            slow            <= '0';
            turn_out        <= '0';
        elsif rising_edge(clk) then
            game_state      <= game_state_next;
            ack_counter     <= ack_counter_r;
            pl1_ready       <= pl1_ready_r;
            pl2_ready       <= pl2_ready_r;
            game_type_real  <= game_type_real_r;
            turn_sig        <= turn_sig_r;
            hit_in_sig      <= hit_in_sig_r;
            miss_in_sig     <= miss_in_sig_r;
            ack_flag        <= ack_flag_r;
            data_sent_index <= data_sent_index_r;
            state_index     <= state_index_r;
            kundovinka      <= kundovinka_r;
            fast            <= fast_r;
            slow            <= slow_r;
            turn_out        <= turn_out_r;
        end if;
    end process;

    ----------------------------
    --   MPL STATE MACHINE    --
    ----------------------------
    process(game_state, rx_data, rx_receive_CE, tx_busy, game_type_want, game_type_want_CE, ack_counter, pl1_ready_out, ack_flag, pl1_ready, pl2_ready, game_type_real, turn_sig, shoot_position_out, hit_in_sig, miss_in_sig, hit_out, miss_out, data_sent_index, state_index, kundovinka, fast, slow, turn_out)
    begin
        tx_data           <= (others => '0');
        tx_send_CE        <= '0';
        pl2_ready_in      <= pl2_ready;
        turn              <= '0';
        miss_in           <= '0';
        hit_in            <= '0';
        shoot_position_in <= (others => '0');
        fast_game         <= fast;
        slow_game         <= slow;
        turn              <= turn_out;
        led_1             <= '0';
        led_2             <= '0';
        led_3             <= '0';
        led_8             <= '0';
        game_state_next   <= game_state;
        game_type_real_r  <= game_type_real;
        ack_flag_r        <= ack_flag;
        ack_counter_r     <= ack_counter;
        miss_in_sig_r     <= miss_in_sig;
        turn_sig_r        <= turn_sig;
        pl2_ready_r       <= pl2_ready;
        pl1_ready_r       <= pl1_ready;
        hit_in_sig_r      <= hit_in_sig;
        data_sent_index_r <= data_sent_index;
        state_index_r     <= state_index;
        kundovinka_r      <= kundovinka;
        fast_r            <= fast;
        slow_r            <= slow;
        turn_out_r        <= turn_out;

        case game_state is
            when idle =>                -- FIRTS INITIALIZATION -- 
                led_1 <= '1';
                if (tx_busy = '0') then -- when UART is NOT busy, thn send initialization packet --
                    tx_data    <= initialization;
                    tx_send_CE <= '1';
                else
                    game_state_next <= idle; -- when UART IS busy, then remain in state idle --
                end if;

                if (rx_receive_CE = '1') then -- when CE is active and received data are "initialization" then go to the next state --
                    if (rx_data = initialization) then
                        game_state_next <= game_type;
                    else
                        game_state_next <= idle; -- else remain in this state and wait for connection of other FPGA --
                    end if;
                end if;

            when game_type =>           -- GAME TYPE CHOICE --
                led_2 <= '1';
                if (game_type_want_CE = '1') then -- when CE is active, set TURN  <= '1' -- 
                    turn_sig_r       <= '1';
                    kundovinka_r     <= '1'; -- zmìním to snad -- 
                    game_type_real_r <= game_type_want;
                    if (tx_busy = '0' and data_sent_index = '0') then -- when UART is not busy and data hasnt been sent yet, send it -- 
                        tx_data           <= ("10000000" & game_type_want);
                        tx_send_CE        <= '1';
                        data_sent_index_r <= '1';
                        state_index_r     <= "010";
                        ack_counter_r     <= (others => '0');
                        game_state_next   <= acknowledge; -- when data sent, go to "acknowledge" state a wait for ack --
                    end if;

                elsif (rx_receive_CE = '1') then -- else when data received, set TURN  <= '0' --
                    if (rx_data = game_type_slow) or (rx_data = game_type_fast) then
                        game_type_real_r <= rx_data(0);
                        turn_sig_r       <= '0';
                        kundovinka_r     <= '0';
                        if (tx_busy = '0') then -- if UART is free, send ack --
                            tx_data         <= ack;
                            tx_send_CE      <= '1';
                            game_state_next <= game_init;
                        end if;
                    end if;
                end if;

            when game_init =>           -- GAME INITIALIZATION --
                led_3      <= '1';
                ack_flag_r <= '0';
                if (kundovinka = '1') then
                    if (pl1_ready_out = '1') then
                        if (tx_busy = '0' and data_sent_index = '0' and ack_flag = '0') then
                            tx_data           <= player_ready;
                            tx_send_CE        <= '1';
                            data_sent_index_r <= '1';
                            state_index_r     <= "011";
                            ack_counter_r     <= (others => '0');
                            game_state_next   <= acknowledge;
                        end if;

                        if (ack_flag = '1') then
                            pl1_ready_r  <= '1';
                            kundovinka_r <= '0';
                        end if;
                    end if;

                elsif (kundovinka = '0') then
                    if (rx_receive_CE = '1') then
                        if (rx_data = player_ready) then
                            if (tx_busy = '0') then
                                tx_data      <= ack;
                                tx_send_CE   <= '1';
                                pl2_ready_r  <= '1';
                                kundovinka_r <= '1';
                            end if;
                        end if;
                    end if;
                end if;

                if (pl1_ready = '1' and pl2_ready = '1') then
                    if (turn_sig = '1') then
                        game_state_next   <= my_turn;
                        data_sent_index_r <= '0';
                        ack_flag_r        <= '0';
                    else
                        game_state_next   <= his_turn;
                        data_sent_index_r <= '0';
                        ack_flag_r        <= '0';
                    end if;
                end if;

                if (game_type_real = '1') then
                    fast_r <= '1';
                else
                    slow_r <= '1';
                end if;

            when my_turn =>             -- MY TURN --
                turn_out_r <= '1';
                if not (unsigned(shoot_position_out) = 0) then
                    if (tx_busy = '0' and data_sent_index = '0' and ack_flag = '0') then
                        tx_data           <= shoot_position_out;
                        tx_send_CE        <= '1';
                        data_sent_index_r <= '1';
                        state_index_r     <= "100";
                        ack_counter_r     <= (others => '0');
                        game_state_next   <= acknowledge;
                    end if;
                end if;

                if (ack_flag = '1') then
                    if (rx_receive_CE = '1') then
                        if (rx_data = hit) then
                            hit_in_sig_r <= '1';
                            if (tx_busy = '0') then
                                tx_data    <= ack;
                                tx_send_CE <= '1';
                                if (game_type_real = '1') then
                                    game_state_next   <= my_turn;
                                    data_sent_index_r <= '0';
                                    ack_flag_r        <= '0';
                                else
                                    game_state_next   <= his_turn;
                                    data_sent_index_r <= '0';
                                    ack_flag_r        <= '0';
                                end if;
                            end if;
                        elsif (rx_data = miss) then
                            miss_in_sig_r <= '1';
                            if (tx_busy = '0') then
                                tx_data           <= ack;
                                tx_send_CE        <= '1';
                                game_state_next   <= his_turn;
                                data_sent_index_r <= '0';
                                ack_flag_r        <= '0';
                            end if;
                        end if;
                    end if;
                end if;
                hit_in  <= hit_in_sig;
                miss_in <= miss_in_sig;

            when his_turn =>            -- HIS TURN --
                turn_out_r <= '0';

                if (rx_receive_CE = '1') then
                    --   if not (rx_data = ack or rx_data = game_type_fast or rx_data = game_type_slow or rx_data = player_ready or rx_data = hit or rx_data = miss) then --upravit!!! teoreticky by to nemìlo být potøeba --
                    shoot_position_in <= rx_data; -- data na shoot_position_in jsou jenom po dobu trvání rx_CE, pak se vymažou => kdyby byl problém, pøidat registr -- 
                    if (tx_busy = '0') then
                        tx_data    <= ack;
                        tx_send_CE <= '1';
                    end if;
                end if;
                --  end if;

                if (hit_out = '1') then
                    ack_counter_r <= (others => '0');
                    if (tx_busy = '0' and data_sent_index = '0' and ack_flag = '0') then
                        tx_data           <= hit;
                        tx_send_CE        <= '1';
                        data_sent_index_r <= '1';
                        state_index_r     <= "101";
                        ack_counter_r     <= (others => '0');
                        game_state_next   <= acknowledge;
                    end if;

                    if (ack_flag = '1') then
                        if (game_type_real = '1') then
                            game_state_next   <= his_turn;
                            data_sent_index_r <= '0';
                            ack_flag_r        <= '0';
                        else
                            game_state_next   <= my_turn;
                            data_sent_index_r <= '0';
                            ack_flag_r        <= '0';
                        end if;
                    end if;
                elsif (miss_out = '1') then
                    if (tx_busy = '0' and data_sent_index = '0' and ack_flag = '0') then
                        tx_data           <= miss;
                        tx_send_CE        <= '1';
                        data_sent_index_r <= '1';
                        state_index_r     <= "101";
                        ack_counter_r     <= (others => '0');
                        game_state_next   <= acknowledge;
                    end if;

                    if (ack_flag = '1') then
                        game_state_next   <= my_turn;
                        data_sent_index_r <= '0';
                        ack_flag_r        <= '0';
                    end if;
                end if;

            when acknowledge =>         -- ACKNOWLEDGE --
                led_8 <= '1';
                if (ack_counter < 125000) then -- wait max 2,5ms for the ack --
                    ack_counter_r <= ack_counter + 1;
                    if (rx_receive_CE = '1') then
                        if (rx_data = ack) then
                            ack_counter_r     <= (others => '0');
                            ack_flag_r        <= '1';
                            data_sent_index_r <= '0';
                        end if;
                    end if;
                else
                    data_sent_index_r <= '0';
                end if;

                if (ack_flag = '1') then
                    if (state_index = "010") then
                        game_state_next <= game_init;
                    elsif (state_index = "011") then
                        game_state_next <= game_init;
                    elsif (state_index = "100") then
                        game_state_next <= my_turn;
                    elsif (state_index = "101") then
                        game_state_next <= his_turn;
                    end if;
                elsif (ack_counter = 125000) then
                    if (state_index = "010") then
                        game_state_next <= game_type;
                    elsif (state_index = "011") then
                        game_state_next <= game_init;
                    elsif (state_index = "100") then
                        game_state_next <= my_turn;
                    elsif (state_index = "101") then
                        game_state_next <= his_turn;
                    end if;
                end if;

        end case;
    end process;

end architecture RTL;
