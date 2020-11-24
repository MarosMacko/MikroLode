library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity debouncer is
    Port(clk, ps2c : in  STD_LOGIC;
         ps2c_deb  : out STD_LOGIC);
end debouncer;

architecture Behavioral of debouncer is
    signal ps2c_pom : std_logic_vector(63 downto 0);

begin
    process(clk)
    begin
        if (clk'event and clk = '1') then
            ps2c_pom <= ps2c & ps2c_pom(63 downto 1);
        end if;
    end process;

    ps2c_deb <= '0' when unsigned(ps2c_pom) = 0 else '1';

end Behavioral;
