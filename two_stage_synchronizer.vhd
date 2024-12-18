library ieee;
use ieee.std_logic_1164.all;

entity two_stage_synchronizer is
    generic (
        WIDTH : positive := 1
    );
    port (
        clk     : in  std_logic;
        rst_n   : in  std_logic;
        din     : in  std_logic_vector(WIDTH-1 downto 0);
        dout    : out std_logic_vector(WIDTH-1 downto 0)
    );
end entity;

architecture rtl of two_stage_synchronizer is
    signal stage1 : std_logic_vector(WIDTH-1 downto 0);
begin
    process(clk, rst_n)
    begin
        if rst_n = '0' then
            stage1 <= (others => '0');
            dout   <= (others => '0');
        elsif rising_edge(clk) then
            stage1 <= din;
            dout   <= stage1;
        end if;
    end process;
end architecture;