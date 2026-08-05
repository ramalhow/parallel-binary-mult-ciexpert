# -------------------------------------------------------------------------------------
# Copyright (c) 2026 VIRTUS CC-UFCG. All rights reserved
# VIRTUS CC-UFCG Confidential Proprietary
#
# Copy, distribuition or use of this code is not allowed without
# VIRTUS CC-UFCG explicit written consent.
# -------------------------------------------------------------------------------------
#
# Id: cts.tcl_2026-06-02_by_LuizHenriqueNascimento
#
# Project: 		CI Expert - UFCG
# Description:  CTS script:
#                 * Defines CTS options
#                 * Runs CTS
#                 * Set propagated clocks
#                 * Reports clock trees
#                 * Reports timing
# -------------------------------------------------------------------------------------


###############################################################################
# ICC2 Setup
###############################################################################
source ../setup/tech_setup.tcl
source ../setup/icc2_setup.tcl

set DLIB_DIR            "${PRJT_BASE}/dlib"
###############################################################################
# Design stage
###############################################################################
set PREV_STAGE          "placement"
set DESIGN_STAGE        "cts"
file mkdir              ${RPT_DIR}/${DESIGN_STAGE}

###############################################################################
# Load Previous Stage Design
###############################################################################
# Open created design library
open_lib                $DLIB_DIR/${DESIGN}.dlib

# Make a copy of last stage block and rename to the new stage
copy_block             -from ${DESIGN}/${PREV_STAGE} \
                       -to ${DESIGN}/${DESIGN_STAGE}

open_block              ${DESIGN}/${DESIGN_STAGE}

# Set the copy as the current design to work
current_block          ${DESIGN}/${DESIGN_STAGE}

save_block              -as ${DESIGN}/${DESIGN_STAGE} \
                        -compress    

# Enable clock reconvergence pessimism removal as_user_default
# Remove the pessimism from the timing calculation caused by charged clock paths
set_app_options -as_user_default -name time.remove_clock_reconvergence_pessimism -value true

# Generate SVF for Formality tool

set_svf -append  ${OUT_DIR}/${DESIGN}.svf

###############################################################################
# Is the Design Ready for CTS?
###############################################################################
# Reports quality-of-results (QoR) information related to clock tree synthesis
# The structure report is a very detailed representation of the clock tree structure.
# The entire fanout is represented with identation and numbering
report_clock_qor -type structure

# Have a look at the EMS messages in the ICC2 GUI (Window -> Message Browser Window.  File -> Open Message Database)
check_design                -checks pre_clock_tree_stage \
                            -ems_database  ${RPT_DIR}/${DESIGN_STAGE}/check_pre_clock_tree_stage.ems


###############################################################################
# CTS Options
###############################################################################
# CTS Analysis scenarios
get_scenarios
report_scenarios -nosplit
current_scenario

set CTS_SCENARIO                tc

# Clock Tree Synthesis Does Not Honor The Specified Target Skew
# Reference1: https://solvnetplus.synopsys.com/s/article/IC-Compiler-II-does-not-follow-the-set-target-skew-during-CTS
# Reference2: https://solvnetplus.synopsys.com/s/article/Seeing-different-clock-latency-than-the-value-set
set_app_options         -name cts.common.enable_auto_skew_target_for_local_skew \
                        -value true

set CTS_MAX_FANOUT              12

# Routing Layers: M2 to M3
set BOTTOM_ROUTING_LAYER        M4
set TOP_ROUTING_LAYER           M6

# Clock 1 ================================================================
set CLK1_ROOT                   i_clk
set CLK1_BUFF_MAX_TRANS         0.25
#set CLK1_SINK_MAX_TRANS         0.15
set CLK1_TARGET_SKEW            0.20

# Clock skew adjustment: Set clock skew value 
# ("set_clock_tree_options -target_skew <skew_value> -target_latency <latency_value>") 
# based on "rpt/cts/clock_tree_qor.rpt" ("Global Skew") info after some CTS iterations 
# to catch the adequate value of clock skew.
set_clock_tree_options  -clocks          $CLK1_ROOT \
                        -target_skew     $CLK1_TARGET_SKEW

set_max_transition      $CLK1_BUFF_MAX_TRANS    [get_clocks ${CLK1_ROOT}] -clock_path

#set_max_transition      $CLK1_SINK_MAX_TRANS [get_pins -hierarchical */CP] 

