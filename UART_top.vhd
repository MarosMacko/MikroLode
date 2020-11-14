library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_top is
	generic(clk_f      : integer := 50_000_000; -- main clock frequency 
	        baud_rate  : integer := 115_200; -- data link baud rate [bit/s] 
	        os_rate    : integer := 16; -- oversampling rate to find center of receive bits [samples/baud period] --
	        data_width : integer := 8   -- data bus width --
	       );
	port(clk, rst      : in  std_logic;
	     ------------------------------	-- signals between UART & MP_LOGIC --
	     tx_data       : in  std_logic_vector(data_width - 1 downto 0);
	     tx_send_CE    : in  std_logic;
	     tx_busy       : out std_logic;
	     rx_data       : out std_logic_vector(data_width - 1 downto 0);
	     rx_receive_CE : out std_logic;
	     ------------------------------ -- communication signals between FPGA1 & FPGA2 --
	     RxD           : in  std_logic;
	     TxD           : out std_logic := '1'
	    );
end UART_top;

architecture Behavioral of UART_top is

	type tx_machine is (idle, start_bit, bit0, bit1, bit2, bit3, bit4, bit5, bit6, bit7, stop_bit); -- tranmit state machine data type --
	type rx_machine is (idle, bit0, bit1, bit2, bit3, bit4, bit5, bit6, bit7, stop_bit); -- recieve state machine data type --
	signal tx_state, tx_state_next                : tx_machine                                         := idle; -- transmit state machine --
	signal rx_state, rx_state_next                : rx_machine                                         := idle; -- recieve state machine -- 
	-------------------------------------------
	signal baud_CE                                : std_logic;
	signal os_CE                                  : std_logic;
	signal tx_buffer, tx_buffer_r                 : std_logic_vector(data_width - 1 downto 0)          := (others => '1');
	signal baud_cnt, baud_cnt_next                : unsigned((clk_f / baud_rate) downto 0)             := (others => '0'); -- counter [0-434] to determine baud rate period --
	signal os_cnt, os_cnt_next                    : unsigned((clk_f / (baud_rate * os_rate)) downto 0) := (others => '0'); -- counter [0-27] to determine oversampling period --
	signal TxD_r                                  : std_logic;
	signal rx_buffer, rx_buffer_r                 : std_logic_vector(data_width - 1 downto 0)          := (others => '1');
	signal middle_period_cnt, middle_period_cnt_r : unsigned(5 downto 0)                               := (others => '0');

