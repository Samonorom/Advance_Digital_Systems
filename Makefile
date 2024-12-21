# Makefile for Project4 (SoC) testbench

# language for top will be in VHDL.
TOPLEVEL_LANG = vhdl

# VHDL top level name, (IE top_level.vhd).
TOPLEVEL = seven_segment_agent

#Python testbench name (IE: tb_toplevel_wrapper.py).
MODULE = tb_toplevel_wrapper

# Simulation options, (simulating in GHDL).
SIM = ghdl
# COMPILE_ARGS=--std=08.
# SIM_ARGS=--wave=$(TOPLEVEL).ghw 

# VHDL Source files and location (PWD is the present working directory).
VHDL_SOURCES = \
    $(PWD)/seven_segment_pkg.vhd \
    $(PWD)/seven_segment_agent.vhd \
    # $(PWD)/top_level.vhd
    #seven_segment_pkg.vhd \
    #seven_segment_agent.vhd \
    #top_level.vhd

# uncomment one of the export if COCOTB's PATH is not established.
export COCOTB_REDUCED_LOG_FMT=1 
# export  COCOTB_SCHEDULER_DEBUG=1

include $(shell cocotb-config --makefiles)/Makefile.sim

