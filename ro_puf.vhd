library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.MATH_REAL.ALL;

entity ro_puf is
    generic (
        ro_length : integer := 13;
        ro_count  : integer := 16
    );
    port (
        clock       : in  std_logic;  -- Added clock input
        reset     : in  std_logic;
        enable    : in  std_logic;
        challenge : in  std_logic_vector(2*(integer(ceil(log2(real(ro_count))))-1) - 1 downto 0);
        response  : out std_logic
    );
end ro_puf;

architecture Behavioral of ro_puf is
    component ring_oscillator is
        generic (n : integer);
        port (enable : in std_logic; output : out std_logic);
    end component;

    type ro_outputs is array (0 to ro_count-1) of std_logic;
    signal ro_out : ro_outputs;
    
    type counter_array is array (0 to ro_count-1) of unsigned(7 downto 0);
    signal counters : counter_array;
    
    constant challenge_width : integer := integer(ceil(log2(real(ro_count/2))));

    function is_power_of_two(n: positive) return boolean is
        variable temp: positive := n;
    begin
        if temp = 1 then
            return true;
        end if;
        while temp > 1 loop
            if temp mod 2 /= 0 then
                return false;
            end if;
            temp := temp / 2;
        end loop;
        return true;
    end function;

begin
    assert is_power_of_two(ro_count)
        report "Number of ring oscillators must be a power of two"
        severity error;

    gen_ro: for i in 0 to ro_count-1 generate
        ro: ring_oscillator
            generic map (n => ro_length)
            port map (enable => enable, output => ro_out(i));
    end generate;

    -- Improved Counter process
    counter_proc: process(clock, reset)
        variable ro_out_prev : ro_outputs := (others => '0');
    begin
        if reset = '0' then
            for i in 0 to ro_count-1 loop
                counters(i) <= (others => '0');
                ro_out_prev(i) := '0';
            end loop;
        elsif rising_edge(clock) then
            for i in 0 to ro_count-1 loop
                if ro_out(i) = '1' and ro_out_prev(i) = '0' then
                    counters(i) <= counters(i) + 1;
                end if;
                ro_out_prev(i) := ro_out(i);
            end loop;
        end if;
    end process counter_proc;

    -- Compare counters
    compare_proc: process(counters, challenge)
        variable group1, group2 : unsigned((ro_count/2-1) downto 0);
    begin
        group1 := counters(to_integer(unsigned(challenge(challenge_width-1 downto 0))));
        group2 := counters(ro_count/2 + to_integer(unsigned(challenge(challenge'high downto challenge_width))));
        
        if group1 < group2 then
            response <= '1';
        else
            response <= '0';
        end if;
    end process compare_proc;

end Behavioral;