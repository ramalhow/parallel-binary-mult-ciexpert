########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: floorplan.tcl
# Description: Floorplan Creation Script:
#                * Defines IO cells (if necessary)
#                * Defines Floorplan
#                * Defines Powerplan
#                * Routes power nets
# Version: 2026-08-19
# Author: Arthur Ramalho
#########################################################################

###############################################################################
# Tech & ICC2 Setup
###############################################################################
source ../setup/tech_setup.tcl

set PREV_STAGE   "init_design"
set DESIGN_STAGE "floorplan"

file mkdir ${RPT_DIR}/${DESIGN_STAGE}

###############################################################################
# ICC2 Open Library & Copy Block
###############################################################################
open_lib $DLIB_DIR/${DESIGN}.dlib

copy_block -from ${DESIGN}/${PREV_STAGE} -to ${DESIGN}/${DESIGN_STAGE}
current_block ${DESIGN}/${DESIGN_STAGE}

# Activate all MMMC scenarios
set_scenario_status -active true [all_scenarios]
report_scenarios -nosplit

# Load and enforce SDC constraints
read_sdc ${SDC_DIR}/${DESIGN}.sdc

set_svf -append ${OUT_DIR}/${DESIGN}.svf

###############################################################################
# Floorplan Initialization (Core Area & Utilization)
###############################################################################
# Core Utilization ~55%, 3.0um boundary offset, 1:1 aspect ratio
initialize_floorplan -shape R \
                     -orientation N \
                     -side_ratio {1 1 1 1} \
                     -core_offset {3} \
                     -core_utilization 0.55

###############################################################################
# Routing Directions Setup
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
set_attribute -name routing_direction [get_layer MRDL] -value vertical 

###############################################################################
# Coarse / Floorplan Placement & Congestion Optimization
###############################################################################
set_app_options -name plan.place.congestion_driven_mode -value both
set_app_options -name place.coarse.cong_restruct -value on
set_app_options -name place.coarse.cong_restruct_effort -value ultra

create_placement -floorplan -congestion -congestion_effort high

###############################################################################
# Logical Power & Ground Connections (Prevents floating PG pin errors)
###############################################################################
create_net -power VDD
create_net -ground VSS

set_net_type -net VDD -type power
set_net_type -net VSS -type ground

connect_pg_net -net VDD [get_pins -physical_context {*/VDD}]
connect_pg_net -net VSS [get_pins -physical_context {*/VSS}]
connect_pg_net -automatic

###############################################################################
# Power Delivery Network (PDN / Power Grid) Creation
###############################################################################
remove_redundant_shapes -remove_floating_shapes false -remove_dangling_shapes true
remove_routes -lib_cell_pin_connect -stripe -ring

set_app_options -name plan.pgroute.ignore_signal_route -value true

# --- 1. Core Ring on Top Metal Layers (M8 / M9) ---
create_pg_ring_pattern ring_pattern \
   -horizontal_layer M9 -horizontal_width {0.8} -horizontal_spacing {0.6} \
   -vertical_layer M8   -vertical_width {0.8}   -vertical_spacing {0.6} 

set_pg_strategy core_ring \
   -pattern {{name: ring_pattern} {nets: {VDD VSS}} {offset: {0.5 0.5}}} \
   -core

compile_pg -strategies core_ring

# --- 2. Standard Cell Rails on M1 ---
create_pg_std_cell_conn_pattern rail_pattern -layers {M1}

set_pg_strategy M1_rails \
   -pattern  { {name: rail_pattern} {nets: {VDD VSS}} } \
   -extension { {stop: innermost_ring} } \
   -core

compile_pg -strategies M1_rails

# --- 3. Intermediate & Top Power Meshes (M2 to M9) ---
# M2 Mesh (Vertical)
create_pg_mesh_pattern pg_mesh2 -layers { {{vertical_layer: M2} {width: 0.15} {spacing: 5} {pitch: 10} {trim: true}} }
set_pg_strategy pg_strategy2 -core -pattern {{pattern: pg_mesh2} {nets: {VSS VDD}}} -extension {{stop: innermost_ring}}
compile_pg -strategies pg_strategy2

# M3 Mesh (Horizontal)
create_pg_mesh_pattern pg_mesh3 -layers { {{horizontal_layer: M3} {width: 0.4} {spacing: 11} {pitch: 13} {trim: true}} }
set_pg_strategy pg_strategy3 -core -pattern {{pattern: pg_mesh3} {nets: {VSS VDD}}} -extension {{stop: innermost_ring}}
compile_pg -strategies pg_strategy3

