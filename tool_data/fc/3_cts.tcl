########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: 3_cts.tcl
# Description: 
# Version: 2026-07-02
# Author: Arthur Ramalho
#########################################################################

###############################################################################
# Project Setup
###############################################################################
source ../../../scripts/setup_vars.tcl

set_app_var search_path ". ${DB_DIR} ${DLIB_DIR} ${NDM_DIR} ${RTL_DIR} ${TECH_DIR}"

# Tech setup
source ../../../scripts/tech_setup.tcl

# Reading the design data
open_lib ${DLIB_DIR}/${DLIB_FUSION}.dlib
set LAST_STAGE "floorplan"
set DESIGN_STAGE "cts"

copy_block -from ${DLIB_FUSION}/${LAST_STAGE} -to ${DLIB_FUSION}/${DESIGN_STAGE}
current_block ${DLIB_FUSION}/${DESIGN_STAGE}

# Setup the fusion compiler specific settings
source ../setup/setup_fc.tcl

# Outputs 
derive_clock_cell_references -output ${RPT_DIR}/FUSION/${DESIGN_STAGE}/cts_leq_set.tcl

###############################################################################
# CTS Setup
###############################################################################
set CTS_SCENARIO    tc
current_scenario    ${CTS_SCENARIO}

# Clock Tree Targets
set CLK_ROOT            i_clk
set CLK_FREQ	        3.3333
set CTS_MAX_FANOUT      20

set CLK_BUFF_MAX_TRANS  [expr $CLK_FREQ * 0.02]   ;# ~66.7 ps
set CLK_SINK_MAX_TRANS  [expr $CLK_FREQ * 0.02]   ;# ~66.7 ps
set CLK_TARGET_SKEW     [expr $CLK_FREQ * 0.02]   ;# ~66.7 ps
set CLOCK_SKEW_SETUP    [expr $CLK_FREQ * 0.02]
set CLOCK_SKEW_HOLD     [expr $CLK_FREQ * 0.02]
set CLOCK_SRC_LATENCY_MAX   [expr $CLK_FREQ * 0.015]
set CLOCK_LATENCY_MAX       [expr $CLK_FREQ * 0.015]
set CLOCK_CAP_MAX           [expr $CLK_FREQ * 0.05]

# Settings
set_app_options -name cts.common.enable_auto_skew_target_for_local_skew -value true
set_app_options -name time.remove_clock_reconvergence_pessimism -value true
set_app_options -name cts.compile.enable_local_skew -value true
set_app_options -name cts.optimize.enable_local_skew -value true
set_app_options -name clock_opt.flow.enable_ccd -value true
set_app_options -name cts.common.max_fanout -value $CTS_MAX_FANOUT

# Apply Target Skew
set_clock_tree_options -clocks $CLK_ROOT -target_skew $CLK_TARGET_SKEW

# Apply Slew / Transition limits on clock path and flip-flop CP sinks
set_max_transition $CLK_BUFF_MAX_TRANS -clock_path $CLK_ROOT
set_max_transition $CLK_SINK_MAX_TRANS [get_pins -hierarchical -filter "is_clock_pin == true"]

#
set_clock_uncertainty -setup $CLOCK_SKEW_SETUP \
    -corners [all_corners] \
    [get_clocks]

set_clock_uncertainty -hold  $CLOCK_SKEW_HOLD  \
    -corners [all_corners] \
    [get_clocks]

#
set_clock_latency -max $CLOCK_LATENCY_MAX \
    -corners [all_corners] \
    [get_clocks]

set_max_capacitance -clock_path $CLOCK_CAP_MAX \
    -corners [all_corners] \
    [get_clocks]

# Defining the routing rules
set_clock_routing_rules -default_rule \
		-min_routing_layer $CTS_MIN_ROUTING_LAYER \
		-max_routing_layer $CTS_MAX_ROUTING_LAYER

# Sanity check
check_clock_trees

# Run CTS

# Step 1: Synthesize clock tree topology (Buffer insertion)
clock_opt -from build_clock -to build_clock

# Step 2: Route clock tree nets (Physical wire assignment)
clock_opt -from route_clock -to route_clock

# Step 3: Post-CTS timing and area optimization (Hold/Setup/DRC fixing)
set_app_options -name route.global.timing_driven    -value true
set_app_options -name route.global.crosstalk_driven -value false
set_app_options -name route.track.timing_driven     -value true
set_app_options -name route.track.crosstalk_driven  -value true
set_app_options -name route.detail.timing_driven    -value true
set_app_options -name route.detail.force_max_number_iterations -value false

clock_opt -from final_opto -to final_opto

check_clock_trees

# Check signal nets with high fanout (>20)
report_net_fanout -threshold 20 [get_flat_nets -filter "net_type==signal"]

###############################################################################
# Post-CTS Quality & Design Diagnostics
###############################################################################
file mkdir ${RPT_DIR}/FUSION/${DESIGN_STAGE}

check_design -checks clock_trees \
             -ems_database ${RPT_DIR}/FUSION/${DESIGN_STAGE}/check_clock_trees.ems

report_clock_qor -all -show_paths       > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_clock_qor.rpt
report_clocks -modes [get_modes]        > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_clocks.rpt
report_clock_timing -type summary       > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_clock_timing.rpt
report_power                            > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_power.rpt
check_pg_connectivity                   > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/check_pg_connectivity.rpt
report_utilization                      > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_utilization_postCTS.rpt
report_congestion -rerun_global_router  > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_congestion.rpt

###############################################################################
# Static Timing & Constraint Reports (STA)
###############################################################################
# Overall Quality of Results
report_qor -significant_digits 3 -scenarios [get_scenarios] > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_qor.rpt
report_qor -summary > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_qor_summary.rpt

# Setup Timing Report
report_timing -delay_type max \
              -scenarios [get_scenarios] \
              -report_by scenario \
              -nworst 3 \
              -max_paths 10 \
              -nosplit \
              -transition_time \
              -capacitance \
              > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_sta_setup.rpt

# Hold Timing Report
report_timing -delay_type min \
              -scenarios [get_scenarios] \
              -report_by scenario \
              -nworst 3 \
              -max_paths 10 \
              -nosplit \
              -transition_time \
              -capacitance \
              > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_sta_hold.rpt

# Design Rule Violations (Max Transition, Max Cap, Min Pulse Width)
report_constraints -all_violators \
                   -scenarios [get_scenarios] \
                   > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_drv.rpt

###############################################################################
# Save Block & Finish Session
###############################################################################
save_lib
save_block -as ${DESIGN}/${DESIGN_STAGE} -compress
