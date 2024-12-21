library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.seven_segment_pkg.all;

entity seven_segment_agent is
	generic (
		lamp_mode_common_anode:		boolean	:= true; -- true is common anode (on), false is common cathode (off).
		decimal_support:		boolean := true;
		implementer: 			natural	:= 200;
		revision: 			natural	:= 0;
		signed_support: 		boolean	:= true;
		blank_zeros_support:		boolean	:= true
	);
	port (
		-- Input ports
		clk:			in	std_logic;
		reset_n:		in	std_logic;
		address:		in	std_logic_vector(1 downto 0);
		read:			in	std_logic;
		write:			in	std_logic;
		writedata:		in	std_logic_vector(31 downto 0);
		-- Output ports
		readdata:		out	std_logic_vector(31 downto 0);
		lamps:			out 	std_logic_vector(41 downto 0) -- lamps/digits
	);
end entity seven_segment_agent;

architecture logic of seven_segment_agent is
	-- Signals
	signal data: 		std_logic_vector(31 downto 0) := (others => '0');
	signal control: 	std_logic_vector(31 downto 0) := (others => '0');
	signal data_to_driver: 	std_logic_vector(31 downto 0);
	signal hex_digits: seven_segment_digit_array;
	constant outputs_off: seven_segment_digit_array := lamps_off(lamp_mode_common_anode);

	type leading_zeros is array (seven_segment_digit_array'range) of boolean;
	signal have_seen_only_zeros: leading_zeros := (others => false);

	-- get Features Function 
	function get_features
		return std_logic_vector
	is
		variable ret: std_logic_vector(31 downto 0);
	begin
		ret := (others => '0');
		ret(31 downto 24) := std_logic_vector(to_unsigned(implementer, 8));
		ret(23 downto 16) := std_logic_vector(to_unsigned(revision, 8));

		if lamp_mode_common_anode then
			ret(3) := '1';
		end if;
		if decimal_support then
			ret(0) := '1';
		end if;
		if signed_support then
			ret(1) := '1';
		end if;
		if blank_zeros_support then
			ret(2) := '1';
		end if;
		return ret;
	end function get_features;
	
	--Double Dabble Function
	function to_bcd (data_value: in std_logic_vector(15 downto 0))
	return std_logic_vector is
	variable ret: std_logic_vector(19 downto 0);
	variable temp: std_logic_vector(data_value'range);
	begin
		temp := data_value;
		ret := (others => '0');
		for i in data_value'range loop
			for j in 0 to ret'length/4 - 1 loop
				if unsigned(ret(4*j + 3 downto 4*j)) >= 5 then
					ret(4*j + 3 downto 4*j) := std_logic_vector(unsigned(ret(4*j + 3 downto 4 * j)) + 3);
				end if;
			end loop;
			ret := ret(ret'high -1 downto 0) & temp(temp'high);
			temp := temp(temp'high - 1 downto 0) & '0';
		end loop;
		return ret;
	end function to_bcd;
	
	-- Concatenation Function
	function concat_function(
		config:	in seven_segment_digit_array
	) return std_logic_vector
	is
		variable ret: std_logic_vector(41 downto 0);
	begin
		for i in config'range loop
			ret(7*i + 6 downto 7*i) := config(i).g & config(i).f & config(i).e &	config(i).d & config(i).c & config(i).b & config(i).a;
		end loop;

		return ret;
	end function concat_function;

begin
	-- Data Driver (Data Processing from inputs)
	data_driver: process(data, control) is
		variable intermediate: std_logic_vector(15 downto 0);
		variable signed_value: signed(15 downto 0);
	begin
		if signed_support and control(3) = '1' and data(15) = '1' then
			signed_value := -signed(data(15 downto 0)); 	-- Two's complement for negative numbers
			intermediate := std_logic_vector(signed_value); -- Convert to std_logic_vector
		else
			intermediate := data(15 downto 0);
		end if;

		if decimal_support and control(1) = '1' then
			data_to_driver <= (others => '0');
			data_to_driver(19 downto  0) <= to_bcd(intermediate(15 downto 0)); -- Convert to BCD
		else
			data_to_driver <= data;
		end if;
	end process data_driver;
	
	-- concat. the digits
	lamps <= concat_function(hex_digits) when control(0) = '1'
	else concat_function(outputs_off);

	-- Assigning Digits
	assign_digit: for digit in seven_segment_digit_array'reverse_range generate
		constant high_bit: natural := 4 * digit + 3;
		constant low_bit:  natural := 4 * digit;
	begin
		process(control, data_to_driver) is
		begin
			-- negative feature
			if decimal_support and signed_support and control(3) = '1' 
						and digit = seven_segment_digit_array'high 
						and data(15) = '1' and control(1) = '1' then
							hex_digits(digit) <= lamps_negative(lamp_mode_common_anode);
							have_seen_only_zeros(digit) <= true;
			-- Handle MSB
			elsif decimal_support and control(1) = '1' 
						and digit = seven_segment_digit_array'high then
								hex_digits(digit) <= lamps_off(lamp_mode_common_anode)(digit);
								have_seen_only_zeros(digit) <= true;
			-- blank leading zeros feature
			elsif decimal_support and blank_zeros_support
						and control(2) = '1' and control(1) = '1'
						and digit > 0
						and digit < seven_segment_digit_array'high
						and have_seen_only_zeros(digit + 1)
						and data_to_driver(high_bit downto low_bit) = "0000" then
							hex_digits(digit) <= lamps_off(lamp_mode_common_anode)(digit);
							have_seen_only_zeros(digit) <= true;
			-- everything else
			else 
							have_seen_only_zeros(digit) <= false;
							hex_digits(digit) <= get_hex_digit(
							to_integer(unsigned(data_to_driver(high_bit downto low_bit))), lamp_mode_common_anode
							);
			end if;
		end process;
	end generate;

	-- Clock trigger (Process for handling read/write operations and resets).
	change_trigger: process(clk) is
	begin
		if rising_edge(clk) then
			if reset_n = '0' then
				-- reset everything
				data <= (others => '0');
				control <= (others => '0');
				--readdata <= (others => '0'); -- Reset readdata to avoid conflicts EXPERIMENTAL ADD
			end if;
			elsif read = '1' then
				case address is
					when "00" => readdata <= data;
					when "01" => readdata <= control;
					when "10" => readdata <= get_features;
					when "11" => readdata <= std_logic_vector(to_unsigned(16#41445335#, 32));
					when others => null;
					--when others => readdata <= (others => '0'); -- Avoid unassigned states
				end case;
			elsif write = '1' then
				case address is
					when "00" => data <= writedata;
					when "01" => 	--control <= writedata;
							if decimal_support then
								control(1) <= writedata(1);
							end if;
							if decimal_support and signed_support then
								control(3) <= writedata(3);
							end if;
							if decimal_support and blank_zeros_support then
								control(2) <= writedata(2);
							end if;
							control(0) <= writedata(0);
					when others => null;
				end case;
			end if;
	end process change_trigger;
end architecture logic;

