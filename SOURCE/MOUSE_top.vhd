----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    03:43:10 11/11/2020 
-- Design Name: 
-- Module Name:    MOUSE_top - Behavioral 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity MOUSE_top is
    Port ( ps2_clock_pin : inout  STD_LOGIC;
           ps2_data_pin : inout  STD_LOGIC;
           clk : in  STD_LOGIC;
           position_x : out  STD_LOGIC_VECTOR (10 downto 0);
           position_y : out  STD_LOGIC_VECTOR (9 downto 0);
           button_l : out  STD_LOGIC;
           button_r : out  STD_LOGIC;
           scroll_up : out  STD_LOGIC;
           scroll_down : out  STD_LOGIC);
end MOUSE_top;

architecture Behavioral of MOUSE_top is
	signal IN_SIG_cl, OUT_SIG_cl, T_ENABLE_cl: std_logic;
	signal IN_SIG_dat, OUT_SIG_dat, T_ENABLE_dat: std_logic;
	
	
	component IOBUF
		port (I, T: in std_logic;
				O: out std_logic;
				IO: inout std_logic);
	end component;

begin


end Behavioral;