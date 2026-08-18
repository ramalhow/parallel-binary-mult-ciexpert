# -------------------------------------------------------------------------------------
# Copyright (c) 2026 VIRTUS CC-UFCG. All rights reserved
# VIRTUS CC-UFCG Confidential Proprietary
#
# Copy, distribuition or use of this code is not allowed without
# VIRTUS CC-UFCG explicit written consent.
# -------------------------------------------------------------------------------------
#
# Id: floorplan.tcl_2026-05-05_by_LuizHenriqueNascimento
#
# Project: 		CI Expert/UFCG - Physical Design Track
# Description:	Floorplan creation script:
#                * Defines IO cells (if necessary)
#                * Defines Floorplan
#                * Defines Powerplan
#                * Routes power nets
# -------------------------------------------------------------------------------------

###############################################################################
# Tech & ICC2 Setup
###############################################################################
source ../setup/tech_setup.tcl

set PREV_STAGE "init_design"
set DESIGN_STAGE "floorplan"

file mkdir ${RPT_DIR}/${DESIGN_STAGE}
###############################################################################
# ICC2 Open created library and block
###############################################################################
open_lib $DLIB_DIR/${DESIGN}.dlib

copy_block -from ${DESIGN}/${PREV_STAGE} -to ${DESIGN}/${DESIGN_STAGE}
current_block ${DESIGN}/${DESIGN_STAGE}

# Ativa todos os cenários ANTES de carregar restrições adicionais
get_scenarios
set_scenario_status -active true [all_scenarios]
report_scenarios -nosplit

# Lê restrições de SDC
read_sdc ${SDC_DIR}/${DESIGN}.sdc

set_svf -append ${OUT_DIR}/${DESIGN}.svf

# ################################################################################
# # ICC2 Creates floorplan
# ################################################################################
# # By default, the initialize_floorplan command creates site arrays. To modify Rows you must use -use_site_row

initialize_floorplan -shape R -orientation N -side_ratio {1 1 1 1} -core_offset {3} -core_utilization 0.55

shape_blocks

create_placement

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

set_app_options -list {plan.place.congestion_driven_mode both}
# ## Creates a rough placement of the cells only for floorplaning purpose
create_placement -floorplan -use_seed_locs -timing_driven -incremental -effort high

#report_app_options plan.place*

# # Unplace all std cells, since only macro place at this stage
# #reset_placement -spread_cells
# #reset_placement

# ###############################################################################
# # prePlacement congestion driven
# ###############################################################################
# # After all relative place constraints set
# # Effort level for congestion-driven restructuring
set_app_options  -name place.coarse.cong_restruct        -value on
set_app_options  -name place.coarse.cong_restruct_effort -value ultra
set_app_options  -name plan.place.congestion_driven_mode -value both

create_placement -floorplan -congestion -congestion_effort high

# ###############################################################################
# # Power Logical Connections
# ###############################################################################
# # Create new PG nets
get_ports
get_terminals

create_net                  -power          VDD
create_net                  -ground         VSS

set_net_type                -net            VDD    -type   power
set_net_type                -net            VSS   -type    ground

connect_pg_net              -net            VDD        [get_pins -physical_context {*/VDD}]
connect_pg_net              -net            VSS        [get_pins -physical_context {*/VSS}]

connect_pg_net -automatic
###############################################################################
# PG Ring Creation
###############################################################################
remove_redundant_shapes -remove_floating_shapes false \
                        -remove_dangling_shapes true

remove_routes -lib_cell_pin_connect
remove_routes -stripe
remove_routes -ring

connect_pg_net
set_pg_via_master_rule pgvia_8x10 -via_array_dimension {8 10}

set power_nets {VDD}
set ground_nets {VSS}
foreach_in_collection corner [get_cells -filter design_type==corner] {
	foreach net [concat $power_nets $ground_nets] { 
		connect_supply_net ${net} -port "[get_object_name $corner]/${net}"
	}
}


set_app_options -name plan.pgroute.ignore_signal_route -value true

# PG RING 
# create_pg_ring_pattern ring_pattern -horizontal_layer M9 \
#    -horizontal_width {1} -horizontal_spacing {1} \
#    -vertical_layer M8 -vertical_width {1} -vertical_spacing {1} \
#    -track_alignment auto 
# 
# set_pg_strategy core_ring \
#    -pattern {{name: ring_pattern} \
#    {nets: {VDD VSS}} {offset: {2 2}}} \
#    -core
# compile_pg -strategies core_ring

# --- PG Ring em metais superiores (M8 e M9) ---
create_pg_ring_pattern ring_pattern \
   -horizontal_layer M9 -horizontal_width {0.8} -horizontal_spacing {0.6} \
   -vertical_layer M8   -vertical_width {0.8}   -vertical_spacing {0.6} 

set_pg_strategy core_ring \
   -pattern {{name: ring_pattern} {nets: {VDD VSS}} {offset: {0.5 0.5}}} -core

compile_pg -strategies core_ring

create_pg_std_cell_conn_pattern rail_pattern \
                                -layers {M1} 
                                

# # Create the std cell rails for the pattern created
set_pg_strategy M1_rails \
                 -pattern   { {name: rail_pattern} {nets: {VDD VSS}}} \
                 -extension  {{stop: innermost_ring} } \
                 -core



compile_pg -strategies M1_rails -via_rule {rail_rule}

# --- Std Cell Rails em M1 ---
create_pg_std_cell_conn_pattern rail_pattern -layers {M1}

set_pg_strategy M1_rails \
   -pattern   { {name: rail_pattern} {nets: {VDD VSS}} } \
   -extension { {stop: innermost_ring} } \
   -core

compile_pg -strategies M1_rails

