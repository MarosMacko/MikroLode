----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity TOP is
	Port(clk                 : in    STD_LOGIC;
	     ps2_clock_pin       : inout STD_LOGIC;
	     ps2_data_pin        : inout STD_LOGIC;
	     uart_tx             : out   STD_LOGIC;
	     uart_rx             : in    STD_LOGIC;
	     vga_R, vga_G, vga_B : out   STD_LOGIC_VECTOR(6 downto 0);
	     vga_VS, vga_HS      : out   STD_LOGIC;
	     audio_out           : out   STD_LOGIC_VECTOR(7 downto 0);
	     buzzer              : out   STD_LOGIC);
end TOP;

architecture Behavioral of TOP is

begin

end Behavioral;

