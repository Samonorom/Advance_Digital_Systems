library ieee;
use ieee.std_logic_1164.all;

package seven_segment_pkg is 
	type seven_segment_config is record
		a: std_logic;
		b: std_logic;
		c: std_logic;
		d: std_logic;
		e: std_logic;
		f: std_logic;
		g: std_logic;
	end record seven_segment_config;

	type seven_segment_array_type is array (natural range <>) of seven_segment_config;
	type seven_segment_digit_array is array (0 to 5) of seven_segment_config;

	constant seven_segment_table: seven_segment_array_type := (
        (a => '1', b => '1', c => '1', d => '1', e => '1', f => '1', g => '0'), -- 0
        (a => '0', b => '1', c => '1', d => '0', e => '0', f => '0', g => '0'), -- 1
        (a => '1', b => '1', c => '0', d => '1', e => '1', f => '0', g => '1'), -- 2
        (a => '1', b => '1', c => '1', d => '1', e => '0', f => '0', g => '1'), -- 3
        (a => '0', b => '1', c => '1', d => '0', e => '0', f => '1', g => '1'), -- 4
        (a => '1', b => '0', c => '1', d => '1', e => '0', f => '1', g => '1'), -- 5
        (a => '1', b => '0', c => '1', d => '1', e => '1', f => '1', g => '1'), -- 6
        (a => '1', b => '1', c => '1', d => '0', e => '0', f => '0', g => '0'), -- 7
        (a => '1', b => '1', c => '1', d => '1', e => '1', f => '1', g => '1'), -- 8
        (a => '1', b => '1', c => '1', d => '1', e => '0', f => '1', g => '1'), -- 9
        (a => '1', b => '1', c => '1', d => '0', e => '1', f => '1', g => '1'), -- A
        (a => '0', b => '0', c => '1', d => '1', e => '1', f => '1', g => '1'), -- B
        (a => '1', b => '0', c => '0', d => '1', e => '1', f => '1', g => '0'), -- C
        (a => '0', b => '1', c => '1', d => '1', e => '1', f => '0', g => '1'), -- D
        (a => '1', b => '0', c => '0', d => '1', e => '1', f => '1', g => '1'), -- E
        (a => '1', b => '0', c => '0', d => '0', e => '1', f => '1', g => '1')  -- F
    );

	subtype hex_digit is natural range 0 to seven_segment_table'length - 1;

	-- Note Anode is 'true', 'on'. Cathode is 'false', 'off'.

	-- Hex Digit Function
	function get_hex_digit (
		digit:     in hex_digit;
		lamp_mode_common_anode: in boolean := true -- Example of true for anode, which can be set to false for cathode.
		) return seven_segment_config;

	-- Lamps Off Function
	function lamps_off (
		lamp_mode_common_anode: in boolean := true
		) return seven_segment_digit_array;

	-- Lamp Negative Function
	function lamps_negative (
		lamp_mode_common_anode: in boolean := true
	) return seven_segment_config;

end package seven_segment_pkg;

-- Body of Package
package body seven_segment_pkg is

	-- Invert Function
	function invert_segments (
	 	seg: in seven_segment_config
	) return seven_segment_config is
	begin
	 	return (a => not seg.a, b => not seg.b, c => not seg.c,
			d => not seg.d, e => not seg.e, f => not seg.f,
			g => not seg.g);
	end function invert_segments;
	
	-- Hex Digit Function
	function get_hex_digit (
		digit: in hex_digit;
		lamp_mode_common_anode: in boolean := true
	) return seven_segment_config is
	begin
		if lamp_mode_common_anode then
			return invert_segments(seven_segment_table(digit)); -- Invert for common anode
		else
			return seven_segment_table(digit); -- Direct for common cathode
		end if;
	end function get_hex_digit;

	-- Lamps Off Function
	function lamps_off (
			lamp_mode_common_anode: in boolean := true
			) return seven_segment_digit_array is

	variable off_array: seven_segment_digit_array;
	begin
		for i in off_array'range loop
			if lamp_mode_common_anode then
				off_array(i) := (a => '1', b => '1', c => '1', d => '1', e => '1', f => '1', g => '1');
			else
				off_array(i) := (a => '0', b => '0', c => '0', d => '0', e => '0', f => '0', g => '0');	
			end if;		
		end loop;
		return off_array;
	end function lamps_off;

	-- Lamp Negative Function
	function lamps_negative (
		lamp_mode_common_anode: in boolean := true
	) return seven_segment_config is
	begin
		if lamp_mode_common_anode then
			return (a => '1', b => '1', c => '1', d => '1', e => '1', f => '1', g => '0'); -- anode
		end if;
			return (a => '0', b => '0', c => '0', d => '0', e => '0', f => '0', g => '1'); -- cathode
	end function lamps_negative;

end package body seven_segment_pkg;