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
	Port(pos_x                                 : in  STD_LOGIC_VECTOR(10 downto 0);
	     pos_y                                 : in  STD_LOGIC_VECTOR(9 downto 0);
	     button_r_ce, button_l_ce, button_m_ce : in  STD_LOGIC;
	     clk                                   : in  STD_LOGIC;
	     rst                                   : in  STD_LOGIC;
	     turn                                  : in  STD_LOGIC;
	     miss_in, hit_in                       : in  STD_LOGIC;
	     game_ready_in                         : in  STD_LOGIC;
	     game_ready_out                        : out STD_LOGIC;
	     RNG_in                                : in  STD_LOGIC_VECTOR(15 downto 0);
	     Sound_out                             : out STD_LOGIC;
	     shoot_position_in                     : in  STD_LOGIC_VECTOR(8 downto 0);
	     shoot_position_in_CE                  : in  STD_LOGIC;
	     shoot_position_out                    : out STD_LOGIC_VECTOR(8 downto 0);
	     shoot_position_out_CE                 : out STD_LOGIC;
	     hit_out, miss_out                     : out STD_LOGIC;
	     game_type_want, game_type_want_CE     : out STD_LOGIC;
	     fast_game, slow_game                  : in  STD_LOGIC;
	     data_read_ram                         : in  STD_LOGIC_VECTOR(17 downto 0);
	     data_write_ram                        : out STD_LOGIC_VECTOR(17 downto 0);
	     we_A                                  : out STD_LOGIC;
	     addr_A                                : out STD_LOGIC_VECTOR(9 downto 0));
end Game_logic_top;

architecture Behavioral of Game_logic_top is

						-- Change outside of simulation
						--counter_n <= x"7F2815";
	constant c_animation_counter : natural := 8333333;
	constant c_fade_out_counter : natural := 12500003;
	constant c_validate_counter : natural := 2000000;
	constant c_number_of_ships : std_logic_vector(10 downto 0) := "11010010101";



type ram_data is record
		red_p2    : STD_LOGIC;
		grey_p2   : STD_LOGIC;
		taken     : STD_LOGIC;
		red_p1    : STD_LOGIC;
		grey_p1   : STD_LOGIC;
		ship      : STD_LOGIC;
		HUD       : STD_LOGIC;
		tile_data : STD_LOGIC_VECTOR(10 downto 0);
end record ram_data;

function pack(arg : ram_data) return std_logic_vector is
		variable result : std_logic_vector(17 downto 0);
	begin
		result(17)         := arg.red_p2;
		result(16)         := arg.grey_p2;
		result(15)         := arg.taken;
		result(14)         := arg.red_p1;
		result(13)         := arg.grey_p1;
		result(12)         := arg.ship;
		result(11)         := arg.HUD;
		result(10 downto 0) := arg.tile_data;
	return result;
end function pack;

function unpack(arg : std_logic_vector(17 downto 0)) return ram_data is
		variable result : ram_data;
	begin
		result.red_p2    := arg(17);
		result.grey_p2   := arg(16);
		result.taken     := arg(15);
		result.red_p1    := arg(14);
		result.grey_p1   := arg(13);
		result.ship      := arg(12);
		result.HUD       := arg(11);
		result.tile_data := arg(10 downto 0);
	return result;
end function unpack;


component MOUSE_cooldown is
    Port ( clk, rst : in  STD_LOGIC;
           button_l_in, button_m_in, button_r_in : in  STD_LOGIC;
           button_l_CE, button_m_CE, button_r_CE : out  STD_LOGIC);
end component;

	signal data_ram : ram_data;

	type stav is (init, start_init, start, wait_for_game_type, RAM_init, placement, validate, val_check, rem_flags, val_draw, place, set_taken_flags, wait_4_player,  my_turn, his_turn, ask,
	              hit_1_anim, miss_1_anim, hit_2_anim, miss_2_anim, game_over);
	signal game_state, game_state_n                          : stav                          := init;
	signal counter, counter_n                                : STD_LOGIC_VECTOR(23 downto 0) := (others => '0');
	signal ship_counter, ship_counter_n                      : STD_LOGIC_VECTOR(10 downto 0);
	signal enemy_hits_n, enemy_hits                          : STD_LOGIC_VECTOR(7 downto 0);
	signal health_n, health                                  : STD_LOGIC_VECTOR(7 downto 0);
	signal button_l_ce_int, button_m_ce_int, button_r_ce_int : STD_LOGIC;
	signal button_l_reg, button_l_reg_n                      : STD_LOGIC;
	signal button_r_reg, button_r_reg_n                      : STD_LOGIC;
	signal button_m_reg, button_m_reg_n                      : STD_LOGIC;
	signal margin_x, margin_x_n, margin_y, margin_y_n        : std_logic_vector(2 downto 0);
	signal tile_pos_x, tile_pos_y                            : std_logic_vector(4 downto 0);
	signal ship_type, ship_type_n                            : std_logic_vector(3 downto 0);
	signal byte_read, byte_read_n                            : STD_LOGIC_VECTOR(1 downto 0);
	signal not_valid, not_valid_n                            : STD_LOGIC;
	signal ship_used, ship_used_n                            : STD_LOGIC;
	signal fade_in, fade_in_n                                : STD_LOGIC;
	signal Sound_reg, Sound_reg_n                            : STD_LOGIC;

	signal addr_A_reg, addr_A_reg_n                                 : STD_LOGIC_VECTOR(9 downto 0);
	signal shoot_position_out_reg, shoot_position_out_reg_n         : STD_LOGIC_VECTOR(8 downto 0);
	signal shoot_position_out_CE_reg, shoot_position_out_CE_reg_n   : STD_LOGIC;
	signal shoot_position_in_reg, shoot_position_in_reg_n           : STD_LOGIC_VECTOR(8 downto 0);
	signal shoot_position_in_CE_reg, shoot_position_in_CE_reg_n     : STD_LOGIC;
	signal game_type_want_reg, game_type_want_reg_n                 : STD_LOGIC;
	signal game_type_real_reg, game_type_real_reg_n                 : STD_LOGIC;
	signal hit_out_reg, hit_out_reg_n, miss_out_reg, miss_out_reg_n : STD_LOGIC;
	signal my_screen, my_screen_n                                   : STD_LOGIC;
	signal game_ready_out_reg, game_ready_out_reg_n                 : STD_LOGIC;
	signal game_type_want_CE_reg, game_type_want_CE_reg_n           : STD_LOGIC;

