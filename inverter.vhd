-- Inverter component
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity inverter is
    port (
        input : in std_logic;
        output : out std_logic
    );
end inverter;

architecture Behavioral of inverter is
    attribute dont_touch : string;
    attribute dont_touch of Behavioral : architecture is "true";
begin
    output <= not input;
end Behavioral;