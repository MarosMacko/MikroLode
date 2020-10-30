----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:43:45 10/17/2020 
-- Design Name: 
-- Module Name:    TOP - Behavioral 
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

    type game_state_enum is (init, start, placement, wait4player, local_turn, remote_turn, lost, won);
    signal game_state : game_state_enum := init;

    -- PS/2 signals
    signal mouse_x                      : STD_LOGIC_VECTOR(10 downto 0);
    signal mouse_y                      : STD_LOGIC_VECTOR(10 downto 0);
    signal button_l, button_r, button_m : STD_LOGIC;
    signal ps2_newdata_flag             : STD_LOGIC;

    -- Multi-player logic signals
    signal data_mp_out    : STD_LOGIC_VECTOR(8 downto 0);
    signal data_mp_out_en : STD_LOGIC;
    signal data_mp_in     : STD_LOGIC_VECTOR(8 downto 0);
    signal data_mp_in_en  : STD_LOGIC;

    -- Sound unit signals
    signal sound_play : STD_LOGIC_VECTOR(1 downto 0);

    --======================================================
    --                  TOP COMPONENTS                                   
    --======================================================

    -- PS2 component 

    -- UART / MultiPlayer component

    -- VGA component

    -- Sound component

    -- Game logic component

begin

    -- PS2 component
    -- port map here

    -- UART / MultiPlayer component
    -- port map here

    -- VGA component
    -- port map here

    -- Sound component
    -- port map here

    -- Game logic component
    -- port map here

end Behavioral;

