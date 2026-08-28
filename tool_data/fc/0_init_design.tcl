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

# Setup the fusion compiler specific settings
source ../setup/setup_fc.tcl

###############################################################################
# Initialize the design
###############################################################################

# Diferenciando o nome das dlibs pra evitar corrompimento das dlibs já existentes
set DLIB_FUSION ${DESIGN}_fusion

# Current Stage
set DESIGN_STAGE "init_design"

if { [file exists ${DLIB_DIR}/${DLIB_FUSION}.dlib] } {
    puts "\[INFO\] SETUP: Existing Dlib found at ${DLIB_DIR}/${DLIB_FUSION}.dlib. Loading block..."

    open_lib ${DLIB_DIR}/${DLIB_FUSION}.dlib
    open_block ${DESIGN}

} else {
    puts "\[INFO\] SETUP: No existing Dlib found. Creating database from scratch..."

    #source ../setup/create_ndm.tcl 

    create_lib -technology  $TECH_FILE -ref_libs $REFERENCE_LIBRARY ${DLIB_DIR}/${DLIB_FUSION}.dlib
    
    analyze -format verilog ${DESIGN}.v
    elaborate ${DESIGN}
    set_top_module ${DESIGN}

    current_block
}

###############################################################################
# Tech Setup
###############################################################################

# reading the site_row from lef file
read_tech_lef ${LEF_DIR}/saed32nm_lvt_1p9m.lef -design ${DESIGN} -merge_action add

set_attribute [get_site_defs unit] symmetry Y
set_attribute [get_site_defs unit] is_default true

# suppresse the warning just for the init design
suppress_message ATTR-12

# metal via direction
set_attribute [get_layers {M1 M3 M5 M7 M9}] routing_direction horizontal
set_attribute [get_layers {M2 M4 M6 M8 MRDL}] routing_direction vertical

#set_ignored_layers -max_routing_layer $MAX_ROUTING_LAYER

###############################################################################
# Scenarios and Constraints
###############################################################################

# loading and applying the constraints
source ../../../scripts/constraints.tcl

# loading the scenarios
set CURRENT_DLIB ${DLIB_FUSION}
source ../../../scripts/scenarios.tcl

###############################################################################
# Tie Cells
###############################################################################
set_dont_touch [get_lib_cells */TIE*] false
set_lib_cell_purpose -include optimization [get_lib_cells */TIE*]

###############################################################################
# Auto Floorplan
###############################################################################
set_auto_floorplan_constraints -shape R \
                     -orientation N \
                     -side_ratio {1 1 1 1} \
                     -core_offset {3} \
                     -core_utilization 0.55 \
                     -use_site_row

set_block_pin_constraints -self \
                          -pin_spacing_distance 4 \
                          -sides {1 2 3 4} \
                          -allowed_layers {M4 M5 M6 M7} \
                          -hard_constraints {location spacing layer}

###############################################################################
# CTS Setup
###############################################################################

set CLOCK_BUFFERS           "NBUFFX32_LVT NBUFFX16_LVT NBUFFX8_LVT NBUFFX4_LVT NBUFFX2_LVT \
							IBUFFX32_LVT IBUFFX16_LVT IBUFFX8_LVT IBUFFX4_LVT IBUFFX2_LVT"

set CLOCK_BUFFERS_INV       "INVX32_LVT INVX16_LVT INVX8_LVT INVX4_LVT INVX2_LVT INVX1_LVT INVX0_LVT"

set_lib_cell_purpose -exclude cts [get_lib_cells]
set_dont_touch ${CLOCK_BUFFERS} false
set_dont_touch ${CLOCK_BUFFERS_INV} false

set_lib_cell_purpose -include cts  "${CLOCK_BUFFERS} ${CLOCK_BUFFERS_INV}"
set_lib_cell_purpose -include optimization "${CLOCK_BUFFERS} ${CLOCK_BUFFERS_INV}"
set_lib_cell_purpose -include hold "${CLOCK_BUFFERS} ${CLOCK_BUFFERS_INV}"

# Enable auto-skew target adjustment for local skew tuning
set_app_options -name cts.common.enable_auto_skew_target_for_local_skew -value true

# Clock Tree Targets
set CLK1_ROOT           i_clk
set CTS_MAX_FANOUT      20
set CLK1_BUFF_MAX_TRANS [expr $MAIN_CLK * 0.02]   ;# ~66.7 ps
set CLK1_SINK_MAX_TRANS [expr $MAIN_CLK * 0.02]   ;# ~66.7 ps
set CLK1_TARGET_SKEW    [expr $MAIN_CLK * 0.02]   ;# ~66.7 ps

# Apply Target Skew
set_clock_tree_options -clocks $CLK1_ROOT -target_skew $CLK1_TARGET_SKEW

# Apply Slew / Transition limits on clock path and flip-flop CP sinks
set_max_transition $CLK1_BUFF_MAX_TRANS [get_clocks ${CLK1_ROOT}] -clock_path
set_max_transition $CLK1_SINK_MAX_TRANS [get_pins -hierarchical -filter "is_clock_pin == true"]


###############################################################################
# End off init_design
###############################################################################
save_lib
save_block -compress -as ${DLIB_FUSION}/${DESIGN_STAGE}

unsuppress_message ATTR-12