########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: route.tcl
# Description: Detailed Routing Script:
#                * Configures routing layer bounds & antenna rules
#                * Performs auto-routing and route optimization
#                * Performs incremental DRV and detail routing
#                * Inserts standard cell fillers & checks LVS
#                * Generates post-route STA, DRV, and quality reports
# Version: 2026-08-19
# Author: Arthur Ramalho
#########################################################################

###############################################################################
# Tech & ICC2 Setup
###############################################################################
source ../../../scripts/setup_vars.tcl
source ../../../scripts/tech_setup.tcl

set PREV_STAGE   "cts"
set DESIGN_STAGE "route"

file mkdir ${RPT_DIR}/${DESIGN_STAGE}

###############################################################################
# Load Previous Stage Design (CTS)
###############################################################################
open_lib $DLIB_DIR/${DESIGN}.dlib

copy_block -from ${DESIGN}/${PREV_STAGE} -to ${DESIGN}/${DESIGN_STAGE}
current_block ${DESIGN}/${DESIGN_STAGE}

# Map VDD and VSS ports physically to avoid unplaced port warnings
set_attribute [get_ports VDD] port_type power
set_attribute [get_ports VSS] port_type ground

# Enable Clock Reconvergence Pessimism Removal (CRPR)
#set_app_options -as_user_default -name time.remove_clock_reconvergence_pessimism -value true

# Setup SVF for Formality equivalence checking
set_svf -append ${OUT_DIR}/${DESIGN}.svf

# Analysis Scenarios Configuration
get_scenarios
report_scenarios -nosplit
current_scenario tc

###############################################################################
# Pre-Route Options & Antenna Rules
###############################################################################
# Set signal routing layer bounds
set BOTTOM_ROUTING_LAYER M3
set TOP_ROUTING_LAYER    M9

remove_ignored_layers -all
set_ignored_layers -min_routing_layer ${BOTTOM_ROUTING_LAYER} \
                   -max_routing_layer ${TOP_ROUTING_LAYER}

# Antenna Rules and Diode Insertion
set_app_options -name route.detail.insert_diodes_during_routing -value true
source -echo ${TECH_DIR}/saed32nm_ant_1p9m.tcl

###############################################################################
# Execute Routing Flow
###############################################################################
# Step 1: Auto Routing (Global & Track assignment)
set_app_options -name route.global.timing_driven -value true
set_app_options -name route.global.timing_driven_effort_level -value high
set_app_options -name route.track.timing_driven -value true

route_auto
save_block -as ${DESIGN}/${DESIGN_STAGE}_after_routeAuto -compress

# Step 2: Route Optimization
set_app_options -name route_opt.flow.enable_ccd -value true
set_app_options -name route_opt.flow.enable_clock_power_recovery -value auto
set_app_options -name route_opt.flow.enable_ccd_clock_drc_fixing -value always_on

route_opt
save_block -as ${DESIGN}/${DESIGN_STAGE}_after_routeOpt -compress

# Step 4: Detail Routing (Final physical layout pass)
set_app_options -name route.detail.timing_driven -value true
set_app_options -name route.detail.incremental_detail_route_special_design_rule_fixing_stage -value early_routing

route_detail -initial_drc_from_input true
route_detail -incremental true

save_block -as ${DESIGN}/${DESIGN_STAGE}_after_routeDetail -compress

###############################################################################
# Filler Cells & PG Re-connection
###############################################################################
create_stdcell_fillers -lib_cells $FILLER_CELLS

connect_pg_net -automatic

###############################################################################
# Post-Route Verification & Quality Diagnostics
###############################################################################
check_routes -report_all_open_nets true \
             -antenna true \
             > ${RPT_DIR}/${DESIGN_STAGE}/verify_route.rpt

report_design -routing > ${RPT_DIR}/${DESIGN_STAGE}/report_route.rpt

# Congestion Map & Statistics
#route_global -congestion_map_only true
report_congestion -rerun_global_router > ${RPT_DIR}/${DESIGN_STAGE}/report_congestion.rpt

# Power, Utilization, and PG Connectivity Checks
check_pg_connectivity > ${RPT_DIR}/${DESIGN_STAGE}/check_pg_connectivity.rpt
report_utilization > ${RPT_DIR}/${DESIGN_STAGE}/report_utilization_postRoute.rpt
report_power > ${RPT_DIR}/${DESIGN_STAGE}/report_power.rpt

# LVS (Layout Versus Schematic) Verification
check_lvs -max_errors 200 \
          -checks all \
          -open_reporting detailed \
          -report_floating_pins true \
          > ${RPT_DIR}/${DESIGN_STAGE}/check_lvs.rpt

###############################################################################
# Static Timing & Constraint Reports (STA)
###############################################################################
# Quality of Results
report_qor -significant_digits 3 -scenarios [get_scenarios] > ${RPT_DIR}/${DESIGN_STAGE}/report_qor.rpt
report_qor -summary > ${RPT_DIR}/${DESIGN_STAGE}/report_qor_summary.rpt
report_qor -summary -pba_mode path

# Setup Timing Report
report_timing -delay_type max \
              -scenarios [get_scenarios] \
              -report_by scenario \
              -nworst 3 \
              -max_paths 10 \
              -slack_lesser_than 0.0 \
              -nosplit \
              -transition_time \
              -capacitance \
              -significant_digits 4 \
              > ${RPT_DIR}/${DESIGN_STAGE}/report_sta_setup.rpt

# Hold Timing Report
report_timing -delay_type min \
              -scenarios [get_scenarios] \
              -report_by scenario \
              -nworst 3 \
              -max_paths 10 \
              -slack_lesser_than 0.0 \
              -nosplit \
              -transition_time \
              -capacitance \
              -significant_digits 4 \
              > ${RPT_DIR}/${DESIGN_STAGE}/report_sta_hold.rpt

# Design Rule Violations (Max Transition, Max Cap, Min Pulse Width)
report_constraints -all_violators \
                   -scenarios [get_scenarios] \
                   -significant_digits 4 \
                   > ${RPT_DIR}/${DESIGN_STAGE}/report_drv.rpt

###############################################################################
# Save Block & Finish Session
###############################################################################
save_lib
save_block -as ${DESIGN}/${DESIGN_STAGE} -compress

echo "*****************************************************************************************"
puts "\[VIRTUS-CC\] INFO: The ${DESIGN_STAGE} stage for ${DESIGN} completed successfully."
echo "*****************************************************************************************"
date
return