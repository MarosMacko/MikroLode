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
	Port(pos_x                                                  : in  STD_LOGIC_VECTOR(10 downto 0);
	     pos_y                                                  : in  STD_LOGIC_VECTOR(9 downto 0);
	     button_r_ce, button_l_ce, scroll_up_ce, scroll_down_ce : in  STD_LOGIC;
	     clk                                                    : in  STD_LOGIC;
	     rst                                                    : in  STD_LOGIC;
	     turn                                                   : in  STD_LOGIC;
	     miss_in, hit_in                                        : in  STD_LOGIC;
	     game_type_real                                         : in  STD_LOGIC;
	     shoot_position_in                                      : in  STD_LOGIC_VECTOR(8 downto 0);
	     shoot_position_out                                     : out STD_LOGIC_VECTOR(8 downto 0);
	     hit_out, miss_out                                      : out STD_LOGIC;
	     game_type_want                                         : out STD_LOGIC;
	     data_read_ram                                          : in  STD_LOGIC_VECTOR(17 downto 0);
	     data_write_ram                                         : out STD_LOGIC_VECTOR(17 downto 0);
	     we_A                                                   : out STD_LOGIC;
	     addr_A                                                 : out STD_LOGIC_VECTOR(9 downto 0));
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

	constant c_number_of_ships   : natural := 1; -- replace with 9 outside simulation
	constant c_health            : natural := 56;
	constant c_animation_counter : natural := 400;



type ram_data is record
		hit_p1    : STD_LOGIC;
		hit_p2    : STD_LOGIC;
		miss_p1   : STD_LOGIC;
		miss_p2   : STD_LOGIC;
		taken     : STD_LOGIC;
		red       : STD_LOGIC;
		grey      : STD_LOGIC;
		ship      : STD_LOGIC;
		HUD       : STD_LOGIC;
		tile_data : STD_LOGIC_VECTOR(8 downto 0);
end record ram_data;

function pack(arg : ram_data) return std_logic_vector is
		variable result : std_logic_vector(17 downto 0);
	begin
		result(17)         := arg.hit_p1;
		result(16)         := arg.hit_p2;
		result(15)         := arg.miss_p1;
		result(14)         := arg.miss_p2;
		result(13)         := arg.taken;
		result(12)         := arg.red;
		result(11)         := arg.grey;
		result(10)         := arg.ship;
		result(9 )         := arg.HUD;
		result(8 downto 0) := arg.tile_data;
	return result;
end function pack;

function unpack(arg : std_logic_vector(17 downto 0)) return ram_data is
		variable result : ram_data;
	begin
		result.hit_p1    := arg(17);
		result.hit_p2    := arg(16);
		result.miss_p1   := arg(15);
		result.miss_p2   := arg(14);
		result.taken     := arg(13);
		result.red       := arg(12);
		result.grey      := arg(11);
		result.ship      := arg(10);
		result.HUD       := arg(9 );
		result.tile_data := arg(8 downto 0);
	return result;
