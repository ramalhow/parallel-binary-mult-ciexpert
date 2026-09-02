########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: cts.tcl
# Description: Clock Tree Synthesis (CTS) Script:
#                * Configures CTS targets and constraints
#                * Builds clock tree topology & routes clock nets
#                * Updates propagated clock and uncertainties
#                * Optimizes post-CTS timing, power, area, and DRVs
# Version: 2026-08-19
# Author: Arthur Ramalho
#########################################################################

###############################################################################
# Tech & ICC2 Setup
###############################################################################
source ../../../scripts/setup_vars.tcl
source ../../../scripts/tech_setup.tcl

set PREV_STAGE   "placement"
set DESIGN_STAGE "cts"

file mkdir ${RPT_DIR}/${DESIGN_STAGE}

###############################################################################
# Load Previous Stage Design (Placement)
###############################################################################
open_lib $DLIB_DIR/${DESIGN}.dlib

copy_block -from ${DESIGN}/${PREV_STAGE} -to ${DESIGN}/${DESIGN_STAGE}
current_block ${DESIGN}/${DESIGN_STAGE}

# Enable Clock Reconvergence Pessimism Removal (CRPR)
set_app_options -as_user_default -name time.remove_clock_reconvergence_pessimism -value true

# Setup SVF for Formality equivalence checking
set_svf -append ${OUT_DIR}/${DESIGN}.svf

###############################################################################
# Pre-CTS Design Readiness Checks
###############################################################################
report_clock_qor -type structure
check_design -checks pre_clock_tree_stage \
             -ems_database ${RPT_DIR}/${DESIGN_STAGE}/check_pre_clock_tree_stage.ems

###############################################################################
# CTS Targets & Constraint Setup
###############################################################################
set CTS_SCENARIO    tc
current_scenario    ${CTS_SCENARIO}

# Enable auto-skew target adjustment for local skew tuning
set_app_options -name cts.common.enable_auto_skew_target_for_local_skew -value true

# Clock Tree Targets
set CLK1_ROOT           i_clk
set CTS_MAX_FANOUT      32
set MAIN_CLK 3.333333
set CLK1_BUFF_MAX_TRANS [expr $MAIN_CLK * 0.02]   ;# ~66.7 ps
set CLK1_SINK_MAX_TRANS [expr $MAIN_CLK * 0.02]   ;# ~66.7 ps
set CLK1_TARGET_SKEW    [expr $MAIN_CLK * 0.02]   ;# ~66.7 ps

# Apply Target Skew
set_clock_tree_options -clocks $CLK1_ROOT -target_skew $CLK1_TARGET_SKEW

# Apply Slew / Transition limits on clock path and flip-flop CP sinks
set_max_transition $CLK1_BUFF_MAX_TRANS [get_clocks ${CLK1_ROOT}] -clock_path
set_max_transition $CLK1_SINK_MAX_TRANS [get_pins -hierarchical -filter "is_clock_pin == true"]

