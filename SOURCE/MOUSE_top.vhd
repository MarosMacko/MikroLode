library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity MOUSE_top is
    Port(ps2_clock_pin : inout STD_LOGIC;
         ps2_data_pin  : inout STD_LOGIC;
         clk, rst      : in    STD_LOGIC;
         position_x    : out   STD_LOGIC_VECTOR(10 downto 0);
         position_y    : out   STD_LOGIC_VECTOR(9 downto 0);
         button_l      : out   STD_LOGIC;
         button_r      : out   STD_LOGIC;
         button_m      : out   STD_LOGIC);
end MOUSE_top;

architecture Behavioral of MOUSE_top is
    --iobuf signaly
    signal IN_SIG_cl, OUT_SIG_cl, T_ENABLE_cl    : std_logic;
    signal IN_SIG_dat, OUT_SIG_dat, T_ENABLE_dat : std_logic;

    --pomocne signaly
    signal ps2c_deb     : std_logic;    --vystup z debouncra pre ps2c
    signal ps2c_fall    : std_logic;    --detekovana sestupna hrana
    signal rx_en        : std_logic;    --enable pre citanie
    signal rx_done_en   : std_logic;    --uspesne nacitanie dat z mouse
    signal tx_en        : std_logic;    --enable pre zapis
    signal tx_done_en   : std_logic;    --uspesne odoslanie to mouse
	 signal CE_rdy: std_logic;	
    signal num_to_mouse : std_logic_vector(7 downto 0); -- znak posielany do mouse
    signal rx_data      : std_logic_vector(7 downto 0); -- precitane data z mouse
	 signal plus_x, plus_y : std_logic_vector (10 downto 0);
	 
	 signal btn_l, btn_l_pom : std_logic;
	 signal btn_r, btn_r_pom: std_logic;
	 signal btn_m, btn_m_pom: std_logic;
	 signal x_data: std_logic_vector (8 downto 0);			
	 signal y_data: std_logic_vector (8 downto 0);
	 signal x_pretec: std_logic;		
	 signal y_pretec: std_logic;	
	 signal pos_x_next, pos_x, pos_x_pom: std_logic_vector (10 downto 0);			
	 signal pos_y_next, pos_y, pos_y_pom: std_logic_vector (10 downto 0);
		

    component debouncer is
        port(clk, ps2c : in  STD_LOGIC;
             ps2c_deb  : out STD_LOGIC);
    end component;

    component detec_falling_endge is
        port(ps2c_deb, clk, rst : in  STD_LOGIC;
             ps2c_fall          : out STD_LOGIC);
    end component;

    component ps2_tx is
        port(ps2c_fall, ps2d_out : in  STD_LOGIC;
             clk, rst            : in  STD_LOGIC;
             num_to_mouse        : in  std_logic_vector(7 downto 0);
             tx_en               : in  STD_LOGIC;
             ps2c_t_en, ps2c_in  : out STD_LOGIC;
             ps2d_t_en, ps2d_in  : out STD_LOGIC;
             tx_done_en          : out STD_LOGIC);
    end component;

    component ps2_rx is
        port(clk, rst        : in  STD_LOGIC;
             ps2d, ps2c_fall : in  STD_LOGIC;
             rx_en           : in  STD_LOGIC;
             rx_done_en      : out STD_LOGIC;
             ps2d_data       : out STD_LOGIC_VECTOR(7 downto 0));
    end component;

    component state_log_m is
		port(clk, rst                     : in  STD_LOGIC;
         tx_done_en, rx_done_en       : in  STD_LOGIC;
         rx_data                      : in  STD_LOGIC_VECTOR(7 downto 0);
         tx_en, rx_en, CE_rdy                 : out STD_LOGIC;
         num_to_mouse                 : out STD_LOGIC_VECTOR(7 downto 0);
         btn_l_out, btn_r_out, btn_m_out : out STD_LOGIC;
			x_pretec_out, y_pretec_out		: out STD_LOGIC;
         x_data_out                   : out STD_LOGIC_VECTOR(8 downto 0);
         y_data_out                   : out STD_LOGIC_VECTOR(8 downto 0));
	end component;
	
	component scitac_11bit is
    Port ( a, b : in  STD_LOGIC_VECTOR (10 downto 0);
           y : out  STD_LOGIC_VECTOR (10 downto 0));
	end component;

