----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    11:03:59 11/17/2020 
-- Design Name: 
-- Module Name:    ps2_tx - Behavioral 
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
--library UNISIM;
--use UNISIM.VComponents.all;

entity ps2_tx is
	Port(ps2c_fall, ps2d_out : in  STD_LOGIC;
	     clk, rst            : in  STD_LOGIC;
	     num_to_mouse        : in  std_logic_vector(7 downto 0);
	     ps2c_t_en, ps2c_in  : out STD_LOGIC;
	     ps2d_t_en, ps2d_in  : out STD_LOGIC;
	     tx_done_en          : out STD_LOGIC;
	     tx_en               : in  STD_LOGIC);
end ps2_tx;

architecture Behavioral of ps2_tx is

begin

end Behavioral;