###############################################################################
# CTS Tool Options & Routing Rules
###############################################################################
# Remove qualquer propósito anterior
set_lib_cell_purpose -exclude cts          [get_lib_cells */*]
set_lib_cell_purpose -exclude optimization [get_lib_cells */*]
set_lib_cell_purpose -exclude hold         [get_lib_cells */*]

# Restrict allowed clock cells to designated CTS buffers/inverters
set_lib_cell_purpose -include cts  "${CLOCK_BUFFERS} ${CLOCK_BUFFERS_INV}"
set_lib_cell_purpose -include optimization "${CLOCK_BUFFERS} ${CLOCK_BUFFERS_INV}"
set_lib_cell_purpose -include hold "${CLOCK_BUFFERS} ${CLOCK_BUFFERS_INV}"

# Placement & Congestion Controls
set_app_options -name clock_opt.place.congestion_effort -value high
set_app_options -name place.coarse.max_density -value 0.60
set_app_options -name cts.compile.enable_global_route -value true

# Power & Architecture Optimizations
set_app_options -name cts.common.max_fanout -value $CTS_MAX_FANOUT
set_app_options -name clock_opt.flow.enable_ccd -value true

# Hold Fixing
set_app_options -name refine_opt.hold.effort -value high

# --- METAL LAYER RULES ---
# Global Design Routing Limits
#set_ignored_layers -min_routing_layer M2 -max_routing_layer M9

# Clock Tree Routing Limits
set BOTTOM_ROUTING_LAYER    M4
set TOP_ROUTING_LAYER       M5

set_clock_routing_rules -clocks $CLK1_ROOT \
                        -min_routing_layer $BOTTOM_ROUTING_LAYER \
                        -max_routing_layer $TOP_ROUTING_LAYER \
                        -default_rule

# Pre-CTS clock check sanity
check_clock_trees

###############################################################################
# Execute Clock Tree Synthesis (clock_opt)
###############################################################################
set_host_options -max_cores 8

# Step 1: Synthesize clock tree topology (Buffer insertion)
clock_opt -from build_clock -to build_clock

# Step 2: Route clock tree nets (Physical wire assignment)
clock_opt -from route_clock -to route_clock

# Step 3: Post-CTS timing and area optimization (Hold/Setup/DRC fixing)
clock_opt -from final_opto -to final_opto

check_clock_trees

###############################################################################
# Clock Propagation & Post-CTS Uncertainty Update
###############################################################################
set_scenario_status -active true [all_scenarios]

# Post-CTS uncertainty adjustments (Jitter residual: ~1% setup / ~0.6% hold)
set POST_CTS_SETUP_UNCERTAINTY [expr $MAIN_CLK * 0.010]  ;# ~33 ps
set POST_CTS_HOLD_UNCERTAINTY  [expr $MAIN_CLK * 0.006]  ;# ~20 ps

foreach_in_collection scen [all_scenarios] {
    current_scenario $scen
    
    # Propagate real physical clock delay
    set_propagated_clock [all_clocks]
    
    # Adjust clock uncertainties
    set_clock_uncertainty -setup $POST_CTS_SETUP_UNCERTAINTY [all_clocks]
    set_clock_uncertainty -hold  $POST_CTS_HOLD_UNCERTAINTY  [all_clocks]
}
current_scenario ${CTS_SCENARIO}

mark_clock_trees

# Check signal nets with high fanout (>20)
report_net_fanout -threshold 20 [get_flat_nets -filter "net_type==signal"]

###############################################################################
# Post-CTS Quality & Design Diagnostics
###############################################################################
check_design -checks clock_trees \
             -ems_database ${RPT_DIR}/${DESIGN_STAGE}/check_clock_trees.ems

report_clock_qor -all -show_paths > ${RPT_DIR}/${DESIGN_STAGE}/report_clock_qor.rpt
report_clocks -modes [get_modes] > ${RPT_DIR}/${DESIGN_STAGE}/report_clocks.rpt
report_clock_timing -type summary > ${RPT_DIR}/${DESIGN_STAGE}/report_clock_timing.rpt
report_power > ${RPT_DIR}/${DESIGN_STAGE}/report_power.rpt
check_pg_connectivity > ${RPT_DIR}/${DESIGN_STAGE}/check_pg_connectivity.rpt
report_utilization > ${RPT_DIR}/${DESIGN_STAGE}/report_utilization_postCTS.rpt
report_congestion -rerun_global_router > ${RPT_DIR}/${DESIGN_STAGE}/report_congestion.rpt

###############################################################################
# Static Timing & Constraint Reports (STA)
###############################################################################
# Overall Quality of Results
report_qor -significant_digits 3 -scenarios [get_scenarios] > ${RPT_DIR}/${DESIGN_STAGE}/report_qor.rpt
report_qor -summary > ${RPT_DIR}/${DESIGN_STAGE}/report_qor_summary.rpt

# Setup Timing Report
report_timing -delay_type max \
              -scenarios [get_scenarios] \
              -report_by scenario \
              -nworst 3 \
              -max_paths 10 \
              -nosplit \
              -transition_time \
              -capacitance \
              > ${RPT_DIR}/${DESIGN_STAGE}/report_sta_setup.rpt

# Hold Timing Report
report_timing -delay_type min \
              -scenarios [get_scenarios] \
              -report_by scenario \
              -nworst 3 \
              -max_paths 10 \
              -nosplit \
              -transition_time \
              -capacitance \
              > ${RPT_DIR}/${DESIGN_STAGE}/report_sta_hold.rpt

# Design Rule Violations (Max Transition, Max Cap, Min Pulse Width)
report_constraints -all_violators \
                   -scenarios [get_scenarios] \
                   > ${RPT_DIR}/${DESIGN_STAGE}/report_drv.rpt

###############################################################################
# Save Block & Finish Session
###############################################################################
save_lib
save_block -as ${DESIGN}/${DESIGN_STAGE} -compress

echo "*****************************************************************************************"
puts "INFO: The ${DESIGN_STAGE} stage for ${DESIGN} completed successfully."
echo "*****************************************************************************************"
date
return