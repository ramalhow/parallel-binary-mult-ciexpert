########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: 4_route.tcl
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
set LAST_STAGE "cts"
set DESIGN_STAGE "route"

copy_block -from ${DLIB_FUSION}/${LAST_STAGE} -to ${DLIB_FUSION}/${DESIGN_STAGE}
current_block ${DLIB_FUSION}/${DESIGN_STAGE}

# Setup the fusion compiler specific settings
source ../setup/setup_fc.tcl

# Setup SVF for Formality equivalence checking
set_svf -append ${OUT_DIR}/${DESIGN}.svf

# Sanity Checks
set_app_options -name route.common.verbose_level -value 1
check_design -checks pre_route_stage

###########################################################################
# Route Setup
###########################################################################
current_scenario tc

# loading antenna data
source -echo ${TECH_DIR}/saed32nm_ant_1p9m.tcl

# Set application options for track and detail routing
set_app_options -name route.global.timing_driven_effort_level -value high
set_app_options -name route.track.timing_driven     -value true
set_app_options -name route.track.crosstalk_driven  -value true
set_app_options -name route.detail.timing_driven    -value true
set_app_options -name route.detail.force_max_number_iterations -value false
set_app_options -name time.si_enable_analysis -value true

# Running route_auto phase
route_auto
save_block -as ${DESIGN}/${DESIGN_STAGE}_after_routeAuto -compress

check_routes

# Running route_detail phase
set_app_options -name route.detail.timing_driven -value true
#set_app_options -name route.detail.incremental_detail_route_special_design_rule_fixing_stage -value early_routing
#route_detail -initial_drc_from_input true
route_detail -incremental true

save_block -as ${DESIGN}/${DESIGN_STAGE}_after_routeDetail -compress

# Running route_opt phase 1
set_app_options -name route_opt.flow.enable_ccd -value true
set_app_options -name route_opt.flow.enable_clock_power_recovery -value auto
#set_app_options -name ccd.post_route_buffer_removal -value true

route_opt
save_block -as ${DESIGN}/${DESIGN_STAGE}_after_routeOpt_1 -compress

###############################################################################
# Post-Route Verification & Quality Diagnostics
###############################################################################
file mkdir ${RPT_DIR}/FUSION/${DESIGN_STAGE}

check_routes -report_all_open_nets true \
             -antenna true \
             > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/verify_route.rpt

report_design -routing                  > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_route.rpt

# Congestion Map & Statistics
#route_global -congestion_map_only true
report_congestion -rerun_global_router  > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_congestion.rpt

# Power, Utilization, and PG Connectivity Checks
check_pg_connectivity                   > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/check_pg_connectivity.rpt
report_utilization                      > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_utilization_postRoute.rpt
report_power                            > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_power.rpt

# LVS (Layout Versus Schematic) Verification
check_lvs -max_errors 200 \
          -checks all \
          -open_reporting detailed \
          -report_floating_pins true \
          > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/check_lvs.rpt

###############################################################################
# Static Timing & Constraint Reports (STA)
###############################################################################
# Quality of Results
report_qor -significant_digits 3 -scenarios [get_scenarios] > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_qor.rpt
report_qor -summary > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_qor_summary.rpt
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
              > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_sta_setup.rpt

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
              > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_sta_hold.rpt

# Design Rule Violations (Max Transition, Max Cap, Min Pulse Width)
report_constraints -all_violators \
                   -scenarios [get_scenarios] \
                   -significant_digits 4 \
                   > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_drv.rpt

###############################################################################
# Save Block & Finish Session
###############################################################################
save_lib
save_block -as ${DESIGN}/${DESIGN_STAGE} -compress
