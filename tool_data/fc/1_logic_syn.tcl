########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: 1_design_syn.tcl
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
set LAST_STAGE "init_design"
open_block ${DLIB_FUSION}/${LAST_STAGE}

# Setup the fusion compiler specific settings
source ../setup/setup_fc.tcl

# Setup SVF for Formality equivalence checking
set_svf -append ${OUT_DIR}/${DESIGN}.svf

###############################################################################
# 1° stage = initial_map
###############################################################################
set DESIGN_STAGE "initial_map"

# OBS: como esse stage é o primeiro, ainda não definimos o last stage
compile_fusion -to $DESIGN_STAGE
save_block -compress -as ${DLIB_FUSION}/${DESIGN_STAGE}

file mkdir ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}
report_timing                       > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_timing.rpt
report_qor                          > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_qor.rpt
report_area -designware             > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_area_dw.rpt
report_area -hierarchy -nosplit     > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_area_hierarchy.rpt
report_power -verbose               > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_power.rpt
report_clock_gating                 > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_clock_gating.rpt

###############################################################################
# 2° stage = logic_opto
###############################################################################
set LAST_STAGE $DESIGN_STAGE
set DESIGN_STAGE "logic_opto"

compile_fusion -from $LAST_STAGE -to $DESIGN_STAGE
save_block -compress -as ${DLIB_FUSION}/${DESIGN_STAGE}


file mkdir ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}
report_timing                       > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_timing.rpt
report_qor                          > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_qor.rpt
report_area -designware             > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_area_dw.rpt
report_area -hierarchy -nosplit     > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_area_hierarchy.rpt
report_power -verbose               > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_power.rpt
report_clock_gating                 > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_clock_gating.rpt

###############################################################################
# 3° stage = initial_place
###############################################################################
set LAST_STAGE $DESIGN_STAGE
set DESIGN_STAGE "initial_place"

compile_fusion -from $LAST_STAGE -to $DESIGN_STAGE
save_block -compress -as ${DLIB_FUSION}/${DESIGN_STAGE}

all_high_transitive_fanout -nets -threshold 100
report_design

file mkdir ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}
report_timing                       > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_timing.rpt
report_qor                          > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_qor.rpt
report_area -designware             > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_area_dw.rpt
report_area -hierarchy -nosplit     > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_area_hierarchy.rpt
report_power -verbose               > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_power.rpt
report_clock_gating                 > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_clock_gating.rpt

###############################################################################
# 4° stage = initial_drc
###############################################################################
set LAST_STAGE $DESIGN_STAGE
set DESIGN_STAGE "initial_drc"

compile_fusion -from $LAST_STAGE -to $DESIGN_STAGE
save_block -compress -as ${DLIB_FUSION}/${DESIGN_STAGE}


file mkdir ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}
report_timing                       > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_timing.rpt
report_qor                          > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_qor.rpt
report_area -designware             > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_area_dw.rpt
report_area -hierarchy -nosplit     > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_area_hierarchy.rpt
report_power -verbose               > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_power.rpt
report_clock_gating                 > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_clock_gating.rpt

report_design
report_congestion -rerun_global_router

###############################################################################
# 5° stage = initial_opto
###############################################################################
set LAST_STAGE $DESIGN_STAGE
set DESIGN_STAGE "initial_opto"

compile_fusion -from $LAST_STAGE -to $DESIGN_STAGE
save_block -compress -as ${DLIB_FUSION}/${DESIGN_STAGE}


file mkdir ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}
report_timing                       > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_timing.rpt
report_qor                          > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_qor.rpt
report_area -designware             > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_area_dw.rpt
report_area -hierarchy -nosplit     > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_area_hierarchy.rpt
report_power -verbose               > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_power.rpt
report_clock_gating                 > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_clock_gating.rpt

###############################################################################
# 6° stage = final_place
###############################################################################
set LAST_STAGE $DESIGN_STAGE
set DESIGN_STAGE "final_place"

compile_fusion -from $LAST_STAGE -to $DESIGN_STAGE
save_block -compress -as ${DLIB_FUSION}/${DESIGN_STAGE}


file mkdir ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}
report_timing                       > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_timing.rpt
report_qor                          > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_qor.rpt
report_area -designware             > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_area_dw.rpt
report_area -hierarchy -nosplit     > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_area_hierarchy.rpt
report_power -verbose               > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_power.rpt
report_clock_gating                 > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_clock_gating.rpt

###############################################################################
# 7° stage = final_opto
###############################################################################
set LAST_STAGE $DESIGN_STAGE
set DESIGN_STAGE "final_opto"

compile_fusion -from $LAST_STAGE -to $DESIGN_STAGE
save_block -compress -as ${DLIB_FUSION}/${DESIGN_STAGE}

file mkdir ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}
report_timing                       > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_timing.rpt
report_qor                          > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_qor.rpt
report_area -designware             > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_area_dw.rpt
report_area -hierarchy -nosplit     > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_area_hierarchy.rpt
report_power -verbose               > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_power.rpt
report_clock_gating                 > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN_STAGE}/${DESIGN}_report_clock_gating.rpt


###############################################################################
# Final report of logic sythesis
###############################################################################
report_constraint -all_violators -significant_digits 4 \
                                    > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN}_constraints_violators.rpt

report_timing -significant_digits 4 \
                                    > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN}_report_timing_setup.rpt

report_timing -delay_type min -significant_digits 4 \
                                    > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN}_report_timing_hold.rpt

# QoR reports
report_qor -significant_digits 4    > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN}_report_qor.rpt
report_clock_gating                 > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN}_report_clock_gating.rpt
report_disable_timing               > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN}_report_disable_timing.rpt

# Area and power
report_area -designware             > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN}_report_area_dw.rpt
report_area -hierarchy -nosplit     > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN}_report_area_hierarchy.rpt
report_power -hierarchy -verbose    > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN}_report_power.rpt

# Cells
report_cell                         > ${RPT_DIR}/FUSION/LogicSynthesis/${DESIGN}_report_cell.rpt

###############################################################################
# End of logic sythesis
###############################################################################
save_lib