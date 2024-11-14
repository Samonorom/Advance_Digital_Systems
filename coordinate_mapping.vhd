library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library ads;
use ads.ads_fixed.all;
use ads.ads_complex_pkg.all;
package coordinate_mapping is
    -- Function to map screen coordinates to complex plane
    function map_coordinate_x(
        x: integer;          
        max_x: integer     
    ) return ads_sfixed;
	 
    function map_coordinate_y(
        y: integer;          
        max_y: integer      
    ) return ads_sfixed;
																 
    constant two_const: ads_sfixed 				:= "000000000000010000000000000000000"; -- 2.0
    constant two_p_two_const: ads_sfixed 		:= "000000000000010001100110011001101"; -- 2.2
    constant three_p_two_const: ads_sfixed 	:= "000000000000011001100110011001101"; -- 3.2
	 
    constant ESCAPE_THRESHOLD_const: ads_sfixed := "000000001100100000000000000000000"; -- 100
	  
    -- Constants for Julia viewport
    -- -2.0 = 1111110.00000000
    constant JULIA_X_MIN: ads_sfixed := "111111111111100000000000000000000"; -- -2.0
    
    -- 2.0 = 0000010.00000000
    constant JULIA_X_MAX: ads_sfixed := "000000000000010000000000000000000"; -- 2.0
    
    -- -2.0 = 1111110.00000000
    constant JULIA_Y_MIN: ads_sfixed := "111111111111100000000000000000000"; -- -2.0
    
    -- 2.0 = 0000010.00000000
    constant JULIA_Y_MAX: ads_sfixed := "000000000000010000000000000000000"; -- 2.0

    -- Default Julia set parameter (-0.4 + 0.6i)
    -- -0.4 = 11111111.10011010
    constant DEFAULT_JULIA_C_RE: ads_sfixed := "111111111111111100110011001100110"; -- -0.4
    
    -- 0.6 = 0000000.10011010
    constant DEFAULT_JULIA_C_IM: ads_sfixed := "000000000000000100110011001100110"; -- 0.6

end package;

package body coordinate_mapping is
    
	 function map_coordinate_x(
        x: integer;
        max_x: integer
    ) return ads_sfixed is
        variable x_fixed: ads_sfixed;
        variable max_fixed: ads_sfixed;
        variable pos: ads_sfixed;
    begin
        -- Convert coordinates to fixed point
        x_fixed := to_ads_sfixed(x);
        max_fixed := to_ads_sfixed(max_x);
         
        pos := three_p_two_const * x_fixed / max_fixed;
        
        return pos - two_p_two_const ;
    end function;
	 
	 
	 function map_coordinate_y(
        y: integer;
        max_y: integer
    ) return ads_sfixed is
        variable y_fixed: ads_sfixed;
        variable max_fixed: ads_sfixed;
        variable pos: ads_sfixed;
        variable half_max: ads_sfixed;
    begin
        -- Convert coordinates to fixed point
        y_fixed := to_ads_sfixed(y);
        max_fixed := to_ads_sfixed(max_y);
         
        half_max := max_fixed(max_fixed'high) & max_fixed(max_fixed'high downto (-lsb+1));
	 
        pos := (half_max - y_fixed ) / max_fixed;
        
        return two_p_two_const * pos;
    end function;

 
end package body;