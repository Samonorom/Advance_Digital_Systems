create_clock -name clk -period 20    [get_ports clock]


set_input_delay -clock clk -max 0.5  [get_ports reset]
set_input_delay -clock clk -min 0.1  [get_ports reset]

set_output_delay -clock clk -max 0.5 [get_ports done]
set_output_delay -clock clk -min 0.1 [get_ports done]
set_output_delay -clock clk -max 0.5 [get_ports puf_response_out]
set_output_delay -clock clk -min 0.1 [get_ports puf_response_out]