library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
library vga;
use vga.vga_data.all;
use vga.color_data.all;

entity DE10_LITE_Golden_Top_tb is
end entity;

architecture testbench of DE10_LITE_Golden_Top_tb is
    -- Component declaration for the top-level entity
    component DE10_LITE_Golden_Top is
        port (
            MAX10_CLK1_50  : in  std_logic;
            KEY            : in  std_logic_vector(1 downto 0);
            SW             : in  std_logic_vector(9 downto 0);
            VGA_R         : out std_logic_vector(3 downto 0);
            VGA_G         : out std_logic_vector(3 downto 0);
            VGA_B         : out std_logic_vector(3 downto 0);
            VGA_HS        : out std_logic;
            VGA_VS        : out std_logic
        );
    end component;

    -- Test bench signals
    signal clk           : std_logic := '0';
    signal keys          : std_logic_vector(1 downto 0) := "11";  -- Active low
    signal switches      : std_logic_vector(9 downto 0) := (others => '0');
    signal vga_red      : std_logic_vector(3 downto 0);
    signal vga_green    : std_logic_vector(3 downto 0);
    signal vga_blue     : std_logic_vector(3 downto 0);
    signal vga_hsync    : std_logic;
    signal vga_vsync    : std_logic;

    -- Constants for image generation
    constant CLK_PERIOD : time := 20 ns;  -- 50 MHz clock
    constant FRAME_WIDTH : integer := 640;  -- For 640x480 resolution
    constant FRAME_HEIGHT : integer := 480;
    
	 
--    -- Create signals for monitoring
    signal color_valid_monitor : boolean;
    signal vga_clock : std_logic;
    
	 -- Signals for counting
    signal x_count      : integer := 0;
    signal y_count      : integer := 0;
	 
    -- File handling
    file output_file: text;
    
    -- Function to convert 4-bit color to 8-bit
    function expand_color(color_4bit: std_logic_vector(3 downto 0)) return integer is
    begin
        -- Scale up 4-bit color (0-15) to 8-bit range (0-255)
        return to_integer(unsigned(color_4bit)) * 17;
    end function;

