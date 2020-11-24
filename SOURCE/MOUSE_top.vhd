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

    --hlavny stavovy automat
    type state_type is (idle, ack_f4, pack1, pack2, pack3, decod_x, decod_y, done);
    signal next_state, present_state : state_type;

    signal btn_l_next, btn_l       : std_logic;
    signal btn_r_next, btn_r       : std_logic;
    signal btn_m_next, btn_m       : std_logic;
    signal x_data_next, x_data     : std_logic_vector(8 downto 0);
    signal y_data_next, y_data     : std_logic_vector(8 downto 0);
    signal x_pretec_next, x_pretec : std_logic;
    signal y_pretec_next, y_pretec : std_logic;
    signal pos_x_next, pos_x       : std_logic_vector(10 downto 0);
    signal pos_y_next, pos_y       : std_logic_vector(9 downto 0);

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
             kb_code_en      : out STD_LOGIC;
             ps2d_data       : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

    --testovaci komponent
    --component mouse_vystup is
    -- Port ( clk, tx_done : in  STD_LOGIC;
    --       led : out  STD_LOGIC);
    --end component;

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
                 kb_code_en => rx_done_en);

    --hlavny stavovy automat
    --sekvencna cast:
    process(clk, rst)
    begin
        if rst = '1' then
            present_state <= idle;
            btn_l_next    <= '0';
            btn_r_next    <= '0';
            btn_m_next    <= '0';
            x_data_next   <= (others => '0');
            y_data_next   <= (others => '0');
            x_pretec_next <= '0';
            y_pretec_next <= '0';
            pos_x_next    <= (others => '0');
            pos_y_next    <= (others => '0');
        elsif (clk'event and clk = '1') then
            present_state <= next_state;
            btn_l_next    <= btn_l;
            btn_r_next    <= btn_r;
            btn_m_next    <= btn_m;
            x_data_next   <= x_data;
            y_data_next   <= y_data;
            x_pretec_next <= x_pretec;
            y_pretec_next <= y_pretec;
            pos_x_next    <= pos_x;
            pos_y_next    <= pos_y;
        end if;
    end process;

    --kombinacna_cast:
    process(present_state, tx_done_en, rx_done_en, btn_l_next, btn_r_next, btn_m_next, x_data_next, y_data_next, x_pretec_next, y_pretec_next, pos_x_next, pos_y_next, rx_data)
    begin
        next_state   <= present_state;
        tx_en        <= '0';
        rx_en        <= '0';
        num_to_mouse <= (others => '0');
        position_x   <= (others => '0');
        position_y   <= (others => '0');
        button_l     <= '0';
        button_r     <= '0';
        scroll_up    <= '0';
        btn_l        <= btn_l_next;
        btn_r        <= btn_r_next;
        btn_m        <= btn_m_next;
        x_data       <= x_data_next;
        y_data       <= y_data_next;
        x_pretec     <= x_pretec_next;
        y_pretec     <= y_pretec_next;
        pos_x        <= pos_x_next;
        pos_y        <= pos_y_next;
        case present_state is
            when idle =>
                tx_en        <= '1';
                num_to_mouse <= "11110100"; --F4
                if (tx_done_en = '1') then
                    next_state <= ack_f4;
                end if;

            when ack_f4 =>
                rx_en <= '1';
                if (rx_done_en = '1') then
                    next_state <= pack1;
                end if;

            when pack1 =>
                rx_en <= '1';
                if (rx_done_en = '1') then
                    btn_l      <= rx_data(0);
                    btn_r      <= rx_data(1);
                    btn_m      <= rx_data(2);
                    x_data(8)  <= rx_data(4);
                    y_data(8)  <= rx_data(5);
                    x_pretec   <= rx_data(6);
                    y_pretec   <= rx_data(7);
                    next_state <= pack2;
                end if;

            when pack2 =>
                rx_en <= '1';
                if (rx_done_en = '1') then
                    x_data(7 downto 0) <= rx_data;
                    next_state         <= pack3;
                end if;

            when pack3 =>
                rx_en <= '1';
                if (rx_done_en = '1') then
                    y_data(7 downto 0) <= rx_data;
                    next_state         <= done;
                end if;

            when decod_x =>
                if (x_pretec = '1') then
                    if (x_data(8) = '1') then
                        pos_x <= (others => '0');
                    else
                        pos_x <= (others => '1');
                    end if;
                end if;

            when decod_y =>
                if (y_pretec = '1') then
                    if (y_data(8) = '1') then
                        pos_y <= (others => '0');
                    else
                        pos_y <= (others => '1');
                    end if;
                end if;

            when done =>
                position_x  <= (others => '0'); --pos_x_next;
                position_y  <= (others => '0'); --pos_y_next;
                button_l    <= '0';     --btn_l_next;
                button_r    <= '0';     --btn_r_next;
                scroll_up   <= '0';     --btn_m_next;
                scroll_down <= '0';
                next_state  <= pack1;

            when others =>
                next_state <= idle;
        end case;
    end process;

end Behavioral;
