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
    --   signal game_state_memory, game_state_memory_r     : unsigned(2 downto 0)         := (others => '0');
    signal pl1_ready, pl1_ready_r                     : std_logic                    := '0';
    signal pl2_ready, pl2_ready_r                     : std_logic                    := '0';
    signal ack_flag                                   : std_logic                    := '0';
    signal turn_sig, turn_sig_r                       : std_logic                    := '0';
    signal shoot_position_save, shoot_position_save_r : std_logic_vector(8 downto 0) := (others => '0');
    signal hit_in_sig, hit_in_sig_r                   : std_logic                    := '0';
    signal miss_in_sig, miss_in_sig_r                 : std_logic                    := '0';
    constant ack                                      : std_logic_vector             := "100111001";

begin

    ----------------------------
    --    SEQUENTIAL LOGIC    --
    ----------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            game_state          <= idle;
            ack_counter         <= (others => '0');
            --   game_state_memory   <= (others => '0');
            pl1_ready           <= '0';
            pl2_ready           <= '0';
            game_type_real      <= '0';
            turn_sig            <= '0';
            shoot_position_save <= (others => '0');
            miss_in_sig         <= '0';
            hit_in_sig          <= '0';
        elsif rising_edge(clk) then
            game_state          <= game_state_next; -- MPL state machine register --    
            ack_counter         <= ack_counter_r;
            --      game_state_memory   <= game_state_memory_r;
            pl1_ready           <= pl1_ready_r;
            pl2_ready           <= pl2_ready_r;
            game_type_real      <= game_type_real_r;
            turn_sig            <= turn_sig_r;
            shoot_position_save <= shoot_position_save_r;
            hit_in_sig          <= hit_in_sig_r;
            miss_in_sig         <= miss_in_sig_r;
        end if;
    end process;

    ----------------------------
    --   MPL STATE MACHINE    --
    ----------------------------
    process(game_state, rx_data, rx_receive_CE, tx_busy, game_type_want, game_type_want_CE, ack_counter, pl1_ready_out, ack_flag, pl1_ready, pl2_ready, game_type_real, turn_sig, shoot_position_out, shoot_position_out_CE, shoot_position_save, hit_in_sig, miss_in_sig, hit_out, miss_out)
    begin
        tx_data               <= (others => '0');
        tx_send_CE            <= '0';
        turn                  <= '0';
        pl2_ready_in          <= '0';
        miss_in               <= '0';
        hit_in                <= '0';
        shoot_position_in     <= (others => '0');
        --   game_state_memory_r   <= game_state_memory;
        game_state_next       <= game_state;
        game_type_real_r      <= game_type_real;
        ack_flag              <= '0';
        ack_counter_r         <= (others => '0');
        miss_in_sig_r         <= miss_in_sig;
        turn_sig_r            <= turn_sig;
        pl2_ready_r           <= pl2_ready;
        pl1_ready_r           <= pl1_ready;
        shoot_position_save_r <= shoot_position_save;
        hit_in_sig_r          <= hit_in_sig;

        case game_state is
            when idle =>
                if (tx_busy = '0') then
                    tx_data    <= "111111111";
                    tx_send_CE <= '1';
                end if;

                if (rx_receive_CE = '1') then
                    if (rx_data = "111111111") then
                        game_state_next <= game_type;
                    else
                        game_state_next <= idle;
                    end if;
                end if;

            when game_type =>
                if (game_type_want_CE = '1') then
                    game_type_real_r <= game_type_want;
                    if (tx_busy = '0') then
                        tx_data    <= ("10000000" & game_type_want);
                        tx_send_CE <= '1';
                        turn_sig_r <= '1';
                        if (ack_flag = '0') then
                            if (ack_counter < 125000) then -- wait max 2,5ms for the ack --
                                ack_counter_r <= ack_counter + 1;
                                if (rx_receive_CE = '1') then
                                    if (rx_data = ack) then
                                        ack_flag <= '1';
                                    end if;
                                end if;
                            end if;
                        end if;
                        game_state_next <= game_init;
                    end if;
                elsif (rx_receive_CE = '1') then
                    if (rx_data = "100000000") or (rx_data = "100000001") then
                        game_type_real_r <= rx_data(0);
                        turn_sig_r       <= '0';
                        if (tx_busy = '0') then
                            tx_data    <= ack;
                            tx_send_CE <= '1';
                        end if;
                        game_state_next  <= game_init;
                    end if;
                end if;

            when game_init =>
                if (pl1_ready_out = '1') then
                    pl1_ready_r <= '1';
                    if (tx_busy = '0') then
                        tx_data    <= "010000001";
                        tx_send_CE <= '1';
                        ------------------------------------------------------------------------------------ FUNKCE ??? ACK_WAIT
                        if (ack_flag = '0') then
                            if (ack_counter < 125000) then -- wait max 2,5ms for the ack --
                                ack_counter_r <= ack_counter + 1;
                                if (rx_receive_CE = '1') then
                                    if (rx_data = "100111001") then
                                        ack_flag <= '1';
                                    end if;
                                end if;
                            end if;
                        end if;
                        ------------------------------------------------------------------------------------ FUNKCE ???
                    end if;
                end if;

                if (rx_receive_CE = '1') then
                    if (rx_data = "010000001") then
                        pl2_ready_r <= '1';
                        ------------------------------------------------------------------------------------ FUNKCE ??? ACK_SEND
                        if (tx_busy = '0') then
                            tx_data    <= "100111001";
                            tx_send_CE <= '1';
                        end if;
                        ------------------------------------------------------------------------------------ FUNKCE ??? ACK_SEND
                    end if;
                end if;

                if (pl1_ready = '1' and pl2_ready = '1') then
                    if (turn_sig = '1') then
                        game_state_next <= my_turn;
                    else
                        game_state_next <= his_turn;
                    end if;
                end if;

            when my_turn =>
                turn <= '1';
                if (shoot_position_out_CE = '1') then
                    shoot_position_save_r <= shoot_position_out;
                    if (tx_busy = '0') then
                        tx_data    <= shoot_position_save;
                        tx_send_CE <= '1';
                        ------------------------------------------------------------------------------------ FUNKCE ??? ACK_WAIT
                        if (ack_flag = '0') then
                            if (ack_counter < 125000) then -- wait max 2,5ms for the ack --
                                ack_counter_r <= ack_counter + 1;
                                if (rx_receive_CE = '1') then
                                    if (rx_data = ack) then
                                        ack_flag <= '1';
                                    end if;
                                end if;
                            end if;
                        end if;
                        ------------------------------------------------------------------------------------ FUNKCE ??? ACK_WAIT
                    end if;

                    if (rx_receive_CE = '1') then
                        if (rx_data = "001000001") then
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
                        elsif (rx_data = "001000000") then
                            miss_in_sig_r   <= '1';
                            if (tx_busy = '0') then
                                tx_data    <= ack;
                                tx_send_CE <= '1';
                            end if;
                            game_state_next <= his_turn;
                        end if;
                    end if;

                    hit_in  <= hit_in_sig;
                    miss_in <= miss_in_sig;
                end if;

            when his_turn =>
                turn <= '0';
                if (rx_receive_CE = '1') then
                    shoot_position_in <= rx_data;
                    if (tx_busy = '0') then
                        tx_data    <= ack;
                        tx_send_CE <= '1';
                    end if;
                    if (hit_out = '1') then
                        if (tx_busy = '0') then
                            tx_data    <= "001000001";
                            tx_send_CE <= '1';
                            if (ack_flag = '0') then
                                if (ack_counter < 125000) then -- wait max 2,5ms for the ack --
                                    ack_counter_r <= ack_counter + 1;
                                    if (rx_receive_CE = '1') then
                                        if (rx_data = "100111001") then
                                            ack_flag <= '1';
                                        end if;
                                    end if;
                                end if;
                            end if;
                        end if;
                        if (game_type_real = '1') then
                            game_state_next <= his_turn;
                        else
                            game_state_next <= my_turn;
                        end if;
                    elsif (miss_out = '1') then
                        if (tx_busy = '0') then
                            tx_data    <= "001000000";
                            tx_send_CE <= '1';
                            if (ack_flag = '0') then
                                if (ack_counter < 125000) then -- wait max 2,5ms for the ack --
                                    ack_counter_r <= ack_counter + 1;
                                    if (rx_receive_CE = '1') then
                                        if (rx_data = "100111001") then
                                            ack_flag <= '1';
                                        end if;
                                    end if;
                                end if;
                            end if;
                        end if;
                        game_state_next <= my_turn;
                    end if;
                end if;

                --        when ack_wait =>
                --             if (ack_counter < 125000) then -- wait max 2,5ms for the ack --
                --                 ack_counter_r <= ack_counter + 1;
                --                 if (rx_receive_CE = '1') then
                --                     if (rx_data = "100111001") then
                --                         game_state_next     <= ack_send;
                --                         game_state_memory_r <= (others => '0');
                --                     end if;
                --                 end if;
                --             else
                --                 --   game_state_next     <= MPL_SM(game_state_memory);
                --                 game_state_memory_r <= (others => '0');
                --             end if;

                --         when ack_send =>
                --             if (tx_busy = '0') then
                --                tx_data             <= "100111001";
                --                 tx_send_CE          <= '1';
                --                 game_state_next     <= ack_wait;
                --                 game_state_memory_r <= (others => '0');
                --            end if;

        end case;
    end process;

end architecture RTL;
