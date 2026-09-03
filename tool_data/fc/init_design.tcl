########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: 0_init_design.tcl
# Description: todo
# Version: 2026-07-02
# Author: Arthur Ramalho
#########################################################################

###############################################################################
# Project Setup
###############################################################################

# Project definitions and variables
source ../../../scripts/setup_vars.tcl

# 
set_app_var search_path ". ${DB_DIR} ${DLIB_DIR} ${NDM_DIR} ${RTL_DIR} ${TECH_DIR}"

# Tech setup
source ../../../scripts/tech_setup.tcl

###############################################################################
# Initialize the design
###############################################################################

# Current Stage
set DESIGN_STAGE "init_design"

# TODO: create a new dlib with the reference library and the design
#source ../setup/create_ndm.tcl 

create_lib -technology  $TECH_FILE -ref_libs $REFERENCE_LIBRARY ${DLIB_DIR}/${DLIB_FUSION}.dlib

analyze -format verilog ${DESIGN}.v
elaborate ${DESIGN}
set_top_module ${DESIGN}

###############################################################################
# Tech Setup
###############################################################################

# reading the site_row from lef file
#read_tech_lef ${LEF_DIR}/saed32nm_lvt_1p9m.lef -design ${DESIGN} -merge_action add

set_attribute [get_site_defs unit] symmetry Y
set_attribute [get_site_defs unit] is_default true

# suppresse the warning just for the init design
suppress_message ATTR-12

# metal via direction
set_attribute [get_layers {M1 M3 M5 M7 M9}] routing_direction horizontal
set_attribute [get_layers {M2 M4 M6 M8 MRDL}] routing_direction vertical

report_ignored_layers
set_ignored_layers -max_routing_layer $MAX_SIGNAL_ROUTING_LAYER
report_ignored_layers

###############################################################################
# Scenarios 
###############################################################################
set CURRENT_DLIB ${DLIB_FUSION}
source ../../../scripts/scenarios.tcl

###############################################################################
# Timing Constraints
###############################################################################
set MAIN_CLK 3.333333

# Define the clock var name used in our design
set DESIGN_CLK_NAME i_clk

set CLOCK_SKEW_SETUP [expr $MAIN_CLK*0.02]
#set CLOCK_SKEW_HOLD  [expr $MAIN_CLK*0.02]

set INPUT_PORT_DELAY_MIN [expr $MAIN_CLK*0.01]
set INPUT_PORT_DELAY_MAX [expr $MAIN_CLK*0.15]

set OUTPUT_PORT_DELAY_MAX [expr $MAIN_CLK*0.15]

create_clock -period $MAIN_CLK [get_ports $DESIGN_CLK_NAME]

set_clock_uncertainty -setup $CLOCK_SKEW_SETUP [get_clocks $DESIGN_CLK_NAME]
#set_clock_uncertainty -hold $CLOCK_SKEW_HOLD [get_clocks $DESIGN_CLK_NAME]

set_input_delay -min $INPUT_PORT_DELAY_MIN -clock $DESIGN_CLK_NAME [all_inputs -exclude_clock_ports]
set_input_delay -max $INPUT_PORT_DELAY_MAX -clock $DESIGN_CLK_NAME [all_inputs -exclude_clock_ports]

set_output_delay -max $OUTPUT_PORT_DELAY_MAX -clock $DESIGN_CLK_NAME [get_ports [all_outputs]]

###############################################################################
# Tie Cells
###############################################################################
set_dont_touch [get_lib_cells */TIE*] false
set_lib_cell_purpose -include optimization [get_lib_cells */TIE*]

###############################################################################
# End off init_design
###############################################################################
file mkdir ${RPT_DIR}/FUSION/${DESIGN_STAGE}
report_lib \
        -timing_arcs \
        -parasitic_tech \
        -physical \
        -antenna \
        -routability \
        -pattern_must_join_pin \
        -placement_constraints \
        -wire_tracks \
        -wire_track_colors \
        -verbose \
        -include_db_mapping \
        -cell_summary \
        -char_model \
        [current_lib] > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_reference.rpt


save_block -compress -as ${DLIB_FUSION}/${DESIGN_STAGE}
save_lib

unsuppress_message ATTR-12
