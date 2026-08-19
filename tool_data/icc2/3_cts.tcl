########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: cts.tcl
# Description: ICC2 script for Clock Tree Synthesis (CTS) execution,
#              clock propagation, and post-CTS STA/DRV analysis.
# Version: 2026-08-18
# Author: Arthur Ramalho
########################################################################

###############################################################################
# 1. ICC2 & Technology Setup
###############################################################################
source ../setup/tech_setup.tcl
source ../../../scripts/constraints.tcl

set DLIB_DIR        "${PRJT_BASE}/dlib"
set PREV_STAGE      "placement"
set DESIGN_STAGE    "cts"

file mkdir ${RPT_DIR}/${DESIGN_STAGE}

###############################################################################
# 2. Load Previous Stage Design (Placement)
###############################################################################
open_lib    $DLIB_DIR/${DESIGN}.dlib

copy_block  -from ${DESIGN}/${PREV_STAGE} \
            -to ${DESIGN}/${DESIGN_STAGE}

open_block     ${DESIGN}/${DESIGN_STAGE}
current_block  ${DESIGN}/${DESIGN_STAGE}

# Enable Clock Reconvergence Pessimism Removal (CRPR)
# Why: Prevents the tool from being overly pessimistic by removing artificial 
# delay differences in common clock path segments.
set_app_options -as_user_default -name time.remove_clock_reconvergence_pessimism -value true

# Setup SVF for Formality equivalence checking
# Why: Tracks logic transformations (like buffer insertion/downsizing) so the 
# formal verification tool knows the netlist is still functionally equivalent.
set_svf -append ${OUT_DIR}/${DESIGN}.svf

###############################################################################
# 3. Pre-CTS Design Readiness Checks
###############################################################################
# Why: Ensures the database is clean, placement is legal, and there are no 
# high-fanout nets masquerading as clocks before building the physical tree.
report_clock_qor -type structure
check_design -checks pre_clock_tree_stage \
             -ems_database ${RPT_DIR}/${DESIGN_STAGE}/check_pre_clock_tree_stage.ems

###############################################################################
# 4. CTS Targets & Constraint Setup
###############################################################################
set CTS_SCENARIO    tc
current_scenario    ${CTS_SCENARIO}

# Enable auto-skew target adjustment for local skew tuning
# Why: Allows the tool to intentionally skew clocks to fix tricky setup/hold 
# violations (useful clustering/time-borrowing technique).
set_app_options -name cts.common.enable_auto_skew_target_for_local_skew -value true

# Clock Tree Targets
set CLK1_ROOT               i_clk
set CTS_MAX_FANOUT          32
set CLK1_BUFF_MAX_TRANS     [expr $MAIN_CLK * 0.02]   ;# ~66.7 ps
set CLK1_SINK_MAX_TRANS     [expr $MAIN_CLK * 0.02]   ;# ~66.7 ps
set CLK1_TARGET_SKEW        [expr $MAIN_CLK * 0.02]   ;# ~66.7 ps

# Apply Target Skew
set_clock_tree_options -clocks $CLK1_ROOT -target_skew $CLK1_TARGET_SKEW

# Apply Slew / Transition limits on clock path and flip-flop CP sinks
# Why: Crisp clock edges are mandatory to prevent short-circuit power dissipation 
# inside the flops and to minimize jitter/skew degradation.
set_max_transition $CLK1_BUFF_MAX_TRANS [get_clocks ${CLK1_ROOT}] -clock_path

# Why: Using the '-filter' is standard-cell library independent, preventing 
# missed pins if a library uses 'CP' or 'CK' instead of 'CLK'.
set_max_transition $CLK1_SINK_MAX_TRANS [get_pins -hierarchical -filter "is_clock_pin == true"]

###############################################################################
# 5. CTS Tool Options & Routing Rules
###############################################################################
# Restrict allowed clock cells to designated CTS buffers/inverters
# Why: Ensures the tool only uses balanced, symmetrical clock-driving cells, 
# avoiding weak standard logic cells in the clock tree.
set_lib_cell_purpose -include cts ${CLOCK_BUFFERS}

# Placement & Congestion Controls
# Why: High effort and max density limit prevent the tool from grouping too 
# many clock buffers in one spot, which causes M4/M5 routing congestion.
set_app_options -name clock_opt.place.congestion_effort -value high
set_app_options -name place.coarse.max_density -value 0.60
set_app_options -name cts.compile.enable_global_route -value true

# Power & Architecture Optimizations
# Why: Max fanout of 32 balances buffer count (area/power) vs. slew limit.
set_app_options -name cts.common.max_fanout -value $CTS_MAX_FANOUT
# Why: Optimizes buffer sizing specifically to reduce dynamic clock power.
set_app_options -name cts.compile.enable_power -value true
# Why: Concurrent Clock and Data (CCD) trades excess setup slack (+1.7ns) 
# to downsize datapath cells, saving significant area and power.
set_app_options -name clock_opt.flow.enable_ccd -value true

