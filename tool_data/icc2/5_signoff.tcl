# -------------------------------------------------------------------------------------
# Project: 	   CI Expert/UFCG - Physical Design Track
# Description: Signoff script:
#                 * Add filler cells
#                 * Report timing
#                 * Verify design integrity:
#                      - Route
#                      - DRC
#                      - LVS
#                 * Generate deliverables:
#                      - Verilog netlists
#                      - SDC
#                      - LEF
#                      - DEF
#                      - SDF
#                      - SPEF
# -------------------------------------------------------------------------------------
###############################################################################
# Tech Setup
###############################################################################
source ../../../scripts/setup_vars.tcl
source ../../../scripts/tech_setup.tcl


###############################################################################
# Design stage
###############################################################################
set PREV_STAGE              "route"
set DESIGN_STAGE            "signoff"
file mkdir                  ${RPT_DIR}/${DESIGN_STAGE}

###############################################################################
# Load Previous Stage Design
###############################################################################
# Open created Design Library
open_lib ${DLIB_DIR}/${DESIGN}.dlib

# Make a copy of last stage block and rename to the new stage
copy_block -from ${DESIGN}/${PREV_STAGE} -to ${DESIGN}/${DESIGN_STAGE}

# Set the copy as the current design to work
current_block ${DESIGN}/${DESIGN_STAGE}

open_block ${DESIGN}/${PREV_STAGE}

#########################################################

# Analysis scenarios
get_scenarios
report_scenarios -nosplit
current_scenario {tc}

# Enable clock reconvergence pessimism removal as_user_default
# Remove the pessimism from the timing calculation caused by charged clock paths
set_app_options -as_user_default -name time.remove_clock_reconvergence_pessimism -value true

# Generate SVF for Formality tool
set_svf -append  ${OUT_DIR}/${DESIGN}.svf

###############################################################################
# Insert DECAP and FILLER cells
###############################################################################
# Remove all placement blockages
report_utilization           > ${RPT_DIR}/${DESIGN_STAGE}/report_utilization_beforeRemoveBlockages.rpt
remove_placement_blockage -all -verbose

# Ensure that the block is legalized before inserting filler cells
check_legality

# Insert and connect to PG net metal filler cells (DECAP Cells) This command by default
# fills all empty space. To leave some empty space use the -utilization option
create_stdcell_fillers      -lib_cells          ${DECAP_CELLS}   -continue_on_error

#connect_pg_net              -automatic   -verbose

# Remove metal filler cells with DRC violations before insert nonmental filler cells
remove_stdcell_fillers_with_violation

# Insert and connect to PG net nonmetal filler cells (FILLER CELLS)
create_stdcell_fillers      -lib_cells          ${FILLER_CELLS}

connect_pg_net              -net            VDD        [get_pins -physical_context {*/VDD}]
connect_pg_net              -net            VSS        [get_pins -physical_context {*/VSS}]

# --- Connect supply to cells (io_cells DVDD, DVSS, AVDD, AVSS)
connect_pg_net              -net            VDD        [get_pins -physical_context */VDD]
connect_pg_net              -net            VSS        [get_pins -physical_context */VSS]

# Check Legality
check_legality              > ${RPT_DIR}/${DESIGN_STAGE}/placement_legality.rpt

###############################################################################
# Report_power
###############################################################################
report_power -scenario [get_scenarios] -significant_digits 3    > ${RPT_DIR}/${DESIGN_STAGE}/report_power_allScenarios.rpt


###############################################################################
# Report timing
###############################################################################
# Report QoR
report_qor              -significant_digits 3 \
                        -scenarios [get_scenarios] \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_qor.rpt

report_qor              -summary \
                        -significant_digits 3 \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_qor_summary.rpt

# Report Setup  DEFAULT path_type full
report_timing           -delay_type        max \
                        -scenarios         [get_scenarios] \
                        -nworst            3 \
                        -max_paths         10 \
                        -slack_lesser_than 0.0 \
                        -nosplit \
                        -transition_time \
                        -capacitance \
                        -significant_digits 4 \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_sta_setup.rpt
# Report Setup  full_clock_expanded
report_timing           -delay_type        max \
                        -path_type         full_clock_expanded \
                        -scenarios         [get_scenarios] \
                        -nworst            10 \
                        -max_paths         100 \
                        -slack_lesser_than 0.0 \
                        -nosplit \
                        -transition_time \
                        -capacitance \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_sta_setup_full_clock_expanded.rpt


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
                        -significant_digits 5 \
                        -scenarios [get_scenarios] \
                        > ${RPT_DIR}/${DESIGN_STAGE}/report_drv.rpt

