library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MISC_prng is
    Port(clk_rng, clk_sync, rst : in  STD_LOGIC;
         random_output          : out STD_LOGIC_VECTOR(15 downto 0));
end MISC_prng;

architecture Behavioral of MISC_prng is
    signal counter, counter_n, out_prep, out_prep_n, out_meta, out_stable : std_logic_vector(15 downto 0) := (others => '0');

    attribute keep : boolean;
    --attribute keep of out_prep : signal is true;
    attribute keep of out_meta : signal is true;
    attribute keep of out_stable : signal is true;
begin

    rng_seq : process(clk_rng, rst)
    begin
        if (rst = '1') then
            counter  <= (others => '0');
            out_prep <= (others => '0');
        elsif (rising_edge(clk_rng)) then
            counter  <= counter_n;
            out_prep <= out_prep_n;
        end if;
    end process;

    comb : process(counter)
    begin
        counter_n <= std_logic_vector(unsigned(counter) + 1);
        if (counter(0) = '0') then
            out_prep_n <= (others => '0');
        else
            out_prep_n <= "0" & counter(15 downto 1);
        end if;
    end process;

    output_buf : process(clk_sync)
    begin
        if (rising_edge(clk_sync)) then
            out_meta   <= out_prep;
            out_stable <= out_meta;
        end if;

    end process;

    random_output <= out_stable;

end Behavioral;
