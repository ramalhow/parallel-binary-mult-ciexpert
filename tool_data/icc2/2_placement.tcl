########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: setup_dc.tcl
# Description:  Placement script:
#                 * Places Tap cells
#                 * Places input/output buffers
#                 * Places port protection diodes
#                 * Places Design
#                 * Connects Tie cells
#                 * Places spare cells
# Version: 2026-07-02
# Author: Arthur Ramalho
#########################################################################

###############################################################################
# Tech & ICC2 Setup
###############################################################################
source ../setup/tech_setup.tcl

set DLIB_DIR            "${PRJT_BASE}/dlib"

###############################################################################
# Design Setup
###############################################################################
set PREV_STAGE          "floorplan"
set DESIGN_STAGE        "placement"
file mkdir              ${RPT_DIR}/${DESIGN_STAGE}

###############################################################################
# ICC2 Open created library and block
###############################################################################
# Open created Design Library
open_lib                $DLIB_DIR/${DESIGN}.dlib

# Make a copy of last stage block and rename to the new stage
copy_block             -from ${DESIGN}/${PREV_STAGE} \
                       -to ${DESIGN}/${DESIGN_STAGE}
# Set the copy as the current design to work
current_block          ${DESIGN}/${DESIGN_STAGE}

# load the initial constraints
read_sdc                ${OUT_DIR}/${DESIGN}_initial_constraints.sdc

save_block              -as ${DESIGN}/${DESIGN_STAGE} \
                        -compress   


set_svf -append  ${OUT_DIR}/${DESIGN}.svf


################################################################################
# Pre-Placement Check and Analysis
################################################################################
# Have a look at the EMS messages in the ICC2 GUI (Window -> Message Browser Window.  File -> Open Message Database)
check_design            -checks pre_placement_stage \
                        -ems_database ${DLIB_DIR}/${DESIGN}.dlib/${DESIGN}/design_label.${DESIGN_STAGE}/check_pre_placement.ems

check_design            -checks physical_constraints \
                        -ems_database ${DLIB_DIR}/${DESIGN}.dlib/${DESIGN}/design_label.${DESIGN_STAGE}/check_physical_constraints.ems
report_design           -summary

report_user_units

# IF ...
# Error: Toplevel sanity check has failed. Run check_hier_design -stage pre_placement command for detailed errors. (HOPT-007)
# check_hier_design       -stage pre_placement

get_scenarios
report_scenarios        -nosplit
current_scenario
set_scenario_status     -active true [all_scenarios]
#current_scenario        func_typ

report_ideal_network    -scenarios [all_scenarios]
report_ignored_layers
report_host_options
report_qor              -summary
get_scan_chain_count
check_scan_chain

################################################################################
# Fanout
################################################################################
# Analyze high fanout nets
report_net_fanout -high_fanout
report_net_fanout -threshold 60

# Limit the fanout of each tie cell to avoid congestion issues
set_app_options -name opt.tie_cell.max_fanout -value 5
#add_tie_cells -tie_high_lib_cells [get_lib_cells $TIE_HIGH] -tie_low_lib_cells [get_lib_cells $TIE_LOW]

###############################################################################
# Remove all placement and routing blockages
###############################################################################
remove_placement_blockages   -all -verbose
remove_routing_blockages     -all -verbose



###############################################################################
# CTS Cell Selection
###############################################################################
set CTS_LIB_CELL_PATTERN_LIST "INV* IBUFF* NBUFF*"
set CTS_CELLS [get_lib_cells $CTS_LIB_CELL_PATTERN_LIST]
set_dont_touch $CTS_CELLS false
suppress_message ATTR-12

set_lib_cell_purpose -exclude cts [get_lib_cells]
set_lib_cell_purpose -include cts $CTS_CELLS

unsuppress_message ATTR-12

###############################################################################
# Clock NDRs
###############################################################################
# mark_clock_trees

###############################################################################
# Tap cells placement
###############################################################################
# create_tap_cells        -lib_cell             $TAP_CELL \
#                         -pattern              every_row \
#                         -separator            "_" \
#                         -skip_fixed_cells

####################
legalize_placement
####################

# return
###############################################################################
# Add diode to input ports interfacing analog.
# Example from redbirdio project.
###############################################################################
#add_port_protection_diodes -diode_lib_cell ${ANTENNA_DIODES} -port [remove_from_collection [all_inputs] [get_ports {i_osc_3megahz i_osc_9megahz i_pmu_DVDD_ok_5v}]]
# add_port_protection_diodes -diode_lib_cell $ANTENNA_DIODES -prefix my_diode -port [all_inputs]
# add_port_protection_diodes -diode_lib_cell ${ANTENNA_DIODES} -port [remove_from_collenction [all_inputs] [get_ports <<nome_da_porta>>]]