# M4 Mesh (Vertical)
create_pg_mesh_pattern pg_mesh4 -layers { {{vertical_layer: M4} {width: 0.75} {spacing: 10} {pitch: 20} {trim: true}} }
set_pg_strategy pg_strategy4 -core -pattern {{pattern: pg_mesh4} {nets: {VSS VDD}}} -extension {{stop: innermost_ring}}
compile_pg -strategies pg_strategy4

# M5 Mesh (Horizontal)
create_pg_mesh_pattern pg_mesh5 -layers { {{horizontal_layer: M5} {width: 4.0} {spacing: 20} {pitch: 320} {trim: true}} }
set_pg_strategy pg_strategy5 -core -pattern {{pattern: pg_mesh5} {nets: {VSS VDD}}} -extension {{stop: innermost_ring}}
compile_pg -strategies pg_strategy5

# M8 Mesh (Vertical)
create_pg_mesh_pattern pg_mesh8 -layers { {{vertical_layer: M8} {width: 1.0} {spacing: 15} {pitch: 25} {trim: true}} }
set_pg_strategy pg_strategy8 -core -pattern {{pattern: pg_mesh8} {nets: {VSS VDD}}} -extension {{stop: outermost_ring}}
compile_pg -strategies pg_strategy8

# M9 Mesh (Horizontal)
create_pg_mesh_pattern pg_mesh9 -layers { {{horizontal_layer: M9} {width: 1.0} {spacing: 10} {pitch: 25} {trim: true}} }
set_pg_strategy pg_strategy9 -core -pattern {{pattern: pg_mesh9} {nets: {VSS VDD}}} -extension {{stop: outermost_ring}}
compile_pg -strategies pg_strategy9

###############################################################################
# Pin Placement & Constraints
###############################################################################
legalize_placement

# Constrain all 130 I/O pins with 4um pitch strictly across layers M4 to M7
set_block_pin_constraints -self \
                          -pin_spacing_distance 4 \
                          -sides {1 2 3 4} \
                          -allowed_layers {M4 M5 M6 M7} \
                          -hard_constraints {location spacing layer}

place_pins -self

###############################################################################
# Global Routing Check & Blockage Cleanup
###############################################################################
remove_placement_blockages -all -verbose
remove_routing_blockages   -all -verbose

route_global -floorplan true -congestion_map_only true

###############################################################################
# Reports & Quality Checks
###############################################################################
report_design -floorplan                     > ${RPT_DIR}/${DESIGN_STAGE}/report_design.rpt
report_utilization                           > ${RPT_DIR}/${DESIGN_STAGE}/report_utilization.rpt
check_legality                               > ${RPT_DIR}/${DESIGN_STAGE}/check_legality.rpt
report_ports                                 > ${RPT_DIR}/${DESIGN_STAGE}/report_ports.rpt
report_pg_strategies                         > ${RPT_DIR}/${DESIGN_STAGE}/report_pg_stategies.rpt

# Structural Power Grid Checks
check_pg_connectivity -check_std_cell_pins none > ${RPT_DIR}/${DESIGN_STAGE}/check_pg_connectivity.rpt
check_pg_drc -ignore_std_cells               > ${RPT_DIR}/${DESIGN_STAGE}/check_pg_drc.rpt
check_pg_missing_vias                        > ${RPT_DIR}/${DESIGN_STAGE}/check_pg_missing_vias.rpt

# Final QoR Report
report_qor -significant_digits 3 -scenarios [get_scenarios] > ${RPT_DIR}/${DESIGN_STAGE}/report_qor.rpt

###############################################################################
# Export Deliverables (Abstract, DEF, Floorplan File)
###############################################################################
#create_abstract -read_only
#create_frame

write_floorplan -force -output ${OUT_DIR}/${DESIGN}.fp
write_floorplan -force -output ${OUT_DIR}/${DESIGN}.fp.dc -net_types {power ground} -include_physical_status {fixed locked}

write_def -include_tech_via_definitions \
          -include {rows_tracks vias blockages specialnets} \
          "${OUT_DIR}/floorplan.def"

###############################################################################
# Save Block & Close Stage
###############################################################################
save_lib
save_block -as ${DESIGN}/${DESIGN_STAGE} -compress

echo "*****************************************************************************************"
puts "\[VIRTUS-CC\] INFO: The ${DESIGN_STAGE} stage for ${DESIGN} completed successfully."
echo "*****************************************************************************************"
date
return