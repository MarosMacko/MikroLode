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
	Port(pos_x                                            : in  STD_LOGIC_VECTOR(10 downto 0);
	     pos_y                                            : in  STD_LOGIC_VECTOR(9 downto 0);
	     button_r_ce, button_l_ce, scroll_up, scroll_down : in  STD_LOGIC;
	     clk                                              : in  STD_LOGIC;
	     rst                                              : in  STD_LOGIC;
	     turn                                             : in  STD_LOGIC;
	     miss_in, hit_in                                  : in  STD_LOGIC;
	     game_type_real                                   : in  STD_LOGIC;
	     shoot_position_in                                : in  STD_LOGIC_VECTOR(8 downto 0);
	     shoot_position_out                               : out STD_LOGIC_VECTOR(8 downto 0);
	     hit_out, miss_out                                : out STD_LOGIC;
	     game_type_want                                   : out STD_LOGIC;
	     data_read_ram                                    : in  STD_LOGIC_VECTOR(8 downto 0);
	     data_write_ram                                   : out STD_LOGIC_VECTOR(8 downto 0);
	     we_A                                             : out STD_LOGIC;
	     addr_A                                           : out STD_LOGIC_VECTOR(10 downto 0));

end Game_logic_top;

architecture Behavioral of Game_logic_top is

	constant c_quick_game_left_boundary_x  : natural := 200;
	constant c_quick_game_left_boundary_y  : natural := 200;
	constant c_quick_game_right_boundary_x : natural := 400;
	constant c_quick_game_right_boundary_y : natural := 400;

	constant c_normal_game_left_boundary_x  : natural := 400;
	constant c_normal_game_left_boundary_y  : natural := 200;
	constant c_normal_game_right_boundary_x : natural := 600;
	constant c_normal_game_right_boundary_y : natural := 400;

	constant c_number_of_ships : natural := 9;

	type stav is (init, start, placement, validate, val_check, rem_flags, val_draw, place, my_turn, his_turn, ask,
	              hit_1_anim, miss_1_anim, hit_2_anim, miss_2_anim, game_over_win, game_over_lose);
	signal game_state, game_state_n : stav := init;
	signal counter, counter_n : STD_LOGIC_VECTOR(20 downto 0) := (others => '0');
	signal ship_counter, ship_counter_n : STD_LOGIC_VECTOR(4 downto 0);
	signal button_l_reg : STD_LOGIC;
	signal margin_x, margin_x_n, margin_y, margin_y_n : std_logic_vector(3 downto 0);
	signal mem_reg, mem_reg_n : std_logic_vector(8 downto 0);
	signal ship_type, ship_type_n : std_logic_vector(3 downto 0);
	signal byte_read, byte_read_n : STD_LOGIC;