analyze_design_violations -type max_trans -fanout $MAX_FANOUT -output ${RPT_DIR}/${DESIGN_STAGE}/analyze_design_violations
analyze_design_violations -type setup     -fanout $MAX_FANOUT -output ${RPT_DIR}/${DESIGN_STAGE}/analyze_design_violations
analyze_design_violations -type hold      -fanout $MAX_FANOUT -output ${RPT_DIR}/${DESIGN_STAGE}/analyze_design_violations


###############################################################################
# Verify Design
###############################################################################
# Verify Route
check_routes            -report_all_open_nets true \
                        -antenna true \
                        -write_blockage_drcs_to_error_cell_as_ignored false \
                        >  ${RPT_DIR}/${DESIGN_STAGE}/report_route.rpt

check_pg_connectivity   >  ${RPT_DIR}/${DESIGN_STAGE}/check_pg_connectivity.rpt

# Report LVS
check_lvs               -max_error                        200 \
                        -checks                           all \
                        -open_reporting                   detailed \
                        -report_floating_pins             true \
                        -treat_terminal_as_voltage_source true \
                        >  ${RPT_DIR}/${DESIGN_STAGE}/check_lvs.rpt

# Verify if there is LVS errors
# verify_errors ${RPT_DIR}/${DESIGN_STAGE}/check_lvs.rpt

#Check if there are any empty spaces
check_empty_space > ${RPT_DIR}/${DESIGN_STAGE}/check_empty_space.rpt

# Have a look at the EMS messages in the ICC2 GUI (Window -> Message Browser Window.  File -> Open Message Database)
check_design            -checks {netlist legality scan_chain timing analyze_design_violations block_ready_for_top cts_qor design_states dp_floorplan_rules dp_pre_block_shaping dp_pre_budgeting dp_pre_clock_trunk_planning dp_pre_create_placement_abstract dp_pre_create_timing_abstract dp_pre_floorplan dp_pre_macro_placement dp_pre_pin_placement dp_pre_power_insertion dp_pre_push_down dp_pre_timing_estimation feedthroughs finfet_grid hier_pre_compile hier_timing mib_alignment physical_constraints pin_placement pre_clock_tree_stage pre_placement_stage pre_route_stage routes safety_status unbound 3d_netlist} \
                        -ems_database  ${RPT_DIR}/${DESIGN_STAGE}/check_design_FINAL.ems
#                         -open_message_browser

# Reports unbound cell, via, via array, site row, site array, shape, track, layer, pin_guide, pin_blockage, routing_guide, routing_corridor_shape and via_def object types.
report_unbound          -verbose

check_pg_drc            >   ${RPT_DIR}/${DESIGN_STAGE}/check_pg_drc.rpt      

check_pg_missing_vias   >   ${RPT_DIR}/${DESIGN_STAGE}/check_pg_missing_vias.rpt 

check_pg_connectivity   >   ${RPT_DIR}/${DESIGN_STAGE}/check_pg_connectivity.rpt

# Report High Fanout nets
source ../setup/rpt_high_fanout.tcl > ${RPT_DIR}/${DESIGN_STAGE}/report_high_fanout.rpt

# Shows only nets with fanout greater than 50 fanout.
report_net_fanout       -threshold 50

report_utilization      > ${RPT_DIR}/${DESIGN_STAGE}/report_utilization_postSignoff.rpt

# DRC
#set_app_options -name signoff.check_drc.runset -value "/opt/cad/foundries/tsmc/CV013LPBCDPlus_OA/T013CVSP011K3_1.5f1p5m28k_5V_v1_2a_29Mar2019/Calibre/drc/calibre.drc"
set_app_options -name signoff.check_drc.enable_icv_explorer_mode -value true
set_app_options -name signoff.check_drc.max_errors_per_rule -value 200
set_app_options -name signoff.check_drc.run_dir -value ./signoff_drc_run
set_app_options -name signoff.check_drc.ignore_blockages_in_cells -value false
signoff_check_drc  >  ${RPT_DIR}/${DESIGN_STAGE}/report_drc.rpt
signoff_fix_drc

# Report Spare cells (check ${RPT_DIR}/${DESIGN_STAGE}/report_spare_cells.rpt)
source ${PRJT_BASE}/tools/icc2/ADDER/utils/spare_cells.tcl
report_spare_cells $DESIGN $DESIGN_STAGE $RPT_DIR

###############################################################################
# Save design
###############################################################################
save_block              -as ${DESIGN}/${DESIGN_STAGE} \
                        -force\
                        -compress


