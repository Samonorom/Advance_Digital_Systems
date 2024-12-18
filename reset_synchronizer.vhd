library ieee;
use ieee.std_logic_1164.all;

entity reset_synchronizer is
    port (
        clk     : in  std_logic;  -- Clock
        async_n : in  std_logic;  -- Asynchronous reset input (active low)
        sync_n  : out std_logic   -- Synchronized reset output (active low)
    );
end entity;

architecture rtl of reset_synchronizer is
    signal sync_reg : std_logic_vector(1 downto 0);
begin
    process(clk, async_n)
    begin
        if async_n = '0' then
            sync_reg <= (others => '0');
        elsif rising_edge(clk) then
            sync_reg <= sync_reg(0) & '1';
        end if;
    end process;
    
    sync_n <= sync_reg(1);
end architecture;