########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: setup_dc.tcl
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

set_host_options -max_cores 8

###############################################################################
# Design Setup
###############################################################################
set PREV_STAGE          "init_design"
set DESIGN_STAGE        "floorplan"

###############################################################################
# ICC2 Open created library and block
###############################################################################
# Open created Design Library
open_lib                ${DLIB_DIR}/${DESIGN}.dlib

# Make a copy of last stage block and rename to the new stage
copy_block             -from ${DESIGN}/${PREV_STAGE} \
                       -to ${DESIGN}/${DESIGN_STAGE}

# set the copy as the current design to work
current_block          ${DESIGN}/${DESIGN_STAGE}

# Analysis scenarios
get_scenarios
report_scenarios -nosplit
current_scenario tc

# Enable clock reconvergence pessimism removal as_user_default
# Remove the pessimism from the timing calculation caused by charged clock paths
set_app_options -as_user_default -name time.remove_clock_reconvergence_pessimism -value true

# Generate SVF for Formality tool
set_svf -append  ${OUT_DIR}/${DESIGN}.svf

# ###############################################################################
# # prePlacement timing driven
# ###############################################################################

set_attribute -name routing_direction [get_layer M1] -value  horizontal 
set_attribute -name routing_direction [get_layer M2] -value  vertical 
set_attribute -name routing_direction [get_layer M3] -value  horizontal 
set_attribute -name routing_direction [get_layer M4] -value  vertical 
set_attribute -name routing_direction [get_layer M5] -value  horizontal
set_attribute -name routing_direction [get_layer M6] -value  vertical 
set_attribute -name routing_direction [get_layer M7] -value  horizontal 
set_attribute -name routing_direction [get_layer M8] -value  vertical 
set_attribute -name routing_direction [get_layer M9] -value  horizontal 

# ################################################################################
# # ICC2 Creates floorplan
# ################################################################################
# # By default, the initialize_floorplan command creates site arrays. To modify Rows you must use -use_site_row

initialize_floorplan \
      -shape R\
      -orientation N\
      -side_ratio {1 1 1 1}\
      -core_offset {1}\
      -core_utilization 0.55

shape_blocks

create_placement

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

create_net -power  VDD
create_net -ground VSS

set_net_type -net VDD -type power
set_net_type -net VSS -type ground

connect_pg_net -net VDD [get_pins -physical_context {*/VDD}]
connect_pg_net -net VSS [get_pins -physical_context {*/VSS}]

connect_pg_net -automatic

###############################################################################
# PG Ring Creation
###############################################################################
remove_redundant_shapes -remove_floating_shapes false \
                        -remove_dangling_shapes true

remove_routes -lib_cell_pin_connect
remove_routes -stripe
remove_routes -ring

# connect_pg_net
# set_pg_via_master_rule pgvia_8x10 -via_array_dimension {8 10}

set power_nets {VDD}
set ground_nets {VSS}
foreach_in_collection corner [get_cells -filter design_type==corner] {
	foreach net [concat $power_nets $ground_nets] { 
		connect_supply_net ${net} -port "[get_object_name $corner]/${net}"
	}
}

set_app_options -name plan.pgroute.ignore_signal_route -value true

## PG RING 
create_pg_ring_pattern ring_pattern -horizontal_layer M1 \
   -horizontal_width {0.15} -horizontal_spacing {0.15} \
   -vertical_layer M2 -vertical_width {0.15} -vertical_spacing {0.15} 

set_pg_strategy core_ring \
   -pattern {{name: ring_pattern} \
   {nets: {VDD VSS}} {offset: {0.25 0.25}}} -core

compile_pg -strategies core_ring


## Create the std cell rails for the pattern created
create_pg_std_cell_conn_pattern rail_pattern \
                                -layers {M1} 

set_pg_strategy M1_rails \
                 -pattern   { {name: rail_pattern} {nets: {VDD VSS}} } \
                 -extension { {stop: innermost_ring} } \
                 -core

compile_pg -strategies M1_rails


