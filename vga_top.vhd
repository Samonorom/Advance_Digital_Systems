library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library vga;
use vga.vga_data.all;
use vga.color_data.all;
library ads;
use ads.ads_fixed.all;
use ads.ads_complex_pkg.all;
use work.coordinate_mapping.all;

entity vga_top is
    port (
        clock_50    : in  std_logic;
        reset       : in  std_logic;
        -- Control inputs
        set_sel     : in  std_logic;  -- SW9
        key1        : in  std_logic;  -- For palette switching
        -- VGA outputs
        red         : out std_logic_vector(3 downto 0);
        green       : out std_logic_vector(3 downto 0);
        blue        : out std_logic_vector(3 downto 0);
        h_sync      : out std_logic;
        v_sync      : out std_logic
    );
end entity;

architecture rtl of vga_top is
    -- Internal signals
    signal vga_clock: std_logic;
    signal clock_100: std_logic;
    signal vga_point: coordinate;
    signal point_valid: boolean;
    signal color_valid: boolean;
    signal color_output: rgb_color;
    signal palette_index: palette_index_type := 0;
    signal key1_reg: std_logic_vector(1 downto 0);  -- For edge detection

    -- Component declarations
    component pll_vga_clk is
        port (
            inclk0: in std_logic;   -- 50 MHz input
            c0: out std_logic;       -- 25 MHz output
            c1: out std_logic       -- 100 MHz output
        );
    end component;

    component vga_fsm is
        generic (
            vga_res: vga_timing := vga_res_default
        );
        port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            h_sync      : out std_logic;
            v_sync      : out std_logic;
            point       : out coordinate;
            point_valid : out boolean
        );
    end component;

    component fractal_renderer is
        generic (
            vga_res: vga_timing := vga_res_default;
            PIPELINE_STAGES: natural := 16
        );
        port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            set_sel     : in  std_logic;
            julia_c_re  : in  ads_sfixed;
            julia_c_im  : in  ads_sfixed;
            palette_sel : in  palette_index_type;
            vga_point   : in  coordinate;
            point_valid : in  boolean;
            color_valid : out  boolean;
            color       : out rgb_color
        );
    end component;

begin
    -- PLL for VGA clock generation
    vga_pll: pll_vga_clk 
        port map (
            inclk0 => clock_50,
            c0 => vga_clock,
            c1 => clock_100
        );

    -- VGA fsm instantiation
    vga_fsm_inst: vga_fsm
        generic map (
            vga_res => vga_res_default
        )
        port map (
            clk => vga_clock,
            reset => reset,
            h_sync => h_sync,
            v_sync => v_sync,
            point => vga_point,
            point_valid => point_valid
        );

    -- Fractal renderer instantiation
    fractal_renderer_inst: fractal_renderer
        generic map (
            vga_res => vga_res_default,
            PIPELINE_STAGES => 8
        )
        port map (
            clk => clock_100,
            reset => reset,
            set_sel => set_sel,
            julia_c_re => DEFAULT_JULIA_C_RE,
            julia_c_im => DEFAULT_JULIA_C_IM,
            palette_sel => palette_index,
            vga_point => vga_point,
            point_valid => point_valid,
            color_valid => color_valid, 
            color => color_output
        );

    -- Palette switching process
    process(clock_100, reset)
    begin
        if reset = '1' then
            palette_index <= 0;
            key1_reg <= "11";
        elsif rising_edge(clock_100) then
            -- Edge detection for KEY1
            key1_reg <= key1_reg(0) & key1;
            
            -- Falling edge detected on KEY1
            if key1_reg = "10" then
                if palette_index = PALETTE_SIZE - 1 then
                    palette_index <= 0;
                else
                    palette_index <= palette_index + 1;
                end if;
            end if;
        end if;
    end process;

    -- Convert rgb_color to output signals
    process(color_output)
    begin
        red <= std_logic_vector(to_unsigned(color_output.red, 4));
        green <= std_logic_vector(to_unsigned(color_output.green, 4));
        blue <= std_logic_vector(to_unsigned(color_output.blue, 4));
    end process;

end architecture;