#############################################################################
create_pg_mesh_pattern pg_mesh2 -layers { {{vertical_layer: M2 } {width: 0.15} {spacing: 5} {pitch: 10} {trim: true} }}  -via_rule {}
set_pg_strategy  pg_strategy2  -core  -pattern {{pattern: pg_mesh2}{nets: {VSS VDD }} } -extension {{stop: inermost_ring}}
compile_pg -strategies pg_strategy2 -via_rule {rail_rule}

create_pg_mesh_pattern pg_mesh3 -layers { {{horizontal_layer: M3} {width: 0.4} {spacing: 11} {pitch: 13} {trim: true}}} -via_rule {}
set_pg_strategy  pg_strategy3  -core  -pattern {{pattern: pg_mesh3}{nets: {VSS VDD }} } -extension {{stop: inermost_ring}}
compile_pg -strategies pg_strategy3 

create_pg_mesh_pattern pg_mesh4 -layers { {{vertical_layer: M4 } {width: 0.75} {spacing: 10} {pitch: 20} {trim: true} }}  -via_rule {}
set_pg_strategy  pg_strategy4  -core  -pattern {{pattern: pg_mesh4}{nets: {VSS VDD }} } -extension {{stop: inermost_ring}}
compile_pg -strategies pg_strategy4 -via_rule {rail_rule}

create_pg_mesh_pattern pg_mesh5 -layers { {{horizontal_layer: M5} {width: 4} {spacing: 20} {pitch: 320} {trim: true}}} -via_rule {}
set_pg_strategy  pg_strategy5  -core  -pattern {{pattern: pg_mesh5}{nets: {VSS VDD }} } -extension {{stop: inermost_ring}}
compile_pg -strategies pg_strategy5

# --- PG Mesh em M5 (Horizontal) e M6 (Vertical) ---
# create_pg_mesh_pattern pg_mesh_m5_m6 \
#    -layers {
#       {{horizontal_layer: M5} {width: 0.5} {spacing: 1.0} {pitch: 10} {trim: true}}
#       {{vertical_layer: M6}   {width: 0.5} {spacing: 1.0} {pitch: 10} {trim: true}}
#    }
# 
# set_pg_strategy pg_strategy_mesh \
#    -core \
#    -pattern {{pattern: pg_mesh_m5_m6} {nets: {VDD VSS}}} \
#    -extension {{stop: innermost_ring}}
# 
# compile_pg -strategies pg_strategy_mesh


create_pg_mesh_pattern pg_mesh8 -layers { {{vertical_layer: M8 } {width: 1} {spacing: 15} {pitch: 25} {trim: true} }}  -via_rule {}
set_pg_strategy  pg_strategy8 -core -pattern {{pattern: pg_mesh8}{nets: {VSS VDD }} } -extension {{stop: outermost_ring}}
compile_pg -strategies pg_strategy8 

create_pg_mesh_pattern pg_mesh9 -layers { {{horizontal_layer: M9 } {width: 1} {spacing: 10} {pitch: 25} {trim: true} }}  -via_rule {}
set_pg_strategy  pg_strategy9 -core -pattern {{pattern: pg_mesh9}{nets: {VSS VDD }} } -extension {{stop: outermost_ring}}
compile_pg -strategies pg_strategy9

legalize_placement

set_block_pin_constraints -self -pin_spacing_distance 4 -sides {1 2 3 4} -allowed_layers {M4 M5 M6 M7} -hard_constraints {location spacing layer}
place_pins -self


save_lib

###############################################################################
# Remove all placement blockages
###############################################################################
remove_placement_blockages   -all -verbose
remove_routing_blockages     -all -verbose

###############################################################################
# Global Route
###############################################################################
# Creates a rough routing of the cells after the Power Planning
remove_placement_blockages [get_placement_blockages *]
route_global -floorplan true -congestion_map_only true

check_pg_missing_vias
check_pg_drc -ignore_std_cells
check_pg_connectivity -check_std_cell_pins none

###############################################################################
# Report_timing
###############################################################################
file mkdir             ${RPT_DIR}/${DESIGN_STAGE}
report_qor              -significant_digits 3 \
                        -scenarios [get_scenarios] \
                        > ${RPT_DIR}/report_qor.rpt

###############################################################################
# Reports
###############################################################################
report_utilization           > ${RPT_DIR}/report_utilization_postFloorplan.rpt

# Reports the routing track direction, startpoint, number of tracks and pitch
#report_tracks

report_design -floorplan     > ${RPT_DIR}/report_design.rpt

###############################################################################
# Creates abstract and frame views of the design
###############################################################################
create_abstract	-read_only

create_frame

###############################################################################
# Generate Floorplan DEF file
###############################################################################
write_floorplan	        -force \
                        -output ${OUT_DIR}/${DESIGN}.fp

# Writes the floorplan for Design Compiler Synopsys tool
write_floorplan	        -force -output ${OUT_DIR}/${DESIGN}.fp.dc -net_types {power ground} -include_physical_status {fixed locked}

write_def               -include_tech_via_definitions \
                        -include {rows_tracks vias blockages specialnets} \
                        "${OUT_DIR}/floorplan.def"

###############################################################################
# ICC2 Save Design
###############################################################################
save_block              -as ${DESIGN}/${DESIGN_STAGE} \
                        -compress

#close_lib

###############################################################################
###############################################################################
############################ FINISH FLOORPLAN #################################
###############################################################################
###############################################################################
echo "*****************************************************************************************"
echo "*****************************************************************************************"
puts "\[VIRTUS-CC\] INFO: The ${DESIGN_STAGE} for the ${DESIGN} has been completed."
puts "\[VIRTUS-CC\] INFO: Calling GUI ..."
echo "*****************************************************************************************"
echo "*****************************************************************************************"
date
after 5000
start_gui 
return