begin
	
	unit_mouse_cooldown : component MOUSE_cooldown
		port map(
			clk         => clk,
			rst         => rst,
			button_l_in => button_l_ce,
			button_m_in => button_m_ce,
			button_r_in => button_r_ce,
			button_l_CE => button_l_ce_int,
			button_m_CE => button_m_ce_int,
			button_r_CE => button_r_ce_int
		);
	
	process(clk, rst)
	begin
		if (rst = '1') then
			game_state <= init;
			counter <= (others => '0');
			ship_counter <= (others => '0');
			ship_type <= (others => '0');
			margin_y <= (others => '0');
			margin_x <= (others => '0');
			byte_read <= (others => '0');
			not_valid <= '0';
			health <= (others => '0');
			enemy_hits <= (others => '0');
			shoot_position_out_reg <= (others => '0');
			shoot_position_out_CE_reg <= '0';
			shoot_position_in_reg <= (others => '0');
			shoot_position_in_CE_reg <= '0';
			addr_A_reg <= (others => '0');
			game_type_want_reg <= '0';
			game_type_want_CE_reg <= '0';
			game_type_real_reg <= '0';
			hit_out_reg <= '0';
			miss_out_reg <= '0';
			button_l_reg <= '0';
			button_r_reg <= '0';
			button_m_reg <= '0';
			my_screen <= '1';
			ship_used <= '0';
			game_ready_out_reg <= '0';
			fade_in <= '0';
			Sound_reg <= '0';
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
			shoot_position_out_CE_reg <= shoot_position_out_CE_reg_n;
			shoot_position_in_reg <= shoot_position_in_reg_n;
			shoot_position_in_CE_reg <= shoot_position_in_CE_reg_n;
			addr_A_reg <= addr_A_reg_n;
			game_type_want_reg <= game_type_want_reg_n;
			game_type_want_CE_reg <= game_type_want_CE_reg_n;
			game_type_real_reg <= game_type_real_reg_n;
			hit_out_reg <= hit_out_reg_n;
			miss_out_reg <= miss_out_reg_n;
			button_l_reg <= button_l_reg_n;
			button_r_reg <= button_r_reg_n;
			button_m_reg <= button_m_reg_n;
			my_screen <= my_screen_n;
			ship_used <= ship_used_n;
			game_ready_out_reg <= game_ready_out_reg_n;
			fade_in <= fade_in_n;
			Sound_reg <= Sound_reg_n;
		end if;
	end process;

	process(button_l_ce_int, game_state, pos_x, pos_y, counter, turn, margin_x, margin_y, ship_counter, ship_type, byte_read, data_read_ram, button_l_reg, not_valid, tile_pos_x, tile_pos_y, addr_A_reg, data_ram, enemy_hits, game_ready_in, health, hit_in, miss_in, shoot_position_out_reg, game_type_want_reg, hit_out_reg, miss_out_reg, shoot_position_in, my_screen, ship_counter_n(0), ship_counter_n(2 downto 1), ship_counter_n(4 downto 3), ship_counter_n(7 downto 5), ship_counter_n(9 downto 8), ship_used, game_ready_out_reg, RNG_in, button_m_reg, button_r_reg, fade_in, button_m_ce_int, button_r_ce_int, shoot_position_in_reg, game_type_real_reg, fast_game, slow_game, game_type_want_CE_reg, shoot_position_out_CE_reg, shoot_position_in_CE, shoot_position_in_CE_reg, Sound_reg)
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
		shoot_position_out_CE_reg_n <= shoot_position_out_CE_reg;
		shoot_position_in_reg_n <= shoot_position_in_reg;
		if (game_state = his_turn) and (shoot_position_in_CE = '1') then
			shoot_position_in_CE_reg_n <= '1';
			shoot_position_in_reg_n <= shoot_position_in;
		else
			shoot_position_in_CE_reg_n <= shoot_position_in_CE_reg;
		end if;
		addr_A_reg_n <= addr_A_reg;
		addr_A <= addr_A_reg;
		shoot_position_out <= shoot_position_out_reg;
		shoot_position_out_CE <= shoot_position_out_CE_reg;
		data_write_ram <= (others => '0');
		game_type_want_reg_n <= game_type_want_reg;
		game_type_want_CE_reg_n <= game_type_want_CE_reg;
		game_type_real_reg_n <= game_type_real_reg;
		hit_out_reg_n <= hit_out_reg;
		miss_out_reg_n <= miss_out_reg;
		hit_out <= hit_out_reg;
		miss_out <= miss_out_reg;
		game_type_want <= game_type_want_reg;
		game_type_want_CE <= game_type_want_CE_reg;
		my_screen_n <= my_screen;
		ship_used_n <= ship_used;
		game_ready_out_reg_n <= game_ready_out_reg;
		game_ready_out <= game_ready_out_reg;
		fade_in_n <= fade_in;
		Sound_reg_n <= Sound_reg;
		Sound_out <= Sound_reg;
		case (game_state) is
		when validate | val_check | rem_flags | val_draw =>
			if button_l_ce_int = '1' then
				button_l_reg_n <= '1';
			else
				button_l_reg_n <= button_l_reg;
			end if;
			if button_r_ce_int = '1' then
				button_r_reg_n <= '1';
			else
				button_r_reg_n <= button_r_reg;
			end if;
			if button_m_ce_int = '1' then
				button_m_reg_n <= '1';
			else
				button_m_reg_n <= button_m_reg;
			end if;
		when others =>
			button_l_reg_n <= '0';
			button_r_reg_n <= '0';
			button_m_reg_n <= '0';
		end case;
		case (game_state) is
			when init =>
			----------------------------------------
			----------------------------------------
				game_state_n <= start_init;
				game_ready_out_reg_n <= '0';
				health_n <= x"5" & x"3";
				enemy_hits_n <= x"5" & x"3";
				ship_used_n <= '0';
				fade_in_n <= '0';
				my_screen_n <= '1';
				-- Counter for all the ships (change outside of simulation)
				ship_counter_n <= c_number_of_ships;
				counter_n <= x"072140"; --20*16 (tiles + 1 info vector), (19 downto 12) == 115 tiles v mape
				byte_read_n <= "00";
			when start_init =>
			----------------------------------------
			-- Writes the "Home" screen to RAM
			----------------------------------------
				if byte_read = "00" then
					addr_A_reg_n <= std_logic_vector(unsigned(counter(addr_A'length-1 downto 0)));
					byte_read_n <= "01";
				else
					counter_n(11 downto 0) <= std_logic_vector(unsigned(counter(11 downto 0)) - 1);
					we_A <= '1';
					case (to_integer(unsigned(counter(11 downto 0)))) is
					when 0 => --grey + nextstate
						data_ram.tile_data <= "000" & x"73";
						game_state_n <= start;
					when 1 to 19 =>--grey
						data_ram.tile_data <= "000" & x"73";
					when 20 to 39 =>--tiledown
						data_ram.tile_data <= "000" & counter(19 downto 12);
					when 127 to 132 =>--normalgame
						data_ram.tile_data <= "000" & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) - 1);
					when 167 to 172 =>--quickgame
						data_ram.tile_data <= "000" & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) - 1);
					when 185 to 186 =>--firstsolder
						data_ram.tile_data <= "000" & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) - 1);
					when 193 to 198 =>--firstESD
						data_ram.tile_data <= "000" & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) - 1);
					when 203 to 206 =>--secondsolder
						data_ram.tile_data <= "000" & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) - 1);
					when 212 to 218 =>--secondESD
						data_ram.tile_data <= "000" & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) - 1);
					when 220 to 224 =>--thirdsolder
						data_ram.tile_data <= "000" & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) - 1);
					when 233 to 239 =>--thirdESD
						data_ram.tile_data <= "000" & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) - 1);
					when 240 to 242 =>--fourthsolder
						data_ram.tile_data <= "000" & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) - 1);
					when 256 to 259 =>--fourthESD
						data_ram.tile_data <= "000" & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) - 1);
					when 260 to 262 =>--fifthsolder
						data_ram.tile_data <= "000" & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) - 1);
					when 277 to 279 =>--fifthESD
						data_ram.tile_data <= "000" & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) - 1);
					when 280 =>--tileup
						data_ram.tile_data <= "000" & counter(19 downto 12);
						counter_n(19 downto 12) <= std_logic_vector(unsigned(counter(19 downto 12)) - 1);
					when 281 to 299 =>--tileup
						data_ram.tile_data <= "000" & counter(19 downto 12);
					when 300 to 319 =>--grey
						data_ram.tile_data <= "000" & x"73";
					when 320 =>--infovector
						data_ram.tile_data <= (0 => '1', others => '0');
					when others =>--black
						data_ram.tile_data <= "000" & x"74";
					end case;
					data_ram.HUD <= '1';
					data_write_ram <= pack(data_ram);
					byte_read_n <= "00";
				end if;
			when start =>
			----------------------------------------
			-- Waiting for button_l_ce on quick/normal game
			----------------------------------------
				if (button_l_ce_int = '1') and fade_in = '0' then
					if	(unsigned(tile_pos_x) > 6) and (unsigned(tile_pos_x) < 13)
						and (unsigned(tile_pos_y) = 8)
					then
						game_state_n <= wait_for_game_type;
						game_type_want_reg_n <= '1';
						game_type_want_CE_reg_n <= '1';
						fade_in_n <= '0';
					elsif	(unsigned(tile_pos_x) > 6) and (unsigned(tile_pos_x) < 13)
						and (unsigned(tile_pos_y) = 6) 
					then
						game_state_n <= wait_for_game_type;
						game_type_want_CE_reg_n <= '1';
						game_type_want_reg_n <= '0';
						fade_in_n <= '0';
					end if;
				end if;
				if (fast_game = '1') or (slow_game = '1') then
					fade_in_n <= '1';
					game_type_real_reg_n <= fast_game;
					counter_n <= (others => '0');
					game_state_n <= wait_for_game_type;
				end if;
			when wait_for_game_type =>
				-- remove for release