#--------------------------------------------------------------------------------------
## PG Stripes M1
create_pg_std_cell_conn_pattern std_cell_vss_pattern -layers {M1}
set_pg_strategy  pg_std_cell -core  -pattern {{pattern: std_cell_vss_pattern }{nets: {VSS}} }
compile_pg -strategies pg_std_cell

create_pg_std_cell_conn_pattern std_cell_vdd_pattern -layers {M2}
set_pg_strategy  pg_std_cell -core  -pattern {{pattern: std_cell_vdd_pattern }{nets: {VDD}} }
compile_pg -strategies pg_std_cell
#---------------------------------------------------------------------------------------


#---------------------------------------------------------------------------------------
create_pg_mesh_pattern pg_mesh_m3 -layers { {{horizontal_layer: M3} {width: 1} {spacing: 4} {pitch: 10} {trim: true}}  } -via_rule {}
set_pg_strategy  pg_strategy_mesh_m3  -core  -pattern {{pattern: pg_mesh_m3}{nets: {VSS VDD}} } -extension {{stop: outermost_ring}}
compile_pg -strategies pg_strategy_mesh_m3

create_pg_mesh_pattern pg_mesh_m4 -layers { {{vertical_layer: M4 } {width: 1} {spacing: 4} {pitch: 10} {trim: true} }}  -via_rule {}
set_pg_strategy  pg_strategy_mesh_m4  -core  -pattern {{pattern: pg_mesh_m4}{nets: {VSS VDD }} } -extension {{stop: outermost_ring}}
compile_pg -strategies pg_strategy_mesh_m4
#---------------------------------------------------------------------------------------

# # TODO: Do the Internal PG mesh
# create_pg_mesh_pattern pg_internal_mesh_m5 -layers { {{horizontal_layer: M5} {width: 5} {spacing: 8} {pitch: 20} {trim: true}}  } -via_rule {}
# set_pg_strategy  pg_strategy_mesh_m5  -core  -pattern {{pattern: pg_internal_mesh_m5}{nets: {VSS VDD}} } -extension {{stop: outermost_ring}}
# compile_pg -strategies pg_strategy_mesh_m5

# create_pg_mesh_pattern pg_internal_mesh_m6 -layers { {{vertical_layer: M6} {width: 5} {spacing: 8} {pitch: 20} {trim: true}} }  -via_rule {}
# set_pg_strategy  pg_strategy_mesh_m6 -core  -pattern {{pattern: pg_internal_mesh_m6}{nets: {VSS VDD }} } 
# compile_pg -strategies pg_strategy_mesh_m6

legalize_placement

set_block_pin_constraints -self -allowed_layers {M3 M4 M5 M6}
place_pins -self

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
file mkdir           ${RPT_DIR}/${DESIGN_STAGE}
report_qor           -significant_digits 3 \
                     -scenarios [get_scenarios] \
                     > ${RPT_DIR}/report_qor.rpt

###############################################################################
# Reports
###############################################################################
report_utilization           > ${RPT_DIR}/${DESIGN_STAGE}/report_utilization_postfloorplan.rpt

# Reports the routing track direction, startpoint, number of tracks and pitch
report_tracks                > ${RPT_DIR}/${DESIGN_STAGE}/report_tracks.rpt

report_design -floorplan     > ${RPT_DIR}/${DESIGN_STAGE}/report_design.rpt

###############################################################################
# Creates abstract and frame views of the design
###############################################################################
create_abstract	-read_only

create_frame

###############################################################################
# Generate Floorplan DEF file
###############################################################################
write_floorplan	      -force \
                        -output ${OUT_DIR}/${DESIGN_STAGE}/${DESIGN}.fp

# Writes the floorplan for Design Compiler Synopsys tool
write_floorplan	      -force -output ${OUT_DIR}/${DESIGN_STAGE}/${DESIGN}.fp.dc -net_types {power ground} -include_physical_status {fixed locked}

write_def               -include_tech_via_definitions \
                        -include {rows_tracks vias blockages specialnets} \
                        "${OUT_DIR}/${DESIGN_STAGE}/floorplan.def"

save_lib
save_block -compress -as ${DESIGN}/${DESIGN_STAGE}
close_lib

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
start_gui
return
