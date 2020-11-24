library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity detec_falling_endge is
    Port(ps2c_deb, clk, rst : in  STD_LOGIC;
         ps2c_fall          : out STD_LOGIC);
end detec_falling_endge;

architecture Behavioral of detec_falling_endge is
    signal q_xor   : std_logic;
    signal q_out   : std_logic;
    signal d_and   : std_logic;
    signal m       : std_logic;
    signal inv_out : std_logic;

begin
    --sekvencna cast
    process(ps2c_deb, clk, rst)
    begin
        if rst = '1' then
            q_xor <= '0';
            q_out <= '0';
        elsif (clk'event and clk = '1') then
            q_xor <= ps2c_deb;
            q_out <= d_and;
        end if;
    end process;

    --kombinacna cast
    m         <= q_xor xor ps2c_deb;
    inv_out   <= not ps2c_deb;
    d_and     <= m and inv_out;
    ps2c_fall <= q_out;

end Behavioral;
