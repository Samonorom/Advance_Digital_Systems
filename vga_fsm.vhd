library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library vga;
use vga.vga_data.all;
use vga.color_data.all;

entity vga_fsm is
    generic (
        vga_res: vga_timing := vga_res_default
    );
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        -- VGA outputs
        h_sync      : out std_logic;
        v_sync      : out std_logic;
        -- Coordinate and valid signals
        point       : out coordinate;
        point_valid : out boolean
    );
end entity;

architecture rtl of vga_fsm is
    signal current_point: coordinate;
    
begin
    -- Main VGA timing process
    process(clk, reset)
    begin
        if reset = '1' then
            current_point <= make_coordinate(0, 0);
            
				if vga_res.sync_polarity = active_high then
					h_sync <= '1';
					v_sync <= '1';
				else
					h_sync <= '0';
					v_sync <= '0';
				end if;
				 
            
        elsif rising_edge(clk) then
            -- Update coordinates
            current_point <= next_coordinate(current_point, vga_res);
            
            -- Generate sync signals
            h_sync <= do_horizontal_sync(current_point, vga_res);
            v_sync <= do_vertical_sync(current_point, vga_res);
				
				-- Output current point and validity
				point <= current_point;
				point_valid <= point_visible(current_point, vga_res);
	 
        end if;
    end process;


end architecture;