------------------------------------------------------------
--============================================================
--				game_state_n <= RAM_init;
--				counter_n <= std_logic_vector(to_unsigned(20*16-1, counter'length));
--============================================================
------------------------------------------------------------
				if ((fast_game = '1') or (slow_game = '1')) and (fade_in = '0') then
					game_type_real_reg_n <= fast_game;
					counter_n <= (others => '0');
					fade_in_n <= '1';
				end if;
				if fade_in = '1' then
					if byte_read = "00" then
						if unsigned(counter)>5 then
							addr_A_reg_n <= std_logic_vector(to_unsigned(320, addr_A_reg'length));
						else
							if game_type_real_reg = '1' then
								addr_A_reg_n <= std_logic_vector(unsigned(counter(9 downto 0)) + 167);
							else
								addr_A_reg_n <= std_logic_vector(unsigned(counter(9 downto 0)) + 127);
							end if;
						end if;
						byte_read_n <= "01";
					elsif byte_read = "01" then
						byte_read_n <= "10";
					elsif byte_read = "10" then
						data_ram <= unpack(data_read_ram);
						case to_integer(unsigned(counter)) is
						when 0 to 5 => data_ram.tile_data <= "000" & x"73"; we_A <= '1';
						when 6 to c_fade_out_counter-4 => 
							data_ram.tile_data(3 downto 2) <= "10";
							we_A <= '1';
						when others =>
							data_ram.tile_data(3 downto 2) <= "01";
							we_A <= '1';
						end case;
						data_write_ram <= pack(data_ram);
						byte_read_n <= "11";
					else
						byte_read_n <= "00";
						counter_n <= std_logic_vector(unsigned(counter) + 1);
						if unsigned(counter) = c_fade_out_counter-3 then -- 12 500 000 outside simulation
							counter_n <= std_logic_vector(to_unsigned(20*16-1, counter'length));
							game_state_n   <= RAM_init;
							fade_in_n <= '0';
						end if;
					end if;
				end if;
			when RAM_init =>
			----------------------------------------
			-- Writes the playing field and HUD to RAM
			----------------------------------------
				if byte_read = "00" then
					addr_A_reg_n <= std_logic_vector(unsigned(counter(addr_A'length-1 downto 0)));
					byte_read_n <= "01";
				else
					counter_n <= std_logic_vector(unsigned(counter) - 1);
					we_A <= '1';
					if unsigned(counter) > 20*14-1 then
						data_ram.HUD <= '1';
						case (to_integer(unsigned(counter))) is
							-- LOGO FEKT + suciastky bot
						when 320 => data_ram.tile_data <= (0 => '1', others => '0');
						when 319 => data_ram.tile_data <= "000" & x"23";
						when 305 to 318 => data_ram.tile_data <= "000" & std_logic_vector(to_unsigned(to_integer(unsigned(counter)) - 305 + 43, 8));
							-- Pocitadlo zivotov p1
						when 304 => data_ram.tile_data <= "000" & x"0" & health(3 downto 0);
						when 303 => data_ram.tile_data <= "000" & x"0" & health(7 downto 4);
							-- Koncova suciastka
						when 302 => data_ram.tile_data <= "000" & x"28";
							-- Tlacidlo p1 bot
						when 301 => data_ram.tile_data <= "000" & x"25";
						when 300 => data_ram.tile_data <= "000" & x"24";
							-- LOGO FEKT + empty display top
						when 299 => data_ram.tile_data <= "000" & x"22";
						when 297 to 298 => data_ram.tile_data <= "000" & std_logic_vector(to_unsigned(to_integer(unsigned(counter)) - 297 + 26, 8));
						when 296 => data_ram.tile_data <= "000" & x"73";
						when 294 to 295 => data_ram.tile_data <= "000" & std_logic_vector(to_unsigned(to_integer(unsigned(counter)) - 294 + 24, 8));
						when 290 to 293 => data_ram.tile_data <= "000" & x"2c";
						when 288 to 289 => data_ram.tile_data <= "000" & std_logic_vector(to_unsigned(to_integer(unsigned(counter)) - 288 + 20, 8));
							-- Pocitadlo zivotov p2
						when 287 => data_ram.tile_data <= "000" & x"0" & enemy_hits(3 downto 0);
						when 286 => data_ram.tile_data <= "000" & x"0" & enemy_hits(7 downto 4);
							-- "LIVES"
						when 285 => data_ram.tile_data <= "000" & x"11";
						when 284 => data_ram.tile_data <= "000" & x"10";
						when 283 => data_ram.tile_data <= "000" & x"0F";
							-- Koncova suciastka
						when 282 => data_ram.tile_data <= "000" & x"0E";
							-- Tlacidlo p1 top
						when 281 => data_ram.tile_data <= "000" & x"0B";
						when others => data_ram.tile_data <= "000" & x"0A";
						end case;
					else
						data_ram.HUD <= '0';
--						data_ram.tile_data <= "000" & x"06";
						data_ram.tile_data(9 downto 7) <= std_logic_vector(shift_right(unsigned(RNG_in), to_integer(unsigned(counter(4 downto 0))))(2 downto 0));
						data_ram.tile_data(2 downto 0) <= std_logic_vector(shift_right(unsigned(RNG_in), to_integer(unsigned(counter(4 downto 0))))(2 downto 0));
					-- RNG tile generator & split tile sets to 2 ppl
					end if;
					data_write_ram <= pack(data_ram); 
					byte_read_n <= "00";
					if unsigned(counter) = 0 then
						game_state_n <= placement;
					end if;
				end if;
			when placement =>
				if (unsigned(ship_counter) = 0) then
					game_state_n <= wait_4_player;
					byte_read_n <= "00";
					counter_n <= (1 downto 0 => '1', others => '0');
					game_ready_out_reg_n <= '1';
				elsif (unsigned(tile_pos_x) < 20) and (unsigned(tile_pos_y) < 14) then
					game_state_n <= validate;
					byte_read_n <= "00";
					ship_used_n <= '1';
					counter_n <= (others => '0');
				end if;
				if (button_l_ce_int = '1') and (unsigned(tile_pos_x) > 16) and (unsigned(tile_pos_y) > 13) then
					game_state_n <= RAM_init;
					ship_counter_n <= c_number_of_ships;
					counter_n <= std_logic_vector(to_unsigned(20*16-1, counter'length));
				end if;
			when validate =>
			----------------------------------------
			-- Waiting for time interval or button_l_ce,
			-- sets the placing ship and its margins
			----------------------------------------
				if ship_used = '1' then
					case (to_integer(unsigned(ship_type(3 downto 1)))) is
					when 0 => if (ship_counter(10) = '0')				then ship_used_n <= '1'; ship_type_n <= std_logic_vector(unsigned(ship_type) + 2);	else ship_used_n <= '0'; end if;
					when 1 => if (ship_counter_n(9 downto 8) = "00")	then ship_used_n <= '1'; ship_type_n <= std_logic_vector(unsigned(ship_type) + 2);	else ship_used_n <= '0'; end if;
					when 2 => if (ship_counter_n(7 downto 5) = "000")	then ship_used_n <= '1'; ship_type_n <= std_logic_vector(unsigned(ship_type) + 2);	else ship_used_n <= '0'; end if;
					when 3 => if (ship_counter_n(4 downto 3) = "00")	then ship_used_n <= '1'; ship_type_n <= std_logic_vector(unsigned(ship_type) + 2);	else ship_used_n <= '0'; end if;
					when 4 => if (ship_counter_n(2 downto 1) = "00")	then ship_used_n <= '1'; ship_type_n <= std_logic_vector(unsigned(ship_type) + 2);	else ship_used_n <= '0'; end if;
					when others => if (ship_counter_n(0) = '0')			then ship_used_n <= '1'; ship_type_n <= x"0";										else ship_used_n <= '0'; end if;
					end case;
				else
					if (button_r_reg = '1') then
						ship_type_n    <= ship_type xor "0001";
						button_r_reg_n <= '0';
					elsif (button_m_reg = '1') then
						button_m_reg_n <= '0';
						ship_used_n <= '1';
						if (ship_type(3 downto 1) = "101") then
							ship_type_n <= x"0";
						else
							ship_type_n <= std_logic_vector(unsigned(ship_type) + 2);
						end if;
					end if;
					not_valid_n <= '0';
					counter_n <= std_logic_vector(unsigned(counter) + 1);
					if (button_m_reg = '0') and (button_r_reg = '0') and ((unsigned(counter) = c_validate_counter) or (button_l_reg = '1')) then
						counter_n <= (others => '0');
						case ship_type is
							when "0000" | "0001" => margin_x_n <= std_logic_vector(to_unsigned(3, margin_x_n'length)); margin_y_n <= std_logic_vector(to_unsigned(3, margin_y_n'length));
							when "0011" => margin_x_n <= std_logic_vector(to_unsigned(4, margin_x_n'length)); margin_y_n <= std_logic_vector(to_unsigned(0, margin_y_n'length));
							when "0010" => margin_x_n <= std_logic_vector(to_unsigned(0, margin_x_n'length)); margin_y_n <= std_logic_vector(to_unsigned(4, margin_y_n'length));
							when "0101" => margin_x_n <= std_logic_vector(to_unsigned(3, margin_x_n'length)); margin_y_n <= std_logic_vector(to_unsigned(0, margin_y_n'length));
							when "0100" => margin_x_n <= std_logic_vector(to_unsigned(0, margin_x_n'length)); margin_y_n <= std_logic_vector(to_unsigned(3, margin_y_n'length));
							when "0111" => margin_x_n <= std_logic_vector(to_unsigned(2, margin_x_n'length)); margin_y_n <= std_logic_vector(to_unsigned(0, margin_y_n'length));
							when "0110" => margin_x_n <= std_logic_vector(to_unsigned(0, margin_x_n'length)); margin_y_n <= std_logic_vector(to_unsigned(2, margin_y_n'length));
							when "1001" => margin_x_n <= std_logic_vector(to_unsigned(1, margin_x_n'length)); margin_y_n <= std_logic_vector(to_unsigned(0, margin_y_n'length));
							when "1000" => margin_x_n <= std_logic_vector(to_unsigned(0, margin_x_n'length)); margin_y_n <= std_logic_vector(to_unsigned(1, margin_y_n'length));
							when others => margin_x_n <= std_logic_vector(to_unsigned(0, margin_x_n'length)); margin_y_n <= std_logic_vector(to_unsigned(0, margin_y_n'length));
						end case;
						game_state_n <= val_check;
					end if;
				end if;
			when val_check =>
			----------------------------------------
			-- Checks if the ship is inside playing field based on margins
			----------------------------------------
				if ((unsigned(tile_pos_x) + unsigned(margin_x)) > 19) or ((unsigned(tile_pos_y) + unsigned(margin_y)) > 13) then
					game_state_n <= placement;
				else
					game_state_n <= rem_flags;
					byte_read_n <= "00";
					counter_n <= std_logic_vector(to_unsigned(20*14, counter'length));
				end if;
			when rem_flags =>
			----------------------------------------
			-- Removes the red/grey flags
			----------------------------------------
				if byte_read = "00" then
					addr_A_reg_n <= std_logic_vector(unsigned(counter(addr_A'length-1 downto 0)));
					byte_read_n <= "01";
				elsif byte_read = "01" then
					byte_read_n <= "11";
				else
					counter_n <= std_logic_vector(unsigned(counter) - 1);
					we_A <= '1';
					-- remove red/grey flags
					data_ram <= unpack(data_read_ram);
					data_ram.red_p1 <= '0';
					data_ram.grey_p1 <= '0';
					data_write_ram <= pack(data_ram);
					byte_read_n <= "00";
				end if;
				if (unsigned(counter) = 0) and (byte_read = "11") then
					game_state_n <= val_draw;
					byte_read_n <= "00";
					-- set counter to 8x8 field to read positions based on margin
					counter_n <= std_logic_vector(to_unsigned(63, counter'length));
				end if;
			when val_draw =>
			----------------------------------------
			-- Evaluates if ship can be placed and sets the red/grey flags
			----------------------------------------
				if byte_read = "00" then
					-- if position to validate is inside the play field
					if ((unsigned(tile_pos_x) + unsigned(counter(2 downto 0)) < 20) and
						(unsigned(tile_pos_y) + shift_right(unsigned(counter), 3)) < 14) then
					--madžikk (loads current validate position to address)
						addr_A_reg_n <= std_logic_vector(resize(unsigned(tile_pos_x) + unsigned(counter(2 downto 0)) + 20*(unsigned(tile_pos_y) + unsigned(counter(5 downto 3))), addr_A'length));
						byte_read_n <= "01";
					else
						counter_n <= std_logic_vector(unsigned(counter) - 1);
					end if;
				elsif byte_read = "01" then
					byte_read_n <= "10";
				elsif byte_read = "10" then
					byte_read_n <= "11";
					data_ram <= unpack(data_read_ram);
					if (unsigned(counter(2 downto 0)) <= unsigned(margin_x)) and
						(shift_right(unsigned(counter), 3) <= unsigned(margin_y)) then
						we_A <= '1';
						if (data_ram.taken = '0') then
							data_ram.grey_p1 <= '1';
							--if unsigned(addr_A_reg) = 0 then
							--	not_valid_n <= '1';
							--end if;
						else
							data_ram.red_p1 <= '1';
							not_valid_n <= '1';
						end if;	
						data_write_ram <= pack(data_ram);
					end if;
				else
					counter_n <= std_logic_vector(unsigned(counter) - 1);
					byte_read_n <= "00";
				end if;
				if (unsigned(counter) = 0) and (byte_read = "11") then
					if (not_valid = '0') and (button_l_reg = '1') then
						game_state_n <= place;
						case (to_integer(unsigned(ship_type(3 downto 1)))) is
						when 0 =>	ship_counter_n(10) <= '0';
						when 1 =>	ship_counter_n(9 downto 8) <= std_logic_vector(unsigned(ship_counter(9 downto 8)) - 1);
						when 2 =>	ship_counter_n(7 downto 5) <= std_logic_vector(unsigned(ship_counter(7 downto 5)) - 1);
						when 3 =>	ship_counter_n(4 downto 3) <= std_logic_vector(unsigned(ship_counter(4 downto 3)) - 1);
						when 4 =>	ship_counter_n(2 downto 1) <= std_logic_vector(unsigned(ship_counter(2 downto 1)) - 1);
						when others =>	ship_counter_n(0) <= '0';
						end case;
						byte_read_n <= "00";
						-- set counter to 8x8 field to read positions based on margin
						counter_n <= std_logic_vector(to_unsigned(63, counter'length));
					else
						game_state_n <= placement;
					end if;
				end if;
			when place =>
			----------------------------------------
			-- Places the ship inside margin_x and _y
			----------------------------------------
				if byte_read = "00" then
					addr_A_reg_n <= std_logic_vector(resize(unsigned(tile_pos_x) + unsigned(counter(2 downto 0)) + 20*(unsigned(tile_pos_y) + unsigned(counter(5 downto 3))), addr_A'length));
					byte_read_n <= "01";
				elsif byte_read = "01" then
					byte_read_n <= "11";
				else
					byte_read_n <= "00";
					counter_n <= std_logic_vector(unsigned(counter) - 1);
					if (unsigned(counter(2 downto 0)) <= unsigned(margin_x)) and
						(shift_right(unsigned(counter), 3) <= unsigned(margin_y)) then
						we_A <= '1';
						data_ram <= unpack(data_read_ram);
						data_ram.ship <= '1';
						if ship_type(3 downto 1) = "000" then
							-- 4x4 ship
							data_ram.tile_data(5 downto 0) <=  std_logic_vector(7 + shift_left(unsigned("000" & counter(5 downto 3)), 2) + unsigned(counter(2 downto 0)));
							--data_write_ram <= "00" & x"4800" or std_logic_vector(resize(unsigned(counter(2 downto 0)) + 5*(3+shift_right(unsigned(counter), 3)), data_write_ram'length));
						elsif ship_type(3 downto 1) = "101" then
							data_ram.tile_data(6 downto 0) <= "000" & x"6";
						elsif (ship_type(0) = '1') then
							-- Vertical ship (####)
							if (unsigned(counter(2 downto 0)) = 0) then
								data_ram.tile_data(6 downto 0) <= "000" & x"1";
							elsif (counter(2 downto 0) = margin_x) then
								data_ram.tile_data(6 downto 0) <= "000" & x"2";
							else
								data_ram.tile_data(6 downto 0) <= "000" & x"3";
							end if;
						else
							if (shift_right(unsigned(counter), 3) = 0) then
								data_ram.tile_data(6 downto 0) <= "000" & x"0";
							elsif (shift_right(unsigned(counter), 3) = unsigned(margin_y)) then
								data_ram.tile_data(6 downto 0) <= "000" & x"4";
							else
								data_ram.tile_data(6 downto 0) <= "000" & x"5";
							end if;
						end if;
						data_ram.grey_p1 <= '0';
						data_write_ram <= pack(data_ram);
					end if;
				end if;
				if (unsigned(counter) = 0) and (byte_read = "11") then
					counter_n <= std_logic_vector(to_unsigned(63, counter'length));
					byte_read_n <= "00";
					game_state_n <= set_taken_flags;
					margin_x_n <= std_logic_vector(unsigned(margin_x) + 2);
					margin_y_n <= std_logic_vector(unsigned(margin_y) + 2);
				end if;
			when set_taken_flags =>
			----------------------------------------
			-- Sets the flags around and inside ships to prevent overlapping
			----------------------------------------
				if byte_read = "00" then
					-- if position to validate is inside the play field
					if ((unsigned(tile_pos_x) + unsigned(counter(2 downto 0)) < 21) and
						(unsigned(tile_pos_y) + shift_right(unsigned(counter), 3)) < 15) and
						(unsigned(tile_pos_x) + unsigned(counter(2 downto 0)) >= 1) and
						(unsigned(tile_pos_y) + shift_right(unsigned(counter), 3) >= 1) then
					--madžikk (loads current validate position to address)
						addr_A_reg_n <= std_logic_vector(resize(unsigned(tile_pos_x) - 1 + unsigned(counter(2 downto 0)) + 20*(unsigned(tile_pos_y) - 1 + unsigned(counter(5 downto 3))), addr_A'length));
						byte_read_n <= "01";
					else
						if unsigned(counter) = 0 then
							game_state_n <= placement;
							ship_used_n <= '1';
						else
							counter_n <= std_logic_vector(unsigned(counter) - 1);
						end if;
					end if;
				elsif byte_read = "01" then
					byte_read_n <= "10";
				elsif byte_read = "10" then
					counter_n <= std_logic_vector(unsigned(counter) - 1);
					byte_read_n <= "11";
					if (unsigned(counter(2 downto 0)) <= unsigned(margin_x)) and
						(shift_right(unsigned(counter), 3) <= unsigned(margin_y)) then
						we_A <= '1';
						data_ram <= unpack(data_read_ram);
						data_ram.taken <= '1';
						data_write_ram <= pack(data_ram);
					end if;
				else
					byte_read_n <= "00";
				end if;	
				if (unsigned(counter) = 0) and (byte_read = "10") then
					game_state_n <= placement;
					ship_used_n <= '1';
				end if;
			when wait_4_player =>
			----------------------------------------
			-- Waiting after placement for game_ready
			----------------------------------------
				if unsigned(counter(3 downto 0)) = 0 and byte_read = "11" then
					if (game_ready_in = '1') then
						counter_n <= std_logic_vector(to_unsigned(c_fade_out_counter, counter'length));
						byte_read_n <= "00";
						if (turn = '1') then
							game_state_n <= my_turn;
						else
							game_state_n <= his_turn;
							my_screen_n <= not my_screen;
						end if;
					end if;
				else
					if byte_read = "00" then
							case (to_integer(unsigned(counter))) is
							when 3 => addr_A_reg_n <= std_logic_vector(to_unsigned(293, addr_A_reg'length));
							when 2 => addr_A_reg_n <= std_logic_vector(to_unsigned(292, addr_A_reg'length));
							when others => addr_A_reg_n <= std_logic_vector(to_unsigned(291, addr_A_reg'length));
							end case;
						byte_read_n <= "01";
					elsif byte_read = "01" then
						byte_read_n <= "10";
					elsif byte_read = "10" then
						data_ram <= unpack(data_read_ram);
							case (to_integer(unsigned(counter))) is
							when 3 => data_ram.tile_data <= std_logic_vector(to_unsigned(23, data_ram.tile_data'length));
							when 2 => data_ram.tile_data <= std_logic_vector(to_unsigned(22, data_ram.tile_data'length));
							when others => data_ram.tile_data <= std_logic_vector(to_unsigned(44, data_ram.tile_data'length));
							end case;
						we_A <= '1';
						byte_read_n <= "11";
						data_write_ram <= pack(data_ram);
					else
						byte_read_n <= "00";
						counter_n(3 downto 0) <= std_logic_vector(unsigned(counter(3 downto 0)) - 1);
					end if;
				end if;
			when my_turn =>
			----------------------------------------
			-- My turn (waiting for button_l_ce)
			----------------------------------------
				if (unsigned(enemy_hits) = 0) then
					game_state_n <= game_over;
					byte_read_n <= "00";
					counter_n <= (others => '0');
					fade_in_n <= '1';
				end if;
				if (unsigned(counter) = 0) then
					if (button_l_ce_int = '1') then
						if (unsigned(tile_pos_x) < 20) and (unsigned(tile_pos_y) < 14) then
							game_state_n <= ask;
							byte_read_n <= "00";
						elsif (unsigned(tile_pos_x) < 2) and (unsigned(tile_pos_y) > 13) then
							counter_n <= std_logic_vector(to_unsigned(c_fade_out_counter-3, counter'length));
						end if;
					end if;
				else
					if byte_read = "00" then
						case (to_integer(unsigned(counter))) is
						when c_fade_out_counter => addr_A_reg_n <= std_logic_vector(to_unsigned(293, addr_A_reg'length)); 
						when c_fade_out_counter-1 => addr_A_reg_n <= std_logic_vector(to_unsigned(292, addr_A_reg'length)); 
						when c_fade_out_counter-2 => addr_A_reg_n <= std_logic_vector(to_unsigned(291, addr_A_reg'length)); 
						when 6 to c_fade_out_counter-3 => addr_A_reg_n <= std_logic_vector(to_unsigned(320, addr_A_reg'length)); 
						when 5 => addr_A_reg_n <= std_logic_vector(to_unsigned(320, addr_A_reg'length)); 
						when 4 => addr_A_reg_n <= std_logic_vector(to_unsigned(280, addr_A_reg'length)); 
						when 3 => addr_A_reg_n <= std_logic_vector(to_unsigned(281, addr_A_reg'length)); 
						when 2 => addr_A_reg_n <= std_logic_vector(to_unsigned(300, addr_A_reg'length)); 
						when others => addr_A_reg_n <= std_logic_vector(to_unsigned(301, addr_A_reg'length));
						end case;
						byte_read_n <= "01";
					elsif byte_read = "01" then
						byte_read_n <= "10";
					else
						data_ram <= unpack(data_read_ram);
						case (to_integer(unsigned(counter))) is
						when c_fade_out_counter => data_ram.tile_data <= std_logic_vector(to_unsigned(33, data_ram.tile_data'length));
						when c_fade_out_counter-1 => data_ram.tile_data <= std_logic_vector(to_unsigned(32, data_ram.tile_data'length));
						when c_fade_out_counter-2 => data_ram.tile_data <= std_logic_vector(to_unsigned(31, data_ram.tile_data'length));
						when 7 to c_fade_out_counter-3 => data_ram.tile_data(3 downto 2) <= "10";
						when 6 => data_ram.tile_data(3 downto 2) <= "01";
						when 5 => data_ram.tile_data(0) <= not my_screen; my_screen_n <= not my_screen;
						when 4 => if my_screen = '0' then data_ram.tile_data <= "000" & x"0A"; else data_ram.tile_data <= "000" & x"0C"; end if;
						when 3 => if my_screen = '0' then data_ram.tile_data <= "000" & x"0B"; else data_ram.tile_data <= "000" & x"0D"; end if;
						when 2 => if my_screen = '0' then data_ram.tile_data <= "000" & x"24"; else data_ram.tile_data <= "000" & x"26"; end if;
						when others => if my_screen = '0' then data_ram.tile_data <= "000" & x"25"; else data_ram.tile_data <= "000" & x"27"; end if;
						end case;
					counter_n <= std_logic_vector(unsigned(counter) - 1);
					we_A <= '1';
					byte_read_n <= "00";
					data_write_ram <= pack(data_ram);
					end if;
				end if;
			when his_turn =>
			----------------------------------------
			-- Opponent's turn (waiting for shoot_position_in)
			----------------------------------------
				if (unsigned(health) = 0) then
					game_state_n <= game_over;
					byte_read_n <= "00";
					counter_n <= (others => '0');
					fade_in_n <= '1';
				end if;
				if unsigned(counter) = 0 then
					if (button_l_ce_int = '1') and (unsigned(tile_pos_x) < 2) and (unsigned(tile_pos_y) > 13) then
							counter_n <= std_logic_vector(to_unsigned(c_fade_out_counter-3 , counter'length));
					end if;
					if shoot_position_in_CE_reg = '1' then
						if byte_read = "00" then
							addr_A_reg_n <= '0' & shoot_position_in_reg;
							byte_read_n <= "01";
						elsif byte_read = "01" then
							byte_read_n <= "11";
						else
							byte_read_n <= "00";
							data_ram <= unpack(data_read_ram);
							if (data_ram.ship = '1') then
								hit_out_reg_n <= '1';
								if unsigned(health(3 downto 0)) = 0 then
									health_n(7 downto 4) <= std_logic_vector(unsigned(health(7 downto 4)) - 1);
									health_n(3 downto 0) <= x"9";
								else
									health_n(3 downto 0) <= std_logic_vector(unsigned(health(3 downto 0)) - 1);
								end if;
								game_state_n <= hit_2_anim;
							else
								miss_out_reg_n <= '1';
								game_state_n <= miss_2_anim;
							end if;
							counter_n <= std_logic_vector(to_unsigned(c_animation_counter, counter'length));
							shoot_position_in_CE_reg_n <= '0';
						end if;
					end if;
				else
					if byte_read = "00" then
						case (to_integer(unsigned(counter))) is
						when c_fade_out_counter => addr_A_reg_n <= std_logic_vector(to_unsigned(293, addr_A_reg'length)); 
						when c_fade_out_counter-1 => addr_A_reg_n <= std_logic_vector(to_unsigned(292, addr_A_reg'length)); 
						when c_fade_out_counter-2 => addr_A_reg_n <= std_logic_vector(to_unsigned(291, addr_A_reg'length)); 
						when 6 to c_fade_out_counter-3 => addr_A_reg_n <= std_logic_vector(to_unsigned(320, addr_A_reg'length)); 
						when 5 => addr_A_reg_n <= std_logic_vector(to_unsigned(320, addr_A_reg'length));
						when 4 => addr_A_reg_n <= std_logic_vector(to_unsigned(280, addr_A_reg'length));
						when 3 => addr_A_reg_n <= std_logic_vector(to_unsigned(281, addr_A_reg'length));
						when 2 => addr_A_reg_n <= std_logic_vector(to_unsigned(300, addr_A_reg'length));
						when others => addr_A_reg_n <= std_logic_vector(to_unsigned(301, addr_A_reg'length)); if my_screen = '1' then data_ram.tile_data <= "000" & x"2A"; else data_ram.tile_data <= "000" & x"2C"; end if;
						end case;
						byte_read_n <= "01";
					elsif byte_read = "01" then
						byte_read_n <= "10";
					else
						data_ram <= unpack(data_read_ram);
						case (to_integer(unsigned(counter))) is
						when c_fade_out_counter => data_ram.tile_data <= std_logic_vector(to_unsigned(23, data_ram.tile_data'length));
						when c_fade_out_counter-1 => data_ram.tile_data <= std_logic_vector(to_unsigned(22, data_ram.tile_data'length));
						when c_fade_out_counter-2 => data_ram.tile_data <= std_logic_vector(to_unsigned(44, data_ram.tile_data'length));
						when 7 to c_fade_out_counter-3 => data_ram.tile_data(3 downto 2) <= "10";
						when 6 => data_ram.tile_data(3 downto 2) <= "01";
						when 5 => data_ram.tile_data(0) <= not my_screen; my_screen_n <= not my_screen;
						when 4 => if my_screen = '0' then data_ram.tile_data <= "000" & x"0A"; else data_ram.tile_data <= "000" & x"0C"; end if;
						when 3 => if my_screen = '0' then data_ram.tile_data <= "000" & x"0B"; else data_ram.tile_data <= "000" & x"0D"; end if;
						when 2 => if my_screen = '0' then data_ram.tile_data <= "000" & x"24"; else data_ram.tile_data <= "000" & x"26"; end if;
						when others => if my_screen = '0' then data_ram.tile_data <= "000" & x"25"; else data_ram.tile_data <= "000" & x"27"; end if;
						end case;
					counter_n <= std_logic_vector(unsigned(counter) - 1);
					we_A <= '1';
					byte_read_n <= "00";
					data_write_ram <= pack(data_ram);
					end if;
				end if;
			when ask =>
				if byte_read = "00" then
					addr_A_reg_n <= std_logic_vector(resize(unsigned(tile_pos_x) + 20*unsigned(tile_pos_y), addr_A_reg'length));
					byte_read_n <= "01";
				elsif byte_read = "01" then
					byte_read_n <= "11";
				elsif byte_read = "11" then
					byte_read_n <= "10";
					data_ram <= unpack(data_read_ram);
					if (data_ram.grey_p2 = '1') or (data_ram.red_p2 = '1') then
						game_state_n <= my_turn;
						counter_n <= (others => '0');
					else
						shoot_position_out_reg_n <= addr_A_reg(8 downto 0);
						shoot_position_out_CE_reg_n <= '1';
					end if;
				end if;
				if (hit_in = '1') or (miss_in = '1') then
					if (hit_in = '1') then
						if unsigned(enemy_hits(3 downto 0)) = 0 then
							enemy_hits_n(7 downto 4) <= std_logic_vector(unsigned(enemy_hits(7 downto 4)) - 1);
							enemy_hits_n(3 downto 0) <= x"9";
						else
							enemy_hits_n(3 downto 0) <= std_logic_vector(unsigned(enemy_hits(3 downto 0)) - 1);
						end if;
						game_state_n <= hit_1_anim;
					else
						game_state_n <= miss_1_anim;
					end if;
					shoot_position_out_CE_reg_n <= '0';
					byte_read_n <= "00";
					counter_n <= std_logic_vector(to_unsigned(c_animation_counter, counter'length));
				end if;
			when hit_1_anim =>
			----------------------------------------
			-- Player 1 hits opponent's ship
			----------------------------------------
				if byte_read = "00" then
					if unsigned(counter) <= 1 then
						addr_A_reg_n <= std_logic_vector(unsigned(counter(9 downto 0)) + 303);
					else
						addr_A_reg_n <= '0' & std_logic_vector(unsigned(shoot_position_out_reg));
					end if;
					byte_read_n <= "01";
				elsif byte_read = "01" then
					byte_read_n <= "11";
				else
					counter_n <= std_logic_vector(unsigned(counter) - 1);
					we_A <= '1';
					byte_read_n <= "00";
					data_ram <= unpack(data_read_ram);
					case to_integer(unsigned(counter)) is
					when 8333333 => 
						Sound_reg_n <= '1';
						ship_counter_n(10 downto 7) <= data_read_ram(10 downto 7);
					when 6666668 to 8333332 =>
						data_ram.tile_data(10 downto 7) <= x"8";
					when 5000002 to 6666667 =>
						data_ram.tile_data(10 downto 7) <= x"9";
					when 3333336 to 5000001 =>
						data_ram.tile_data(10 downto 7) <= x"a";
					when 1666670 to 3333335 =>
						data_ram.tile_data(10 downto 7) <= x"b";
					when 3 to 1666669 =>
						data_ram.tile_data(10 downto 7) <= x"c";
					when 2 =>
						data_ram.tile_data(10 downto 7) <= ship_counter(10 downto 7);
						data_ram.red_p2 <= '1';
					when 1 =>
						data_ram.tile_data(3 downto 0) <= enemy_hits(3 downto 0);
					when others =>
						data_ram.tile_data(3 downto 0) <= enemy_hits(7 downto 4);
						Sound_reg_n <= '0';
					end case;
					data_write_ram <= pack(data_ram);
				end if;
				if (unsigned(counter) = 0) and (byte_read = "11") then
					if (game_type_real_reg = '1') then
						game_state_n <= my_turn;
						counter_n <= (others => '0');
					else
						game_state_n <= his_turn;
						counter_n <= std_logic_vector(to_unsigned(c_fade_out_counter, counter'length));
					end if;
					byte_read_n <= "00";
				end if;
			when miss_1_anim =>
			----------------------------------------
			-- Player 1 misses opponent's ship
			----------------------------------------
				if byte_read = "00" then
					addr_A_reg_n <=  '0' & std_logic_vector(unsigned(shoot_position_out_reg));
					byte_read_n <= "01";
				elsif byte_read = "01" then
					byte_read_n <= "11";
				else
					counter_n <= std_logic_vector(unsigned(counter) - 1);
					we_A <= '1';
					byte_read_n <= "00";
					data_ram <= unpack(data_read_ram);
					case to_integer(unsigned(counter)) is
					when 8333333 => 
						ship_counter_n(10 downto 7) <= data_read_ram(10 downto 7);
					when 6666668 to 8333332 =>
						data_ram.tile_data(10 downto 7) <= x"8";
					when 5000002 to 6666667 =>               
						data_ram.tile_data(10 downto 7) <= x"9";
					when 3333336 to 5000001 =>               
						data_ram.tile_data(10 downto 7) <= x"a";
					when 1666670 to 3333335 =>               
						data_ram.tile_data(10 downto 7) <= x"b";
					when 3 to 1666669 =>                     
						data_ram.tile_data(10 downto 7) <= x"c";
					when others =>
						data_ram.tile_data(10 downto 7) <= ship_counter(10 downto 7);
						data_ram.grey_p2 <= '1';
					end case;
					data_write_ram <= pack(data_ram);
				end if;
				if (unsigned(counter) = 0) and (byte_read = "11") then
					game_state_n <= his_turn;
					byte_read_n <= "00";
					counter_n <= std_logic_vector(to_unsigned(c_fade_out_counter, counter'length));
				end if;
			when hit_2_anim =>
			----------------------------------------
			-- Player 2 hits my ship animation
			----------------------------------------
				if byte_read = "00" then
					case to_integer(unsigned(counter)) is
					when 2 to 3 =>
						case to_integer(unsigned(health(7 downto 4))) is
						when 4 => addr_A_reg_n <= std_logic_vector(to_unsigned(307, addr_A_reg'length));
						when 3 => addr_A_reg_n <= std_logic_vector(to_unsigned(308, addr_A_reg'length));
						when 2 => addr_A_reg_n <= std_logic_vector(to_unsigned(309, addr_A_reg'length));
						when 1 => addr_A_reg_n <= std_logic_vector(unsigned(counter(9 downto 0)) + 312);
						when 0 => addr_A_reg_n <= std_logic_vector(unsigned(counter(9 downto 0)) + 308);
						when others =>
						end case;
					when 0 to 1 =>
						addr_A_reg_n <= std_logic_vector(unsigned(counter(9 downto 0)) + 286);
					when others =>
						addr_A_reg_n <= std_logic_vector(unsigned('0' & shoot_position_in_reg));
					end case;
					byte_read_n <= "01";
				elsif byte_read = "01" then
					byte_read_n <= "11";
				else
					counter_n <= std_logic_vector(unsigned(counter) - 1);
					we_A <= '1';
					byte_read_n <= "00";
					data_ram <= unpack(data_read_ram);
					case to_integer(unsigned(counter)) is
					when 8333333 =>
						ship_counter_n(6 downto 0) <= data_read_ram(6 downto 0);
						data_ram.ship <= '0';
					when 6666668 to 8333332 =>
						data_ram.tile_data(6 downto 0) <= "000" & x"8";
					when 5000002 to 6666667 =>                      
						data_ram.tile_data(6 downto 0) <= "000" & x"9";
					when 3333336 to 5000001 =>                      
						data_ram.tile_data(6 downto 0) <= "000" & x"a";
					when 1666670 to 3333335 =>                      
						data_ram.tile_data(6 downto 0) <= "000" & x"b";
					when 5 to 1666669 =>                            
						data_ram.tile_data(6 downto 0) <= "000" & x"c";
					when 4 =>
						data_ram.tile_data(6 downto 0) <= ship_counter(6 downto 0);
						data_ram.red_p1 <= '1';
						data_ram.ship <= '1';
					when 2 to 3 =>
						case to_integer(unsigned(health(7 downto 4))) is
						when 4 => data_ram.tile_data <= "000" & x"29";
						when 3 => data_ram.tile_data <= "000" & x"2A";
						when 2 => data_ram.tile_data <= "000" & x"12";
						when 1 => data_ram.tile_data <= std_logic_vector(unsigned(counter(10 downto 0)) + 27);
						when 0 => data_ram.tile_data <= std_logic_vector(unsigned(counter(10 downto 0)) + 16);
						when others =>
						end case;
					when 1 =>
						data_ram.tile_data(3 downto 0) <= health(3 downto 0);
					when others =>
						data_ram.tile_data(3 downto 0) <= health(7 downto 4);
					end case;
					data_write_ram <= pack(data_ram);
				end if;
				if (unsigned(counter) = 0) and (byte_read = "11") then
					if (game_type_real_reg = '0') then
						game_state_n <= my_turn;
						counter_n <= std_logic_vector(to_unsigned(c_fade_out_counter, counter'length));
					else
						game_state_n <= his_turn;
						counter_n <= (others => '0');
					end if;
					hit_out_reg_n <= '0';
					byte_read_n <= "00";
				end if;
			when miss_2_anim =>
			----------------------------------------
			-- Player 2 misses my ship animation
			----------------------------------------
				if byte_read = "00" then
					addr_A_reg_n <= std_logic_vector(unsigned('0' & shoot_position_in_reg));
					byte_read_n <= "01";
				elsif byte_read = "01" then
					byte_read_n <= "11";
				else
					counter_n <= std_logic_vector(unsigned(counter) - 1);
					we_A <= '1';
					byte_read_n <= "00";
					data_ram <= unpack(data_read_ram);
					case to_integer(unsigned(counter)) is
					when 8333333 =>
						ship_counter_n(6 downto 0) <= data_read_ram(6 downto 0);
					when 6666668 to 8333332 =>
						data_ram.tile_data(6 downto 0) <= "000" & x"8";
					when 5000002 to 6666667 =>                      
						data_ram.tile_data(6 downto 0) <= "000" & x"9";
					when 3333336 to 5000001 =>                      
						data_ram.tile_data(6 downto 0) <= "000" & x"a";
					when 1666670 to 3333335 =>                      
						data_ram.tile_data(6 downto 0) <= "000" & x"b";
					when 3 to 1666669 =>                            
						data_ram.tile_data(6 downto 0) <= "000" & x"c";
					when others =>
						data_ram.tile_data(6 downto 0) <= ship_counter(6 downto 0);
						data_ram.grey_p1 <= '1';
					end case;
					data_write_ram <= pack(data_ram);
				end if;
				if (unsigned(counter) = 0) and (byte_read = "11") then
					game_state_n <= my_turn;
					miss_out_reg_n <= '0';
					byte_read_n <= "00";
					counter_n <= std_logic_vector(to_unsigned(c_fade_out_counter, counter'length));
				end if;
			when game_over =>
			----------------------------------------
			----------------------------------------
				if fade_in = '1' then
					if byte_read = "00" then
						addr_A_reg_n <= std_logic_vector(to_unsigned(320, addr_A_reg'length));
						byte_read_n <= "01";
					elsif byte_read = "01" then
						byte_read_n <= "10";
					elsif byte_read = "10" then
						data_ram <= unpack(data_read_ram);
						if unsigned(counter) = 0 then
							data_ram.tile_data(3 downto 2) <= "10";
							we_A <= '1';
						elsif unsigned(counter) = c_fade_out_counter-3 then -- 12 500 000 outside simulation -- 6250
							data_ram.tile_data(3 downto 2) <= "01";
							we_A <= '1';
						end if;
						data_write_ram <= pack(data_ram);
						byte_read_n <= "11";
					else
						byte_read_n <= "00";
						counter_n <= std_logic_vector(unsigned(counter) + 1);
						if unsigned(counter) = c_fade_out_counter-3 then -- 12 500 000 outside simulation
							fade_in_n <= '0';
							counter_n <= x"000140"; --20*16 (tiles + 1 info vector)
						end if;
					end if;
				else
					-- TODO: Change outgoing state
					if (unsigned(counter) = 0) and (button_r_ce_int = '1') then
						game_state_n <= init;
					elsif (unsigned(counter) > 0) then
						if byte_read = "00" then
							addr_A_reg_n <= std_logic_vector(unsigned(counter(addr_A'length-1 downto 0)));
							byte_read_n <= "01";
						else
							counter_n(11 downto 0) <= std_logic_vector(unsigned(counter(11 downto 0)) - 1);
							we_A <= '1';
							data_ram.HUD <= '1';
							case (to_integer(unsigned(counter(11 downto 0)))) is
							when 0 to 99 =>--green tile
								data_ram.tile_data <= "000" & x"00";
								data_ram.HUD <= '0';
							when 100 to 119 =>--tile up
								data_ram.tile_data <= "000" & x"72";
							when 120 to 139 =>--tile down
								data_ram.tile_data <= "000" & x"39";
							when 140 to 166 =>--black
								data_ram.tile_data <= "000" & x"74";
							when 167 to 172 =>--WINNER / LOSER
								if unsigned(enemy_hits) = 0 then
									data_ram.tile_data <= "000" & std_logic_vector(unsigned(counter(7 downto 0))-45);
								else
									data_ram.tile_data <= "000" & std_logic_vector(unsigned(counter(7 downto 0))-51);
								end if;
							when 173 to 199 =>--black
								data_ram.tile_data <= "000" & x"74";
							when 200 to 219 =>--tile up
								data_ram.tile_data <= "000" & x"72";
							when 220 to 239 =>--tile down
								data_ram.tile_data <= "000" & x"39";
							when 240 to 319 =>--green tile
								data_ram.tile_data <= "000" & x"00";
								data_ram.HUD <= '0';
							when 320 =>--infovector
								data_ram.tile_data <= (0 => '1', others => '0');
							when others =>--black
								data_ram.tile_data <= "000" & x"72";
							end case;
							data_write_ram <= pack(data_ram);
							byte_read_n <= "00";
						end if;
					end if;
			end if;
		end case;
	end process;


end Behavioral;