###############################################################################
# Creates abstract and frame views of the design
###############################################################################
## Set the following application option for creating abstract for intermediate level, when bottom-level is an abstract
set_app_options -name abstract.allow_all_level_abstract -value true

create_abstract -read_only

create_frame


###############################################################################
# Generate Deliverables
###############################################################################
#write_gds -verbose      $env(POS_DIR)/${DESIGN}.gds

# SDF generation (available from ICC2 version S-2021.06-SP5)
#write_sdf               $env(POS_DIR)/${DESIGN}.sdf

#set scenarioNames [list ss1p44v125c ss1p44vn40c ff5p5v125c ff5p5vn40c ss1p7v125c ss1p7vn40c tt5v25c tt3p3v25c]
#foreach scenarioName $scenarioNames {
#    write_sdf           -corner $scenarioName \
#                        -compress gzip \
#                        $env(POS_DIR)/${DESIGN}_$scenarioName.sdf
#}

# Prime time Recommended command (TSMC Application Note)
#write_sdf               -context verilog \
#                        -version 3.0 \
#                        -no_edge \
#                        -include [list SETUPHOLD RECREM] \
#                        -no_internal_pins $env(POS_DIR)/$env(MODULE_NAME).sdf

#   physical_only_cells:      Exclude all DECAP and FILLER cells
#   scalar_wire_declarations: Exclude all wire declarations
#   supply_statements:        removes all supply declarations
#   pg_objects:               removes all analog_pg, pg_netlist and supply_statements
write_verilog           -exclude {physical_only_cells analog_pg pg_netlist pg_objects supply_statements scalar_wire_declarations} \
                        ${OUT_DIR}/${DESIGN}.v

# Specifyng pg_objects is equivalent to specifying: analog_pg, pg_netlist, and sypply_statements 
# -force_reference to force the list to be inserted in the netlist.
write_verilog           -include {all} \
                        ${OUT_DIR}/${DESIGN}_pg_pins.v
#                        -exclude {physical_only_cells supply_statements}
#                        -force_reference { "AM_VDDIO_WIDE" "AM_VSS_WIDE" }

# To write out a flat Verilog netlist
# The change_names command ensures that the bus naming convention adheres to the specified rules and prevents assign statements from appearing in the netlist.
#change_names -hierarchy -rules verilog
# The ungroup -all -flatten -force command forces the flattening of the cells across different hierarchies, regardless of the dont_touch attribute. Note that you can also use the flatten_fp_hierarchy command to flatten the complete hierarchy of the design.
ungroup       -all -flatten -force
ungroup_cells -all -flatten -force
                        
write_verilog           -top_module_first \
                        -include {pg_objects supply_statements diode_cells well_tap_cells} \
                        -force_reference {*DCAP*} \
                        -force_no_reference {*TIE* *FILLTIE* *FILL*} \
                        ${OUT_DIR}/${DESIGN}_pg_pins_flat.v
#                        -include {analog_pg pg_netlist pg_objects user_pg diode_cells flip_chip_driver_cells supply_statements unconnected_ports}
#                        -force_reference "$DECAP_CELLS AM_VDDIO_WIDE AM_VSS_WIDE sc_tielo"

# SDC
write_sdc               -output "${OUT_DIR}/${DESIGN}_pnr.sdc"

# LEF 
write_lef               -slice_polygon \
                        -include cell \
                        ${OUT_DIR}/${DESIGN}.lef
    # -slice_polygon : Slices the polygons into rectangles for output to the LEF file. **
    # -write_additional_viarule: Specifies the option to write simple via_def as VIARULE. **
    # -include cell: use this if you want to include just cell information (no technology info) 
    # -exclude_layers {LD M1_2B M1_4B M2_2B M2_4B OL PC}: use this when you don't want to have a blockage on layers that you block is not using (specify the unused layers)
                                    
# Controls whether the write_def command skips the net connections when outputting the net shape or via to NETS and/or SPECIALNETS section.
# This app option, if set to false, indicates that the write_def command will output the net connections.
set_app_options  -name  file.def.skip_connection_of_incomplete_net  -value  false

# DEF 
write_def               -include_tech_via_definitions \
                        -via_as_fixed \
                        -include_pad_owned_terminals \
                        ${OUT_DIR}/${DESIGN}.def

echo "*****************************************************************************************"
echo "*****************************************************************************************"
puts "INFO: The ${DESIGN_STAGE} for the ${DESIGN} has been completed."
puts "INFO: Calling GUI ..."
echo "*****************************************************************************************"
echo "*****************************************************************************************"
date
after 5000
start_gui 
return
