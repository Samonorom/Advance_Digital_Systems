library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.simulation_config_pkg.all;

entity temperature_system is
    port (
        -- Clock and reset
        MAX10_CLK1_50  : in  std_logic;  -- 50MHz system clock from DE10-Lite
        KEY           : in   std_logic_vector(1 downto 0);   -- Reset button (active low)
		  
        --LEDR          : out std_logic_vector(9 downto 0);  -- Right digit
        -- Seven segment display outputs
        HEX0          : out std_logic_vector(6 downto 0);  -- Right digit
        HEX1          : out std_logic_vector(6 downto 0);  -- Middle digit
        HEX2          : out std_logic_vector(6 downto 0);   -- Left digit
        HEX3          : out std_logic_vector(6 downto 0)   -- Left digit
    );
end entity;

architecture rtl of temperature_system is
    -- Component declarations
    component pll is
        port (
            inclk0  : in  std_logic;
            c0      : out std_logic;
            locked  : out std_logic
        );
    end component;

    component max10_adc is
        port (
            pll_clk : in  std_logic;
            chsel   : in  natural range 0 to 2**5 - 1;
            soc     : in  std_logic;
            tsen    : in  std_logic;
            dout    : out natural range 0 to 2**12 - 1;
            eoc     : out std_logic;
            clk_dft : out std_logic
        );
    end component;

    component max10_adc_sim is
        port (
            pll_clk : in  std_logic;
            chsel   : in  natural range 0 to 2**5 - 1;
            soc     : in  std_logic;
            tsen    : in  std_logic;
            dout    : out natural range 0 to 2**12 - 1;
            eoc     : out std_logic;
            clk_dft : out std_logic
        );
    end component;

    component adc_controller is
        port (
            clk_dft     : in  std_logic;
            rst_n       : in  std_logic;
            soc         : out std_logic;
            eoc         : in  std_logic;
            tsen        : out std_logic;
            adc_data    : in  std_logic_vector(11 downto 0);
            fifo_wrdata : out std_logic_vector(11 downto 0);
            fifo_wrreq  : out std_logic;
            fifo_full   : in  std_logic
        );
    end component;

    component fifo_synchronizer is
        generic (
            DATA_WIDTH : positive := 12;
            FIFO_DEPTH : positive := 4
        );
        port (
            -- Write domain (ADC clock)
            wr_clk      : in  std_logic;
            wr_rst_n    : in  std_logic;
            wr_data     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
            wr_en       : in  std_logic;
            full        : out std_logic;
            
            -- Read domain (50MHz clock)
            rd_clk      : in  std_logic;
            rd_rst_n    : in  std_logic;
            rd_data     : out std_logic_vector(DATA_WIDTH-1 downto 0);
            rd_en       : in  std_logic;
            empty       : out std_logic
        );
    end component;

    component display_controller is
        port (
            clk_50mhz   : in  std_logic;
            rst_n       : in  std_logic;
            fifo_data   : in  std_logic_vector(11 downto 0);
            fifo_empty  : in  std_logic;
            fifo_rd_en  : out std_logic;
            hex0        : out std_logic_vector(6 downto 0);
            hex1        : out std_logic_vector(6 downto 0);
            hex2        : out std_logic_vector(6 downto 0);
            hex3        : out std_logic_vector(6 downto 0)
				
        );
    end component;

    component reset_synchronizer is
        port (
            clk     : in  std_logic;
            async_n : in  std_logic;
            sync_n  : out std_logic
        );
    end component;

    -- Clock domain signals
    signal pll_clk_10mhz     : std_logic;
    signal adc_clk           : std_logic;  -- 1MHz ADC clock
    signal pll_locked        : std_logic;
    signal reset_locked      : std_logic;

    -- Reset signals
    signal reset_n           : std_logic;  
    signal reset_sync_50mhz_n: std_logic;  
    signal reset_sync_adc_n  : std_logic;  

    -- ADC interface signals
    signal adc_soc          : std_logic;
    signal adc_eoc          : std_logic;
    signal adc_tsen         : std_logic;
    signal adc_data_natural : natural range 0 to 2**12 - 1;
    signal adc_data         : std_logic_vector(11 downto 0);

    -- FIFO interface signals
    signal fifo_wr_data     : std_logic_vector(11 downto 0);
    signal fifo_wr_en       : std_logic;
    signal fifo_full        : std_logic;
    signal fifo_rd_data     : std_logic_vector(11 downto 0);
    signal fifo_rd_en       : std_logic;
    signal fifo_empty       : std_logic;

