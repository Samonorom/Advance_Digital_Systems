library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DE10_LITE_Golden_Top is
    port (
        -- Clock
        MAX10_CLK1_50  : in  std_logic;  -- 50 MHZ 
        
        -- Keys (active low)
        KEY            : in  std_logic_vector(1 downto 0);
        
        -- Switches
        SW             : in  std_logic_vector(9 downto 0);
        
        -- VGA Interface
        VGA_R         : out std_logic_vector(3 downto 0);
        VGA_G         : out std_logic_vector(3 downto 0);
        VGA_B         : out std_logic_vector(3 downto 0);
        VGA_HS        : out std_logic;
        VGA_VS        : out std_logic
    );
end entity DE10_LITE_Golden_Top;

architecture rtl of DE10_LITE_Golden_Top is
    -- Component declaration for VGA top module
    component vga_top is
        port (
            clock_50    : in  std_logic;
            reset       : in  std_logic;
            set_sel     : in  std_logic;  -- SW9
            key1        : in  std_logic;  -- For palette switching
            red         : out std_logic_vector(3 downto 0);
            green       : out std_logic_vector(3 downto 0);
            blue        : out std_logic_vector(3 downto 0);
            h_sync      : out std_logic;
            v_sync      : out std_logic
        );
    end component;

    -- Internal signals
    signal reset : std_logic;

begin
    -- Convert active low KEY[0] to active high reset
    reset <= not KEY(0);

    -- VGA controller instance
    vga_top_inst: vga_top
        port map (
            clock_50    => MAX10_CLK1_50,
            reset       => reset,
            set_sel     => SW(9),         -- SW9 selects between Mandelbrot and Julia
            key1        => KEY(1),        -- KEY1 for palette switching
            red         => VGA_R,
            green       => VGA_G,
            blue        => VGA_B,
            h_sync      => VGA_HS,
            v_sync      => VGA_VS
        );

end architecture rtl;