begin
	process(clk, rst)
	begin
		if (rst = '1') then
			game_state <= init;
			counter <= (others => '0');
			ship_counter <= (others => '0');
			ship_type <= (others => '0');
			margin_y <= (others => '0');
			margin_x <= (others => '0');
			mem_reg <= (others => '0');
			byte_read <= '0';
		elsif (rising_edge(clk)) then
			game_state <= game_state_n;
			counter <= counter_n;
			ship_counter <= ship_counter_n;
			ship_type <= ship_type_n;
			margin_y <= margin_y_n;
			margin_x <= margin_x_n;
			mem_reg <= mem_reg_n;
			byte_read <= byte_read_n;
		end if;
	end process;

	process(button_l_ce, game_state, pos_x, pos_y, counter, turn, margin_x, margin_y, ship_counter, ship_type, byte_read, data_read_ram, mem_reg)
	begin
		game_state_n <= game_state;
		counter_n <= counter;
		ship_counter_n <= ship_counter;
		ship_type_n <= ship_type;
		margin_y_n <= margin_y;
		margin_x_n <= margin_x;
		mem_reg_n <= mem_reg;
		byte_read_n <= byte_read;
		case (game_state) is
			when init =>
				game_state_n <= start;
			when start =>
				if (button_l_ce = '1') then
					if		((unsigned(pos_x) > c_quick_game_left_boundary_x)
						and (unsigned(pos_x) < c_quick_game_right_boundary_x)
						and (unsigned(pos_y) > c_quick_game_left_boundary_y)
						and (unsigned(pos_y) < c_quick_game_right_boundary_y))
					then
						game_state_n   <= placement;
						game_type_want <= '1';
					elsif	((unsigned(pos_x) > c_normal_game_left_boundary_x)
						and (unsigned(pos_x) < c_normal_game_right_boundary_x)
						and (unsigned(pos_y) > c_normal_game_left_boundary_y)
						and (unsigned(pos_y) < c_normal_game_right_boundary_y))
					 then
						game_state_n   <= placement;
						game_type_want <= '0';
					end if;
				end if;
			when placement =>
				if (unsigned(ship_counter) = c_number_of_ships) then
					if (turn = '1') then
						game_state_n <= my_turn;
					else
						game_state_n <= his_turn;
					end if;
				end if;
				if (shift_right(unsigned(pos_x), 6) < 20) and (shift_right(unsigned(pos_y), 6) < 14) then
					game_state_n <= validate;
				end if;
			when validate =>
				counter_n <= std_logic_vector(unsigned(counter) + 1);
				if (unsigned(counter) = 2000) or (button_l_ce = '1') then
					if (button_l_ce = '1') then
						button_l_reg <= '1';
					end if;
					case ship_type is
						when "0000" => margin_x_n <= std_logic_vector(to_unsigned(3, margin_x_n'length)); margin_y_n <= std_logic_vector(to_unsigned(3, margin_y_n'length));
						when "0001" => margin_x_n <= std_logic_vector(to_unsigned(4, margin_x_n'length)); margin_y_n <= std_logic_vector(to_unsigned(0, margin_y_n'length));
						when "0010" => margin_x_n <= std_logic_vector(to_unsigned(0, margin_x_n'length)); margin_y_n <= std_logic_vector(to_unsigned(4, margin_y_n'length));
						when "0011" => margin_x_n <= std_logic_vector(to_unsigned(3, margin_x_n'length)); margin_y_n <= std_logic_vector(to_unsigned(0, margin_y_n'length));
						when "0100" => margin_x_n <= std_logic_vector(to_unsigned(0, margin_x_n'length)); margin_y_n <= std_logic_vector(to_unsigned(3, margin_y_n'length));
						when "0101" => margin_x_n <= std_logic_vector(to_unsigned(2, margin_x_n'length)); margin_y_n <= std_logic_vector(to_unsigned(0, margin_y_n'length));
						when "0110" => margin_x_n <= std_logic_vector(to_unsigned(0, margin_x_n'length)); margin_y_n <= std_logic_vector(to_unsigned(2, margin_y_n'length));
						when "0111" => margin_x_n <= std_logic_vector(to_unsigned(1, margin_x_n'length)); margin_y_n <= std_logic_vector(to_unsigned(0, margin_y_n'length));
						when "1000" => margin_x_n <= std_logic_vector(to_unsigned(0, margin_x_n'length)); margin_y_n <= std_logic_vector(to_unsigned(1, margin_y_n'length));
						when others => margin_x_n <= std_logic_vector(to_unsigned(0, margin_x_n'length)); margin_y_n <= std_logic_vector(to_unsigned(0, margin_y_n'length));
					end case;
					game_state_n <= val_check;
				end if;
			when val_check =>
				if ((unsigned(pos_x) + unsigned(margin_x)) > 20) or ((unsigned(pos_y) + unsigned(margin_y)) > 14) then
					game_state_n <= validate;
				else
					game_state_n <= rem_flags;
					counter_n <= std_logic_vector(to_unsigned(20*14, counter'length));
				end if;
			when rem_flags =>
				if byte_read = '1' then
					counter_n <= std_logic_vector(unsigned(counter) + 1);
					addr_A <= std_logic_vector(to_unsigned(280, addr_A'length) + unsigned(counter(addr_A'length-1 downto 0)));
					mem_reg_n <= data_read_ram;
				else
					addr_A <= std_logic_vector(to_unsigned(0, addr_A'length) + unsigned(counter(addr_A'length-1 downto 0)));
					data_write_ram <= mem_reg and "001111111";
				end if;
				if (unsigned(counter) = 280) then
					game_state_n <= val_draw;
				end if;
				
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
