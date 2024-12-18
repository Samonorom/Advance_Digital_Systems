library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adc_controller is
    port (
        -- Clock and reset
        clk_dft     : in  std_logic;  -- ADC clock domain (1MHz)
        rst_n       : in  std_logic;  -- Active low reset
        
        -- ADC interface
        soc         : out std_logic;  -- Start of conversion
        eoc         : in  std_logic;  -- End of conversion
        tsen        : out std_logic;  -- Temperature sense enable
        adc_data    : in  std_logic_vector(11 downto 0);  -- ADC data input
        
        -- FIFO interface
        fifo_wrdata : out std_logic_vector(11 downto 0);  -- Data to FIFO
        fifo_wrreq  : out std_logic;  -- Write request to FIFO
        fifo_full   : in  std_logic   -- FIFO full flag
    );
end entity adc_controller;

architecture rtl of adc_controller is
    -- FSM state definition
    type state_type is (
        ST_INIT,        -- Initial state, wait for power-up
        ST_IDLE,        -- Waiting to start conversion
        ST_START_CONV,  -- Assert SOC
        ST_CONVERTING,  -- Wait for EOC
        ST_STORE_DATA,  -- Store data and write to FIFO
        ST_WAIT        -- Wait state between conversions
    );
    
    -- Internal signals
    signal state, next_state : state_type;
    signal wait_counter     : unsigned(7 downto 0);
    signal data_reg        : std_logic_vector(11 downto 0);
    
    -- Constants
    constant INIT_WAIT : unsigned(7 downto 0) := to_unsigned(100, 8);  -- 100 cycles startup
    constant CONV_WAIT : unsigned(7 downto 0) := to_unsigned(20, 8);   -- 20 cycles between conversions

begin
    -- Sequential process for state register and counter
    process(clk_dft, rst_n)
    begin
        if rst_n = '0' then
            state <= ST_INIT;
            wait_counter <= INIT_WAIT;
            data_reg <= (others => '0');
        elsif rising_edge(clk_dft) then
            state <= next_state;
            
            -- Counter logic
            case state is
                when ST_INIT | ST_WAIT =>
                    if wait_counter /= 0 then
                        wait_counter <= wait_counter - 1;
                    end if;
                
                when ST_STORE_DATA =>
                    wait_counter <= CONV_WAIT;
                    data_reg <= adc_data;
                
                when others =>
                    null;
            end case;
        end if;
    end process;

    -- Next state and output logic
    process(state, eoc, fifo_full, wait_counter,data_reg)
    begin
        -- Default assignments
        next_state <= state;
        soc <= '0';
        tsen <= '1';  -- Always in temperature sensing mode
        fifo_wrreq <= '0';
        fifo_wrdata <= data_reg;

        case state is
            when ST_INIT =>
                if wait_counter = 0 then
                    next_state <= ST_IDLE;
                end if;
                
            when ST_IDLE =>
                if fifo_full = '0' then
                    next_state <= ST_START_CONV;
                end if;
                
            when ST_START_CONV =>
                soc <= '1';
                next_state <= ST_CONVERTING;
                
            when ST_CONVERTING =>
                if eoc = '1' then
                    next_state <= ST_STORE_DATA;
                end if;
                
            when ST_STORE_DATA =>
                fifo_wrreq <= '1';
                next_state <= ST_WAIT;
                
            when ST_WAIT =>
                if wait_counter = 0 then
                    next_state <= ST_IDLE;
                end if;
        end case;
    end process;

end architecture rtl;