# DRC & Hold corrections
# Why: Fixes early timing and max capacitance dynamically during tree construction,
# leaving a cleaner database for the detailed router.
set_app_options -name clock_opt.flow.enable_hold_correction -value true
set_app_options -name clock_opt.drc.max_capacitance -value true

# --- METAL LAYER RULES ---
# Global Design Routing Limits
# Why: Unblocks M1 and M2 for general signal routing, preventing total overflow.
set_ignored_layers -min_routing_layer M1 -max_routing_layer M9

# Clock Tree Routing Limits
# Why: Forces clock nets to use higher metals (M3-M8) which have lower 
# resistance, resulting in faster propagation and less RC delay variation.
set BOTTOM_ROUTING_LAYER    M3
set TOP_ROUTING_LAYER       M8

set_clock_routing_rules -clocks $CLK1_ROOT \
                        -min_routing_layer $BOTTOM_ROUTING_LAYER \
                        -max_routing_layer $TOP_ROUTING_LAYER

# Pre-CTS clock check sanity
check_clock_trees

###############################################################################
# 6. Execute Clock Tree Synthesis (clock_opt)
###############################################################################
set_host_options -max_cores 8

# Why: Breaking clock_opt into 3 steps allows granular visibility and prevents 
# the tool from masking structural errors under optimization band-aids.
# Step 1: Synthesize clock tree topology (Buffer insertion)
clock_opt -from build_clock -to build_clock

# Step 2: Route clock tree nets (Physical wire assignment)
clock_opt -from route_clock -to route_clock

# Step 3: Post-CTS timing and area optimization (Hold/Setup/DRC fixing)
clock_opt -from final_opto -to final_opto

check_clock_trees

###############################################################################
# 7. Clock Propagation & Post-CTS Uncertainty Update
###############################################################################
set_scenario_status -active true [all_scenarios]

# Post-CTS uncertainty adjustments (Jitter residual: ~1% setup / ~0.6% hold)
set POST_CTS_SETUP_UNCERTAINTY [expr $MAIN_CLK * 0.010]  ;# ~33 ps
set POST_CTS_HOLD_UNCERTAINTY  [expr $MAIN_CLK * 0.006]  ;# ~20 ps

foreach_in_collection scen [all_scenarios] {
    current_scenario $scen
    
    # Why: Replaces estimated/ideal clock delays with the actual RC delays 
    # of the synthesized physical network.
    set_propagated_clock [all_clocks]
    
    # Why: Ideal skew margin is no longer needed since we have real physical 
    # skew. We only leave a small margin for PLL jitter and On-Chip Variation (OCV).
    set_clock_uncertainty -setup $POST_CTS_SETUP_UNCERTAINTY [all_clocks]
    set_clock_uncertainty -hold  $POST_CTS_HOLD_UNCERTAINTY  [all_clocks]
}
current_scenario ${CTS_SCENARIO}

mark_clock_trees

# Check signal nets with high fanout (>20)
report_net_fanout -threshold 20 [get_flat_nets -filter "net_type==signal"]

###############################################################################
# 8. Post-CTS Quality & Design Diagnostics
###############################################################################
# Why: Generates physical, electrical, and topological reports to validate 
# that the clock tree meets the target constraints.
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
# 9. Static Timing & Constraint Reports (STA)
###############################################################################
# Why: Validates that the core logic timing (Setup/Hold/DRC) is still safe 
# after the massive disruption of inserting the clock tree buffers and wires.

# Overall Quality of Results
report_qor -significant_digits 3 -scenarios [get_scenarios] > ${RPT_DIR}/${DESIGN_STAGE}/report_qor.rpt
report_qor -summary > ${RPT_DIR}/${DESIGN_STAGE}/report_qor_summary.rpt

# Setup Timing Report (Late paths across all scenarios)
report_timing -delay_type max \
              -scenarios [get_scenarios] \
              -report_by scenario \
              -nworst 3 \
              -max_paths 10 \
              -nosplit \
              -transition_time \
              -capacitance \
              > ${RPT_DIR}/${DESIGN_STAGE}/report_sta_setup.rpt

# Hold Timing Report (Early paths across all scenarios)
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
# 10. Save Block & Finish Session
###############################################################################
save_block -as ${DESIGN}/${DESIGN_STAGE} -compress
save_lib

echo "*****************************************************************************************"
puts "\[VIRTUS-CC\] INFO: Clock Tree Synthesis stage for ${DESIGN} has finished successfully."
puts "\[VIRTUS-CC\] INFO: Opening ICC2 GUI..."
echo "*****************************************************************************************"
date
return