--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   15:45:50 01/26/2021
-- Design Name:   
-- Module Name:   C:/Users/Matej/git/MikroLode/SIMULATION_SOURCES/top_beh.vhd
-- Project Name:  MikroLode
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: TOP
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
--USE ieee.numeric_std.ALL;
 
ENTITY top_beh IS
END top_beh;
 
ARCHITECTURE behavior OF top_beh IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT TOP
    PORT(
         clk : IN  std_logic;
         rst_button : IN  std_logic;
         ps2_clock_pin : INOUT  std_logic;
         ps2_data_pin : INOUT  std_logic;
         uart_tx : OUT  std_logic;
         uart_rx : IN  std_logic;
         vga_R : OUT  std_logic_vector(6 downto 0);
         vga_G : OUT  std_logic_vector(6 downto 0);
         vga_B : OUT  std_logic_vector(6 downto 0);
         vga_VS : OUT  std_logic;
         vga_HS : OUT  std_logic;
         audio_out : OUT  std_logic_vector(7 downto 0);
         buttons : IN  std_logic_vector(7 downto 0);
         buzzer : OUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal clk : std_logic := '0';
   signal rst_button : std_logic := '0';
   signal uart_rx : std_logic := '0';
   signal buttons : std_logic_vector(7 downto 0) := (others => '0');

	--BiDirs
   signal ps2_clock_pin : std_logic;
   signal ps2_data_pin : std_logic;

 	--Outputs
   signal uart_tx : std_logic;
   signal vga_R : std_logic_vector(6 downto 0);
   signal vga_G : std_logic_vector(6 downto 0);
   signal vga_B : std_logic_vector(6 downto 0);
   signal vga_VS : std_logic;
   signal vga_HS : std_logic;
   signal audio_out : std_logic_vector(7 downto 0);
   signal buzzer : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: TOP PORT MAP (
          clk => clk,
          rst_button => rst_button,
          ps2_clock_pin => ps2_clock_pin,
          ps2_data_pin => ps2_data_pin,
          uart_tx => uart_tx,
          uart_rx => uart_rx,
          vga_R => vga_R,
          vga_G => vga_G,
          vga_B => vga_B,
          vga_VS => vga_VS,
          vga_HS => vga_HS,
          audio_out => audio_out,
          buttons => buttons,
          buzzer => buzzer
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
      rst_button <= '1';
      wait for 100 ns;
      rst_button <= '0';

      wait for clk_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
