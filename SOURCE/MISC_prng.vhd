library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity MISC_prng is
    Port(clk, rst      : in  STD_LOGIC;
         random_output : out STD_LOGIC_VECTOR(31 downto 0));
end MISC_prng;

architecture Behavioral of MISC_prng is

    signal counter, counter_n : std_logic_vector(31 downto 0) := (others => '0');

begin

    process(clk, rst)
    begin
        if (rst = '1') then
            counter <= (others => '0');
        elsif (rising_edge(clk)) then
            counter <= counter_n;
        end if;
    end process;

    counter_n     <= std_logic_vector(unsigned(counter) + 1);
    random_output <= counter;

end Behavioral;