report_path_groups

###############################################################################
# General CTS Options
###############################################################################
# Id: D.001

# Set clock tree cells to be used
#set_lib_cell_purpose            -include cts ${CLOCK_BUFFERS}
#set_lib_cell_purpose            -include optimization ${CLOCK_BUFFERS}
#set_lib_cell_purpose            -include hold ${CLOCK_BUFFERS}

#report_lib_cells -objects [get_lib_cells] -columns {name:20 valid_purposes dont_touch}

# Define that the clock tree cells do no drive more than the max_fanout cells number defined. Default is 1000000
#set_app_options -name cts.common.max_fanout -value $CTS_MAX_FANOUT

# Enable congestion aware CTS for design with complex or fragmented floorplans. CTS detours #congested areas by enabling global routing during CTS
#set_app_options -name cts.compile.enable_global_route -value true

# (default medium) Specifies the effort level for the congestion alleviation in clock_opt. Expect a significant increase in runtime for high effort.
#set_app_options -name clock_opt.place.congestion_effort -value high

# Enable Local Skew CTS and CTO (by default using CCD flow I do not need to enable this app option)
#set_app_options -name cts.compile.enable_local_skew -value true
#set_app_options -name cts.optimize.enable_local_skew -value true

# If you find that hold fixing is not sufficient, you can increase the effort to fix Hold violations
# set_app_options -name clock_opt.hold.effort -value high
#set_app_options -name refine_opt.hold.effort -value high

# Set a prefix for new cell names created by clock tree synthesis tools.
#set_app_options -name cts.common.user_instance_name_prefix -value BUF_CTS_
#set_app_options -name opt.common.user_instance_name_prefix -value BUF_cOPT_
#set_app_options -name cts.multisource.subtree_merge_cell_name_prefix -value CTS_MSMC_
#set_app_options -name cts.multisource.subtree_split_cell_name_prefix -value CTS_MSSC_
#set_app_options -name cts.multisource.subtree_split_net_name_prefix -value CTS_MSSN_

# Minimize hold time violations in scan paths
# (this options by default is false in order to reduce runtime)
#set_app_options -name opt.dft.clock_aware_scan_reorder -value true

# Specifies exceptions to apply while balancing clock trees at the specified pins, ports, and clocks.
#set_app_options -name cts.balance_groups.honor_source_latency -value true

#report_clock_balance_points

# Removes user-specified constraints set with the set_clock_balance_points command. By default, the command removes the constraints from all clocks of the current mode.
# remove_clock_balance_points

# touch_network on clocks, pins, or ports in the current design to prevent cells and nets in the transitive fanout of the set_dont_touch_network objects from being modified or replaced during optimization.
set_ignored_layers              -min_routing_layer  ${BOTTOM_ROUTING_LAYER} \
                                -max_routing_layer  ${TOP_ROUTING_LAYER}

set_routing_rule                -min_routing_layer ${BOTTOM_ROUTING_LAYER} \
                                -max_routing_layer ${TOP_ROUTING_LAYER} \
                                -min_layer_mode allow_pin_connection \
                                -max_layer_mode hard \
                                [get_nets -of_objects $CLK1_ROOT]

# Disable concurrent clock and data (CCD) optimization during the clock_opt command. Default is true.
#set_app_options -name clock_opt.flow.enable_ccd -value true

#set_app_options -name clock_opt.flow.optimize_ndr -value true
# Specifies the mechanism for using global router aware buffering in the initial stage of the
# synthesize_clock_trees command.
#set_app_options -name  cts.compile.global_route_aware_buffering -value true
# Controls whether to enable levelized buffering during clock tree synthesis.
#set_app_options -name cts.multisource.enable_levelized_buffering -value true

#set_app_options -name clock_opt.flow.enable_clock_power_recovery -value true

# Snps training ICC2-BLI recommends to run check_clock_trees before CTS. Checks for, and suggests solutions
check_clock_trees

###############################################################################
# Run CTS
###############################################################################
set_host_options -max_cores 60
clock_opt 
# Construção da árvore de clock
# clock_opt -from build_clock -to build_clock

# Otimização após a construção
# clock_opt -from route_clock -to route_clock

# Otimização final
# clock_opt -from final_opto -to final_opto

# If there are any small clock transition violations after 'clock_opt' run the
# synthesize_clock_trees  -postroute

