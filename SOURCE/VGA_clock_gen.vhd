--------------------------------------------------------------------------------
-- Copyright (c) 1995-2013 Xilinx, Inc.  All rights reserved.
--------------------------------------------------------------------------------
--   ____  ____ 
--  /   /\/   / 
-- /___/  \  /    Vendor: Xilinx 
-- \   \   \/     Version : 14.7
--  \   \         Application : xaw2vhdl
--  /   /         Filename : VGA_clock_gen.vhd
-- /___/   /\     Timestamp : 11/03/2020 12:04:08
-- \   \  /  \ 
--  \___\/\___\ 
--
--Command: xaw2vhdl-st C:\Users\marosm\Documents\ISE_projects\MikroLode\ipcore_dir\.\VGA_clock_gen.xaw C:\Users\marosm\Documents\ISE_projects\MikroLode\ipcore_dir\.\VGA_clock_gen
--Design Name: VGA_clock_gen
--Device: xc3s200-5ft256
--
-- Module VGA_clock_gen
-- Generated by Xilinx Architecture Wizard
-- Written for synthesis tool: XST
-- Period Jitter (unit interval) for block DCM_INST2 = 0.11 UI
-- Period Jitter (Peak-to-Peak) for block DCM_INST2 = 1.00 ns

library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;
library UNISIM;
use UNISIM.Vcomponents.ALL;

entity VGA_clock_gen is
   port ( U1_CLKIN_IN        : in    std_logic; 
          U1_RST_IN          : in    std_logic; 
          U1_CLKIN_IBUFG_OUT : out   std_logic; 
          U1_CLK2X_OUT       : out   std_logic; 
          U1_STATUS_OUT      : out   std_logic_vector (7 downto 0); 
          U2_CLKFX_OUT       : out   std_logic; 
          U2_CLK0_OUT        : out   std_logic; 
          U2_LOCKED_OUT      : out   std_logic; 
          U2_STATUS_OUT      : out   std_logic_vector (7 downto 0));
end VGA_clock_gen;

architecture BEHAVIORAL of VGA_clock_gen is
   signal GND_BIT            : std_logic;
   signal U1_CLKIN_IBUFG     : std_logic;
   signal U1_CLK2X_BUF       : std_logic;
   signal U1_LOCKED_INV_IN   : std_logic;
   signal U2_CLKFB_IN        : std_logic;
   signal U2_CLKFX_BUF       : std_logic;
   signal U2_CLKIN_IN        : std_logic;
   signal U2_CLK0_BUF        : std_logic;
   signal U2_FDS_Q_OUT       : std_logic;
   signal U2_FD1_Q_OUT       : std_logic;
   signal U2_FD2_Q_OUT       : std_logic;
   signal U2_FD3_Q_OUT       : std_logic;
   signal U2_LOCKED_INV_RST  : std_logic;
   signal U2_OR3_O_OUT       : std_logic;
   signal U2_RST_IN          : std_logic;
