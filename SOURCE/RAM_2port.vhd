library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity RAM_2port is
    port(
        clk_GL, clk_VGA : in  STD_LOGIC;
        we              : in  STD_LOGIC;
        addr_GL         : in  STD_LOGIC_VECTOR(10 downto 0);
        addr_VGA        : in  STD_LOGIC_VECTOR(10 downto 0);
        data_in         : in  STD_LOGIC_VECTOR(8 downto 0);
        data_out_GL     : out STD_LOGIC_VECTOR(8 downto 0);
        data_out_VGA    : out STD_LOGIC_VECTOR(8 downto 0)
    );
end RAM_2port;

architecture Behavioral of RAM_2port is

    type RAM_t is array (0 to 2047) of std_logic_vector(8 downto 0);
    signal ram : RAM_t;

begin

    process(clk_GL)
    begin
        if (rising_edge(clk_GL)) then
            if (we = '1') then
                ram(to_integer(unsigned(addr_GL))) <= data_in;
            end if;
            data_out_GL <= ram(to_integer(unsigned(addr_GL)));
        end if;
    end process;

    process(clk_VGA)
    begin
        if (rising_edge(clk_VGA)) then
            data_out_VGA <= ram(to_integer(unsigned(addr_VGA)));
        end if;
    end process;

end Behavioral;