end function unpack;

	signal data_ram : ram_data;

	type stav is (init, start_init, start, RAM_init, placement, validate, val_check, rem_flags, val_draw, place, set_taken_flags, wait_4_player,  my_turn, his_turn, ask,
	              hit_1_anim, miss_1_anim, hit_2_anim, miss_2_anim, game_over_win, game_over_lose);
	signal game_state, game_state_n                   : stav                          := init;
	signal counter, counter_n                         : STD_LOGIC_VECTOR(20 downto 0) := (others => '0');
	signal ship_counter, ship_counter_n               : STD_LOGIC_VECTOR(4 downto 0);
	signal enemy_hits_n, enemy_hits                   : STD_LOGIC_VECTOR(5 downto 0);
	signal health_n, health                           : STD_LOGIC_VECTOR(5 downto 0);
	signal button_l_reg, button_l_reg_n               : STD_LOGIC;
	signal margin_x, margin_x_n, margin_y, margin_y_n : std_logic_vector(2 downto 0);
	signal tile_pos_x, tile_pos_y                     : std_logic_vector(4 downto 0);
	signal ship_type, ship_type_n                     : std_logic_vector(3 downto 0);
	signal byte_read, byte_read_n                     : STD_LOGIC;
	signal not_valid, not_valid_n                     : STD_LOGIC;
	
	signal addr_A_reg, addr_A_reg_n                                 : STD_LOGIC_VECTOR(9 downto 0);
	signal shoot_position_out_reg, shoot_position_out_reg_n         : STD_LOGIC_VECTOR(8 downto 0);
	signal game_type_want_reg, game_type_want_reg_n                 : STD_LOGIC;
	signal hit_out_reg, hit_out_reg_n, miss_out_reg, miss_out_reg_n : STD_LOGIC;

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
			byte_read <= '0';
			not_valid <= '0';
			health <= (others => '0');
			enemy_hits <= (others => '0');
			shoot_position_out_reg <= (others => '0');
			addr_A_reg <= (others => '0');
			game_type_want_reg <= '0';
			hit_out_reg <= '0';
			miss_out_reg <= '0';
			button_l_reg <= '0';
		elsif (rising_edge(clk)) then
			game_state <= game_state_n;
			counter <= counter_n;
			ship_counter <= ship_counter_n;
			ship_type <= ship_type_n;
			margin_y <= margin_y_n;
			margin_x <= margin_x_n;
			byte_read <= byte_read_n;
			not_valid <= not_valid_n;
			health <= health_n;
			enemy_hits <= enemy_hits_n;
			shoot_position_out_reg <= shoot_position_out_reg_n;
			addr_A_reg <= addr_A_reg_n;
			game_type_want_reg <= game_type_want_reg_n;
			hit_out_reg <= hit_out_reg_n;
			miss_out_reg <= miss_out_reg_n;
			button_l_reg <= button_l_reg_n;
		end if;
	end process;

	process(button_l_ce, game_state, pos_x, pos_y, counter, turn, margin_x, margin_y, ship_counter, ship_type, byte_read, data_read_ram, button_l_reg, not_valid, tile_pos_x, tile_pos_y, addr_A_reg, data_ram, enemy_hits, game_type_real, health, hit_in, miss_in, shoot_position_out_reg, game_type_want_reg, hit_out_reg, miss_out_reg, shoot_position_in, button_r_ce, scroll_up_ce, scroll_down_ce)
	begin
		game_state_n <= game_state;
		counter_n <= counter;
		ship_counter_n <= ship_counter;
		ship_type_n <= ship_type;
		margin_y_n <= margin_y;
		margin_x_n <= margin_x;
		byte_read_n <= byte_read;
		not_valid_n <= not_valid;
		tile_pos_x <= pos_x(10 downto 6);
		tile_pos_y <= '0' & pos_y(9 downto 6);
		health_n <= health;
		enemy_hits_n <= enemy_hits;
		data_ram <= unpack("00" & x"0000");
		we_A <= '0';
		shoot_position_out_reg_n <= shoot_position_out_reg;
		addr_A_reg_n <= addr_A_reg;
		addr_A <= addr_A_reg;
		shoot_position_out <= shoot_position_out_reg;
		data_write_ram <= (others => '0');
		game_type_want_reg_n <= game_type_want_reg;
		hit_out_reg_n <= hit_out_reg;
		miss_out_reg_n <= miss_out_reg;
		hit_out <= hit_out_reg;
		miss_out <= miss_out_reg;
		game_type_want <= game_type_want_reg;
		button_l_reg_n <= button_l_reg;
		case (game_state) is
			when init =>
				game_state_n <= start_init;
				health_n <= std_logic_vector(to_unsigned(c_health, health'length));
				enemy_hits_n <= std_logic_vector(to_unsigned(c_health, enemy_hits'length));
				ship_counter_n <= std_logic_vector(to_unsigned(c_number_of_ships, ship_counter'length));
				counter_n <= '0' & x"3e140"; --20*16 (tiles + 1 info vector), (19 downto 12) == 62 tiles v mape
				byte_read_n <= '0';
			when start_init =>
				if byte_read = '0' then
					addr_A_reg_n <= std_logic_vector(unsigned(counter(addr_A'length-1 downto 0)));
					byte_read_n <= not byte_read;
				else
					counter_n(11 downto 0) <= std_logic_vector(unsigned(counter(11 downto 0)) - 1);
					we_A <= '1';
					case (to_integer(unsigned(counter(11 downto 0)))) is
					when 0 => --grey + nextstate
						data_ram.tile_data <= '0' & x"78";
						game_state_n <= start;
					when 1 to 19 =>--grey
						data_ram.tile_data <= '0' & x"78";
					when 20 to 38 =>--tiledown
						data_ram.tile_data <= '0' & counter(19 downto 12);
					when 39 =>--last tiledown
						data_ram.tile_data <= '0' & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) + 1);
					when 127 to 132 =>--normalgame
						data_ram.tile_data <= '0' & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) + 1);
					when 167 to 172 =>--quickgame
						data_ram.tile_data <= '0' & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) + 1);
					when 185 to 186 =>--firstsolder
						data_ram.tile_data <= '0' & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) + 1);
					when 193 to 198 =>--firstESD
						data_ram.tile_data <= '0' & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) + 1);
					when 203 to 205 =>--secondsolder
						data_ram.tile_data <= '0' & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) + 1);
					when 212 to 218 =>--secondESD
						data_ram.tile_data <= '0' & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) + 1);
					when 220 to 224 =>--thirdsolder
						data_ram.tile_data <= '0' & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) + 1);
					when 233 to 239 =>--thirdESD
						data_ram.tile_data <= '0' & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) + 1);
					when 240 to 242 =>--fourthsolder
						data_ram.tile_data <= '0' & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) + 1);
					when 256 to 259 =>--fourthESD
						data_ram.tile_data <= '0' & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) + 1);
					when 260 to 262 =>--fifthsolder
						data_ram.tile_data <= '0' & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) + 1);
					when 277 to 279 =>--fifthESD
						data_ram.tile_data <= '0' & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) + 1);
					when 280 to 299 =>--tileup
						data_ram.tile_data <= '0' & counter(19 downto 12);
					when 300 to 319 =>--grey
						data_ram.tile_data <= '0' & x"78";
					when 320 =>--infovector
						data_ram.tile_data <= '0' & x"00";
					when others =>--black
						data_ram.tile_data <= '0' & x"77";
					end case;
					data_ram.HUD <= '1';
					data_write_ram <= pack(data_ram);
					byte_read_n <= not byte_read;
				end if;
			when start =>
				if (button_l_ce = '1') then
					if		((unsigned(pos_x) > c_quick_game_left_boundary_x)
						and (unsigned(pos_x) < c_quick_game_right_boundary_x)
						and (unsigned(pos_y) > c_quick_game_left_boundary_y)
						and (unsigned(pos_y) < c_quick_game_right_boundary_y))
					then
						game_state_n   <= RAM_init;
						counter_n <= std_logic_vector(to_unsigned(20*16-1, counter'length));
						game_type_want_reg_n <= '1';
					elsif	((unsigned(pos_x) > c_normal_game_left_boundary_x)
						and (unsigned(pos_x) < c_normal_game_right_boundary_x)
						and (unsigned(pos_y) > c_normal_game_left_boundary_y)
						and (unsigned(pos_y) < c_normal_game_right_boundary_y))
					 then
						game_state_n   <= RAM_init;
						counter_n <= std_logic_vector(to_unsigned(20*16-1, counter'length));
						game_type_want_reg_n <= '0';
					end if;
				end if;
			when RAM_init =>
				if byte_read = '0' then
					addr_A_reg_n <= std_logic_vector(unsigned(counter(addr_A'length-1 downto 0)));
					byte_read_n <= not byte_read;
				else
					counter_n <= std_logic_vector(unsigned(counter) - 1);
					we_A <= '1';
					if unsigned(counter) > 20*14-1 then
						data_ram.HUD <= '1';
						case (to_integer(unsigned(counter))) is
							-- LOGO FEKT + suciastky bot
						when 319 => data_ram.tile_data <= '0' & x"28";
						when 305 to 318 => data_ram.tile_data <= '0' & std_logic_vector(to_unsigned(to_integer(unsigned(counter)) - 305 + 48, 8));
							-- Pocitadlo zivotov p1
						when 304 => data_ram.tile_data <= '0' & x"06";
						when 303 => data_ram.tile_data <= '0' & x"05";
							-- Koncova suciastka
						when 302 => data_ram.tile_data <= '0' & x"2D";
							-- Tlacidlo p1 bot
						when 301 => data_ram.tile_data <= '0' & x"2A";
						when 300 => data_ram.tile_data <= '0' & x"29";
							-- LOGO FEKT + wait display top
						when 299 => data_ram.tile_data <= '0' & x"27";
						when 288 to 298 => data_ram.tile_data <= '0' & std_logic_vector(to_unsigned(to_integer(unsigned(counter)) - 288 + 20, 8));
							-- Pocitadlo zivotov p2
						when 287 => data_ram.tile_data <= '0' & x"06";
						when 286 => data_ram.tile_data <= '0' & x"05";
							-- "LIVES"
						when 285 => data_ram.tile_data <= '0' & x"11";
						when 284 => data_ram.tile_data <= '0' & x"10";
						when 283 => data_ram.tile_data <= '0' & x"0F";
							-- Koncova suciastka
						when 282 => data_ram.tile_data <= '0' & x"0E";
							-- Tlacidlo p1 top
						when 281 => data_ram.tile_data <= '0' & x"0B";
						when others => data_ram.tile_data <= '0' & x"0A";
						end case;
					else
						data_ram.HUD <= '0';
						data_ram.tile_data <= '0' & x"06";
						
						-- TODO: add RNG tile generator & split tile sets to 2 ppl
					end if;
					data_write_ram <= pack(data_ram); 
					byte_read_n <= not byte_read;
					if unsigned(counter) = 0 then
						game_state_n <= placement;
					end if;
				end if;
			when placement =>
				button_l_reg_n <= '0';
				if (unsigned(ship_counter) = 0) then
					game_state_n <= wait_4_player;
				elsif (unsigned(tile_pos_x) < 20) and (unsigned(tile_pos_y) < 14) then
					game_state_n <= validate;
				end if;
			when validate =>
				if (button_r_ce = '1') then
					ship_type_n <= ship_type xor "0001";
				elsif (scroll_up_ce = '1') then
					if (ship_type = x"9") then
						ship_type_n <= x"0";
					else
						ship_type_n <= std_logic_vector(unsigned(ship_type) + 2);
					end if;
				elsif (scroll_down_ce = '1') then
					if (ship_type = x"0") then
						ship_type_n <= x"9";
					else
						ship_type_n <= std_logic_vector(unsigned(ship_type) - 2);
					end if;
				end if;
				not_valid_n <= '0';
				counter_n <= std_logic_vector(unsigned(counter) + 1);
				if (unsigned(counter) = 2000) or (button_l_ce = '1') then
					counter_n <= (others => '0');
					if (button_l_ce = '1') then
						button_l_reg_n <= '1';
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
				if ((unsigned(tile_pos_x) + unsigned(margin_x)) > 20) or ((unsigned(tile_pos_y) + unsigned(margin_y)) > 14) then
					game_state_n <= placement;
				else
					game_state_n <= rem_flags;
					byte_read_n <= '0';
					counter_n <= std_logic_vector(to_unsigned(20*14, counter'length));
				end if;
			when rem_flags =>
				if byte_read = '0' then
					addr_A_reg_n <= std_logic_vector(unsigned(counter(addr_A'length-1 downto 0)));
					byte_read_n <= not byte_read;
				else
					counter_n <= std_logic_vector(unsigned(counter) - 1);
					we_A <= '1';
					-- remove red/grey flags
					data_write_ram <= data_read_ram and "111100111111111111"; 
					byte_read_n <= not byte_read;
				end if;
				if (unsigned(counter) = 0) and (byte_read = '1') then
					game_state_n <= val_draw;
					byte_read_n <= '0';
					-- set counter to 8x8 field to read positions based on margin
					counter_n <= std_logic_vector(to_unsigned(64, counter'length));
				end if;
			when val_draw =>
				if (unsigned(counter) = 0) and (byte_read = '1') then
					if (not_valid = '0') and (button_l_reg = '1') then
						game_state_n <= place;
						ship_counter_n <= std_logic_vector(unsigned(ship_counter) - 1);
						byte_read_n <= '0';
						-- set counter to 8x8 field to read positions based on margin
						counter_n <= std_logic_vector(to_unsigned(64, counter'length));
					else
						game_state_n <= placement;
					end if;
				end if;
				if byte_read = '0' then
					-- if position to validate is inside the play field
					if ((unsigned(tile_pos_x) + unsigned(counter(2 downto 0)) < 20) and
						(unsigned(tile_pos_y) + shift_right(unsigned(counter), 3)) < 14) then
					--madžikk (loads current validate position to address)
						addr_A_reg_n <= std_logic_vector(resize(unsigned(tile_pos_x) + unsigned(counter(2 downto 0)) + 20*(unsigned(tile_pos_y) + shift_right(unsigned(counter), 3)), addr_A'length));
						byte_read_n <= not byte_read;
					end if;
				else
					counter_n <= std_logic_vector(unsigned(counter) - 1);
					we_A <= '1';
					byte_read_n <= not byte_read;
					if (unsigned(counter(2 downto 0)) <= unsigned(margin_x)) and
						(shift_right(unsigned(counter), 3) <= unsigned(margin_y)) then
						if (data_read_ram(11) = '0') then
							data_ram.grey <= '1';
							data_write_ram <= data_read_ram or pack(data_ram);
						elsif (data_read_ram(11) = '1') then
							data_ram.red <= '1';
							data_write_ram <= data_read_ram or pack(data_ram);
							not_valid_n <= '1';
						end if;	
					end if;
				end if;
			when place =>
				if (unsigned(counter) = 0) and (byte_read = '1') then
					counter_n <= std_logic_vector(to_unsigned(64, counter'length));
					byte_read_n <= '0';
					game_state_n <= set_taken_flags;
					margin_x_n <= std_logic_vector(unsigned(margin_x) + 2);
					margin_y_n <= std_logic_vector(unsigned(margin_y) + 2);
				end if;
				if byte_read = '0' then
					addr_A_reg_n <= std_logic_vector(resize(unsigned(tile_pos_x) + unsigned(counter(2 downto 0)) + 20*(unsigned(tile_pos_y) + shift_right(unsigned(counter), 3)), addr_A'length));
					counter_n <= std_logic_vector(unsigned(counter) - 1);
					byte_read_n <= not byte_read;
				else	
					byte_read_n <= not byte_read;
					we_A <= '1';
					if (unsigned(counter(2 downto 0)) <= unsigned(margin_x)) and
						(shift_right(unsigned(counter), 3) <= unsigned(margin_y)) then
						if (unsigned(ship_type) = 0) then
							-- 4x4 ship
							data_write_ram <= "00" & x"4800" or std_logic_vector(resize(unsigned(counter(2 downto 0)) + 5*(3+shift_right(unsigned(counter), 3)), data_write_ram'length));
						elsif (ship_type(0) = '1') then
							if (unsigned(counter(2 downto 0)) = 0) then
								data_write_ram <= "00" & x"4801";
							elsif (counter(2 downto 0) = margin_x) then
								data_write_ram <= "00" & x"4804";
							else
								data_write_ram <= "00" & x"4802";
							end if;
						else
							if (unsigned(counter(2 downto 0)) = 0) then
								data_write_ram <= "00" & x"4800";
							elsif (shift_right(unsigned(counter), 3) = unsigned(margin_y)) then
								data_write_ram <= "00" & x"4809";
							else
								data_write_ram <= "00" & x"4805";
							end if;
						end if;
					end if;
				end if;
			when set_taken_flags =>
				if (unsigned(counter) = 0) and (byte_read = '1') then
					game_state_n <= placement;
				end if;
				if byte_read = '0' then
					counter_n <= std_logic_vector(unsigned(counter) - 1);
					-- if position to validate is inside the play field
					if ((unsigned(tile_pos_x) - 1 + unsigned(counter(2 downto 0)) < 20) and
						(unsigned(tile_pos_y) - 1 + shift_right(unsigned(counter), 3)) < 14) and
						(unsigned(tile_pos_x) > 0) and (unsigned(tile_pos_y) > 0) then
					--madžikk (loads current validate position to address)
						addr_A_reg_n <= std_logic_vector(resize(unsigned(tile_pos_x) - 1 + unsigned(counter(2 downto 0)) + 20*(unsigned(tile_pos_y) - 1 + shift_right(unsigned(counter), 3)), addr_A'length));
						byte_read_n <= not byte_read;
					end if;
				else
					we_A <= '1';
					byte_read_n <= not byte_read;
					if (unsigned(counter(2 downto 0)) <= unsigned(margin_x)) and
						(shift_right(unsigned(counter), 3) <= unsigned(margin_y)) then
						data_ram <= unpack(data_read_ram);
						data_ram.taken <= '1';
					end if;
					data_write_ram <= pack(data_ram);
				end if;	
			when wait_4_player =>
		--TODO: start hry nezavisi od typu hry
				if (game_type_real = '1') then
					if (turn = '1') then
						game_state_n <= my_turn;
					else
						game_state_n <= his_turn;
					end if;
				end if;
			when my_turn =>
				--TODO: implementovat zmenu obrazovky
				if (unsigned(enemy_hits) = 0) then
					game_state_n <= game_over_win;
				end if;
				if (button_l_ce = '1') then
					if (unsigned(tile_pos_x) < 20) and (unsigned(tile_pos_y) < 14) then
						shoot_position_out_reg_n <= std_logic_vector(resize(unsigned(tile_pos_x) + 20*unsigned(tile_pos_y), shoot_position_out'length));
						game_state_n <= ask;
					end if;
				end if;
			when his_turn =>
				--TODO: implementovat zmenu obrazovky
				if (unsigned(health) = 0) then
					game_state_n <= game_over_lose;
				end if;
				if not (unsigned(shoot_position_in) = 0) then
					if byte_read = '0' then
						addr_A_reg_n <= '0' & shoot_position_in;
						byte_read_n <= not byte_read;
					else
						byte_read_n <= not byte_read;
						data_ram <= unpack(data_read_ram);
						if (data_ram.ship = '1') then
							hit_out_reg_n <= '1';
							health_n <= std_logic_vector(unsigned(health) - 1);
							game_state_n <= hit_2_anim;
						else
							miss_out_reg_n <= '1';
							game_state_n <= miss_2_anim;
						end if;
					end if;
				end if;
			when ask =>
				if (hit_in = '1') or (miss_in = '1')then
					if (hit_in = '1') then
						enemy_hits_n <= std_logic_vector(unsigned(enemy_hits) - 1);
						game_state_n <= hit_1_anim;
					else
						game_state_n <= miss_1_anim;
					end if;
					counter_n <= std_logic_vector(to_unsigned(c_animation_counter, counter'length));
				end if;
			--TODO: zmenit niektore animacie/ich priebeh
			when hit_1_anim =>
			--TODO: zmenit pocitadlo na HUD
				if (unsigned(counter) = 0) and (byte_read = '1') then
					if (turn = '1') then
						game_state_n <= my_turn;
					else
						game_state_n <= his_turn;
						byte_read_n <= '0';
					end if;
				end if;
				if byte_read = '0' then
					counter_n <= std_logic_vector(unsigned(counter) - 1);
					addr_A_reg_n <= std_logic_vector(unsigned(tile_pos_x) + 20*unsigned(tile_pos_y));
					byte_read_n <= not byte_read;
				else
					we_A <= '1';
					byte_read_n <= not byte_read;
					data_ram.tile_data <= std_logic_vector(resize(5*shift_right(unsigned(counter), 3) + 15, data_ram.tile_data'length));
					data_write_ram <= data_read_ram or pack(data_ram);
				end if;
			when miss_1_anim =>
				if (unsigned(counter) = 0) and (byte_read = '1') then
					if (turn = '1') then
						game_state_n <= my_turn;
					else
						game_state_n <= his_turn;
					end if;
				end if;
				if byte_read = '0' then
					counter_n <= std_logic_vector(unsigned(counter) - 1);
					addr_A_reg_n <= std_logic_vector(unsigned(tile_pos_x) + 20*unsigned(tile_pos_y));
					byte_read_n <= not byte_read;
				else
					we_A <= '1';
					byte_read_n <= not byte_read;
					data_ram.tile_data <= std_logic_vector(resize(5*shift_right(unsigned(counter), 3) + 15, data_ram.tile_data'length));
					data_write_ram <= data_read_ram or pack(data_ram);
				end if;
			when hit_2_anim =>
				--TODO: zmenit pocitadlo na HUD
				if (unsigned(counter) = 0) and (byte_read = '1') then
					if (turn = '1') then
						game_state_n <= my_turn;
					else
						game_state_n <= his_turn;
					end if;
				end if;
				if byte_read = '0' then
					counter_n <= std_logic_vector(unsigned(counter) - 1);
					addr_A_reg_n <= std_logic_vector(unsigned(tile_pos_x) + 20*unsigned(tile_pos_y));
					byte_read_n <= not byte_read;
				else
					we_A <= '1';
					byte_read_n <= not byte_read;
					data_ram.tile_data <= std_logic_vector(resize(5*shift_right(unsigned(counter), 3) + 15, data_ram.tile_data'length));
					data_write_ram <= data_read_ram or pack(data_ram);
				end if;
			when miss_2_anim =>
				if (unsigned(counter) = 0) and (byte_read = '1') then
					if (turn = '1') then
						game_state_n <= my_turn;
					else
						game_state_n <= his_turn;
					end if;
				end if;
				if byte_read = '0' then
					counter_n <= std_logic_vector(unsigned(counter) - 1);
					addr_A_reg_n <= std_logic_vector(unsigned(tile_pos_x) + 20*unsigned(tile_pos_y));
					byte_read_n <= not byte_read;
				else
					we_A <= '1';
					byte_read_n <= not byte_read;
					data_ram.tile_data <= std_logic_vector(resize(5*shift_right(unsigned(counter), 3) + 15, data_ram.tile_data'length));
					data_write_ram <= data_read_ram or pack(data_ram);
				end if;
			when game_over_win =>
			when game_over_lose =>
			when others =>
		end case;
	end process;


end Behavioral;
