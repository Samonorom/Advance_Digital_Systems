library ieee;
use ieee.std_logic_1164.all;

package color_data is

	subtype color_channel_type is natural range 0 to 15;

		  -- Define ranges for the arrays
    constant COLOR_TABLE_SIZE : natural := 8;  -- Number of colors per palette
    constant PALETTE_SIZE : natural := 4;      -- Number of palettes

	 
	type rgb_color is
	record
		red:	color_channel_type;
		green:	color_channel_type;
		blue:	color_channel_type;
	end record rgb_color;

    -- Constrained array types
    type color_table_type is array(0 to COLOR_TABLE_SIZE-1) of rgb_color;
    type color_palette_type is array(0 to PALETTE_SIZE-1) of color_table_type;
	-- NOTE: on your toplevel you can define an output as
	-- 
	-- color: out rgb_color;
	--
	-- then on pin placement:
	--
	-- set_location_assignment PIN_XXXX -to color.red[0]
	-- set_location_assignment PIN_YYYY -to color.red[1]
	--
	-- and so on (use loops to simplify the work!)

	constant color_black: rgb_color :=
		( red =>  0, green =>  0, blue =>  0 );
	constant color_red: rgb_color :=
		( red => 15, green =>  0, blue =>  0 );
	constant color_green: rgb_color :=
		( red =>  0, green => 15, blue =>  0 );
	constant color_blue: rgb_color :=
		( red =>  0, green =>  0, blue => 15 );    
	constant color_white: rgb_color := 
		( red => 15, green => 15, blue => 15 );

--	type color_table_type is array(natural range<>) of rgb_color;
	

 


    -- Original blue gradient palette (kept for reference)
    constant color_table_1: color_table_type := (
        0 => ( red =>  0, green =>  0, blue => 15 ),  -- Pure blue
        1 => ( red =>  2, green =>  2, blue => 13 ),  -- Light blue
        2 => ( red =>  4, green =>  4, blue => 11 ),  -- Sky blue
        3 => ( red =>  6, green =>  6, blue =>  8 ),  -- Light sky blue
        4 => ( red =>  8, green =>  8, blue =>  6 ),  -- Cyan-ish
        5 => ( red => 10, green => 10, blue =>  4 ),  -- Light yellow-green
        6 => ( red => 13, green => 13, blue =>  2 ),  -- Light yellow
        7 => ( red => 15, green => 15, blue =>  0 )   -- Pure yellow
    );

    -- New blue to yellow transition palette
    constant color_table_2: color_table_type := (
        0 => ( red =>  0, green =>  0, blue => 15 ),
        1 => ( red =>  2, green =>  2, blue => 13 ),
        2 => ( red =>  4, green =>  4, blue => 11 ),
        3 => ( red =>  6, green =>  6, blue =>  9 ),
        4 => ( red =>  8, green =>  8, blue =>  7 ),
        5 => ( red => 10, green => 10, blue =>  5 ),
        6 => ( red => 12, green => 12, blue =>  3 ),
        7 => ( red => 15, green => 15, blue =>  0 )
    );

    -- Vibrant blue to yellow palette
    constant color_table_3: color_table_type := (
        0 => ( red =>  0, green =>  0, blue => 15 ),  -- Deep blue
        1 => ( red =>  0, green =>  4, blue => 15 ),  -- Blue with some green
        2 => ( red =>  0, green =>  8, blue => 12 ),  -- Turquoise
        3 => ( red =>  2, green => 10, blue =>  8 ),  -- Sea green
        4 => ( red =>  6, green => 12, blue =>  4 ),  -- Yellow-green
        5 => ( red => 10, green => 14, blue =>  2 ),  -- Light yellow-green
        6 => ( red => 13, green => 15, blue =>  1 ),  -- Warm yellow
        7 => ( red => 15, green => 15, blue =>  0 )   -- Pure yellow
    );

    -- Alternative blue-yellow gradient with more contrast
    constant color_table_4: color_table_type := (
        0 => ( red =>  0, green =>  0, blue => 15 ),  -- Pure blue
        1 => ( red =>  0, green =>  2, blue => 15 ),  -- Bright blue
        2 => ( red =>  2, green =>  6, blue => 13 ),  -- Blue-cyan
        3 => ( red =>  4, green =>  9, blue => 10 ),  -- Cyan
        4 => ( red =>  8, green => 12, blue =>  6 ),  -- Green-yellow
        5 => ( red => 12, green => 14, blue =>  3 ),  -- Yellow-green
        6 => ( red => 14, green => 15, blue =>  1 ),  -- Light yellow
        7 => ( red => 15, green => 15, blue =>  0 )   -- Pure yellow
    );
	--type color_palette_type is array(natural range 0 to 2) of color_table_type;
	
	constant color_palette_table: color_palette_type := (
			0 => color_table_1,
			1 => color_table_2,
			2 => color_table_3,
			3 => color_table_4
		);

	subtype color_index_type is natural range color_table_1'range;
	subtype palette_index_type is natural range color_palette_table'range;

	function get_color (
			color_index: in color_index_type;
			-- palette_index: in palette_index_type;
			color_palette: in color_table_type --color_palette_type 
		) return rgb_color;
		
	function get_palette (
			palette_index: in palette_index_type
		) return color_table_type; --   color_palette_type

end package color_data;


package body color_data is

-- need check these functions
	function get_color (
			color_index: in color_index_type;
			-- palette_index: in palette_index_type;
			color_palette: in color_table_type --color_palette_type 
		) return rgb_color
	is
	 -- variable col_table : color_table_type; 
	begin
		--col_table = get_palette(palette_index);
		return color_palette(color_index);
		-- TODO: return a color from the provided color palette
	end function get_color;

	function get_palette (
			palette_index: in palette_index_type
		) return color_table_type --   color_palette_type
	is
	begin
		return color_palette_table(palette_index);
		-- TODO: return something from the color palette table
	end function get_palette;

end package body color_data; 
