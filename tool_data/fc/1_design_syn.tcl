########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: 1_design_syn.tcl
# Description: 
# Version: 2026-07-02
# Author: Arthur Ramalho
#########################################################################

###############################################################################
# 1° stage = initial_map
###############################################################################
set DESIGN_STAGE "initial_map"

# OBS: como esse stage é o primeiro, ainda não definimos o last stage
compile_fusion -to $DESIGN_STAGE
save_block -compress -as ${DESIGN_FUSION}/${DESIGN_STAGE}

report_qor
report_transformed_registers
report_clock_gating

###############################################################################
# 2° stage = logic_opto
###############################################################################
set LAST_STAGE $DESIGN_STAGE
set DESIGN_STAGE "logic_opto"

compile_fusion -from $LAST_STAGE -to $DESIGN_STAGE
save_block -compress -as ${DESIGN_FUSION}/${DESIGN_STAGE}


###############################################################################
# 3° stage = initial_place
###############################################################################
set LAST_STAGE $DESIGN_STAGE
set DESIGN_STAGE "initial_place"

compile_fusion -from $LAST_STAGE -to $DESIGN_STAGE
save_block -compress -as ${DESIGN_FUSION}/${DESIGN_STAGE}

all_high_transitive_fanout -nets -threshold 100
report_design

###############################################################################
# 4° stage = initial_drc
###############################################################################
set LAST_STAGE $DESIGN_STAGE
set DESIGN_STAGE "initial_drc"

compile_fusion -from $LAST_STAGE -to $DESIGN_STAGE
save_block -compress -as ${DESIGN_FUSION}/${DESIGN_STAGE}

report_design
report_congestion -rerun_global_router

###############################################################################
# 5° stage = initial_opto
###############################################################################
set LAST_STAGE $DESIGN_STAGE
set DESIGN_STAGE "initial_opto"

compile_fusion -from $LAST_STAGE -to $DESIGN_STAGE
save_block -compress -as ${DESIGN_FUSION}/${DESIGN_STAGE}

###############################################################################
# 6° stage = final_place
###############################################################################
set LAST_STAGE $DESIGN_STAGE
set DESIGN_STAGE "final_place"

compile_fusion -from $LAST_STAGE -to $DESIGN_STAGE
save_block -compress -as ${DESIGN_FUSION}/${DESIGN_STAGE}

###############################################################################
# 7° stage = final_opto
###############################################################################
set LAST_STAGE $DESIGN_STAGE
set DESIGN_STAGE "final_opto"

compile_fusion -from $LAST_STAGE -to $DESIGN_STAGE
save_block -compress -as ${DESIGN_FUSION}/${DESIGN_STAGE}