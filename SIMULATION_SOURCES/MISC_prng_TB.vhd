LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY MISC_prng_TB IS
END MISC_prng_TB;

ARCHITECTURE behavior OF MISC_prng_TB IS

    -- Component Declaration for the Unit Under Test (UUT)

    component MISC_prng
        port(
            clk, rst      : in  STD_LOGIC;
            random_output : out STD_LOGIC_VECTOR(15 downto 0)
        );
    end component MISC_prng;

    --Inputs
    signal clk : std_logic := '0';

    --Outputs
    signal random_output : std_logic_vector(15 downto 0);

    -- Clock period definitions
    constant clk_period : time := 10 ns;
    signal set_seed     : std_logic;
    signal rst          : STD_LOGIC;

BEGIN

    -- Instantiate the Unit Under Test (UUT)
    uut : MISC_prng
        PORT MAP(
            clk           => clk,
            rst           => rst,
            random_output => random_output
        );

    -- Clock process definitions
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
        report " " & integer'image(to_integer(unsigned(random_output)));
    end process;

    -- Stimulus process
    stim_proc : process
    begin
        -- hold reset state for 100 ns.
        rst <= '1';
        wait for 100 ns;
        rst <= '0';

        wait for clk_period * 10;

        -- insert stimulus here 

        wait;
    end process;

END;
