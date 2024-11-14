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

entity pixel_pipeline is
    generic (
        PIPELINE_STAGES : natural := 16;
        -- VGA timing configuration
        vga_res: vga_timing := vga_res_640x480;
        -- 4.0 in binary fixed point (33 bits):
        -- sign(0) & integer(000100) & fractional(00000000s)
        ESCAPE_THRESHOLD: ads_sfixed := ESCAPE_THRESHOLD_const  -- 4.0
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        -- Point coordinates
        point_re    : in  ads_sfixed;
        point_im    : in  ads_sfixed;
        -- Initial value
        init_re     : in  ads_sfixed;
        init_im     : in  ads_sfixed;
		  addr_in	  : in  integer range 0 to vga_res.horizontal.active-1; 
        -- Control
        start       : in  std_logic;
        set_sel     : in  std_logic;  -- 0: Mandelbrot, 1: Julia
        -- Output
        valid       : out std_logic;
		  addr_out	  : out  integer range 0 to vga_res.horizontal.active-1;
        iteration   : out natural range 0 to PIPELINE_STAGES
    );
end entity;

architecture rtl of pixel_pipeline is
    -- Pipeline stage record type
    type pipeline_stage is record
        z: ads_complex;
        c: ads_complex;
        escaped: boolean;
		  addr : integer range 0 to vga_res.horizontal.active-1; 
        iter: natural range 0 to PIPELINE_STAGES;
        valid: std_logic;
    end record;
    
    -- Pipeline registers
    type pipeline_array is array(0 to PIPELINE_STAGES) of pipeline_stage;
    signal pipe: pipeline_array;
	 
constant complex_zero: ads_complex := ads_cmplx(to_ads_sfixed(0), to_ads_sfixed(0));

begin
    -- Pipeline process
    process(clk, reset)
        variable z_next: ads_complex;
        variable mag: ads_sfixed;
    begin
        if reset = '1' then
            -- Reset all pipeline stages
            for i in pipe'range loop
                pipe(i).z <= complex_zero;
                pipe(i).c <= complex_zero;
                pipe(i).escaped <= false;
                pipe(i).iter <= 0;
                pipe(i).addr <= 0; 
                pipe(i).valid <= '0';
            end loop;
            
        elsif rising_edge(clk) then
            -- First stage - input
            if start = '1' then
                -- Set initial values based on selected set
                if set_sel = '0' then  -- Mandelbrot
                    pipe(0).z <= ads_cmplx(init_re, init_im);        
                    pipe(0).c <= ads_cmplx(point_re, point_im);     
                else  -- Julia
                    pipe(0).z <= ads_cmplx(point_re, point_im);    
                    pipe(0).c <= ads_cmplx(init_re, init_im);      
                end if;
                pipe(0).escaped <= false;
                pipe(0).iter <= 0;
                pipe(0).addr <= addr_in;
                pipe(0).valid <= '1';
            else
                pipe(0).valid <= '0';
            end if;

            -- Pipeline stages
            for i in 1 to PIPELINE_STAGES loop
                if pipe(i-1).valid = '1' then
                    -- Only compute if previous stage is valid
                    if not pipe(i-1).escaped then
                        -- z = z² + c
                        z_next := ads_square(pipe(i-1).z) + pipe(i-1).c;
                        -- Check if escaped
                        mag := abs2(z_next);
                        
                        pipe(i).z <= z_next; 
								
                        pipe(i).escaped <= mag > ESCAPE_THRESHOLD;
                        pipe(i).iter <= pipe(i-1).iter + 1;
                    else
                        -- Propagate previous result
                        pipe(i).z <= pipe(i-1).z;
                        pipe(i).escaped <= pipe(i-1).escaped;
                        pipe(i).iter <= pipe(i-1).iter;
                    end if;
                    
						  pipe(i).addr <= pipe(i-1).addr;
                    pipe(i).c <= pipe(i-1).c;
                    pipe(i).valid <= pipe(i-1).valid;
                else
                    pipe(i).valid <= '0';
                end if;
            end loop;
        end if;
    end process;

    -- Output assignment
    valid <= pipe(PIPELINE_STAGES).valid;
    addr_out <= pipe(PIPELINE_STAGES).addr;
    iteration <= pipe(PIPELINE_STAGES).iter when pipe(PIPELINE_STAGES).escaped else PIPELINE_STAGES;

end architecture;