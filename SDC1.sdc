#------------------------------------------------------------------------------
# SDC constraints for MAX10 temperature measurement project
#------------------------------------------------------------------------------

# First, let's derive all the clocks in our system

#------------------------------------------------------------------------------
# Primary Clock - 50 MHz from board
#------------------------------------------------------------------------------
create_clock -name MAX10_CLK1_50 -period 20.000 [get_ports MAX10_CLK1_50]

# Specify clock uncertainty for all clocks
# This accounts for jitter and other timing variations
derive_clock_uncertainty
 

#------------------------------------------------------------------------------
# PLL Generated Clock - 10 MHz for ADC
#------------------------------------------------------------------------------
# The multiply/divide values should match your PLL configuration
create_generated_clock -name pll_clk_10mhz \
    -source [get_pins {PLL:pll_inst|altpll:altpll_component|PLL_altpll:auto_generated|pll1|inclk[0]}] \
    -divide_by 5 \
    -multiply_by 1 \
    [get_pins {PLL:pll_inst|altpll:altpll_component|PLL_altpll:auto_generated|pll1|clk[0]}]
 
#------------------------------------------------------------------------------
# ADC Generated Clock - Divided from 10 MHz
#------------------------------------------------------------------------------
 
 create_generated_clock -name adc_clock -source  [get_pins {PLL:pll_inst|altpll:altpll_component|PLL_altpll:auto_generated|pll1|clk[0]}]  -divide_by 10 [get_pins {\REAL_ADC_GEN:adc_inst|primitive_instance|clk_dft}]
 
 
#------------------------------------------------------------------------------
# Clock Groups
# Define asynchronous clock domains
#------------------------------------------------------------------------------
set_clock_groups -asynchronous \
    -group {MAX10_CLK1_50} \
    -group {pll_clk_10mhz adc_clock}
 
 
#------------------------------------------------------------------------------
# I/O Constraints
#------------------------------------------------------------------------------
# Input delays for asynchronous reset (KEY0)
set_input_delay -clock MAX10_CLK1_50 -max 3 [get_ports KEY[0]]
set_input_delay -clock MAX10_CLK1_50 -min 1 [get_ports KEY[0]]

# Output delays for seven-segment displays
set_output_delay -clock MAX10_CLK1_50 -max 2 [get_ports HEX*]
set_output_delay -clock MAX10_CLK1_50 -min 0 [get_ports HEX*]
 