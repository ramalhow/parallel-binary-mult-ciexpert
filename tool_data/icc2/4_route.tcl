# -------------------------------------------------------------------------------------
# Copyright (c) 2026 VIRTUS CC-UFCG. All rights reserved
# VIRTUS CC-UFCG Confidential Proprietary
#
# Copy, distribuition or use of this code is not allowed without
# VIRTUS CC-UFCG explicit written consent.
# -------------------------------------------------------------------------------------
#
# Id: route.tcl_2026-06-02_by_LuizHenriqueNascimento
#
# Project: 	   CI Expert/UFCG - Physical Design Track
# Description: Route script:
#                 * Sets route options
#                 * Executes routing
#                 * Report timing
# -------------------------------------------------------------------------------------
###############################################################################
# ICC2 Setup
###############################################################################
source ../setup/tech_setup.tcl

###############################################################################
# Design stage
###############################################################################
set PREV_STAGE              "placement"
set DESIGN_STAGE            "route"
file mkdir                  ${RPT_DIR}/${DESIGN_STAGE}

###############################################################################
# Load Previous Stage Design
###############################################################################
# Open created Design Library
open_lib                ${DLIB_DIR}/${DESIGN}.dlib

# Make a copy of last stage block and rename to the new stage
# if { [file exists $DLIB_DIR/$DESIGN.dlib/$DESIGN/design_label.$DESIGN_STAGE] } {
#     file delete -force $DLIB_DIR/$DESIGN.dlib/$DESIGN/design_label.$DESIGN_STAGE
# }

copy_block             -from $DESIGN/$PREV_STAGE \
                      -to $DESIGN/$DESIGN_STAGE

# Set the copy as the current design to work
current_block		$DESIGN/$DESIGN_STAGE

open_block              $DESIGN/$PREV_STAGE

#########################################################

# Analysis scenarios
get_scenarios
report_scenarios -nosplit
current_scenario

# Enable clock reconvergence pessimism removal as_user_default
# Remove the pessimism from the timing calculation caused by charged clock paths
set_app_options -as_user_default -name time.remove_clock_reconvergence_pessimism -value true

# Generate SVF for Formality tool
set_svf -append  ${OUT_DIR}/${DESIGN}.svf

###############################################################################
# Route Options
###############################################################################
# Layer Options
set BOTTOM_ROUTING_LAYER        M3
set TOP_ROUTING_LAYER           M9

remove_ignored_layers           -all
set_ignored_layers              -min_routing_layer  ${BOTTOM_ROUTING_LAYER} \
                                -max_routing_layer  ${TOP_ROUTING_LAYER}

report_qor -summary

set_app_options -name route.common.verbose_level -value 1
check_design -checks pre_route_stage
set_app_options -name route.common.verbose_level -value 0

# Examine the EMS messages using the GUI
# Please ignore the NEX-048 Error


#      Antenna
source -echo ${ANT_DIR}/saed32nm_ant_1p9m.tcl
report_app_options route.detail.*antenna*

## Secondary PG Routing : Not applicable for New GRE flow
## This would have already occurred dring clock_opt -from final_opto
####################################
#      Check the power supplies
report_power_domains

# Have a look at the secondary PG routing for the level shifters:
#change_selection [get_cells -hierarchical -filter is_level_shifter&&full_name=~*RISC*]

## Routing
####################################
route_auto
save_block              -as ${DESIGN}/${DESIGN_STAGE}_after_routeAuto \
                        -compress

# Route optimization
route_opt
save_block              -as ${DESIGN}/${DESIGN_STAGE}_after_routeOpt \
                        -compress

check_routes

# Incremental Routing
route_detail -incremental true
save_block              -as ${DESIGN}/${DESIGN_STAGE}_after_routeDetail \
                        -compress  
# Use this option very carefully; set it to true only if you are absolutely sure that the DRC information in the block are up-to-date
#route_detail -initial_drc_from_input false

# Verify Route results
check_routes

## Post-Route Timing Analysis
####################################
report_qor -summary
#set_app_options -name time.si_enable_analysis -value true
#set_app_options -name time.enable_ccs_rcv_cap -value true
# Will only work with CCS libraries:
#set_app_options -name time.delay_calc_waveform_analysis_mode -value full_design
# set_app_options -name time.awp_compatibility_mode -value false   ;# false by default

report_qor -summary
report_qor -summary -pba_mode path


###############################################################################
# Report Route
###############################################################################
# Verify route
check_routes            -report_all_open_nets true \
                        -antenna true \
                        > ${RPT_DIR}/${DESIGN_STAGE}/verify_route.rpt
                        
report_design           -routing \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_route.rpt

# Creates the congestion map without creating global route segments (glinks)
route_global            -congestion_map_only true

check_pg_connectivity   > ${RPT_DIR}/${DESIGN_STAGE}/check_pg_connectivity.rpt

report_utilization      > ${RPT_DIR}/${DESIGN_STAGE}/report_utilization_postRoute.rpt

# Reports the congestion statistics
report_congestion       -rerun_global_router \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_congestion.rpt

# Report power
report_power            > ${RPT_DIR}/${DESIGN_STAGE}/report_power.rpt

# Report High Fanout nets
#source ${PRJT_BASE}/tools/icc2/ADDER/utils/rpt_high_fanout.tcl > ${RPT_DIR}/${DESIGN_STAGE}/report_high_fanout.rpt
# Shows only nets with fanout greater than 50 fanout.
#report_net_fanout       -threshold 50

# Report LVS
check_lvs               -max_errors 200 \
                        -checks all \
                        -open_reporting detailed \
                        -report_floating_pins true \
                        > ${RPT_DIR}/${DESIGN_STAGE}/check_lvs.rpt

# Verify if there is LVS errors
# verify_errors ${RPT_DIR}/${DESIGN_STAGE}/check_lvs.rpt

###############################################################################
# Report timing
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
                        -significant_digits 4 \
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
                        -significant_digits 4 \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_sta_hold.rpt

# Report DRV
report_constraints      -all_violators \
                        -scenarios [get_scenarios] \
                        -significant_digits 4 \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_drv.rpt

###############################################################################
# Save design
###############################################################################
save_lib
save_block              -as ${DESIGN}/${DESIGN_STAGE} \
                        -compress
                
###############################################################################
###############################################################################
########################## FINISH ROUTE #######################################
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
