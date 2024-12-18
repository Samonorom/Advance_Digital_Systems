-- File: simulation_config_pkg.vhd
library ieee;
use ieee.std_logic_1164.all;

package simulation_config_pkg is
	 -- Define simulation mode constant
    -- Set this to TRUE for simulation, FALSE for synthesis
    constant SIMULATION_MODE : boolean := false;  -- Change to FALSE for synthesis
     -- Function to convert std_logic_vector to string
    function to_string(slv: std_logic_vector) return string;
    
    -- Function to decode 7-segment display value to character
    function decode_7seg(hex: std_logic_vector(6 downto 0)) return character;
    
    -- Function to simulate temperature reading (returns ADC value)
--    function get_simulated_temp return natural;
    
    -- Constants for temperature simulation
    constant BASE_TEMP : natural := 25;  -- Base temperature in Celsius
    constant TEMP_VARIATION : natural := 5;  -- +/- variation in temperature
    
    -- Constants for ADC conversion
    constant ADC_MAX : natural := 4095;  -- 12-bit ADC
	 
end package simulation_config_pkg;

package body simulation_config_pkg is
 function to_string(slv: std_logic_vector) return string is
        variable result: string(1 to slv'length);
    begin
        for i in slv'range loop
            case slv(i) is
                when '0' => result(i+1) := '0';
                when '1' => result(i+1) := '1';
                when others => result(i+1) := 'X';
            end case;
        end loop;
        return result;
    end function;

    function decode_7seg(hex: std_logic_vector(6 downto 0)) return character is
    begin
        case hex is
            when "1000000" => return '0';
            when "1111001" => return '1';
            when "0100100" => return '2';
            when "0110000" => return '3';
            when "0011001" => return '4';
            when "0010010" => return '5';
            when "0000010" => return '6';
            when "1111000" => return '7';
            when "0000000" => return '8';
            when "0010000" => return '9';
            when others    => return '?';
        end case;
    end function;

--    function get_simulated_temp return natural is
--        variable seed1, seed2: positive := 1;
--        variable rand: real;
--        variable temp: natural;
--    begin
--        -- Simple simulation returning value between BASE_TEMP +/- TEMP_VARIATION
--        temp := BASE_TEMP + (NOW / 1 us) mod TEMP_VARIATION;
--        return temp;
--    end function;
	 
end package body simulation_config_pkg;