###############################################################################
# Enable tie-cells
###############################################################################
suppress_message ATTR-12

set_lib_cell_purpose -include optimization [get_lib_cells $TIE_HIGH]
set_lib_cell_purpose -include optimization [get_lib_cells $TIE_LOW]
set_dont_touch [get_lib_cells $TIE_HIGH] false
set_dont_touch [get_lib_cells $TIE_LOW] false

unsuppress_message ATTR-12

###############################################################################
# General Placement Options
###############################################################################
# Enable leakage, dynamic or total power optimization (default mode is none)
set_app_options  -name  opt.power.mode -value leakage
set_app_options  -name  opt.power.mode -value dynamic
set_app_options  -name  opt.power.mode -value total

# Enable advanced power restructuring using:
set_app_options  -name  opt.common.advanced_logic_restructuring_mode -value power

# Set a prefix for new cell names created by place tools.
set_app_options  -name  opt.common.user_instance_name_prefix -value BUF_pOPT_

# For advanced technologies, enable route-driven-extration (RDE)
# to improve pre- vs post-route miscorrelation, and reduce buffers/area.
# If this is enabled, older techniques such as layer binning, are automatically disabled.
# The default setting for this option is "auto", which will enable RDE for technologies < 16nm

# set_app_options  -name  opt.common.enable_rde -value true


# Increase Placement/Timing Effort at the cost of runtime, area an possibly power
# set_app_options -list {
#     place_opt.initial_place.effort  high
#     place_opt.final_place.effort    high
#     opt.timing.effort               high
# }

# Synopsys physical guidance support. If the netlist was synthesized using Design Compiler SPG
set_app_options  -name  place_opt.flow.do_spg -value true

# Effort level for congestion-driven restructuring DEFAULT on E medium
set_app_options  -name  place.coarse.cong_restruct                 -value on
set_app_options  -name  place.coarse.cong_restruct_effort          -value ultra
set_app_options  -name  place.coarse.cong_restruct_strategy        -value original
set_app_options  -name  place.coarse.cong_restruct_iterations      -value 5


# For designs with congestion mainly in the horizontal routing layers, set the place.coarse.congestion_expansion_direction to both
set_app_options  -name  place.coarse.congestion_expansion_direction -value both
# When true the congestion driven placement will reduce densities in congested areas more aggressively.
set_app_options  -name  place.coarse.increased_cell_expansion      -value true
# Consider the congestion of each layer separately and improve the accuracy of congestion reduction in coarse placement 
set_app_options  -name  place.coarse.congestion_layer_aware        -value true
# (default false) When true the placer will consider the legalization requirements of cells in the design.
set_app_options  -name  place.coarse.legalizer_driven_placement    -value true

# (default false) When this value is set to true, the placer tries to control the maximum local pin density.
set_app_options  -name  place.coarse.pin_density_aware             -value true

# Defining maximum density treshold
# auto-density control is true by default (place.coarse.auto_density_control)
report_app_options      place.coarse.auto_density_control
set_app_options  -name  place.coarse.auto_density_control          -value enhanced
set_app_options  -name  place.coarse.enhanced_auto_density_control -value true

# The following two App options will be set automatically:
set_app_options  -name  place.coarse.congestion_driven_max_util    -value 0.6
set_app_options  -name  place.coarse.max_density                   -value 0.6

report_app_options place.coarse.*

# If set to true, command will continue even if top level design checks fail.
#set_app_options  -name  top_level.continue_flow_on_check_hier_design_errors -value true

# Enabling Global Route Based High-Fanout Synthesis
set_app_options  -name  place_opt.initial_drc.global_route_based   -value 1
set_app_options  -name  place_opt.initial_place.two_pass           -value true
set_app_options  -name  place_opt.place.congestion_effort          -value high

# Enables early clock tree synthesis
# set_app_options  -name  place_opt.flow.trial_clock_tree            -value true
report_app_options place_opt.*

report_app_options top_level.*

###############################################################################
# Route Options (trying global routing to follow same options as route step to avoid AP layer usage)
###############################################################################
# Layer Options
set BOTTOM_ROUTING_LAYER        M1
set TOP_ROUTING_LAYER           M9

remove_ignored_layers           -all
set_ignored_layers              -min_routing_layer  $BOTTOM_ROUTING_LAYER \
                                -max_routing_layer  $TOP_ROUTING_LAYER

#set_app_options -name route.common.global_max_layer_mode -value hard
#set_app_options -name route.common.global_min_layer_mode -value allow_pin_connection

set_app_options -name route.common.global_min_layer_mode -value hard
set_app_options -name route.common.global_max_layer_mode -value hard

#set_app_options -name route.common.net_min_layer_mode -value allow_pin_connection
#set_app_options -name route.common.net_max_layer_mode -value hard

