library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Audio_top is
    port(clk, rst  : in  std_logic;
         sound_CE  : in  std_logic;
         audio_out : out std_logic_vector(7 downto 0)
        );
end Audio_top;

architecture Behavioral of Audio_top is

    signal cnt, cnt_r     : unsigned(7 downto 0)         := (others => '0'); -- new
    signal help, help_r   : unsigned(14 downto 0)        := (others => '0');
    signal audio, audio_r : std_logic_vector(7 downto 0) := (others => '0');
    constant slow         : integer                      := 19607; -- 10 Hz --
    constant middle       : integer                      := 13071; -- 15 Hz (optimal imho) --
    constant fast         : integer                      := 9804; -- 20 Hz --

begin

    ----------------------------
    --    SEQUENTIAL LOGIC    --
    ----------------------------
    process(clk, rst)
    begin
        if rst = '1' then
            cnt   <= (others => '0');
            help  <= (others => '0');
            audio <= (others => '0');
        elsif rising_edge(clk) then
            cnt   <= cnt_r;
            help  <= help_r;
            audio <= audio_r;
        end if;
    end process;

    ----------------------------
    --  SOUND WAVE GENERATOR  --
    ----------------------------
    process(cnt, help, audio, sound_CE)
    begin
        cnt_r   <= cnt;
        help_r  <= help;
        audio_r <= audio;
        if (sound_CE = '1') then
            if (help = middle) then
                if (cnt = 255) then
                    cnt_r  <= (others => '0');
                    help_r <= (others => '0');
                else
                    cnt_r   <= cnt + 1;
                    help_r  <= (others => '0');
                    audio_r <= std_logic_vector(cnt);
                end if;
            else
                help_r <= help + 1;
            end if;
        end if;
    end process;

    audio_out <= audio;

end Behavioral;

