--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   09:54:47 12/01/2020
-- Design Name:   
-- Module Name:   C:/Users/Matej/git/MikroLode/game_logic_T.vhd
-- Project Name:  MikroLode
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: Game_logic_top
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
USE ieee.numeric_std.ALL;
 
ENTITY game_logic_T IS
END game_logic_T;
 
ARCHITECTURE behavior OF game_logic_T IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Game_logic_top
    PORT(
         pos_x : IN  std_logic_vector(10 downto 0);
         pos_y : IN  std_logic_vector(9 downto 0);
         button_r_ce : IN  std_logic;
         button_l_ce : IN  std_logic;
         scroll_up_ce : IN  std_logic;
         scroll_down_ce : IN  std_logic;
         clk : IN  std_logic;
         rst : IN  std_logic;
         turn : IN  std_logic;
         miss_in : IN  std_logic;
         hit_in : IN  std_logic;
         game_type_real : IN  std_logic;
         shoot_position_in : IN  std_logic_vector(8 downto 0);
         shoot_position_out : OUT  std_logic_vector(8 downto 0);
         hit_out : OUT  std_logic;
         miss_out : OUT  std_logic;
         game_type_want : OUT  std_logic;
         data_read_ram : IN  std_logic_vector(17 downto 0);
         data_write_ram : OUT  std_logic_vector(17 downto 0);
         we_A : OUT  std_logic;
         addr_A : OUT  std_logic_vector(9 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal pos_x : std_logic_vector(10 downto 0) := (others => '0');
   signal pos_y : std_logic_vector(9 downto 0) := (others => '0');
   signal button_r_ce : std_logic := '0';
   signal button_l_ce : std_logic := '0';
   signal scroll_up_ce : std_logic := '0';
   signal scroll_down_ce : std_logic := '0';
   signal clk : std_logic := '0';
   signal rst : std_logic := '0';
   signal turn : std_logic := '0';
   signal miss_in : std_logic := '0';
   signal hit_in : std_logic := '0';
   signal game_type_real : std_logic := '0';
   signal shoot_position_in : std_logic_vector(8 downto 0) := (others => '0');
   signal data_read_ram : std_logic_vector(17 downto 0) := (others => '0');

 	--Outputs
   signal shoot_position_out : std_logic_vector(8 downto 0);
   signal hit_out : std_logic;
   signal miss_out : std_logic;
   signal game_type_want : std_logic;
   signal data_write_ram : std_logic_vector(17 downto 0);
   signal we_A : std_logic;
   signal addr_A : std_logic_vector(9 downto 0);

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Game_logic_top PORT MAP (
          pos_x => pos_x,
          pos_y => pos_y,
          button_r_ce => button_r_ce,
          button_l_ce => button_l_ce,
          scroll_up_ce => scroll_up_ce,
          scroll_down_ce => scroll_down_ce,
          clk => clk,
          rst => rst,
          turn => turn,
          miss_in => miss_in,
          hit_in => hit_in,
          game_type_real => game_type_real,
          shoot_position_in => shoot_position_in,
          shoot_position_out => shoot_position_out,
          hit_out => hit_out,
          miss_out => miss_out,
          game_type_want => game_type_want,
          data_read_ram => data_read_ram,
          data_write_ram => data_write_ram,
          we_A => we_A,
          addr_A => addr_A
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
   	-- hold reset state for 100 ns.
   		rst <= '1';
   	wait for 100 ns;
   		rst <= '0';	
      wait for 1000 ns;
      	pos_x <= std_logic_vector(to_unsigned(300, pos_x'length));
      	pos_y <= std_logic_vector(to_unsigned(300, pos_y'length));
		button_l_ce <= '1';
	wait for clk_period;
		button_l_ce <= '0';
	wait for 10000 ns;
		button_l_ce <= '1';
	wait for clk_period;
		button_l_ce <= '0';
      wait for 10 us;
		turn <= '1';      
      	game_type_real <= '1';
      	
      wait for clk_period*100;
      	button_l_ce <= '1';
      wait for clk_period;
      	button_l_ce <= '0';
      	
      wait for clk_period*100;
      	turn <= '0';
      	miss_in <= '1';

      -- insert stimulus here 

      wait;
   end process;

END;
