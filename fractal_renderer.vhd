library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library ads;
use ads.ads_fixed.all;
use ads.ads_complex_pkg.all;
library vga;
use vga.color_data.all;
use vga.vga_data.all;
use work.coordinate_mapping.all;

entity fractal_renderer is
    generic (
        -- VGA timing configuration
        vga_res: vga_timing := vga_res_640x480;
        -- Pipeline configuration
        PIPELINE_STAGES : natural := 16
    );
    port (
        clk         : in  std_logic;  -- 100 MHz
        reset       : in  std_logic;
        -- Fractal selection and parameters
        set_sel     : in  std_logic;  -- 0: Mandelbrot, 1: Julia
        julia_c_re  : in  ads_sfixed := DEFAULT_JULIA_C_RE;
        julia_c_im  : in  ads_sfixed := DEFAULT_JULIA_C_IM;
        -- Color control
        palette_sel : in  palette_index_type;
        -- VGA interface
        vga_point   : in  coordinate;
        point_valid : in  boolean;
        color_valid : out  boolean;
        color       : out rgb_color
    );
end entity;

architecture rtl of fractal_renderer is
    -- Component declaration for pixel pipeline
    component pixel_pipeline is
        generic (
				PIPELINE_STAGES : natural := 16;
				-- VGA timing configuration
				vga_res: vga_timing := vga_res_640x480;
            ESCAPE_THRESHOLD: ads_sfixed := ESCAPE_THRESHOLD_const  -- 4.0
        );
        port (
            clk         : in  std_logic;
            reset       : in  std_logic;
            point_re    : in  ads_sfixed;
            point_im    : in  ads_sfixed;
            init_re     : in  ads_sfixed;
            init_im     : in  ads_sfixed;
				addr_in	   : in  integer range 0 to vga_res.horizontal.active-1;
            start       : in  std_logic;
            set_sel     : in  std_logic;
            valid       : out std_logic;
				addr_out	   : out  integer range 0 to vga_res.horizontal.active-1;
            iteration   : out natural range 0 to PIPELINE_STAGES
        );
    end component;

    -- Line buffer type definitions
    type line_buffer is array(0 to vga_res.horizontal.active-1) of natural range 0 to PIPELINE_STAGES;
    type dual_buffer is array(0 to 1) of line_buffer;
    
    -- Buffer signals
    signal iter_buffers: dual_buffer;
    signal write_buffer: integer range 0 to 1;
    signal read_buffer: integer range 0 to 1;
    signal write_addr: integer range 0 to vga_res.horizontal.active-1;
    signal write_addr_pipe: integer range 0 to vga_res.horizontal.active-1;
    
    -- Pipeline control signals
    signal pipe_point_re, pipe_point_im: ads_sfixed;
    signal pipe_init_re, pipe_init_im: ads_sfixed;
    signal pipe_start, pipe_valid: std_logic;
    signal pipe_iteration: integer range 0 to PIPELINE_STAGES;
    
    -- Line state control
    signal current_line: integer range 0 to vga_res.vertical.active-1;
    signal line_complete: boolean;
    
    -- Initial zero value in 33-bit fixed point
    constant ZERO_FIXED: ads_sfixed := "000000000000000000000000000000000";
    
    -- Color palette
    signal current_palette: color_table_type;

begin
    -- Get current color palette
    current_palette <= get_palette(palette_sel);
  
    -- Instantiate pixel pipeline
    pixel_calc: pixel_pipeline
        generic map (
            PIPELINE_STAGES => PIPELINE_STAGES,
            ESCAPE_THRESHOLD => ESCAPE_THRESHOLD_const  -- 100
        )
        port map (
            clk => clk,
            reset => reset,
            point_re => pipe_point_re,
            point_im => pipe_point_im,
            init_re => pipe_init_re,
            init_im => pipe_init_im,
				addr_in => write_addr,
            start => pipe_start,
            set_sel => set_sel,
            valid => pipe_valid,
				addr_out => write_addr_pipe,
            iteration => pipe_iteration
        );

    -- Main control process
    process(clk, reset)
    begin
        if reset = '1' then
            write_buffer <= 0;
            read_buffer <= 1;
            write_addr <= 0;
            current_line <= 0;
            pipe_start <= '0';
            line_complete <= false;
            pipe_point_re <= ZERO_FIXED;
            pipe_point_im <= ZERO_FIXED;
            pipe_init_re <= ZERO_FIXED;
            pipe_init_im <= ZERO_FIXED;
            
        elsif rising_edge(clk) then
            pipe_start <= '0';  -- Default state
            
            if not line_complete then
                -- Map coordinates for next pixel
                pipe_point_re <= map_coordinate_x( write_addr  , vga_res.horizontal.active );
                pipe_point_im <= map_coordinate_y( current_line, vga_res.vertical.active);
                
                -- Set initial values
                if set_sel = '0' then  -- Mandelbrot
                    pipe_init_re <= ZERO_FIXED;
                    pipe_init_im <= ZERO_FIXED;
                else  -- Julia
                    pipe_init_re <= julia_c_re;
                    pipe_init_im <= julia_c_im;
                end if;
                
                pipe_start <= '1';
                
                -- Store result when valid
                if pipe_valid = '1' then
                    iter_buffers(write_buffer)(write_addr_pipe) <= pipe_iteration;
                    
                    if write_addr = vga_res.horizontal.active-1 then
                        write_addr <= 0; 
                    else
                        write_addr <= write_addr + 1;
                    end if;
						  
                    if write_addr_pipe = vga_res.horizontal.active-1 then 
                        line_complete <= true; 
                    end if;
						  
                end if;
            end if;
            
            -- Check for buffer swap conditions
            if line_complete and (vga_point.y = current_line) and 
               (vga_point.x = vga_res.horizontal.active-1) then
                -- Swap buffers
                if write_buffer = 0 then
                    write_buffer <= 1;
                    read_buffer  <= 0;
                else
                    write_buffer <= 0;
                    read_buffer  <= 1;
                end if;
                -- Setup for next line
                if current_line = vga_res.vertical.active-1 then
                    current_line <= 0;
                else
                    current_line <= current_line + 1;
                end if;
                line_complete <= false;
            end if;
        end if;
    end process;

    -- Color output process
    process(point_valid, vga_point)
        variable iter_value: integer range 0 to PIPELINE_STAGES;
    begin
        if (point_valid and (vga_point.x < vga_res.horizontal.active) and (vga_point.y < vga_res.vertical.active)) then
            -- Get iteration value from buffer
            iter_value := iter_buffers(read_buffer)(vga_point.x);
            
            -- Map to color
            if iter_value = PIPELINE_STAGES then
                color <= color_black;
            else
                color <= get_color(iter_value, current_palette);
            end if;
        else
            color <= color_black;
        end if;
		  
		  
		  color_valid <= point_valid;
    end process;

end architecture;