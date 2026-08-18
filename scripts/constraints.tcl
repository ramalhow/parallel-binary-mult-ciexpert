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

#set CLOCK_TRANST_MIN [expr $MAIN_CLK*0.02]

set CLOCK_SRC_LATENCY_MAX [expr $MAIN_CLK*0.015]

set CLOCK_LATENCY_MAX [expr $MAIN_CLK*0.015]

set INPUT_PORT_DELAY_MAX [expr $MAIN_CLK*0.15]

set OUTPUT_PORT_DELAY_MAX [expr $MAIN_CLK*0.15]

# TODO: search more about this
set MAX_OUTPUT_LOAD 0.005 

#set MIN_INPUT_TRANST [expr $MAIN_CLK*0.01]

set MAX_INPUT_TRANST [expr $MAIN_CLK*0.1]

########################################################################
# APPLYING CONSTRAINTS
########################################################################

# Create the clock instance in our previously defined clock port name
create_clock -period $MAIN_CLK [get_ports $DESIGN_CLK_NAME]

# Define the max uncertanty (jitter + skew + process variation + clock uncertanty)
# in the SETUP phase
set_clock_uncertainty -setup $CLOCK_SKEW_SETUP [get_clocks $DESIGN_CLK_NAME]

# A ferramenta deixa de assumir um clock ideal.
# Impacto: delay das células, análise de setup, análise de hold e potência.
set_clock_transition -max $CLOCK_TRANST_MAX [get_clocks $DESIGN_CLK_NAME]

# set_clock_transition -min $CLOCK_TRANST_MIN [get_clocks $DESIGN_CLK_NAME]

# Clock source latency
set_clock_latency -source -max $CLOCK_SRC_LATENCY_MAX [get_clocks $DESIGN_CLK_NAME]

# Clock "general" latency (?)
set_clock_latency -max $CLOCK_LATENCY_MAX [get_clocks $DESIGN_CLK_NAME]

# Quanto bloco anterior pode gastar.
set_input_delay -max $INPUT_PORT_DELAY_MAX -clock $DESIGN_CLK_NAME [get_ports [remove_from_collection [all_inputs] $DESIGN_CLK_NAME]]

# Tempo que precisa para entregar a saída cedo o suficiente para o próximo bloco.
set_output_delay -max $OUTPUT_PORT_DELAY_MAX -clock $DESIGN_CLK_NAME [get_ports [all_outputs]]

# Limits the max capacitive load on the outputs
set_load -max $MAX_OUTPUT_LOAD [all_outputs]

#set_input_transition -min $MIN_INPUT_TRANST [remove_from_collection [all_inputs] $DESIGN_CLK_NAME]
set_input_transition -max $MAX_INPUT_TRANST [remove_from_collection [all_inputs] $DESIGN_CLK_NAME]
