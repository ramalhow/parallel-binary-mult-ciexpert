########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: setup_dc.tcl
# Description: Design Compiler's script for defining the constraints 
# Version: 2026-07-02
# Author: Arthur Ramalho
########################################################################

########################################################################
# DEFINING CONSTRAINTS
########################################################################

# Define the operating clock in our design (~300MHz)
set MAIN_CLK 3.333333

# Define the clock var name used in our design
set DESIGN_CLK_NAME i_clk

set CLOCK_SKEW_SETUP [expr $MAIN_CLK*0.02]

set CLOCK_TRANST_MAX [expr $MAIN_CLK*0.02]

set CLOCK_TRANST_MIN [expr $MAIN_CLK*0.01]

set CLOCK_SRC_LATENCY_MAX [expr $MAIN_CLK*0.015]

set CLOCK_LATENCY_MAX [expr $MAIN_CLK*0.015]

set INPUT_PORT_DELAY_MIN [expr $MAIN_CLK*0.01]
set INPUT_PORT_DELAY_MAX [expr $MAIN_CLK*0.15]

set OUTPUT_PORT_DELAY_MAX [expr $MAIN_CLK*0.15]

# TODO: search more about this
set MAX_OUTPUT_LOAD 0.005 

set MIN_INPUT_TRANST [expr $MAIN_CLK*0.01]
set MAX_INPUT_TRANST [expr $MAIN_CLK*0.1]