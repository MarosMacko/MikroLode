library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_top is
    generic(clk_f      : integer := 50000000; -- main clock frequency 
            baud_rate  : integer := 9600; -- data link baud rate [bit/s] 
            os_rate    : integer := 16; -- oversampling rate to find center of receive bits [samples/baud period] --
            data_width : integer := 8   -- data bus width --
           );
    port(clk, rst      : in  std_logic;
         ------------------------------ -- signals between UART & MP_LOGIC --
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

    type tx_machine is (idle, start_bit, transmit, stop_bit); -- tranmit state machine data type --
    type rx_machine is (idle_start_bit, receive, stop_bit); -- receive state machine data type --
    signal tx_state, tx_state_next                : tx_machine                                := idle; -- transmit state machine --
    signal rx_state, rx_state_next                : rx_machine                                := idle_start_bit; -- receive state machine -- 
    -------------------------------------------
    signal baud_CE                                : std_logic;
    signal os_CE                                  : std_logic;
    signal tx_buffer, tx_buffer_r                 : std_logic_vector(data_width - 1 downto 0) := (others => '1');
    signal baud_cnt, baud_cnt_next                : unsigned(12 downto 0)                     := (others => '0'); -- counter [0-5208] to determine baud rate period --
    signal os_cnt, os_cnt_next                    : unsigned(8 downto 0)                      := (others => '0'); -- counter [0-325] to determine oversampling period --
    signal rx_buffer, rx_buffer_r                 : std_logic_vector(data_width - 1 downto 0) := (others => '1');
    signal middle_period_cnt, middle_period_cnt_r : unsigned(5 downto 0)                      := (others => '0');
    signal tx_cnt, tx_cnt_r, rx_cnt, rx_cnt_r     : unsigned(3 downto 0)                      := (others => '0'); -- counter for transmit bites --
    signal TxData, TxData_r                       : std_logic                                 := '1'; -- registered output --
    -------------------------------------------

begin

    ----------------------------
    --    SEQUENTIAL LOGIC    --
    ----------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            tx_state          <= idle;
            rx_state          <= idle_start_bit;
            baud_cnt          <= (others => '0');
            os_cnt            <= (others => '0');
            tx_buffer         <= (others => '1');
            rx_buffer         <= (others => '1');
            middle_period_cnt <= (others => '0');
            tx_cnt            <= (others => '0');
            rx_cnt            <= (others => '0');
            TxData            <= '1';
        elsif rising_edge(clk) then
            tx_state          <= tx_state_next; -- Tx state machine register --
            rx_state          <= rx_state_next; -- Rx state machine register --
            baud_cnt          <= baud_cnt_next; -- counter for baud rate [115 200] --
            os_cnt            <= os_cnt_next; -- counter for over sampling [16] --
            tx_buffer         <= tx_buffer_r; -- register for transmit byte --
            rx_buffer         <= rx_buffer_r; -- register for receive byte --
            TxData            <= TxData_r; -- output register --
            middle_period_cnt <= middle_period_cnt_r; -- counter to determine middle of baud period--
            tx_cnt            <= tx_cnt_r; -- transmit bit counter --
            rx_cnt            <= rx_cnt_r; --receive bit counter --
        end if;
    end process;

    -----------------------------
    --        GENERATOR        --
    --     BAUD_CE & OS_CE     --
    -----------------------------
    process(baud_cnt, os_cnt)
    begin
        baud_CE       <= '0';
        os_CE         <= '0';
        baud_cnt_next <= baud_cnt;
        os_cnt_next   <= os_cnt;

        if (baud_cnt < (to_unsigned((clk_f / baud_rate) - 1, 13))) then -- create BAUD_CE pulse --
            baud_cnt_next <= baud_cnt + 1; -- increment baud period counter --
            baud_CE       <= '0';
        else                            -- baud period reached --
            baud_cnt_next <= (others => '0'); -- reset baud period counter --
            baud_CE       <= '1';       -- assert baud rate pulse --
        end if;

        if (os_cnt < (to_unsigned((clk_f / (baud_rate * os_rate)) - 1, 9))) then -- create OS_CE pulse --
            os_cnt_next <= os_cnt + 1;  --increment oversampling period counter --
        else                            -- oversampling period reached --
            os_cnt_next <= (others => '0'); -- reset oversampling period counter --
            os_CE       <= '1';         --assert oversampling pulse --
        end if;
    end process;

    ----------------------------
    -- TRANSMIT STATE MACHINE --
    ----------------------------
    process(baud_CE, tx_data, tx_send_CE, tx_state, tx_buffer(0), tx_buffer, tx_cnt, TxData)
    begin
        tx_busy       <= '1';           -- set transmit busy signal to indicate unavailable --
        tx_buffer_r   <= tx_buffer;
        tx_state_next <= tx_state;
        tx_cnt_r      <= tx_cnt;
        TxData_r      <= TxData;
        case tx_state is
            when idle =>                -- idle state --
                if (tx_send_CE = '1') then -- new data ready to send --
                    tx_buffer_r   <= tx_data; -- latch in data for transmission --
                    tx_busy       <= '1'; -- assert transmit busy flag --
                    tx_state_next <= start_bit; -- go to next state start_bit --
                else                    -- no new transaction initiated --
                    tx_busy       <= '0'; -- clear transmit busy flag --
                    tx_state_next <= idle; -- remain in idle state --
                end if;

            when start_bit =>           -- start_bit state --
                if (baud_CE = '1') then -- send bit, when BAUD_CE is active --
                    TxData_r      <= '0'; -- send start bit --
                    tx_state_next <= transmit;
                end if;

            when transmit =>            -- transmit state --
                if (baud_CE = '1') then -- send bit, when BAUD_CE is active --
                    tx_cnt_r    <= tx_cnt + 1; -- increment transmit bit counter --
                    tx_buffer_r <= '1' & tx_buffer(data_width - 1 downto 1); -- shift transmit buffer to output next bit --
                    TxData_r    <= tx_buffer(0); -- output last bit in transmit transaction buffer --
                end if;

                if (tx_cnt < data_width) then -- not all bits transmitted --
                    tx_state_next <= transmit; -- remain in transmit state --
                else                    -- all bits transmitted --
                    tx_state_next <= stop_bit; -- go to stop_bit state --
                    tx_cnt_r      <= (others => '0'); -- reset counter --
                end if;

            when stop_bit =>            -- stop_bit state --
                if (baud_CE = '1') then
                    TxData_r      <= '1'; -- send stop bit --
                    tx_state_next <= idle; -- go to idle state --
                end if;
        end case;
        TxD <= TxData;
    end process;

    ----------------------------
    -- RECEIVE STATE MACHINE --
    ----------------------------
    process(RxD, os_CE, rx_state, rx_buffer, middle_period_cnt, rx_cnt)
    begin
        rx_receive_CE       <= '0';
        rx_state_next       <= rx_state;
        middle_period_cnt_r <= middle_period_cnt;
        rx_buffer_r         <= rx_buffer;
        rx_cnt_r            <= rx_cnt;

        case rx_state is

            when idle_start_bit =>      -- idle and start_bit state --
                if (os_CE = '1') then   -- enable pulse at oversampling rate --     
                    if (RxD = '0') then -- check for start bit --
                        if (middle_period_cnt < os_rate / 2) then -- oversampling pulse counter is not at start bit center --
                            middle_period_cnt_r <= middle_period_cnt + 1; -- increment oversampling pulse counter --
                        else            -- oversampling pulse counter is at bit center --
                            middle_period_cnt_r <= (others => '0'); -- clear oversampling pulse counter --
                            rx_state_next       <= receive; -- go to receive state --
                        end if;
                    end if;
                end if;

            when receive =>             -- receive state --
                if (os_CE = '1') then   -- enable pulse at oversampling rate -- 
                    if (middle_period_cnt < os_rate - 1) then -- not center of bit --
                        middle_period_cnt_r <= middle_period_cnt + 1; -- increment oversampling pulse counter --
                    elsif (rx_cnt < data_width) then -- center of bit and not all bits received --
                        middle_period_cnt_r <= (others => '0'); -- clear oversampling pulse counter --
                        rx_cnt_r            <= rx_cnt + 1; -- increment number of bits received counter --
                        rx_buffer_r         <= RxD & rx_buffer(data_width - 1 downto 1); -- shift new received bit into receive buffer --
                    else
                        rx_data       <= rx_buffer; -- output received data to MultiPlayer logic --
                        rx_cnt_r      <= (others => '0'); -- clear the bits received counter --
                        rx_state_next <= stop_bit;
                    end if;
                end if;

            when stop_bit =>            -- stop_bit state --
                if (os_CE = '1') then   -- enable pulse at oversampling rate -- 
                    if (middle_period_cnt < os_rate - 1) then -- not center of bit --
                        middle_period_cnt_r <= middle_period_cnt + 1; -- increment oversampling pulse counter --
                    elsif (RxD = '1') then -- center of bit and stop bit received --
                        middle_period_cnt_r <= (others => '0'); -- clear oversampling pulse counter --
                        rx_receive_CE       <= '1'; -- all bits received signal --
                        rx_state_next       <= idle_start_bit; -- go to idle and start bit state --
                    end if;
                end if;
        end case;
        rx_data <= rx_buffer;
    end process;

end Behavioral;
