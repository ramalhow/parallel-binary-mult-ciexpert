########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: init_design.tcl
# Description: Design initialization Script:
#                * Sets Libraries
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

# Garantir que a pasta de relatórios exista
file mkdir ${RPT_DIR}/init_design

###############################################################################
# ICC2 Create or Load Design Library
###############################################################################

if { [file exists $PRJT_BASE/dlib/${DESIGN}.dlib] } {
    puts "\[VIRTUS-CC\] INFO: Existing Dlib found. Loading design and generating reports..."
    
    # Abre a biblioteca existente
    open_lib ${DLIB_DIR}/${DESIGN}.dlib
    
    # Abre o bloco salvo anteriormente na etapa de init_design
    open_block ${DESIGN}/${DESIGN_STAGE}
    
    # Vincula o bloco para garantir as referências
    link_block

} else {
    puts "\[VIRTUS-CC\] INFO: No existing Dlib found. Creating from scratch..."

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
}

sizeof_collection [get_flat_cells]
sizeof_collection [get_cells -filter pad_cell]

# Generate SVF for Formality tool
set_svf    ${OUT_DIR}/$DESIGN.svf

set_app_options -as_user_default -name time.remove_clock_reconvergence_pessimism -value true
# Adding app option to avoid assign in netlist
set_app_options -name opt.port.eliminate_verilog_assign -value true

################################################################################
# Create analysis scenarios
################################################################################
source ../setup/scenarios.tcl
current_scenario tc

# loading constraints
source ../../../scripts/constraints.tcl

get_corners
all_corners

###############################################################################
# ICC2 Save Design Initial Setup
###############################################################################
save_lib
save_block -compress -as ${DESIGN}/${DESIGN_STAGE}

###############################################################################
# ICC2 Reporting (Executa independente se criou ou apenas carregou)
###############################################################################
puts "\[VIRTUS-CC\] INFO: Generating Init Design Reports..."

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
        $REFERENCE_LIBRARY > ${RPT_DIR}/init_design/report_reference.rpt

report_lib -parasitic_tech ${DLIB_DIR}/${DESIGN}.dlib > ${RPT_DIR}/init_design/report_parasitic_tech.rpt
report_parasitic_parameters > ${RPT_DIR}/init_design/report_parasitic_parameters.rpt

# Relatórios-chave exigidos pela documentação "PHYSICAL DESIGN FLOW DOCUMENTATION"
check_design -checks pre_placement_stage > ${RPT_DIR}/init_design/check_design.rpt
report_qor > ${RPT_DIR}/init_design/report_qor.rpt
report_clocks > ${RPT_DIR}/init_design/report_clocks.rpt
report_scenarios > ${RPT_DIR}/init_design/report_scenarios.rpt
report_constraints -all_violators > ${RPT_DIR}/init_design/report_constraints.rpt

echo "*****************************************************************************************"
echo "*****************************************************************************************"
puts "\[VIRTUS-CC\] INFO: The ${DESIGN_STAGE} for the ${DESIGN} has been completed."
puts "\[VIRTUS-CC\] INFO: Calling GUI ..."
echo "*****************************************************************************************"
echo "*****************************************************************************************"