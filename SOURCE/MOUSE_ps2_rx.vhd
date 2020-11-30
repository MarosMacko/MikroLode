library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ps2_rx is
    Port(clk, rst        : in  STD_LOGIC;
         ps2d, ps2c_fall : in  STD_LOGIC;
         rx_en           : in  STD_LOGIC;
         rx_done_en      : out STD_LOGIC;
         kb_code_en      : out STD_LOGIC;
         ps2d_data       : out STD_LOGIC_VECTOR(7 downto 0));
end ps2_rx;

architecture Behavioral of ps2_rx is
    type state_type is (idle, start, shift, parity, load);
    signal next_state, present_state : state_type;
    signal poc_8b                    : std_logic_vector(3 downto 0);
    signal poc_8b_next               : std_logic_vector(3 downto 0);
    signal pom_data                  : std_logic_vector(7 downto 0);
    signal pom_data_next             : std_logic_vector(7 downto 0);
    signal vysl_data                 : std_logic_vector(7 downto 0);
    signal kb_en_pom                 : std_logic;

begin
    --SYNC_PROC:
    process(clk, rst)
    begin
        if rst = '1' then
            present_state <= idle;
            kb_code_en    <= '0';
            ps2d_data     <= (others => '0');
            poc_8b        <= (others => '0');
            pom_data      <= (others => '0');
        elsif (clk'event and clk = '1') then
            present_state <= next_state;
            kb_code_en    <= kb_en_pom;
            ps2d_data     <= vysl_data;
            poc_8b        <= poc_8b_next;
            pom_data      <= pom_data_next;
        end if;
    end process;

    --OUTPUT_DECODE:
    process(present_state, ps2c_fall, ps2d, pom_data_next)
    begin
        if (present_state = load and ps2d = '1' and ps2c_fall = '1') then
            kb_en_pom <= '1';
            vysl_data <= pom_data_next;
        else
            kb_en_pom <= '0';
            vysl_data <= pom_data_next;
        end if;
    end process;

    --NEXT_STATE_DECODE:
    process(present_state, ps2c_fall, ps2d, poc_8b, pom_data, rx_en)
    begin
        next_state    <= present_state;
        poc_8b_next   <= poc_8b;
        pom_data_next <= pom_data;
        case present_state is
            when idle =>
                if (rx_en = '1') then
                    next_state <= start;
                end if;
            when start =>
                if (ps2c_fall = '1') then --caka na sestupnu hranu
                    if (ps2d = '0') then --ak start bit je 0
                        poc_8b_next   <= (others => '0');
                        pom_data_next <= (others => '0');
                        next_state    <= shift;
                    end if;
                end if;
            when shift =>
                if (ps2c_fall = '1') then
                    if (unsigned(poc_8b) < 8) then
                        poc_8b_next   <= std_logic_vector((unsigned(poc_8b)) + 1);
                        pom_data_next <= ps2d & pom_data(7 downto 1);
                        next_state    <= shift;
                    else
                        next_state <= parity;
                    end if;
                end if;
            when parity =>
                next_state <= load;
            when load =>
                if (ps2c_fall = '1') then
                    next_state <= idle;
                end if;
            when others =>
                next_state <= idle;
        end case;
    end process;

end Behavioral;
