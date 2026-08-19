########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Script: placement.tcl (Corrigido)
# Description: Standard Cell Placement & Timing Optimization Stage
########################################################################

###############################################################################
# Tech & ICC2 Setup
###############################################################################
source ../setup/tech_setup.tcl

set DLIB_DIR "${PRJT_BASE}/dlib"
set PREV_STAGE "floorplan"
set DESIGN_STAGE "placement"

file mkdir ${RPT_DIR}/${DESIGN_STAGE}

###############################################################################
# ICC2 Open Block & Scenario Setup
###############################################################################
open_lib $DLIB_DIR/${DESIGN}.dlib

copy_block -from ${DESIGN}/${PREV_STAGE} -to ${DESIGN}/${DESIGN_STAGE}
current_block ${DESIGN}/${DESIGN_STAGE}

# Ativa todos os cenários ANTES de carregar restrições adicionais
get_scenarios
set_scenario_status -active true [all_scenarios]
report_scenarios -nosplit

set_svf -append ${OUT_DIR}/${DESIGN}.svf

###############################################################################
# Pre-Placement Checks
###############################################################################
check_design -checks pre_placement_stage \
             -ems_database ${DLIB_DIR}/${DESIGN}.dlib/${DESIGN}/check_pre_placement.ems

check_design -checks physical_constraints

###############################################################################
# Cell Purpose & Restrictions Setup
###############################################################################
# Configuração de Células Tie (High/Low)
suppress_message ATTR-12

set_lib_cell_purpose -include optimization [get_lib_cells "$TIE_HIGH $TIE_LOW"]
set_dont_touch [get_lib_cells "$TIE_HIGH $TIE_LOW"] false

# Configuração de Células de CTS (Excluídas da otimização regular se necessário)
set CTS_LIB_CELL_PATTERN_LIST "INV* IBUFF* NBUFF*"
set CTS_CELLS [get_lib_cells -quiet $CTS_LIB_CELL_PATTERN_LIST]

set_dont_touch $CTS_CELLS false
set_lib_cell_purpose -exclude cts [get_lib_cells]
set_lib_cell_purpose -include cts $CTS_CELLS
unsuppress_message ATTR-12

###############################################################################
# Tap Cells Placement 
###############################################################################
create_tap_cells -lib_cell $TAP_CELL \
                     -distance $TAP_CELL_DISTANCE \
                     -pattern every_row \
                     -separator "_" \
                     -skip_fixed_cells

###############################################################################
# Placement & Routing Layer Options
###############################################################################
# Limite de camadas de roteamento para sinais
set BOTTOM_ROUTING_LAYER M2
set TOP_ROUTING_LAYER M8

remove_ignored_layers -all
set_ignored_layers -min_routing_layer $BOTTOM_ROUTING_LAYER \
                   -max_routing_layer $TOP_ROUTING_LAYER

# Opções globais de otimização
set_app_options -name opt.power.mode  -value total
set_app_options -name opt.area.effort -value high
set_app_options -name opt.tie_cell.max_fanout -value $MAX_FANOUT

# Opções de congestionamento e densidade
set_app_options -name place.coarse.cong_restruct -value on
set_app_options -name place.coarse.cong_restruct_effort -value ultra
set_app_options -name place.coarse.pin_density_aware -value true
set_app_options -name place.coarse.max_density -value 0.60
set_app_options -name place.coarse.auto_density_control -value enhanced

###############################################################################
# Place Design
###############################################################################
# Initial placement
create_placement -use_seed_locs -congestion -congestion_effort high -effort high

legalize_placement -incremental

place_opt

#remove_buffer_tree -all -hfs_fanout_threshold 1
set_app_options -name opt.area.effort -value high

###############################################################################
# 3. Tie Cells Insertion
###############################################################################
add_tie_cells -tie_high_lib_cells [get_lib_cells $TIE_HIGH] \
                   -tie_low_lib_cells [get_lib_cells $TIE_LOW] 

# Legalização incremental final
legalize_placement -incremental

###############################################################################
# Check Placement & Reports
###############################################################################
check_legality -verbose > ${RPT_DIR}/${DESIGN_STAGE}/placement_legality.rpt
check_design -checks {legality timing}

report_placement -verbose high > ${RPT_DIR}/${DESIGN_STAGE}/report_placement.rpt
report_utilization > ${RPT_DIR}/${DESIGN_STAGE}/report_utilization_postPlacement.rpt
report_congestion -rerun_global_router > ${RPT_DIR}/${DESIGN_STAGE}/report_congestion.rpt

# Reports de Timing (QoR, Setup, Hold, DRV)
report_qor -significant_digits 3 -scenarios [get_scenarios] > ${RPT_DIR}/${DESIGN_STAGE}/report_qor.rpt

report_timing -delay_type max -scenarios [get_scenarios] -max_paths 10 \
              > ${RPT_DIR}/${DESIGN_STAGE}/report_sta_setup.rpt

report_timing -delay_type min -scenarios [get_scenarios] -max_paths 10 \
              > ${RPT_DIR}/${DESIGN_STAGE}/report_sta_hold.rpt

report_constraints -all_violators -scenarios [get_scenarios] \
                   > ${RPT_DIR}/${DESIGN_STAGE}/report_drv.rpt

###############################################################################
# Save Block
###############################################################################
save_block -as ${DESIGN}/${DESIGN_STAGE} -compress

echo "\[VIRTUS-CC\] INFO: Placement and Optimization stage completed successfully."
date
return