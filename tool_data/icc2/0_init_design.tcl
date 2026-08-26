########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: init_design.tcl
# Description: Design Initialization Script:
#                * Sets Libraries
#                * Creates design DB
#                * Imports pre-layout netlist to DB
#                * Sets Timing scenarios
# Version: 2026-08-19
# Author: Arthur Ramalho
#########################################################################

###############################################################################
# Tech & ICC2 Setup
###############################################################################
source ../../../scripts/setup_vars.tcl
source ../../../scripts/tech_setup.tcl

set DESIGN_STAGE "init_design"
set search_path "${OUT_DIR}/PRE_LAYOUT $TECH_DIR"

printvar search_path
printvar link_library

# Ensure report output directory exists
file mkdir ${RPT_DIR}/${DESIGN_STAGE}

###############################################################################
# ICC2 Create or Load Design Library
###############################################################################

if { [file exists ${DLIB_DIR}/${DESIGN}.dlib] } {
    puts "\[VIRTUS-CC\] INFO: Existing Dlib found at ${DLIB_DIR}/${DESIGN}.dlib. Loading block..."
    
    open_lib ${DLIB_DIR}/${DESIGN}.dlib
    open_block ${DESIGN}/${DESIGN_STAGE}
    link_block

} else {
    puts "\[VIRTUS-CC\] INFO: No existing Dlib found. Creating database from scratch..."

    create_lib -technology $TECH_FILE -ref_libs $REFERENCE_LIBRARY ${DLIB_DIR}/${DESIGN}.dlib

    # Derive via regions based on technology rules (essential for PG grid in floorplan)
    derive_design_level_via_regions

    save_lib

    ############################################################################
    # ICC2 Import pre-layout netlist
    ############################################################################
    # Locate and read the synthesized Verilog netlist
    if { [file exists ${OUT_DIR}/PRE_LAYOUT/${DESIGN}.v] } {
        read_verilog ${OUT_DIR}/PRE_LAYOUT/${DESIGN}.v -top ${DESIGN}
    } else {
        read_verilog ${DESIGN}.v -top ${DESIGN}
    }

    link_block
    current_block
}

sizeof_collection [get_flat_cells]
sizeof_collection [get_cells -filter pad_cell]

# Generate SVF container for Formality equivalence checking
set_svf ${OUT_DIR}/${DESIGN}.svf

###############################################################################
# Global App Options & CRPR Setup
###############################################################################
set_app_options -as_user_default -name time.remove_clock_reconvergence_pessimism -value true
set_app_options -name opt.port.eliminate_verilog_assign -value true

###############################################################################
# Create & Activate Analysis Scenarios
###############################################################################
set CURRENT_DLIB ${DESIGN}
source ../../../scripts/scenarios.tcl

# Ensure all loaded MMMC scenarios are enabled
set_scenario_status -active true [all_scenarios]
current_scenario tc

# Load SDC timing constraints
read_sdc ${SDC_DIR}/${DESIGN}.sdc

get_corners
all_corners

###############################################################################
# ICC2 Save Initial Design Setup
###############################################################################
save_lib
save_block -compress -as ${DESIGN}/${DESIGN_STAGE}

###############################################################################
# ICC2 Reporting
###############################################################################
puts "INFO: Generating Init Design Reports..."

report_lib \
        -timing_arcs \
        -parasitic_tech \
        -physical \
        -antenna \
        -routability \
        -pattern_must_join_pin \
        -placement_constraints \
        -wire_tracks \
        -wire_track_colors \
        -verbose \
        -include_db_mapping \
        -cell_summary \
        -char_model \
        $REFERENCE_LIBRARY > ${RPT_DIR}/${DESIGN_STAGE}/report_reference.rpt

report_lib -parasitic_tech ${DLIB_DIR}/${DESIGN}.dlib > ${RPT_DIR}/${DESIGN_STAGE}/report_parasitic_tech.rpt
report_parasitic_parameters > ${RPT_DIR}/${DESIGN_STAGE}/report_parasitic_parameters.rpt

# Mandatory quality and integrity reports
check_design -checks pre_placement_stage > ${RPT_DIR}/${DESIGN_STAGE}/check_design.rpt
report_qor > ${RPT_DIR}/${DESIGN_STAGE}/report_qor.rpt
report_clocks > ${RPT_DIR}/${DESIGN_STAGE}/report_clocks.rpt
report_scenarios > ${RPT_DIR}/${DESIGN_STAGE}/report_scenarios.rpt
report_constraints -all_violators > ${RPT_DIR}/${DESIGN_STAGE}/report_constraints.rpt

echo "*****************************************************************************************"
puts "INFO: The ${DESIGN_STAGE} stage for ${DESIGN} has been completed successfully."
echo "*****************************************************************************************"
date
return