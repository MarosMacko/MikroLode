
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ps2_tx is
    Port(ps2c_fall, ps2d_out : in  STD_LOGIC;
         clk, rst            : in  STD_LOGIC;
         num_to_mouse        : in  std_logic_vector(7 downto 0);
         tx_en               : in  STD_LOGIC;
         ps2c_t_en, ps2c_in  : out STD_LOGIC;
         ps2d_t_en, ps2d_in  : out STD_LOGIC;
         tx_done_en          : out STD_LOGIC);
end ps2_tx;

architecture Behavioral of ps2_tx is
    --deklarace stavoveho typu
    type state_type is (idle, rts, start, data, control, stop);

    --definice stavoveho signalu
    signal next_state, present_state : state_type;

    --definice vnutornych citacov
    signal cnt_100u, cnt_100u_next : std_logic_vector(12 downto 0); --counter pre 100us '0' na ps2c od FPGA aj s rezervou =>164us => 13bit
    signal cnt_8dat, cnt_8dat_next : std_logic_vector(3 downto 0); --counter pre posielanie 8bitov + parita

    --pomocne signaly => synchronni design
    signal tx_done_en_pom             : std_logic;
    signal ps2c_t_en_pom, ps2c_in_pom : std_logic;
    signal ps2d_t_en_pom, ps2d_in_pom : std_logic;

    signal write_data, write_data_pom : std_logic_vector(8 downto 0);
    signal par                        : std_logic;

begin
    --pamatova_cast:
    process(clk, rst)
    begin
        if rst = '1' then
            present_state <= idle;
            tx_done_en    <= '0';
            ps2c_t_en     <= '1';
            ps2c_in       <= '1';
            ps2d_t_en     <= '1';
            ps2d_in       <= '1';
            cnt_100u      <= (others => '0');
            cnt_8dat      <= (others => '0');
            write_data    <= (others => '0');
        elsif (clk'event and clk = '1') then
            present_state <= next_state;
            tx_done_en    <= tx_done_en_pom;
            ps2c_t_en     <= ps2c_t_en_pom;
            ps2c_in       <= ps2c_in_pom;
            ps2d_t_en     <= ps2d_t_en_pom;
            ps2d_in       <= ps2d_in_pom;
            cnt_100u      <= cnt_100u_next;
            cnt_8dat      <= cnt_8dat_next;
            write_data    <= write_data_pom;
        end if;
    end process;

    --licha parita
    par <= not (num_to_mouse(7) xor num_to_mouse(6) xor num_to_mouse(5) xor num_to_mouse(4) xor num_to_mouse(3) xor num_to_mouse(2) xor num_to_mouse(1) xor num_to_mouse(0));

    --kombinacna_cast:
    process(present_state, cnt_100u, cnt_8dat, write_data, num_to_mouse, par, ps2c_fall, ps2d_out, tx_en)
    begin
        next_state     <= present_state;
        cnt_100u_next  <= cnt_100u;
        cnt_8dat_next  <= cnt_8dat;
        write_data_pom <= write_data;
        tx_done_en_pom <= '0';
        ps2c_t_en_pom  <= '1';          --ps2c = 'Z'
        ps2c_in_pom    <= '1';          --lebo 0 znamena vyziadanie posielat data myske
        ps2d_t_en_pom  <= '1';          --ps2d = 'Z'
        ps2d_in_pom    <= '1';          --lebo start bit 0

        case present_state is
            when idle =>
                cnt_100u_next  <= (others => '1'); --164us
                cnt_8dat_next  <= "1000"; --priradenie cisla 8
                write_data_pom <= par & num_to_mouse; --pridanie parity
                if (tx_en = '1') then
                    next_state <= rts;
                end if;

            when rts =>
                ps2c_in_pom   <= '0';
                ps2c_t_en_pom <= '0';
                cnt_100u_next <= std_logic_vector((unsigned(cnt_100u)) - 1);
                if ((unsigned(cnt_100u) = 0)) then
                    next_state <= start;
                end if;

            when start =>
                ps2d_t_en_pom <= '0';
                ps2d_in_pom   <= '0';
                if (ps2c_fall = '1') then
                    next_state <= data;
                end if;

            when data =>
                ps2d_in_pom   <= write_data(0);
                ps2d_t_en_pom <= '0';
                if (ps2c_fall = '1') then
                    if ((unsigned(cnt_8dat) > 0)) then
                        write_data_pom <= '0' & write_data(8 downto 1);
                        cnt_8dat_next  <= std_logic_vector((unsigned(cnt_8dat)) - 1);
                    else
                        next_state <= control;
                    end if;
                end if;

            when control =>
                if (ps2c_fall = '1') then
                    if (ps2d_out = '0') then
                        next_state <= stop;
                    else
                        next_state <= rts;
                    end if;
                end if;

            when stop =>
                tx_done_en_pom <= '1';
                next_state     <= idle;

            when others =>
                next_state <= idle;
        end case;
    end process;

end Behavioral;