begin
   GND_BIT <= '0';
   U1_CLKIN_IBUFG_OUT <= U1_CLKIN_IBUFG;
   U1_CLK2X_OUT <= U2_CLKIN_IN;
   U2_CLK0_OUT <= U2_CLKFB_IN;
   DCM_INST1 : DCM
   generic map( CLK_FEEDBACK => "2X",
            CLKDV_DIVIDE => 2.0,
            CLKFX_DIVIDE => 1,
            CLKFX_MULTIPLY => 4,
            CLKIN_DIVIDE_BY_2 => FALSE,
            CLKIN_PERIOD => 20.000,
            CLKOUT_PHASE_SHIFT => "NONE",
            DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS",
            DFS_FREQUENCY_MODE => "LOW",
            DLL_FREQUENCY_MODE => "LOW",
            DUTY_CYCLE_CORRECTION => TRUE,
            FACTORY_JF => x"8080",
            PHASE_SHIFT => 0,
            STARTUP_WAIT => FALSE)
      port map (CLKFB=>U2_CLKIN_IN,
                CLKIN=>U1_CLKIN_IBUFG,
                DSSEN=>GND_BIT,
                PSCLK=>GND_BIT,
                PSEN=>GND_BIT,
                PSINCDEC=>GND_BIT,
                RST=>U1_RST_IN,
                CLKDV=>open,
                CLKFX=>open,
                CLKFX180=>open,
                CLK0=>open,
                CLK2X=>U1_CLK2X_BUF,
                CLK2X180=>open,
                CLK90=>open,
                CLK180=>open,
                CLK270=>open,
                LOCKED=>U1_LOCKED_INV_IN,
                PSDONE=>open,
                STATUS(7 downto 0)=>U1_STATUS_OUT(7 downto 0));
   
   DCM_INST2 : DCM
   generic map( CLK_FEEDBACK => "1X",
            CLKDV_DIVIDE => 2.0,
            CLKFX_DIVIDE => 25,
            CLKFX_MULTIPLY => 27,
            CLKIN_DIVIDE_BY_2 => FALSE,
            CLKIN_PERIOD => 10.000,
            CLKOUT_PHASE_SHIFT => "NONE",
            DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS",
            DFS_FREQUENCY_MODE => "LOW",
            DLL_FREQUENCY_MODE => "LOW",
            DUTY_CYCLE_CORRECTION => TRUE,
            FACTORY_JF => x"8080",
            PHASE_SHIFT => 0,
            STARTUP_WAIT => FALSE)
      port map (CLKFB=>U2_CLKFB_IN,
                CLKIN=>U2_CLKIN_IN,
                DSSEN=>GND_BIT,
                PSCLK=>GND_BIT,
                PSEN=>GND_BIT,
                PSINCDEC=>GND_BIT,
                RST=>U2_RST_IN,
                CLKDV=>open,
                CLKFX=>U2_CLKFX_BUF,
                CLKFX180=>open,
                CLK0=>U2_CLK0_BUF,
                CLK2X=>open,
                CLK2X180=>open,
                CLK90=>open,
                CLK180=>open,
                CLK270=>open,
                LOCKED=>U2_LOCKED_OUT,
                PSDONE=>open,
                STATUS(7 downto 0)=>U2_STATUS_OUT(7 downto 0));
   
   U1_CLKIN_IBUFG_INST : IBUFG
      port map (I=>U1_CLKIN_IN,
                O=>U1_CLKIN_IBUFG);
   
   U1_CLK2X_BUFG_INST : BUFG
      port map (I=>U1_CLK2X_BUF,
                O=>U2_CLKIN_IN);
   
   U1_INV_INST : INV
      port map (I=>U1_LOCKED_INV_IN,
                O=>U2_LOCKED_INV_RST);
   
   U2_CLKFX_BUFG_INST : BUFG
      port map (I=>U2_CLKFX_BUF,
                O=>U2_CLKFX_OUT);
   
   U2_CLK0_BUFG_INST : BUFG
      port map (I=>U2_CLK0_BUF,
                O=>U2_CLKFB_IN);
   
   U2_FDS_INST : FDS
      port map (C=>U2_CLKIN_IN,
                D=>GND_BIT,
                S=>GND_BIT,
                Q=>U2_FDS_Q_OUT);
   
   U2_FD1_INST : FD
      port map (C=>U2_CLKIN_IN,
                D=>U2_FDS_Q_OUT,
                Q=>U2_FD1_Q_OUT);
   
   U2_FD2_INST : FD
      port map (C=>U2_CLKIN_IN,
                D=>U2_FD1_Q_OUT,
                Q=>U2_FD2_Q_OUT);
   
   U2_FD3_INST : FD
      port map (C=>U2_CLKIN_IN,
                D=>U2_FD2_Q_OUT,
                Q=>U2_FD3_Q_OUT);
   
   U2_OR2_INST : OR2
      port map (I0=>U2_LOCKED_INV_RST,
                I1=>U2_OR3_O_OUT,
                O=>U2_RST_IN);
   
   U2_OR3_INST : OR3
      port map (I0=>U2_FD3_Q_OUT,
                I1=>U2_FD2_Q_OUT,
                I2=>U2_FD1_Q_OUT,
                O=>U2_OR3_O_OUT);
   
end BEHAVIORAL;