begin

	----------------------------
	--    SEQUENTIAL LOGIC    --
	----------------------------
	process(clk, rst)
	begin
		if rst = '1' then
			tx_state          <= idle;
			rx_state          <= idle;
			baud_cnt          <= (others => '0');
			os_cnt            <= (others => '0');
			TxD               <= '1';
			tx_buffer         <= (others => '1');
			rx_buffer         <= (others => '1');
			middle_period_cnt <= (others => '0');
		elsif rising_edge(clk) then
			tx_state          <= tx_state_next;
			rx_state          <= rx_state_next;
			baud_cnt          <= baud_cnt_next;
			os_cnt            <= os_cnt_next;
			tx_buffer         <= tx_buffer_r;
			rx_buffer         <= rx_buffer_r;
			TxD               <= TxD_r;
			middle_period_cnt <= middle_period_cnt_r;
		end if;
	end process;

	-----------------------------
	-- 		  GENERATOR        --
	-- 	   BAUD_CE & OS_CE	   --
	-----------------------------
	process(baud_cnt, os_cnt)
	begin
		baud_CE       <= '0';
		os_CE         <= '0';
		baud_cnt_next <= baud_cnt;
		os_cnt_next   <= os_cnt;

		if (baud_cnt < (to_unsigned((clk_f / baud_rate) - 1, 9))) then -- create BAUD_CE pulse --
			baud_cnt_next <= baud_cnt + 1; -- increment baud period counter --
			baud_CE       <= '0';
		else                            -- baud period reached --
			baud_cnt_next <= (others => '0'); -- reset baud period counter --
			baud_CE       <= '1';       -- assert baud rate pulse --
		end if;

		if (os_cnt < (to_unsigned((clk_f / (baud_rate * os_rate)) - 1, 5))) then -- create OS_CE pulse --
			os_cnt_next <= os_cnt + 1;  --increment oversampling period counter --
		else                            -- oversampling period reached --
			os_cnt_next <= (others => '0'); -- reset oversampling period counter --
			os_CE       <= '1';         --assert oversampling pulse --
		end if;
	end process;

	----------------------------
	-- TRANSMIT STATE MACHINE --
	----------------------------
	process(baud_CE, tx_data, tx_send_CE, tx_state, tx_buffer(0), tx_buffer)
		--variable tx_cnt : integer range 0 to data_width := 0; -- counter for trasnmitted bits --
	begin
		--	tx_cnt        := 0;             -- clear transmit bit counter --
		tx_busy       <= '1';           -- set transmit busy signal to indicate unavailable --
		tx_buffer_r   <= tx_buffer;
		tx_state_next <= tx_state;

		case tx_state is
			when idle =>                -- idle_start_bit state --
				if (tx_send_CE = '1') then -- new data ready to send --
					tx_buffer_r   <= tx_data; -- latch in data for transmission --
					tx_busy       <= '1'; -- assert transmit busy flag --
					--			tx_cnt        := 0;
					TxD_r         <= '1';
					tx_state_next <= start_bit;
				else                    -- no new transaction initiated --
					tx_busy       <= '0'; -- clear transmit busy flag --
					TxD_r         <= '1';
					tx_state_next <= idle; -- remain in idle state --
				end if;

			when start_bit =>
				if (baud_CE = '1') then
					TxD_r         <= '0'; -- send start bit --
					tx_state_next <= bit0;
				else
					TxD_r <= '1';
				end if;

			when bit0 =>
				if (baud_CE = '1') then
					TxD_r         <= tx_buffer(0);
					tx_state_next <= bit1;
				else
					tx_state_next <= bit0;
					TxD_r         <= '0';
				end if;

			when bit1 =>
				if (baud_CE = '1') then
					TxD_r         <= tx_buffer(1);
					tx_state_next <= bit2;
				else
					tx_state_next <= bit1;
					TxD_r         <= tx_buffer(0);
				end if;

			when bit2 =>
				if (baud_CE = '1') then
					TxD_r         <= tx_buffer(2);
					tx_state_next <= bit3;
				else
					tx_state_next <= bit2;
					TxD_r         <= tx_buffer(1);
				end if;

			when bit3 =>
				if (baud_CE = '1') then
					TxD_r         <= tx_buffer(3);
					tx_state_next <= bit4;
				else
					tx_state_next <= bit3;
					TxD_r         <= tx_buffer(2);
				end if;

			when bit4 =>
				if (baud_CE = '1') then
					TxD_r         <= tx_buffer(4);
					tx_state_next <= bit5;
				else
					tx_state_next <= bit4;
					TxD_r         <= tx_buffer(3);
				end if;

			when bit5 =>
				if (baud_CE = '1') then
					TxD_r         <= tx_buffer(5);
					tx_state_next <= bit6;
				else
					tx_state_next <= bit5;
					TxD_r         <= tx_buffer(4);
				end if;

			when bit6 =>
				if (baud_CE = '1') then
					TxD_r         <= tx_buffer(6);
					tx_state_next <= bit7;
				else
					tx_state_next <= bit6;
					TxD_r         <= tx_buffer(5);
				end if;

			when bit7 =>
				if (baud_CE = '1') then
					TxD_r         <= tx_buffer(7);
					tx_state_next <= stop_bit;
				else
					tx_state_next <= bit7;
					TxD_r         <= tx_buffer(6);
				end if;

			when stop_bit =>
				if (baud_CE = '1') then
					TxD_r         <= '1'; -- send stop bit --
					tx_state_next <= idle;
				else
					tx_state_next <= stop_bit;
					TxD_r         <= tx_buffer(7);
				end if;

		end case;
	end process;

	----------------------------
	-- RECIEVE STATE MACHINE --
	----------------------------
	process(RxD, os_CE, rx_state, rx_buffer, middle_period_cnt)
	begin
		rx_state_next       <= rx_state;
		middle_period_cnt_r <= middle_period_cnt;
		rx_buffer_r         <= rx_buffer;
		rx_receive_CE       <= '0';
		case rx_state is
			when idle =>
				if (os_CE = '1') then
					rx_receive_CE <= '0';
					if (RxD = '0') then
						if (middle_period_cnt < os_rate / 2) then
							middle_period_cnt_r <= middle_period_cnt + 1;
							rx_state_next       <= idle;
						else
							middle_period_cnt_r <= (others => '0');
							rx_state_next       <= bit0;
						end if;
					else
						middle_period_cnt_r <= (others => '0');
						rx_state_next       <= idle;
					end if;
				else
					rx_state_next <= idle;
				end if;

			when bit0 =>
				if (os_CE = '1') then
					if (middle_period_cnt < os_rate - 1) then
						middle_period_cnt_r <= middle_period_cnt + 1;
						rx_state_next       <= bit0;
					else
						middle_period_cnt_r <= (others => '0');
						rx_buffer_r(0)      <= RxD;
						rx_state_next       <= bit1;
					end if;
				end if;

			when bit1 =>
				if (os_CE = '1') then
					if (middle_period_cnt < os_rate - 1) then
						middle_period_cnt_r <= middle_period_cnt + 1;
						rx_state_next       <= bit1;
					else
						middle_period_cnt_r <= (others => '0');
						rx_buffer_r(1)      <= RxD;
						rx_state_next       <= bit2;
					end if;
				end if;

			when bit2 =>
				if (os_CE = '1') then
					if (middle_period_cnt < os_rate - 1) then
						middle_period_cnt_r <= middle_period_cnt + 1;
						rx_state_next       <= bit2;
					else
						middle_period_cnt_r <= (others => '0');
						rx_buffer_r(2)      <= RxD;
						rx_state_next       <= bit3;
					end if;
				end if;

			when bit3 =>
				if (os_CE = '1') then
					if (middle_period_cnt < os_rate - 1) then
						middle_period_cnt_r <= middle_period_cnt + 1;
						rx_state_next       <= bit3;
					else
						middle_period_cnt_r <= (others => '0');
						rx_buffer_r(3)      <= RxD;
						rx_state_next       <= bit4;
					end if;
				end if;

			when bit4 =>
				if (os_CE = '1') then
					if (middle_period_cnt < os_rate - 1) then
						middle_period_cnt_r <= middle_period_cnt + 1;
						rx_state_next       <= bit4;
					else
						middle_period_cnt_r <= (others => '0');
						rx_buffer_r(4)      <= RxD;
						rx_state_next       <= bit5;
					end if;
				end if;

			when bit5 =>
				if (os_CE = '1') then
					if (middle_period_cnt < os_rate - 1) then
						middle_period_cnt_r <= middle_period_cnt + 1;
						rx_state_next       <= bit5;
					else
						middle_period_cnt_r <= (others => '0');
						rx_buffer_r(5)      <= RxD;
						rx_state_next       <= bit6;
					end if;
				end if;

			when bit6 =>
				if (os_CE = '1') then
					if (middle_period_cnt < os_rate - 1) then
						middle_period_cnt_r <= middle_period_cnt + 1;
						rx_state_next       <= bit6;
					else
						middle_period_cnt_r <= (others => '0');
						rx_buffer_r(6)      <= RxD;
						rx_state_next       <= bit7;
					end if;
				end if;

			when bit7 =>
				if (os_CE = '1') then
					if (middle_period_cnt < os_rate - 1) then
						middle_period_cnt_r <= middle_period_cnt + 1;
						rx_state_next       <= bit7;
					else
						middle_period_cnt_r <= (others => '0');
						rx_buffer_r(7)      <= RxD;
						rx_state_next       <= stop_bit;
					end if;
				end if;

			when stop_bit =>
				if (os_CE = '1') then
					if (middle_period_cnt < os_rate - 1) then
						middle_period_cnt_r <= middle_period_cnt + 1;
						rx_state_next       <= stop_bit;
					else
						middle_period_cnt_r <= (others => '0');
						rx_receive_CE       <= '1';
						rx_state_next       <= idle;
					end if;
				end if;
		end case;
		rx_data             <= rx_buffer;
	end process;

end Behavioral;