set_app_options -name route.common.net_min_layer_mode    -value hard
set_app_options -name route.common.net_max_layer_mode    -value hard

###############################################################################
# Scan Chain
###############################################################################
report_app_options  opt.dft.optimize_scan_chain
reset_app_options   opt.dft.optimize_scan_chain
report_app_options  opt.dft.optimize_scan_chain

# Enable placement without scan def
set_app_options         -name place.coarse.continue_on_missing_scandef -value true

###############################################################################
# Place Design
###############################################################################
# Initial placement
#create_placement -use_seed_locs -incremental -congestion -congestion_effort high -effort high
set_app_options -name place.coarse.cong_restruct -value on
set_app_options -name place.coarse.cong_restruct_original_strategy -value true

##################################################################
create_placement -congestion -congestion_effort high -effort high
##################################################################
#remove_buffer_tree -all -hfs_fanout_threshold 1
set_app_options -name opt.area.effort -value high

#######################################
legalize_placement  -incremental
#######################################

###############################################################################
# Check placement
###############################################################################
# Have a look at the EMS messages in the ICC2 GUI (Window -> Message Browser Window.  File -> Open Message Database)

check_design -checks    block_ready_for_top
check_design -checks    cts_qor 
check_design -checks    design_states 
check_design -checks    dp_floorplan_rules 
check_design -checks    dp_pre_block_shaping 
check_design -checks    dp_pre_budgeting 
check_design -checks    dp_pre_clock_trunk_planning 
check_design -checks    dp_pre_create_placement_abstract 
check_design -checks    dp_pre_create_timing_abstract 
check_design -checks    dp_pre_floorplan 
check_design -checks    dp_pre_macro_placement 
check_design -checks    dp_pre_pin_placement 
check_design -checks    dp_pre_power_insertion 
check_design -checks    dp_pre_push_down 
check_design -checks    dp_pre_timing_estimation 
check_design -checks    hier_pre_compile 
check_design -checks    hier_timing 
check_design -checks    mib_alignment 
check_design -checks    netlist 
check_design -checks    physical_constraints 
check_design -checks    pin_placement 
check_design -checks    clock_trees 
check_design -checks    design_mismatch 
check_design -checks    hier_pre_clock_tree 
check_design -checks    legality 
check_design -checks    mv_design 
check_design -checks    scan_chain 
check_design -checks    timing 
check_design -checks    hier_pre_placement 
check_design -checks    rp_constraints 
check_design -checks    routes 
check_design -checks    safety_status 
check_design -checks    unbound 
check_design -checks    3d_netlist

analyze_design_violations

# Check Legality
check_legality          -verbose        > ${RPT_DIR}/${DESIGN_STAGE}/placement_legality.rpt

# Report placement utilization
report_placement        -verbose high \
                        >   ${RPT_DIR}/${DESIGN_STAGE}/report_placement.rpt
                        
check_pg_drc            >   ${RPT_DIR}/${DESIGN_STAGE}/check_pg_drc.rpt      

check_pg_missing_vias   >   ${RPT_DIR}/${DESIGN_STAGE}/check_pg_missing_vias.rpt 

check_pg_connectivity   >   ${RPT_DIR}/${DESIGN_STAGE}/check_pg_connectivity.rpt

report_utilization      >   ${RPT_DIR}/${DESIGN_STAGE}/report_utilization_postPlacement.rpt

# Reports the congestion statistics
# To be able to see the Channel Congestion right after placement, it is necessary to use -rerun_global_router
report_congestion       -rerun_global_router > ${RPT_DIR}/${DESIGN_STAGE}/report_congestion.rpt

report_power            > ${RPT_DIR}/${DESIGN_STAGE}/report_power.rpt

###############################################################################
# Report timing
###############################################################################
# Report QoR
report_qor              -summary \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_qor_summary.rpt

report_qor              -significant_digits 3 \
                        -scenarios [get_scenarios] \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_qor.rpt

# Report Setup
report_timing           -delay_type        max \
                        -scenarios         [get_scenarios] \
                        -nworst            3 \
                        -max_paths         10 \
                        -slack_lesser_than 0.0 \
                        -significant_digits 4 \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_sta_setup.rpt

# Report Hold
report_timing           -delay_type        min \
                        -scenarios         [get_scenarios] \
                        -report_by         scenario \
                        -nworst            3 \
                        -max_paths         10 \
                        -slack_lesser_than 0.0 \
                        -significant_digits 4 \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_sta_hold.rpt

# Report DRV
report_constraints      -all_violators \
                        -scenarios [get_scenarios] \
                        -significant_digits 4 \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_drv.rpt

###############################################################################
# ICC2 Save Design
###############################################################################
save_block              -as ${DESIGN}/${DESIGN_STAGE} \
                        -compress

###############################################################################
###############################################################################
######################## FINISH PLACEMENT #####################################
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
