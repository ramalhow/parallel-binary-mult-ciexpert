########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: init_design.tcl
# Description: Design initialization Script:
#                * Sets Labraries
#                * Creates design DB
#                * Imports prelayout netlist to DB
#                * Sets Timing scenarios
# Version: 2026-07-02
# Author: Arthur Ramalho
#########################################################################

###############################################################################
# Tech & ICC2 Setup
###############################################################################
source ../setup/tech_setup.tcl

###############################################################################
# Design Setup
###############################################################################
set DESIGN_STAGE        "init_design"

set search_path "${OUT_DIR}/PRE_LAYOUT $TECH_DIR"

printvar search_path
printvar link_library

###############################################################################
# ICC2 Create Design Library
###############################################################################

if { [file exists $PRJT_BASE/dlib/${DESIGN}.dlib] } {
    file delete -force $PRJT_BASE/dlib/${DESIGN}.dlib
}

# create the Dlib 
create_lib -technology $TECH_FILE -ref_libs $REFERENCE_LIBRARY ${DLIB_DIR}/${DESIGN}.dlib

# preciso saber oq é
derive_design_level_via_regions

# save in the folder
save_lib

################################################################################
# ICC2 Import prelayout netlist
################################################################################
read_verilog ${DESIGN}.v -top ${DESIGN}

# Make sure that all cells in the netlist are found in the libs reference
link_block
current_block

sizeof_collection [get_flat_cells]
sizeof_collection [get_cells -filter pad_cell]

###############################################################################
# ICC2 Open created library
###############################################################################

# Open created design library
open_lib             ${DLIB_DIR}/${DESIGN}.dlib

file mkdir ${RPT_DIR}/init_design
report_lib   \
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
        $REFERENCE_LIBRARY > ${RPT_DIR}/init_design/reference_lib_full_report.rpt

# Generate SVF for Formality tool
set_svf    ${OUT_DIR}/$DESIGN.svf

set_app_options -as_user_default -name time.remove_clock_reconvergence_pessimism -value true

# load the initial constraints
read_sdc ${OUT_DIR}/${DESIGN}_initial_constraints.sdc

################################################################################
# Create analysis scenarios
################################################################################
source ../setup/scenarios.tcl

current_scenario tc

report_lib -parasitic_tech ${DLIB_DIR}/${DESIGN}.dlib

report_parasitic_parameters > ${RPT_DIR}/report_parasitic_parameters.rpt

get_corners
all_corners

# Adding app option to avoid assign in netlist
set_app_options -name opt.port.eliminate_verilog_assign -value true

###############################################################################
# ICC2 Save Design
###############################################################################
save_lib
save_block -compress -as ${DESIGN}/${DESIGN_STAGE}
close_lib

###############################################################################
###############################################################################
######################## FINISH INITIAL DESIGN ###############################
###############################################################################
###############################################################################
echo "*****************************************************************************************"
echo "*****************************************************************************************"
puts "\[VIRTUS-CC\] INFO: The ${DESIGN_STAGE} for the ${DESIGN} has been completed."
puts "\[VIRTUS-CC\] INFO: Calling GUI ..."
echo "*****************************************************************************************"
echo "*****************************************************************************************"
