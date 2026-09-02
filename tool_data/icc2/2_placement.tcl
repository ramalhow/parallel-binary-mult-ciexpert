########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: placement.tcl
# Description: Standard Cell Placement Script:
#                * Inserts Tap & Tie cells
#                * Configures layer bounds & cell restrictions
#                * Performs coarse & fine placement
#                * Optimizes placement, timing, power & area
# Version: 2026-08-19
# Author: Arthur Ramalho
#########################################################################

###############################################################################
# Tech & ICC2 Setup
###############################################################################
source ../../../scripts/setup_vars.tcl
source ../../../scripts/tech_setup.tcl

set PREV_STAGE   "floorplan"
set DESIGN_STAGE "placement"

file mkdir ${RPT_DIR}/${DESIGN_STAGE}

###############################################################################
# ICC2 Open Block & Scenario Setup
###############################################################################
open_lib $DLIB_DIR/${DESIGN}.dlib

copy_block -from ${DESIGN}/${PREV_STAGE} -to ${DESIGN}/${DESIGN_STAGE}
current_block ${DESIGN}/${DESIGN_STAGE}

# Activate all MMMC scenarios before applying additional constraints
get_scenarios
set_scenario_status -active true [all_scenarios]
report_scenarios -nosplit

set_svf -append ${OUT_DIR}/${DESIGN}.svf

###############################################################################
# Pre-Placement Checks
###############################################################################
check_design -checks pre_placement_stage \
             -ems_database ${DLIB_DIR}/${DESIGN}.dlib/${DESIGN}/check_pre_placement.ems

check_design -checks physical_constraints

###############################################################################
# Cell Purpose & Restrictions Setup
###############################################################################
# Tie Cell Setup (High/Low)
suppress_message ATTR-12

# Limit the fanout of each tie cell to avoid congestion issues
set_app_options -name opt.tie_cell.max_fanout -value $MAX_FANOUT
set_lib_cell_purpose -include optimization [get_lib_cells "$TIE_HIGH $TIE_LOW"]
set_dont_touch [get_lib_cells "$TIE_HIGH $TIE_LOW"] false

# CTS Cell Setup (Exclude from regular optimization if necessary)
set CTS_LIB_CELL_PATTERN_LIST "INV* IBUFF* NBUFF*"
set CTS_CELLS [get_lib_cells -quiet $CTS_LIB_CELL_PATTERN_LIST]

set_dont_touch $CTS_CELLS false
set_lib_cell_purpose -exclude cts [get_lib_cells]
set_lib_cell_purpose -include cts $CTS_CELLS
unsuppress_message ATTR-12

# ###############################################################################
# # Tap Cells Placement 
# ###############################################################################
# create_tap_cells -lib_cell $TAP_CELL \
#                  -distance $TAP_CELL_DISTANCE \
#                  -pattern every_row \
#                  -separator "_" \
#                  -skip_fixed_cells

###############################################################################
# Placement & Routing Layer Options
###############################################################################
# Define signal routing layer bounds
set BOTTOM_ROUTING_LAYER M2
set TOP_ROUTING_LAYER M9

remove_ignored_layers -all
set_ignored_layers -min_routing_layer $BOTTOM_ROUTING_LAYER \
                   -max_routing_layer $TOP_ROUTING_LAYER

# Enabling Global Route Based High-Fanout Synthesis
set_app_options  -name  place_opt.initial_drc.global_route_based   -value 1
set_app_options  -name  place_opt.initial_place.two_pass           -value true
set_app_options  -name  place_opt.place.congestion_effort          -value high

# Congestion and density control options
set_app_options -name place.coarse.cong_restruct -value on
set_app_options -name place.coarse.cong_restruct_effort -value ultra
set_app_options -name place.coarse.congestion_expansion_direction -value both
set_app_options -name place.coarse.pin_density_aware -value true
set_app_options -name place.coarse.max_density -value 0.60
set_app_options -name place.coarse.auto_density_control -value enhanced

###############################################################################
# Place Design & Optimization
###############################################################################
# Initial placement
create_placement -use_seed_locs -congestion -congestion_effort high -effort high

legalize_placement -incremental

place_opt

###############################################################################
# Tie Cells Insertion
###############################################################################
add_tie_cells -tie_high_lib_cells [get_lib_cells $TIE_HIGH] \
              -tie_low_lib_cells [get_lib_cells $TIE_LOW] 

# Final incremental legalization
legalize_placement -incremental

###############################################################################
# Check Placement & Reports
###############################################################################
check_legality -verbose > ${RPT_DIR}/${DESIGN_STAGE}/placement_legality.rpt
check_design -checks {legality timing}

report_placement -verbose high > ${RPT_DIR}/${DESIGN_STAGE}/report_placement.rpt
report_utilization > ${RPT_DIR}/${DESIGN_STAGE}/report_utilization_postPlacement.rpt
report_congestion -rerun_global_router > ${RPT_DIR}/${DESIGN_STAGE}/report_congestion.rpt

# Timing & Constraint Reports (QoR, Setup, Hold, DRV)
report_qor -significant_digits 3 -scenarios [get_scenarios] > ${RPT_DIR}/${DESIGN_STAGE}/report_qor.rpt

report_timing -delay_type max -scenarios [get_scenarios] -max_paths 10 \
              > ${RPT_DIR}/${DESIGN_STAGE}/report_sta_setup.rpt

report_timing -delay_type min -scenarios [get_scenarios] -max_paths 10 \
              > ${RPT_DIR}/${DESIGN_STAGE}/report_sta_hold.rpt

report_constraints -all_violators -scenarios [get_scenarios] \
                   > ${RPT_DIR}/${DESIGN_STAGE}/report_drv.rpt

###############################################################################
# Save Design Block
###############################################################################
save_lib
save_block -as ${DESIGN}/${DESIGN_STAGE} -compress

echo "*****************************************************************************************"
puts "INFO: The ${DESIGN_STAGE} stage for ${DESIGN} completed successfully."
echo "*****************************************************************************************"
date
return