begin
    -- Convert ADC natural output to std_logic_vector
    adc_data <= std_logic_vector(to_unsigned(adc_data_natural, 12));
    --LEDR <= fifo_rd_data(11 downto 2);
	 
    -- Invert reset button signal (KEY0 is active low)
    reset_n <= KEY(0);

    -- PLL instance
    pll_inst: pll
        port map (
            inclk0  => MAX10_CLK1_50,
            c0      => pll_clk_10mhz,
            locked  => pll_locked
        );

		 reset_locked <= reset_n and pll_locked; 
    -- Reset synchronizer for 50MHz domain
    reset_sync_50: reset_synchronizer
        port map (
            clk     => MAX10_CLK1_50,
            async_n => reset_locked,
            sync_n  => reset_sync_50mhz_n
        );

    -- Reset synchronizer for ADC domain
    reset_sync_adc: reset_synchronizer
        port map (
            clk     => adc_clk,
            async_n => reset_locked,
            sync_n  => reset_sync_adc_n
        );

    -- ADC instance - Real Hardware
    REAL_ADC_GEN: if not SIMULATION_MODE generate
        adc_inst: max10_adc
            port map (
                pll_clk => pll_clk_10mhz,
                chsel   => 0,
                soc     => adc_soc,
                tsen    => adc_tsen,
                dout    => adc_data_natural,
                eoc     => adc_eoc,
                clk_dft => adc_clk
            );
    end generate REAL_ADC_GEN;

    -- ADC instance - Simulation
    SIM_ADC_GEN: if SIMULATION_MODE generate
        adc_sim_inst: max10_adc_sim
            port map (
                pll_clk => pll_clk_10mhz,
                chsel   => 0,
                soc     => adc_soc,
                tsen    => adc_tsen,
                dout    => adc_data_natural,
                eoc     => adc_eoc,
                clk_dft => adc_clk
            );
    end generate SIM_ADC_GEN;

    -- ADC controller instance
    adc_ctrl: adc_controller
        port map (
            clk_dft     => adc_clk,
            rst_n       => reset_sync_adc_n,
            soc         => adc_soc,
            eoc         => adc_eoc,
            tsen        => adc_tsen,
            adc_data    => adc_data,
            fifo_wrdata => fifo_wr_data,
            fifo_wrreq  => fifo_wr_en,
            fifo_full   => fifo_full
        );

    -- FIFO synchronizer instance
    fifo_sync: fifo_synchronizer
        generic map (
            DATA_WIDTH => 12,
            FIFO_DEPTH => 4
        )
        port map (
            wr_clk      => adc_clk,
            wr_rst_n    => reset_sync_adc_n,
            wr_data     => fifo_wr_data,
            wr_en       => fifo_wr_en,
            full        => fifo_full,
            rd_clk      => MAX10_CLK1_50,
            rd_rst_n    => reset_sync_50mhz_n,
            rd_data     => fifo_rd_data,
            rd_en       => fifo_rd_en,
            empty       => fifo_empty
        );

    -- Display controller instance
    display_ctrl: display_controller
        port map (
            clk_50mhz   => MAX10_CLK1_50,
            rst_n       => reset_sync_50mhz_n,
            fifo_data   => fifo_rd_data,
            fifo_empty  => fifo_empty,
            fifo_rd_en  => fifo_rd_en,
            hex0        => HEX0,
            hex1        => HEX1,
            hex2        => HEX2,
            hex3        => HEX3
				
        );

end architecture rtl;