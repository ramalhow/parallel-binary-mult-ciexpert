########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Script: floorplan.tcl (Corrigido)
########################################################################

###############################################################################
# Tech & ICC2 Setup
###############################################################################
source ../setup/tech_setup.tcl

set_host_options -max_cores 8

set PREV_STAGE    "init_design"
set DESIGN_STAGE  "floorplan"

open_lib          ${DLIB_DIR}/${DESIGN}.dlib
copy_block        -from ${DESIGN}/${PREV_STAGE} -to ${DESIGN}/${DESIGN_STAGE}
current_block     ${DESIGN}/${DESIGN_STAGE}

# Analysis scenarios
get_scenarios
report_scenarios -nosplit
current_scenario tc

set_app_options -as_user_default -name time.remove_clock_reconvergence_pessimism -value true
set_svf -append ${OUT_DIR}/${DESIGN}.svf

###############################################################################
# Routing Directions setup
###############################################################################
set_attribute -name routing_direction [get_layer M1] -value horizontal 
set_attribute -name routing_direction [get_layer M2] -value vertical 
set_attribute -name routing_direction [get_layer M3] -value horizontal 
set_attribute -name routing_direction [get_layer M4] -value vertical 
set_attribute -name routing_direction [get_layer M5] -value horizontal
set_attribute -name routing_direction [get_layer M6] -value vertical 
set_attribute -name routing_direction [get_layer M7] -value horizontal 
set_attribute -name routing_direction [get_layer M8] -value vertical 
set_attribute -name routing_direction [get_layer M9] -value horizontal 

###############################################################################
# Initialize Floorplan
###############################################################################
initialize_floorplan \
      -shape R \
      -orientation N \
      -side_ratio {1 1 1 1} \
      -core_offset {1} \
      -core_utilization 0.55

###############################################################################
# Power Logical Connections (FIXED)
###############################################################################
# 1. Garante que as portas do topo existam
if {[sizeof_collection [get_ports -quiet VDD]] == 0} { create_port -direction inout VDD }
if {[sizeof_collection [get_ports -quiet VSS]] == 0} { create_port -direction inout VSS }

# 2. Cria e define os tipos das nets
create_net -power  VDD
create_net -ground VSS

set_net_type -net VDD -type power
set_net_type -net VSS -type ground

# 3. Conecta tanto os pinos das células quanto as portas do topo
connect_pg_net -net VDD [get_pins -physical_context {*/VDD}]
connect_pg_net -net VSS [get_pins -physical_context {*/VSS}]
connect_pg_net -net VDD [get_ports VDD]
connect_pg_net -net VSS [get_ports VSS]
connect_pg_net -automatic

###############################################################################
# Power Planning (PG Ring, Mesh & Rails - FIXED)
###############################################################################
remove_redundant_shapes -remove_floating_shapes false -remove_dangling_shapes true
remove_routes -lib_cell_pin_connect
remove_routes -stripe
remove_routes -ring

set_app_options -name plan.pgroute.ignore_signal_route -value true

# --- PG Ring em metais superiores (M8 e M9) ---
create_pg_ring_pattern ring_pattern \
   -horizontal_layer M9 -horizontal_width {0.8} -horizontal_spacing {0.4} \
   -vertical_layer M8   -vertical_width {0.8}   -vertical_spacing {0.4} 

set_pg_strategy core_ring \
   -pattern {{name: ring_pattern} {nets: {VDD VSS}} {offset: {0.5 0.5}}} -core

compile_pg -strategies core_ring

# --- PG Mesh em M5 (Horizontal) e M6 (Vertical) ---
create_pg_mesh_pattern pg_mesh_m5_m6 \
   -layers {
      {{horizontal_layer: M5} {width: 0.5} {spacing: 1.0} {pitch: 10} {trim: true}}
      {{vertical_layer: M6}   {width: 0.5} {spacing: 1.0} {pitch: 10} {trim: true}}
   }

set_pg_strategy pg_strategy_mesh \
   -core \
   -pattern {{pattern: pg_mesh_m5_m6} {nets: {VDD VSS}}} \
   -extension {{stop: innermost_ring}}

compile_pg -strategies pg_strategy_mesh

# --- Std Cell Rails em M1 ---
create_pg_std_cell_conn_pattern rail_pattern -layers {M1}

set_pg_strategy M1_rails \
   -pattern {{name: rail_pattern} {nets: {VDD VSS}}} \
   -core

compile_pg -strategies M1_rails

###############################################################################
# Coarse Placement & Pin Placement
###############################################################################
set_app_options -name place.coarse.cong_restruct -value on
set_app_options -name place.coarse.cong_restruct_effort -value ultra
set_app_options -name plan.place.congestion_driven_mode -value both

# Posicionamento rápido apenas para estimativa do Floorplan
create_placement -floorplan -congestion -effort high

# Posicionamento dos pinos das portas de I/O
set_block_pin_constraints -self -allowed_layers {M3 M4 M5 M6}
place_pins -self

# Reseta o posicionamento das std cells para que a etapa seguinte (place_opt) faça do zero
reset_placement

###############################################################################
# Checks & Reports
###############################################################################
check_pg_missing_vias
check_pg_drc -ignore_std_cells
check_pg_connectivity -check_std_cell_pins none

file mkdir ${RPT_DIR}/${DESIGN_STAGE}
report_qor -significant_digits 3 -scenarios [get_scenarios] > ${RPT_DIR}/report_qor.rpt
report_utilization > ${RPT_DIR}/${DESIGN_STAGE}/report_utilization_postfloorplan.rpt
report_tracks > ${RPT_DIR}/${DESIGN_STAGE}/report_tracks.rpt
report_design -floorplan > ${RPT_DIR}/${DESIGN_STAGE}/report_design.rpt

###############################################################################
# Save & Export
###############################################################################
write_floorplan -force -output ${OUT_DIR}/${DESIGN_STAGE}/${DESIGN}.fp
write_def -include_tech_via_definitions \
          -include {rows_tracks vias blockages specialnets} \
          "${OUT_DIR}/${DESIGN_STAGE}/floorplan.def"

save_lib
save_block -compress -as ${DESIGN}/${DESIGN_STAGE}
close_lib

echo "\[VIRTUS-CC\] INFO: Floorplan completed successfully."
date
return