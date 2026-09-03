########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: setup_fc.tcl
# Description: 
# Version: 2026-07-02
# Author: Arthur Ramalho
#########################################################################

###############################################################################
# Fusion Compiler Settings
###############################################################################

###############################################################################
# Auto Floorplan Setup
###############################################################################
set_app_options -name compile.auto_floorplan.initialize -value auto
set_app_options -name compile.auto_floorplan.place_pins -value all

set_app_options -name compile.auto_floorplan.congestion -value true
set_app_options -name compile.auto_floorplan.timing_driven -value true

set_app_options -name compile.auto_floorplan.buffering_aware_timing_driven -value true
set_app_options -name compile.auto_floorplan.small_design_threshold -value 2500
set_app_options -name compile.auto_floorplan.optimize_small_design -value true

# Auto Floorplan Constraints
set_auto_floorplan_constraints -shape R \
                     -orientation N \
                     -side_ratio {1 1 1 1} \
                     -core_offset {10} \
                     -core_utilization 0.55

set_block_pin_constraints -self \
                          -pin_spacing_distance 8 \
                          -sides {1 2 3 4} \
                          -allowed_layers {M3 M4} \
                          -hard_constraints {location spacing layer}

###############################################################################
# Timing Optimization Setup
###############################################################################
set_app_options -name compile.flow.high_effort_timing -value 1
set_qor_strategy -high_effort_timing -stage synthesis

###############################################################################
# CTS Setup
###############################################################################
set CLOCK_BUFFERS           "NBUFFX32_LVT NBUFFX16_LVT NBUFFX8_LVT NBUFFX4_LVT NBUFFX2_LVT \
							IBUFFX32_LVT IBUFFX16_LVT IBUFFX8_LVT IBUFFX4_LVT IBUFFX2_LVT"

set CLOCK_BUFFERS_INV       "INVX32_LVT INVX16_LVT INVX8_LVT INVX4_LVT INVX2_LVT INVX1_LVT INVX0_LVT"

set_lib_cell_purpose -exclude cts          [get_lib_cells */*]
#set_lib_cell_purpose -exclude optimization [get_lib_cells */*]
#set_lib_cell_purpose -exclude hold         [get_lib_cells */*]

set_dont_touch ${CLOCK_BUFFERS} false
set_dont_touch ${CLOCK_BUFFERS_INV} false

set_lib_cell_purpose -include cts  "${CLOCK_BUFFERS} ${CLOCK_BUFFERS_INV}"
set_lib_cell_purpose -include optimization "${CLOCK_BUFFERS} ${CLOCK_BUFFERS_INV}"
set_lib_cell_purpose -include hold "${CLOCK_BUFFERS} ${CLOCK_BUFFERS_INV}"