library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity state_log_m is
    Port(clk, rst                     : in  STD_LOGIC;
         tx_done_en, rx_done_en       : in  STD_LOGIC;
         rx_data                      : in  STD_LOGIC_VECTOR(7 downto 0);
         tx_en, rx_en                 : out STD_LOGIC;
         num_to_mouse                 : out STD_LOGIC_VECTOR(7 downto 0);
         button_l, button_r, button_m : out STD_LOGIC;
         position_x                   : out STD_LOGIC_VECTOR(10 downto 0);
         position_y                   : out STD_LOGIC_VECTOR(9 downto 0));
end state_log_m;

architecture Behavioral of state_log_m is
    type state_type is (idle_rst, ack_ff, slf_test, id_mouse, stream_md, pack1, pack2, pack3, ack_ff2, decod_x, decod_y, done);
    signal next_state, present_state : state_type;

    signal btn_l_next, btn_l         : std_logic;
    signal btn_r_next, btn_r         : std_logic;
    signal btn_m_next, btn_m         : std_logic;
    signal x_data_next, x_data       : std_logic_vector(8 downto 0);
    signal y_data_next, y_data       : std_logic_vector(8 downto 0);
    signal x_pretec_next, x_pretec   : std_logic;
    signal y_pretec_next, y_pretec   : std_logic;
    signal pos_x_next, pos_x         : std_logic_vector(10 downto 0);
    signal pos_y_next, pos_y         : std_logic_vector(9 downto 0);
    signal pos_x_pom_next, pos_x_pom : std_logic_vector(10 downto 0);
    signal pos_y_pom_next, pos_y_pom : std_logic_vector(9 downto 0);

    --signal count, count_next : std_logic_vector(26 downto 0); --!!!!!!!!!!!!!!!!!!!!!!!***********    

begin
    --hlavny stavovy automat
    --sekvencna cast:
    process(clk, rst)
    begin
        if rst = '1' then
            present_state  <= idle_rst;
            btn_l_next     <= '0';
            btn_r_next     <= '0';
            btn_m_next     <= '0';
            x_data_next    <= (others => '0');
            y_data_next    <= (others => '0');
            x_pretec_next  <= '0';
            y_pretec_next  <= '0';
            pos_x_next     <= (others => '0');
            pos_y_next     <= (others => '0');
            pos_x_pom_next <= "01001111111"; ---stred obraovky pix 639
            pos_y_pom_next <= "0111111111"; ---stred obraovky pix 511
            --count <= (others => '1');---!!!!!!!!!!!!!!!!!!!!!!!!!*************
        elsif (clk'event and clk = '1') then
            present_state  <= next_state;
            btn_l_next     <= btn_l;
            btn_r_next     <= btn_r;
            btn_m_next     <= btn_m;
            x_data_next    <= x_data;
            y_data_next    <= y_data;
            x_pretec_next  <= x_pretec;
            y_pretec_next  <= y_pretec;
            pos_x_next     <= pos_x;
            pos_y_next     <= pos_y;
            pos_x_pom_next <= pos_x_pom;
            pos_y_pom_next <= pos_y_pom;
            --count <= count_next;---!!!!!!!!!!!!!!!!!!!!!!!!!*************
        end if;
    end process;

    --kombinacna_cast:
    process(present_state, tx_done_en, rx_done_en, btn_l_next, btn_r_next, btn_m_next, x_data_next, y_data_next, x_pretec_next, y_pretec_next, pos_x_next, pos_y_next, rx_data, pos_x_pom_next, pos_y_pom_next)
    begin
        next_state   <= present_state;
        tx_en        <= '0';
        rx_en        <= '0';
        num_to_mouse <= (others => '0');
        position_x   <= pos_x_pom_next;
        position_y   <= pos_y_pom_next;
        button_l     <= '0';
        button_r     <= '0';
        button_m     <= '0';
        btn_l        <= btn_l_next;
        btn_r        <= btn_r_next;
        btn_m        <= btn_m_next;
        x_data       <= x_data_next;
        y_data       <= y_data_next;
        x_pretec     <= x_pretec_next;
        y_pretec     <= y_pretec_next;
        pos_x        <= pos_x_next;
        pos_y        <= pos_y_next;
        pos_x_pom    <= pos_x_pom_next;
        pos_y_pom    <= pos_y_pom_next;
        --count_next <= count;---!!!!!!!!!!!!!!!!!!!!!!!!!*************
        case present_state is
            when idle_rst =>
                tx_en        <= '1';
                num_to_mouse <= "11111111"; --poslat FF pre reset mouse
                if (tx_done_en = '1') then
                    next_state <= ack_ff;
                end if;

            when ack_ff =>
                rx_en <= '1';
                if (rx_done_en = '1') then
                    if (rx_data = "11111010") then --ak odpoved je ack cize FA
                        next_state <= slf_test;
                    else
                        next_state <= idle_rst;
                    end if;
                end if;

            when slf_test =>
                rx_en <= '1';
                if (rx_done_en = '1') then
                    if (rx_data = "10101010") then --Self-test passed cize posle AA
                        next_state <= id_mouse;
                    else
                        next_state <= idle_rst;
                    end if;
                end if;

            when id_mouse =>
                rx_en <= '1';
                if (rx_done_en = '1') then
                    if (rx_data = "00000000") then -- mouse device id - 00 
                        next_state <= stream_md;
                    else
                        next_state <= idle_rst;
                    end if;
                end if;

            when stream_md =>
                tx_en        <= '1';
                num_to_mouse <= "11110100"; --poslat FE to enable stream mode
                if (tx_done_en = '1') then
                    next_state <= ack_ff2;
                end if;

            when ack_ff2 =>
                rx_en <= '1';
                if (rx_done_en = '1') then
                    if (rx_data = "11111010") then --ak odpoved je ack cize FA
                        next_state <= pack1;
                    else
                        next_state <= idle_rst;
                    end if;
                end if;

            when pack1 =>
                rx_en <= '1';
                if (rx_done_en = '1') then
                    --count_next <= (others => '1');---!!!!!!!!!!!!!!!!!!!!!!!!!*************
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
                    --else
                    --  pos_x <= pos_x_next + x_data(7 downto 0);
                end if;

            when decod_y =>
                if (y_pretec = '1') then
                    if (y_data(8) = '1') then
                        pos_y <= (others => '0');
                    else
                        pos_y <= (others => '1');
                    end if;
                    --else
                    --  pos_y <= y_data(7 downto 0);
                end if;

            when done =>
                position_x <= pos_x_next;
                position_y <= pos_y_next;
                pos_x_pom  <= pos_x_next;
                pos_y_pom  <= pos_y_next;
                button_l   <= btn_l_next;
                button_r   <= btn_r_next;
                button_m   <= btn_m_next;
                --if (unsigned(count) > 0) then
                --count_next <= std_logic_vector((unsigned(count)) - 1); --!!!!!!!!!*********
                --else
                next_state <= pack1;
            --end if;

            when others =>
                next_state <= idle_rst;
        end case;
    end process;

end Behavioral;
