library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity VGA_sync is
    Port(clk, rst              : in  STD_LOGIC;
         pixel_x, pixel_y      : out STD_LOGIC_VECTOR(10 downto 0);
         video_on              : out STD_LOGIC;
         hsync, vsync          : out STD_LOGIC;
         frame_tick, line_tick : out STD_LOGIC);
end VGA_sync;

architecture RTL of VGA_sync is
    signal V_overflow, V_overflow_next      : STD_LOGIC := '0';
    signal H_overflow, H_overflow_next      : STD_LOGIC := '0';
    signal h_video_on, v_video_on           : STD_LOGIC := '0';
    signal h_video_on_next, v_video_on_next : STD_LOGIC := '0';
    signal hsync_next, vsync_next           : STD_LOGIC := '0';

    signal hsync_delayed, vsync_delayed : STD_LOGIC := '0';

    attribute keep : boolean;
    attribute keep of hsync_delayed : signal is true;
    attribute keep of vsync_delayed : signal is true;

    signal pixel_x_sig  : STD_LOGIC_VECTOR(10 downto 0) := (others => '0');
    signal pixel_y_sig  : STD_LOGIC_VECTOR(10 downto 0) := (others => '0');
    signal pixel_x_next : STD_LOGIC_VECTOR(10 downto 0) := (others => '0');
    signal pixel_y_next : STD_LOGIC_VECTOR(10 downto 0) := (others => '0');

    -- 50MHz 640x480 -- # Nostalgia
    --constant H_DISP : integer := 640;
    --constant H_FP   : integer := 16;
    --constant H_RTR  : integer := 96;
    --constant H_BP   : integer := 48;
    --constant V_DISP : integer := 480;
    --constant V_FP   : integer := 10;
    --constant V_RTR  : integer := 2;
    --constant V_BP   : integer := 33;

    --108MHz 1280x1024
    constant H_DISP : integer := 1280;
    constant H_FP   : integer := 48;
    constant H_RTR  : integer := 112;
    constant H_BP   : integer := 248;
    constant V_DISP : integer := 1024;
    constant V_FP   : integer := 1;
    constant V_RTR  : integer := 3;
    constant V_BP   : integer := 38;

    --constant PIX_DELAY : integer := 1;

begin

    v_count_tick : process(clk, rst)
    begin
        if (rst = '1') then
            V_overflow    <= '0';
            v_video_on    <= '0';
            pixel_y_sig   <= (others => '0');
            vsync         <= '0';
            vsync_delayed <= '0';
        elsif (rising_edge(clk)) then
            V_overflow    <= V_overflow_next;
            v_video_on    <= v_video_on_next;
            pixel_y_sig   <= pixel_y_next;
            vsync         <= vsync_delayed;
            vsync_delayed <= vsync_next;
        end if;
    end process;

    v_count_comb : process(pixel_y_next, H_overflow, pixel_y_sig, v_video_on)
    begin
        V_overflow_next <= '0';
        v_video_on_next <= v_video_on;
        pixel_y_next    <= pixel_y_sig;

        if ((unsigned(pixel_y_next) < V_DISP + V_FP) or (unsigned(pixel_y_next) > V_DISP + V_FP + V_RTR)) then
            vsync_next <= '1';
        else
            vsync_next <= '0';
        end if;

        if (H_overflow = '1') then      -- CE
            pixel_y_next <= std_logic_vector(unsigned(pixel_y_sig) + 1);
            if (unsigned(pixel_y_sig) < V_DISP + V_FP + V_RTR + V_BP) then
                if (unsigned(pixel_y_sig) < V_DISP) then
                    v_video_on_next <= '1';
                else
                    v_video_on_next <= '0';
                end if;
            else
                V_overflow_next <= '1';
                pixel_y_next    <= (others => '0');
            end if;
        end if;

    end process;

    h_count_seq : process(clk, rst)
    begin
        if (rst = '1') then
            H_overflow    <= '0';
            h_video_on    <= '0';
            pixel_x_sig   <= (others => '0');
            hsync         <= '0';
            hsync_delayed <= '0';
        elsif (rising_edge(clk)) then
            H_overflow    <= H_overflow_next;
            h_video_on    <= h_video_on_next;
            pixel_x_sig   <= pixel_x_next;
            hsync         <= hsync_delayed;
            hsync_delayed <= hsync_next;
        end if;
    end process;

    h_count_comb : process(h_video_on, pixel_x_sig)
    begin
        H_overflow_next <= '0';
        h_video_on_next <= h_video_on;
        pixel_x_next    <= std_logic_vector(unsigned(pixel_x_sig) + 1);

        if ((to_integer(unsigned(pixel_x_sig)) < H_DISP + H_FP) or (unsigned(pixel_x_sig) > H_DISP + H_FP + H_RTR)) then
            hsync_next <= '1';
        else
            hsync_next <= '0';
        end if;

        if (to_integer(unsigned(pixel_x_sig)) < H_DISP + H_FP + H_RTR + H_BP) then
            if (to_integer(unsigned(pixel_x_sig)) < H_DISP) then
                h_video_on_next <= '1';
            else
                h_video_on_next <= '0';
            end if;
        else
            H_overflow_next <= '1';
            pixel_x_next    <= (others => '0');
        end if;

    end process;

    --video on helping signal
    video_on <= h_video_on and v_video_on;

    -- inner sig to output
    pixel_x    <= pixel_x_sig;
    pixel_y    <= pixel_y_sig;
    frame_tick <= V_overflow;
    line_tick  <= H_overflow;

end RTL;

