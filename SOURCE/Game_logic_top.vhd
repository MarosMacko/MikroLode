----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    09:24:53 11/09/2020 
-- Design Name: 
-- Module Name:    Game_logic_top - Behavioral 
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

entity Game_logic_top is
	Port(pos_x                                      : in  STD_LOGIC_VECTOR(10 downto 0);
	     pos_y                                      : in  STD_LOGIC_VECTOR(9 downto 0);
	     button_r, button_l, scroll_up, scroll_down : in  STD_LOGIC;
	     clk                                        : in  STD_LOGIC;
	     rst                                        : in  STD_LOGIC;
	     turn                                       : in  STD_LOGIC;
	     miss_in, hit_in                            : in  STD_LOGIC;
	     game_type_real                             : in  STD_LOGIC;
	     shoot_position_in                          : in  STD_LOGIC_VECTOR(8 downto 0);
	     shoot_position_out                         : out STD_LOGIC_VECTOR(8 downto 0);
	     hit_out, miss_out                          : out STD_LOGIC;
	     game_type_want                             : out STD_LOGIC;
	     re_A, we_A                                 : out STD_LOGIC;
	     data_read_ram                              : in  STD_LOGIC_VECTOR(8 downto 0);
	     data_write_ram                             : out STD_LOGIC_VECTOR(8 downto 0);
	     addr_A                                     : out STD_LOGIC_VECTOR(10 downto 0));

end Game_logic_top;

architecture Behavioral of Game_logic_top is

	constant quick_game_left_boundary_x  : natural := 200;
	constant quick_game_left_boundary_y  : natural := 200;
	constant quick_game_right_boundary_x : natural := 400;
	constant quick_game_right_boundary_y : natural := 400;

	constant normal_game_left_boundary_x  : natural := 400;
	constant normal_game_left_boundary_y  : natural := 200;
	constant normal_game_right_boundary_x : natural := 600;
	constant normal_game_right_boundary_y : natural := 400;

	type stav is (init, start, placement, wait_4_player, my_turn, his_turn, ask,
	              hit_1_anim, miss_1_anim, hit_2_anim, miss_2_anim, game_over_win, game_over_lose);
	signal game_state, game_state_n : stav := init;

begin
	process(clk, rst)
	begin
		if (rst = '1') then
			game_state <= init;
		elsif (rising_edge(clk)) then
			game_state <= game_state_n;
		end if;
	end process;

	process(button_l, game_state, pos_x, pos_y)
	begin
		game_state_n <= game_state;
		case (game_state) is
			when init =>
				game_state_n <= start;
			when start =>
				if (button_l = '1') then
					if		((unsigned(pos_x) > quick_game_left_boundary_x)
						and (unsigned(pos_x) < quick_game_right_boundary_x)
						and (unsigned(pos_y) > quick_game_left_boundary_y)
						and (unsigned(pos_y) < quick_game_right_boundary_y))
					then
						game_state_n   <= placement;
						game_type_want <= '1';
					elsif	((unsigned(pos_x) > normal_game_left_boundary_x)
						and (unsigned(pos_x) < normal_game_right_boundary_x)
						and (unsigned(pos_y) > normal_game_left_boundary_y)
						and (unsigned(pos_y) < normal_game_right_boundary_y))
					 then
						game_state_n   <= placement;
						game_type_want <= '0';
					end if;
				end if;
			when placement =>
			when wait_4_player =>
			when my_turn =>
			when his_turn =>
			when ask =>
			when hit_1_anim =>
			when miss_1_anim =>
			when hit_2_anim =>
			when miss_2_anim =>
			when game_over_win =>
			when game_over_lose =>
			when others =>
		end case;
	end process;


end Behavioral;

