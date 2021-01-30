----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:23:26 01/30/2021 
-- Design Name: 
-- Module Name:    MOUSE_cooldown - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity MOUSE_cooldown is
    Port ( clk, rst : in  STD_LOGIC;
           button_l_in, button_m_in, button_r_in : in  STD_LOGIC;
           button_l_CE, button_m_CE, button_r_CE : out  STD_LOGIC);
end MOUSE_cooldown;

architecture Behavioral of MOUSE_cooldown is
	
	type stav is (trigger, cooldown);
	signal state, state_n : stav;
	signal counter, counter_n : STD_LOGIC_VECTOR (23 downto 0);

begin
	process(clk, rst)
	begin
		if rst = '1' then
			counter <= (others => '0');
			state <= trigger;
		elsif rising_edge(clk) then
			counter <= counter_n;
			state <= state_n;
		end if;
	end process;

	process(button_l_in, button_m_in, button_r_in, counter, state)
	begin
		counter_n <= counter;
		state_n <= state;
		button_l_CE <= '0';
		button_m_CE <= '0';
		button_r_CE <= '0';
		case (state) is
		when trigger =>
			if (button_l_in = '1') or (button_m_in = '1') or (button_r_in = '1') then
				button_l_CE <= button_l_in; button_m_CE <= button_m_in; button_r_CE <= button_r_in;
				state_n <= cooldown;
				counter_n <= (others => '0');
			end if;
		when cooldown =>
			if counter = (0 to counter'length-1 => '1') then
				state_n <= trigger;
			else
				counter_n <= std_logic_vector(unsigned(counter) + 1);
			end if;
		end case;
	end process;

end Behavioral;

