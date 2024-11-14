
#**************************************************************
# Create Clock
#**************************************************************
create_clock -name MAX10_CLK1_50 -period 20.000 [get_ports MAX10_CLK1_50]

# Create generated clock for VGA (25 MHz from PLL)
create_generated_clock -name vga_clock -source [get_ports MAX10_CLK1_50] -divide_by 2 \
    [get_pins {vga_top_inst|vga_pll|altpll_component|auto_generated|pll1|clk[0]}]
 
# Create generated clock for system (100 MHz from PLL) 
create_generated_clock -name sys_clock -source [get_ports MAX10_CLK1_50] -multiply_by 2 \
    [get_pins {vga_top_inst|vga_pll|altpll_component|auto_generated|pll1|clk[1]}]

#**************************************************************
# Create Generated Clock
#**************************************************************
derive_pll_clocks -create_base_clocks

#**************************************************************
# Set Clock Uncertainty
#**************************************************************
derive_clock_uncertainty

#**************************************************************
# Set Input and Output Delays
#**************************************************************
# Input delays for asynchronous signals
set_input_delay -clock MAX10_CLK1_50 5.0 [get_ports KEY*]
set_input_delay -clock MAX10_CLK1_50 5.0 [get_ports SW*]

# Output delays for VGA signals
set_output_delay -clock vga_clock -max 2.0 [get_ports VGA_R*]
set_output_delay -clock vga_clock -max 2.0 [get_ports VGA_G*]
set_output_delay -clock vga_clock -max 2.0 [get_ports VGA_B*]
set_output_delay -clock vga_clock -max 2.0 [get_ports VGA_HS]
set_output_delay -clock vga_clock -max 2.0 [get_ports VGA_VS]

set_output_delay -clock vga_clock -min -1.0 [get_ports VGA_R*]
set_output_delay -clock vga_clock -min -1.0 [get_ports VGA_G*]
set_output_delay -clock vga_clock -min -1.0 [get_ports VGA_B*]
set_output_delay -clock vga_clock -min -1.0 [get_ports VGA_HS]
set_output_delay -clock vga_clock -min -1.0 [get_ports VGA_VS]

#**************************************************************
# Set False Path
#**************************************************************
# Asynchronous inputs
set_false_path -from [get_ports {KEY[*]}]
set_false_path -from [get_ports {SW[*]}]

#**************************************************************
# Set Clock Groups
#**************************************************************
# Declare clock domains as asynchronous
set_clock_groups -asynchronous -group [get_clocks {MAX10_CLK1_50 sys_clock}] -group [get_clocks {vga_clock}]

#**************************************************************
# Pin Assignments and I/O Standards
#**************************************************************
# These assignments should be in the .qsf file. They are included here
# for reference but will need to be added to the project through the
# Quartus Assignment Editor or .qsf file:

# Clock pin
# set_instance_assignment -name RESERVE_PIN "AS BIDIRECTIONAL" -to MAX10_CLK1_50
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to MAX10_CLK1_50
# set_location_assignment PIN_P11 -to MAX10_CLK1_50

# KEY pins
# set_instance_assignment -name IO_STANDARD "3.3 V SCHMITT TRIGGER" -to KEY[0]
# set_instance_assignment -name IO_STANDARD "3.3 V SCHMITT TRIGGER" -to KEY[1]
# set_location_assignment PIN_B8 -to KEY[0]
# set_location_assignment PIN_A7 -to KEY[1]

# SW pins
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to SW[0]
# set_location_assignment PIN_C10 -to SW[0]
# (... similar for SW[1] through SW[9])

# VGA pins
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[0]
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[1]
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[2]
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_R[3]
# (... similar for VGA_G and VGA_B)
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_HS
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to VGA_VS

# VGA pin locations
# set_location_assignment PIN_N3 -to VGA_HS
# set_location_assignment PIN_N1 -to VGA_VS
# set_location_assignment PIN_AA1 -to VGA_R[0]
# set_location_assignment PIN_V1 -to VGA_R[1]
# set_location_assignment PIN_Y2 -to VGA_R[2]
# set_location_assignment PIN_Y1 -to VGA_R[3]
# (... similar for VGA_G and VGA_B)

# VGA output settings
# set_instance_assignment -name CURRENT_STRENGTH_NEW 8MA -to VGA_*
# set_instance_assignment -name SLEW_RATE 2 -to VGA_*

#**************************************************************
# Create separate .qsf file with these Quartus-specific assignments
#**************************************************************
# Example .qsf content:
#
# # Clock pin
# set_location_assignment PIN_P11 -to MAX10_CLK1_50
# set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to MAX10_CLK1_50
#
# # KEY pins
# set_location_assignment PIN_B8 -to KEY[0]
# set_location_assignment PIN_A7 -to KEY[1]
# set_instance_assignment -name IO_STANDARD "3.3 V SCHMITT TRIGGER" -to KEY[0]
# set_instance_assignment -name IO_STANDARD "3.3 V SCHMITT TRIGGER" -to KEY[1]
#
# # VGA pins
# set_location_assignment PIN_N3 -to VGA_HS
# set_location_assignment PIN_N1 -to VGA_VS
# set_location_assignment PIN_AA1 -to VGA_R[0]
# set_location_assignment PIN_V1 -to VGA_R[1]
# set_location_assignment PIN_Y2 -to VGA_R[2]
# set_location_assignment PIN_Y1 -to VGA_R[3]
# set_location_assignment PIN_W1 -to VGA_G[0]
# set_location_assignment PIN_T2 -to VGA_G[1]
# set_location_assignment PIN_R2 -to VGA_G[2]
# set_location_assignment PIN_R1 -to VGA_G[3]
# set_location_assignment PIN_P1 -to VGA_B[0]
# set_location_assignment PIN_T1 -to VGA_B[1]
# set_location_assignment PIN_P4 -to VGA_B[2]
# set_location_assignment PIN_N2 -to VGA_B[3]