check_clock_trees
###############################################################################
# Cell count to spare cell insertion
###############################################################################
source /path/to/spare_cells.tcl
get_ref_cells_count_by_location -region [get_attribute [get_core_area] bbox] > ${RPT_DIR}/${DESIGN_STAGE}/report_cell_count.rpt

calculateSpareCellPercentage ${RPT_DIR}/${DESIGN_STAGE}/report_cell_count.rpt 5

###############################################################################
# Update uncertainty AND Set propagated clock:  all clocks AND all scenarios
###############################################################################
set_scenario_status -active true [all_scenarios]

# Specifies that delays be propagated through the clock network to determine latency at register clock pins. If not specified, ideal clocking is assumed.
foreach_in_collection scen [all_scenarios] {
    current_scenario $scen
    set_propagated_clock             [all_clocks]
}
current_scenario ${CTS_SCENARIO}

###############################################################################
# Mark Clock Trees
###############################################################################
mark_clock_trees

########################################
# High-fanout net tree
########################################
# Report High Fanout nets
source ${PRJT_BASE}/tools/icc2/CNN/utils/rpt_high_fanout.tcl > ${RPT_DIR}/${DESIGN_STAGE}/report_high_fanout_before_fix.rpt
# Shows only nets with fanout greater than 20 fanout.
report_net_fanout   -threshold 20  [get_flat_nets -filter "net_type==signal"]

###############################################################################
# Reports
###############################################################################
# Have a look at the EMS messages in the ICC2 GUI (Window -> Message Browser Window.  File -> Open Message Database)
check_design            -checks clock_trees \
                        -ems_database  ${RPT_DIR}/${DESIGN_STAGE}/check_clock_trees.ems

report_clock_qor        -all \
                        -show_paths \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_clock_qor.rpt

report_clocks           -modes [get_modes] \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_clocks.rpt

report_clock_settings
report_clock_tree_options
report_clock_routing_rules

report_clock_balance_points
report_clock_timing     -type summary > ${RPT_DIR}/${DESIGN_STAGE}/report_clock_timing.rpt
report_clock_power      -type per_subtree
#report_clock_power      -type per_segment
report_power            > ${RPT_DIR}/${DESIGN_STAGE}/report_power.rpt

check_pg_connectivity   >  ${RPT_DIR}/${DESIGN_STAGE}/check_pg_connectivity.rpt

report_utilization      > ${RPT_DIR}/${DESIGN_STAGE}/report_utilization_postCTS.rpt

# Reports the congestion statistics
report_congestion -rerun_global_router      > ${RPT_DIR}/${DESIGN_STAGE}/report_congestion.rpt

###############################################################################
# Report_timing
###############################################################################
# Report QoR
report_qor              -significant_digits 3 \
                        -scenarios [get_scenarios] \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_qor.rpt

report_qor              -summary \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_qor_summary.rpt

# Report Setup
report_timing           -delay_type        max \
                        -scenarios         [get_scenarios] \
                        -report_by         scenario \
                        -nworst            3 \
                        -max_paths         10 \
                        -slack_lesser_than 0.0 \
                        -nosplit \
                        -transition_time \
                        -capacitance \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_sta_setup.rpt

# Report Hold
report_timing           -delay_type        min \
                        -scenarios         [get_scenarios] \
                        -report_by         scenario \
                        -nworst            3 \
                        -max_paths         10 \
                        -slack_lesser_than 0.0 \
                        -nosplit \
                        -transition_time \
                        -capacitance \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_sta_hold.rpt

# Report DRV
report_constraints      -all_violators \
                        -scenarios [get_scenarios] \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_drv.rpt

###############################################################################
# ICC2 Save Design
###############################################################################
save_block              -as ${DESIGN}/${DESIGN_STAGE} \
                        -compress

###############################################################################
###############################################################################
##################  FINISH CLOCK TREE SYNTHESIS ###############################
###############################################################################
###############################################################################

echo "*****************************************************************************************"
echo "*****************************************************************************************"
puts "\[VIRTUS-CC\] INFO: The ${DESIGN_STAGE} for the ${DESIGN} has been completed."
puts "\[VIRTUS-CC\] INFO: Calling GUI ..."
echo "*****************************************************************************************"
echo "*****************************************************************************************"
date
after 5000
start_gui 
return