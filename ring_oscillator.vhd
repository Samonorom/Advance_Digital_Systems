library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity ring_oscillator is
    generic (
        n : integer := 13  -- n-1 inverters + 1 NAND gate
    );
    port (
        enable : in  std_logic;
        output : out std_logic
    );
end ring_oscillator;

architecture Behavioral of ring_oscillator is
    signal chain : std_logic_vector(0 to n-1);
    
    -- Attribute to prevent optimization
    attribute dont_touch : string;
    attribute dont_touch of chain : signal is "true";
    
    -- Attribute to prevent net reduction
    attribute keep : string;
    attribute keep of chain : signal is "true";

    -- Component declaration for inverter
    component inverter is
        port (
            input : in std_logic;
            output : out std_logic
        );
    end component;

begin
    -- Check for odd number of stages
    assert (n mod 2 = 1) report "Number of stages must be odd" severity error;

    -- First stage (NAND gate)
    chain(0) <= enable nand chain(n-1);
    
    -- Inverter chain
    gen_inverters: for i in 0 to n-2 generate
        inv: inverter port map (
            input => chain(i),
            output => chain(i+1)
        );
    end generate gen_inverters;

    -- Output
    output <= chain(n-1);
end Behavioral;