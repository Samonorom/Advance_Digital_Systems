library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.simulation_config_pkg.all;

entity temperature_system_tb is
end entity;

architecture tb of temperature_system_tb is
    -- Component declaration for the Device Under Test (DUT)
    component temperature_system is
        port (
            MAX10_CLK1_50  : in  std_logic;
            KEY0           : in  std_logic;
            HEX0          : out std_logic_vector(6 downto 0);
            HEX1          : out std_logic_vector(6 downto 0);
            HEX2          : out std_logic_vector(6 downto 0)
        );
    end component;

    -- Clock period definitions
    constant CLK_50MHZ_PERIOD : time := 20 ns;    -- 50 MHz clock
    constant CLK_10MHZ_PERIOD : time := 100 ns;   -- 10 MHz clock
    constant CLK_1MHZ_PERIOD  : time := 1000 ns;  -- 1 MHz clock (ADC clock)

    -- Testbench signals
    signal clk_50mhz     : std_logic := '0';
    signal reset_n       : std_logic := '0';
    signal hex0          : std_logic_vector(6 downto 0);
    signal hex1          : std_logic_vector(6 downto 0);
    signal hex2          : std_logic_vector(6 downto 0);
    
    -- ADC internal signals (for monitoring)
    signal adc_value     : natural := 0;
    signal last_temp     : natural := 0;
    
    -- Simulation control
    signal sim_done      : boolean := false;
    
    -- Function to convert temperature to ADC value
    function temp_to_adc(temp: natural) return natural is
    begin
        -- Simple linear conversion (you might want to adjust this based on your ADC characteristics)
        return (temp * ADC_MAX) / 100;
    end function;

begin
    -- Instantiate the Device Under Test (DUT)
    dut: temperature_system
        port map (
            MAX10_CLK1_50  => clk_50mhz,
            KEY0           => reset_n,
            HEX0           => hex0,
            HEX1           => hex1,
            HEX2           => hex2
        );

    -- Clock generation process - 50MHz
    clk_gen: process
    begin
        while not sim_done loop
            clk_50mhz <= '0';
            wait for CLK_50MHZ_PERIOD/2;
            clk_50mhz <= '1';
            wait for CLK_50MHZ_PERIOD/2;
        end loop;
        wait;
    end process;

    -- Stimulus process
    stimulus: process
    begin
        -- Initialize
        reset_n <= '1';
        wait for 100 ns;
        
        -- Apply reset
        reset_n <= '0';
        wait for 100 ns;
        reset_n <= '1';
        
        -- Wait for PLL to lock and system to initialize
        wait for 1 us;
        
        -- Let the system run to observe temperature readings
        wait for 1 ms;
        
        -- End simulation
        sim_done <= true;
        report "Simulation completed successfully";
        wait;
    end process;

--    -- Process to simulate temperature changes
--    temp_sim: process
--    begin
--        wait for 1 us;  -- Initial delay
--        
--        while not sim_done loop
--            -- Get new temperature reading
--            last_temp <= get_simulated_temp;
--            adc_value <= temp_to_adc(get_simulated_temp);
--            
--            -- Wait before next temperature update
--            wait for 100 us;
--        end loop;
--        wait;
--    end process;

    -- Monitor process to check outputs
    monitor: process
        variable display_val: string(1 to 3);
    begin
        wait for 1 us;  -- Wait for initialization
        
        while not sim_done loop
            -- Wait for any change in displays
            wait on hex0, hex1, hex2;
            
            -- Decode display values
            display_val(1) := decode_7seg(hex2);
            display_val(2) := decode_7seg(hex1);
            display_val(3) := decode_7seg(hex0);
            
            -- Report temperature reading
            report "Temperature Display: " & display_val & 
                   " (ADC Value: " & integer'image(adc_value) & 
                   ", Actual Temp: " & integer'image(last_temp) & " C)";
            
            -- Basic verification
            assert decode_7seg(hex2) /= '?' and 
                   decode_7seg(hex1) /= '?' and 
                   decode_7seg(hex0) /= '?'
                report "Invalid 7-segment display value detected!"
                severity error;
        end loop;
        wait;
    end process;

end architecture;