begin
    ps2c_iobuf : IOBUF
        port map(I => OUT_SIG_cl, T => T_ENABLE_cl, O => IN_SIG_cl, IO => ps2_clock_pin);
    ps2d_iobuf : IOBUF
        port map(I => OUT_SIG_dat, T => T_ENABLE_dat, O => IN_SIG_dat, IO => ps2_data_pin);

    debounc_ps2c : debouncer
        port map(clk => clk, ps2c => IN_SIG_cl, ps2c_deb => ps2c_deb);

    detekovanie_falling_edge : detec_falling_endge
        port map(ps2c_deb => ps2c_deb, clk => clk, rst => rst, ps2c_fall => ps2c_fall);

    zapis_do_mouse : ps2_tx
        port map(ps2c_fall    => ps2c_fall, ps2d_out => IN_SIG_dat, clk => clk, rst => rst, num_to_mouse => num_to_mouse, tx_en => tx_en,
                 ps2c_t_en    => T_ENABLE_cl, ps2c_in => OUT_SIG_cl, ps2d_t_en => T_ENABLE_dat, ps2d_in => OUT_SIG_dat, tx_done_en => tx_done_en);

    citanie_z_mouse : ps2_rx
        port map(ps2c_fall  => ps2c_fall, ps2d => IN_SIG_dat, clk => clk, rst => rst, rx_en => rx_en, ps2d_data => rx_data,
                 rx_done_en => rx_done_en);

    hlavny_stav_automat : state_log_m
        port map(clk          => clk, rst => rst, tx_done_en => tx_done_en, rx_done_en => rx_done_en, rx_data => rx_data, tx_en => tx_en, rx_en => rx_en,
                 btn_l_out     => btn_l, btn_r_out => btn_r, btn_m_out => btn_m, x_data_out  => x_data, y_data_out => y_data, 
					  num_to_mouse => num_to_mouse, CE_rdy => CE_rdy, x_pretec_out => x_pretec, y_pretec_out => y_pretec);
					  
	--position decoder x
process (x_data)
begin
	if (x_data(8) = '1') then
		plus_x <= "11" & x_data(8 downto 0);
	else 
		plus_x <= "00" & x_data(8 downto 0);
	end if;
end process;

--position decoder y
process (y_data)
begin	
	if (y_data(8) = '0') then
		plus_y <= "11" & not (y_data(8 downto 0));
	else 
		plus_y <= "00" & not (y_data(8 downto 0));
	end if;
end process;

scitanie_pos_x: scitac_11bit
		port map (a => pos_x_next, b => plus_x, y => pos_x_pom);

scitanie_pos_y: scitac_11bit
		port map (a => pos_y_next, b => plus_y, y => pos_y_pom);
		
--synchronna pozice		
process (clk, rst, CE_rdy)
	begin
		if (rst = '1') then
			pos_x_next <= "01001111111";
			pos_y_next <= "00111111111";
			btn_r_pom <= '0';
			btn_l_pom <= '0';
			btn_m_pom <= '0';
		elsif(clk'event and clk='1') then
			if ( CE_rdy = '1') then
				pos_x_next <= pos_x;
				pos_y_next <= pos_y;
				btn_r_pom <= btn_r;
				btn_l_pom <= btn_l;
				btn_m_pom <= btn_m;
			end if;
		end if;end process;

--pretecenie x mimo obraz
pos_x <= "10011111111" when unsigned(pos_x_pom) > "10011111111" else pos_x_pom;
--osetrenie y posledneho bitu
pos_y <= "01111111111" when unsigned(pos_y_pom) > "01111111111" else pos_y_pom;

position_x <= pos_x_next;
position_y <= pos_y_next(9 downto 0);
button_l <= btn_l_pom;
button_r <= btn_r_pom;
button_m <= btn_m_pom;


end Behavioral;