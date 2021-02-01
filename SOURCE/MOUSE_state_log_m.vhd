library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity state_log_m is
    Port(clk, rst                        : in  STD_LOGIC;
         tx_done_en, rx_done_en          : in  STD_LOGIC;
         rx_data                         : in  STD_LOGIC_VECTOR(7 downto 0);
         tx_en, rx_en, CE_rdy            : out STD_LOGIC;
         num_to_mouse                    : out STD_LOGIC_VECTOR(7 downto 0);
         btn_l_out, btn_r_out, btn_m_out : out STD_LOGIC;
         x_data_out                      : out STD_LOGIC_VECTOR(8 downto 0);
         y_data_out                      : out STD_LOGIC_VECTOR(8 downto 0));
end state_log_m;

architecture Behavioral of state_log_m is
    type state_type is (idle_rst, ack_ff, slf_test, id_mouse, stream_md, pack1, pack2, pack3, ack_ff2, decod_x, decod_y, done);
    signal next_state, present_state : state_type;

    signal btn_l_next, btn_l   : std_logic;
    signal btn_r_next, btn_r   : std_logic;
    signal btn_m_next, btn_m   : std_logic;
    signal x_data_next, x_data : std_logic_vector(8 downto 0);
    signal y_data_next, y_data : std_logic_vector(8 downto 0);

begin
    --hlavny stavovy automat
    --sekvencna cast:
    process(clk, rst)
    begin
        if rst = '1' then
            present_state <= idle_rst;
            btn_l_next    <= '0';
            btn_r_next    <= '0';
            btn_m_next    <= '0';
            x_data_next   <= (others => '0');
            y_data_next   <= (others => '0');
        elsif (clk'event and clk = '1') then
            present_state <= next_state;
            btn_l_next    <= btn_l;
            btn_r_next    <= btn_r;
            btn_m_next    <= btn_m;
            x_data_next   <= x_data;
            y_data_next   <= y_data;
        end if;
    end process;

    --kombinacna_cast:
    process(present_state, tx_done_en, rx_done_en, rx_data, btn_l_next, btn_r_next, btn_m_next, x_data_next, y_data_next)
    begin
        next_state   <= present_state;
        tx_en        <= '0';
        rx_en        <= '0';
        num_to_mouse <= (others => '0');
        btn_l        <= btn_l_next;
        btn_r        <= btn_r_next;
        btn_m        <= btn_m_next;
        x_data       <= x_data_next;
        y_data       <= y_data_next;
        CE_rdy       <= '0';
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
                    end if;
                end if;

            when slf_test =>
                rx_en <= '1';
                if (rx_done_en = '1') then
                    if (rx_data = "10101010") then --Self-test passed cize posle AA
                        next_state <= id_mouse;
                    end if;
                end if;

            when id_mouse =>
                rx_en <= '1';
                if (rx_done_en = '1') then
                    if (rx_data = "00000000") then -- mouse device id - 00 
                        next_state <= stream_md;
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
                    end if;
                end if;

            when pack1 =>
                rx_en <= '1';
                if (rx_done_en = '1') then
                    btn_l      <= rx_data(0);
                    btn_r      <= rx_data(1);
                    btn_m      <= rx_data(2);
                    x_data(8)  <= rx_data(4);
                    y_data(8)  <= rx_data(5);
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

            when done =>
                CE_rdy     <= '1';
                next_state <= pack1;

            when others =>
                next_state <= idle_rst;
        end case;
    end process;

    x_data_out <= x_data;
    y_data_out <= y_data;
    btn_l_out  <= btn_l;
    btn_r_out  <= btn_r;
    btn_m_out  <= btn_m;

end Behavioral;
