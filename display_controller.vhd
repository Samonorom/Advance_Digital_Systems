library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity display_controller is
    port (
        -- Clock and reset
        clk_50mhz   : in  std_logic;  -- 50 MHz system clock
        rst_n       : in  std_logic;  -- Active low reset
        
        -- FIFO interface (consumer side)
        fifo_data   : in  std_logic_vector(11 downto 0);  -- Temperature data from FIFO
        fifo_empty  : in  std_logic;  -- FIFO empty flag
        fifo_rd_en  : out std_logic;  -- Read enable to FIFO
        
        -- Seven segment display outputs
        hex0        : out std_logic_vector(6 downto 0);  -- Right digit (ones)
        hex1        : out std_logic_vector(6 downto 0);  -- Middle digit (tens)
        hex2        : out std_logic_vector(6 downto 0);   -- Left digit (hundreds)
        hex3        : out std_logic_vector(6 downto 0)   -- Left digit (hundreds)
    );
end entity display_controller;

architecture rtl of display_controller is
    -- Internal signals
    signal temp_value      : std_logic_vector(11 downto 0);  -- Current temperature value
    signal bcd_value      : std_logic_vector(19 downto 0);   -- BCD converted value
    signal update_counter : unsigned(31 downto 0);           
    signal update_temp    : std_logic;                       

    constant UPDATE_RATE  : unsigned(31 downto 0) := to_unsigned(5000000, 32);  

    -- BCD conversion function
    function to_bcd (
        data_value: in std_logic_vector(15 downto 0)
    ) return std_logic_vector
    is
        variable ret: std_logic_vector(19 downto 0);
        variable temp: std_logic_vector(data_value'range);
    begin
        temp := data_value;
        ret := (others => '0');
        for i in data_value'range loop
            for j in 0 to ret'length/4 - 1 loop
                if unsigned(ret(4*j + 3 downto 4*j)) >= 5 then
                    ret(4*j + 3 downto 4*j) :=
                        std_logic_vector(
                            unsigned(ret(4*j + 3 downto 4 * j)) + 3);
                end if;
            end loop;
            ret := ret(ret'high -1 downto 0) & temp(temp'high);
            temp := temp(temp'high - 1 downto 0) & '0';
        end loop;
        return ret;
    end function to_bcd;

    -- Seven segment encoding function
    function to_seven_segment(digit: std_logic_vector(3 downto 0)) 
        return std_logic_vector is
    begin
        case digit is
            when "0000" => return "1000000";  -- 0
            when "0001" => return "1111001";  -- 1
            when "0010" => return "0100100";  -- 2
            when "0011" => return "0110000";  -- 3
            when "0100" => return "0011001";  -- 4
            when "0101" => return "0010010";  -- 5
            when "0110" => return "0000010";  -- 6
            when "0111" => return "1111000";  -- 7
            when "1000" => return "0000000";  -- 8
            when "1001" => return "0010000";  -- 9
            when others => return "1111111";  -- Blank
        end case;
    end function;

begin
    -- Update timing process
    update_timing: process(clk_50mhz, rst_n)
    begin
        if rst_n = '0' then
            update_counter <= (others => '0');
            update_temp <= '0';
        elsif rising_edge(clk_50mhz) then
            update_temp <= '0';  -- Default state
            
            if update_counter = UPDATE_RATE then
                update_counter <= (others => '0');
                update_temp <= '1';
            else
                update_counter <= update_counter + 1;
            end if;
        end if;
    end process;

    -- FIFO read and temperature update process
    temp_update: process(clk_50mhz, rst_n)
    begin
        if rst_n = '0' then
            temp_value <= (others => '0');
            fifo_rd_en <= '0';
        elsif rising_edge(clk_50mhz) then
            fifo_rd_en <= '0';  -- Default state
            
            if update_temp = '1' and fifo_empty = '0' then
                fifo_rd_en <= '1';
                temp_value <= fifo_data;
            end if;
        end if;
    end process;

    -- Convert binary to BCD continuously
    bcd_value <= to_bcd("0000" & temp_value);  -- Pad to 16 bits

    -- Seven segment display output assignments
    hex0 <= to_seven_segment(bcd_value(3 downto 0));    -- Ones
    hex1 <= to_seven_segment(bcd_value(7 downto 4));    -- Tens
    hex2 <= to_seven_segment(bcd_value(11 downto 8));   -- Hundreds
    hex3 <= to_seven_segment(bcd_value(15 downto 12));   -- Hundreds

end architecture rtl;