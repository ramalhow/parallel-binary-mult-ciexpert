########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: load_design.tcl
# Description: todo
# Version: 2026-07-02
# Author: Arthur Ramalho
#########################################################################

###############################################################################
# Project Setup
###############################################################################

# Project definitions and variables
source ../../../scripts/setup_vars.tcl 
set_app_var search_path ". ${DB_DIR} ${DLIB_DIR} ${NDM_DIR} ${RTL_DIR} ${TECH_DIR}"

# Current Stage
set DESIGN_STAGE "load_design"

open_lib ${DLIB_DIR}/${DLIB_FUSION}.dlib
open_block ${DLIB_FUSION}/final_opto

file mkdir ${RPT_DIR}/FUSION/${DESIGN_STAGE}

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
        [current_lib] > ${RPT_DIR}/FUSION/${DESIGN_STAGE}/report_reference.rpt