begin
    -- Device Under Test
    DUT: DE10_LITE_Golden_Top
        port map (
            MAX10_CLK1_50 => clk,
            KEY => keys,
            SW => switches,
            VGA_R => vga_red,
            VGA_G => vga_green,
            VGA_B => vga_blue,
            VGA_HS => vga_hsync,
            VGA_VS => vga_vsync
        );
		  
    -- Clock generation process
    process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process;
	 
	 process
    begin
        vga_clock <= '0';
        wait for CLK_PERIOD;
        vga_clock <= '1';
        wait for CLK_PERIOD;
    end process;
	 
 
 
 
    -- Main test process
    process
        variable outline : line;
        variable pixel_count : integer := 0;
        variable frame_complete : boolean := false;
        variable int_value : integer;
 
    begin
		  -- MAKING Mandelbrot set
        -- Open PBM file for writing
        file_open(output_file, "Mandelbrot_output.pbm", write_mode);
         
        -- Write PPM header (P3 format)
        write(outline, string'("P3"));  -- PPM magic number for ASCII RGB
        writeline(output_file, outline);
        
        -- Write dimensions with explicit integer formatting
        write(outline, integer'image(FRAME_WIDTH));
        write(outline, string'(" "));
        write(outline, integer'image(FRAME_HEIGHT));
        writeline(output_file, outline);
        
        write(outline, string'("255"));  -- Maximum color value
        writeline(output_file, outline);

        -- Initial reset
        keys(0) <= '0';  -- Active low reset
        wait for CLK_PERIOD * 10;
        keys(0) <= '1';
        
        -- Select fractal type (0 for Mandelbrot, 1 for Julia)
        switches(9) <= '0';  -- Set to Mandelbrot
        
        -- Capture one complete frame
        while not frame_complete loop
            
				-- Wait for falling edge of VSYNC to start frame, just at the begining 
				wait until rising_edge(vga_vsync);
            -- Capture frame data
            for y in 0 to FRAME_HEIGHT-1 loop
					y_count <= y_count +1; 
					x_count <= 0;  
                for x in 0 to FRAME_WIDTH-1 loop
						  x_count <= x_count +1;  
						  -- Write RGB values for current pixel
						  int_value := expand_color(vga_red);
						  write(outline, integer'image(int_value));
						  write(outline, string'(" "));
						  
						  int_value := expand_color(vga_green);
						  write(outline, integer'image(int_value));
						  write(outline, string'(" "));
						  
						  int_value := expand_color(vga_blue);
						  write(outline, integer'image(int_value));
						  write(outline, string'(" "));
						  
--						  -- Add newline every few pixels for readability
--						  if x mod 5 = 0 then
--								writeline(output_file, outline);
--						  end if;
						  
						  wait until rising_edge(vga_clock); 
                end loop;
					 
					 
					 -- Wait for falling edge of vga_hsync to start frame
					 wait until rising_edge(vga_hsync);
					 for x in 0 to 48-1 loop -- 48 vga clcok
                    wait until rising_edge(vga_clock);
                end loop;
                
--                -- Ensure we write any remaining pixels in the line
--                if (FRAME_WIDTH mod 5) /= 0 then
                    writeline(output_file, outline);
--                end if;
--					 
				
            end loop;
            
				-- Wait for falling edge of VSYNC to start frame
				wait until falling_edge(vga_vsync);
            frame_complete := true;
        end loop;

        -- Close file and end simulation
        file_close(output_file); 
          
		  
        frame_complete := false; 
        -- MAKING Mandelbrot set
        -- Open PBM file for writing
        file_open(output_file, "Julia_output.pbm", write_mode);
         
        -- Write PPM header (P3 format)
        write(outline, string'("P3"));  -- PPM magic number for ASCII RGB
        writeline(output_file, outline);
        
        -- Write dimensions with explicit integer formatting
        write(outline, integer'image(FRAME_WIDTH));
        write(outline, string'(" "));
        write(outline, integer'image(FRAME_HEIGHT));
        writeline(output_file, outline);
        
        write(outline, string'("255"));  -- Maximum color value
        writeline(output_file, outline);

        -- Initial reset
        keys(0) <= '0';  -- Active low reset
        wait for CLK_PERIOD * 10;
        keys(0) <= '1';
        
        -- Select fractal type (0 for Mandelbrot, 1 for Julia)
        switches(9) <= '1';  -- Set to Mandelbrot
        
        -- Capture one complete frame
        while not frame_complete loop
            
				-- Wait for falling edge of VSYNC to start frame, just at the begining 
				wait until rising_edge(vga_vsync);
            -- Capture frame data
            for y in 0 to FRAME_HEIGHT-1 loop
					y_count <= y_count +1; 
					x_count <= 0;  
                for x in 0 to FRAME_WIDTH-1 loop
						  x_count <= x_count +1;  
						  -- Write RGB values for current pixel
						  int_value := expand_color(vga_red);
						  write(outline, integer'image(int_value));
						  write(outline, string'(" "));
						  
						  int_value := expand_color(vga_green);
						  write(outline, integer'image(int_value));
						  write(outline, string'(" "));
						  
						  int_value := expand_color(vga_blue);
						  write(outline, integer'image(int_value));
						  write(outline, string'(" "));
						  
--						  -- Add newline every few pixels for readability
--						  if x mod 5 = 0 then
--								writeline(output_file, outline);
--						  end if;
						  
						  wait until rising_edge(vga_clock); 
                end loop;
					 
					 
					 -- Wait for falling edge of vga_hsync to start frame
					 wait until rising_edge(vga_hsync);
					 for x in 0 to 48-1 loop -- 48 vga clcok
                    wait until rising_edge(vga_clock);
                end loop;
                
--                -- Ensure we write any remaining pixels in the line
--                if (FRAME_WIDTH mod 5) /= 0 then
                    writeline(output_file, outline);
--                end if;
--					 
				
            end loop;
            
				-- Wait for falling edge of VSYNC to start frame
				wait until falling_edge(vga_vsync);
            frame_complete := true;
        end loop;

        -- Close file and end simulation
        file_close(output_file); 
		  
        -- Stop the simulation
        assert false report "Simulation Finished Successfully!" severity failure;
    end process;

end architecture;