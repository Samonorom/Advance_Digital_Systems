library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity max10_adc_sim is
    port (
        pll_clk : in  std_logic;
        chsel   : in  natural range 0 to 2**5 - 1;
        soc     : in  std_logic;
        tsen    : in  std_logic;
        dout    : out natural range 0 to 2**12 - 1;  -- Will now contain direct temperature value
        eoc     : out std_logic;
        clk_dft : out std_logic
    );
end entity max10_adc_sim;

architecture sim of max10_adc_sim is
    -- Constants for temperature simulation
    constant BASE_TEMP     : natural := 25;    -- Base temperature in Celsius
    constant MAX_TEMP     : natural := 50;     -- Maximum temperature
    constant MIN_TEMP     : natural := 15;     -- Minimum temperature
    constant CONV_CYCLES  : natural := 12;     -- ADC conversion takes 12 cycles
    
    -- Internal signals
    signal clk_div          : std_logic := '0';
    signal conversion_count : natural range 0 to CONV_CYCLES := 0;
    signal converting       : boolean := false;
    signal temp_value      : natural range 0 to 99 := BASE_TEMP;  -- Direct temperature value
    signal update_counter  : natural := 0;

begin
    -- Clock divider process (10MHz to 1MHz)
    clock_divider: process(pll_clk)
        variable div_count : natural range 0 to 4 := 0;
    begin
        if rising_edge(pll_clk) then
            if div_count = 4 then
                div_count := 0;
                clk_div <= not clk_div;
            else
                div_count := div_count + 1;
            end if;
        end if;
    end process;

    -- Output the divided clock
    clk_dft <= clk_div;

    -- Temperature generation process
    temp_gen: process(clk_div)
        variable seed1, seed2: positive := 1;
        variable rand: real;
        variable new_temp: integer;
    begin
        if rising_edge(clk_div) then
            if update_counter = 1000 then  -- Change temperature every 1000 cycles
                update_counter <= 0;
                
                -- Generate random temperature variation
                uniform(seed1, seed2, rand);
                new_temp := BASE_TEMP + integer(rand * 10.0) - 5;  -- ±5 degrees variation
                
                -- Ensure temperature stays within limits
                if new_temp > MAX_TEMP then
                    temp_value <= MAX_TEMP;
                elsif new_temp < MIN_TEMP then
                    temp_value <= MIN_TEMP;
                else
                    temp_value <= new_temp;
                end if;
            else
                update_counter <= update_counter + 1;
                
                -- Add small variations every 10 cycles
                if update_counter mod 10 = 0 then
                    uniform(seed1, seed2, rand);
                    if rand > 0.5 and temp_value < MAX_TEMP then
                        temp_value <= temp_value + 1;
                    elsif rand <= 0.5 and temp_value > MIN_TEMP then
                        temp_value <= temp_value - 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

    -- ADC conversion simulation process
    adc_sim: process(clk_div)
    begin
        if rising_edge(clk_div) then
            -- Handle conversion process
            if soc = '1' and not converting then
                -- Start new conversion
                converting <= true;
                conversion_count <= 0;
                eoc <= '0';
            elsif converting then
                if conversion_count = CONV_CYCLES-1 then
                    -- Conversion complete
                    converting <= false;
                    eoc <= '1';
                else
                    conversion_count <= conversion_count + 1;
                    eoc <= '0';
                end if;
            else
                eoc <= '0';
            end if;
        end if;
    end process;

    -- Output the direct temperature value
    dout <= temp_value when tsen = '1' else 0;

end architecture sim;