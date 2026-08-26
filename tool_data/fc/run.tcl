
###############################################################################
# Setups
###############################################################################

# Project
source ../setup/setup_fc.tcl

# evitar reescrever as libs
set DESIGN_FUSION ${DESIGN}_FC

###############################################################################
# Initialize the design
###############################################################################

# Current Stage
set DESIGN_STAGE "init_design"

set search_path "${OUT_DIR} ${RTL_DIR} $TECH_DIR"

if { [file exists ${DLIB_DIR}/${DESIGN_FUSION}.dlib] } {
    open_lib ${DLIB_DIR}/${DESIGN_FUSION}.dlib
    open_block ${DESIGN}
} else {
    create_lib -technology  $TECH_FILE -ref_libs $REFERENCE_LIBRARY ${DLIB_DIR}/${DESIGN_FUSION}.dlib
    
    analyze -format verilog ${DESIGN}.v
    elaborate ${DESIGN}
    set_top_module ${DESIGN}

    current_block 
}


###############################################################################
# Tech Setup
###############################################################################

# reading the parasitic tech
read_parasitic_tech -layermap $TLUPLUS_MAP_FILE -tlup $MAX_TLUPLUS_FILE -name maxTLU
read_parasitic_tech -layermap $TLUPLUS_MAP_FILE -tlup $MIN_TLUPLUS_FILE -name minTLU


# reading the site_row from lef file
read_tech_lef ${LEF_DIR}/saed32nm_lvt_1p9m.lef -design ${DESIGN} -merge_action add

set_attribute [get_site_defs unit] symmetry Y
set_attribute [get_site_defs unit] is_default true

# suppresse the warning just for the init design
suppress_message ATTR-12

# metal via direction
set_attribute [get_layers {M1 M3 M5 M7 M9}] routing_direction horizontal
set_attribute [get_layers {M2 M4 M6 M8 MRDL}] routing_direction vertical

set_ignored_layers -max_routing_layer $MAX_ROUTING_LAYER


###############################################################################
# Scenarios and Constraints
###############################################################################

# loading the scenarios
remove_scenarios -all
remove_modes     -all
remove_corners   -all

set modeNames [list slow_mode typical_mode ]
foreach modeName $modeNames {
    create_mode $modeName
}

set cornerNames [list SS125_0P70 TT25_0P85 ]
foreach cornerName $cornerNames {
    create_corner $cornerName
}

#------------ Corner SS ------------------------------------------
current_corner SS125_0P70
set_operating_conditions    -analysis_type on_chip_variation \
                            -library saed32lvt_ss0p7v125c.db

set_pvt_configuration       -clear_filter all \
                            -add \
                            -name rule2 \
                            -process_label wc \
                            -process_numbers {1} \
                            -voltages 0.70 \
                            -temperatures 125

read_parasitic_tech         -sanity_check advanced \
                            -tlup "${MAX_TLUPLUS_FILE}" \
                            -layermap "${TLUPLUS_MAP_FILE}" \
                            -name maxTLU

set_parasitic_parameters    -corners SS125_0P70  \
                            -early_spec maxTLU \
                            -early_temperature 125 \
                            -late_spec maxTLU \
                            -late_temperature 125 \
                            -library $DESIGN_FUSION.dlib

#------------ Corner TT ------------------------------------------
current_corner TT25_0P85
set_operating_conditions    -analysis_type on_chip_variation \
                            -library saed32lvt_tt0p85v25c.db

set_pvt_configuration       -clear_filter all \
                            -add \
                            -name rule3 \
                            -process_label tc \
                            -process_numbers {1} \
                            -voltages 0.85 \
                            -temperatures 25

read_parasitic_tech         -sanity_check advanced \
                            -tlup "${TLUPLUS_TYP_FILE}" \
                            -layermap "${TLUPLUS_MAP_FILE}" \
                            -name typTLU

set_parasitic_parameters    -corners TT25_0P85 \
                            -early_spec typTLU \
                            -early_temperature 25 \
                            -late_spec  typTLU \
                            -late_temperature 25 \
                            -library ${DESIGN_FUSION}.dlib


create_scenario -name wc -mode slow_mode -corner SS125_0P70
create_scenario -name tc -mode typical_mode -corner TT25_0P85

set_scenario_status wc -setup true \
                       -hold true \
                       -max_capacitance true \
                       -min_capacitance true \
                       -max_transition true 

set_scenario_status tc -setup true \
                       -hold true \
                       -max_capacitance true \
                       -min_capacitance true \
                       -max_transition true 


# loading the constraints
source ../../../scripts/constraints.tcl
#read_sdc ${SDC_DIR}/${DESIGN}.sdc

###############################################################################
# Applying clock constraints
###############################################################################

# Create the clock instance in our previously defined clock port name
create_clock -period $MAIN_CLK [get_ports $DESIGN_CLK_NAME]

# Define the max uncertanty (jitter + skew + process variation + clock uncertanty)
# in the SETUP phase
set_clock_uncertainty -setup $CLOCK_SKEW_SETUP [get_clocks $DESIGN_CLK_NAME]

# A ferramenta deixa de assumir um clock ideal.
# Impacto: delay das células, análise de setup, análise de hold e potência.
set_clock_transition -max $CLOCK_TRANST_MAX [get_clocks $DESIGN_CLK_NAME]

# set_clock_transition -min $CLOCK_TRANST_MIN [get_clocks $DESIGN_CLK_NAME]

# Clock source latency
set_clock_latency -source -max $CLOCK_SRC_LATENCY_MAX [get_clocks $DESIGN_CLK_NAME]

# Clock "general" latency (?)
set_clock_latency -max $CLOCK_LATENCY_MAX [get_clocks $DESIGN_CLK_NAME]

# Quanto bloco anterior pode gastar.
set_input_delay -min $INPUT_PORT_DELAY_MIN -clock $DESIGN_CLK_NAME [all_inputs -exclude_clock_ports]
set_input_delay -max $INPUT_PORT_DELAY_MAX -clock $DESIGN_CLK_NAME [all_inputs -exclude_clock_ports]

# Tempo que precisa para entregar a saída cedo o suficiente para o próximo bloco.
set_output_delay -max $OUTPUT_PORT_DELAY_MAX -clock $DESIGN_CLK_NAME [get_ports [all_outputs]]

# Limits the max capacitive load on the outputs
set_load -max $MAX_OUTPUT_LOAD [all_outputs]

set_input_transition -min $MIN_INPUT_TRANST [all_inputs -exclude_clock_ports]
set_input_transition -max $MAX_INPUT_TRANST [all_inputs -exclude_clock_ports]

set_scenario_status -active true [all_scenarios]
current_scenario tc

###############################################################################
# Tie Cells
###############################################################################
set_dont_touch [get_lib_cells */TIE*] false
set_lib_cell_purpose -include optimization [get_lib_cells */TIE*]

###############################################################################
# Auto Floorplan
###############################################################################
set_auto_floorplan_constraints -shape R \
                     -orientation N \
                     -side_ratio {1 1 1 1} \
                     -core_offset {3} \
                     -core_utilization 0.55

set_block_pin_constraints -self \
                          -pin_spacing_distance 4 \
                          -sides {1 2 3 4} \
                          -allowed_layers {M4 M5 M6 M7} \
                          -hard_constraints {location spacing layer}

###############################################################################
# CTS Setup
###############################################################################

set CLOCK_BUFFERS           "NBUFFX32_LVT NBUFFX16_LVT NBUFFX8_LVT NBUFFX4_LVT NBUFFX2_LVT \
							IBUFFX32_LVT IBUFFX16_LVT IBUFFX8_LVT IBUFFX4_LVT IBUFFX2_LVT"

set CLOCK_BUFFERS_INV       "INVX32_LVT INVX16_LVT INVX8_LVT INVX4_LVT INVX2_LVT INVX1_LVT INVX0_LVT"

set_lib_cell_purpose -exclude cts [get_lib_cells]
set_dont_touch ${CLOCK_BUFFERS} false
set_dont_touch ${CLOCK_BUFFERS_INV} false

set_lib_cell_purpose -include cts  "${CLOCK_BUFFERS} ${CLOCK_BUFFERS_INV}"
set_lib_cell_purpose -include optimization "${CLOCK_BUFFERS} ${CLOCK_BUFFERS_INV}"
set_lib_cell_purpose -include hold "${CLOCK_BUFFERS} ${CLOCK_BUFFERS_INV}"

# Enable auto-skew target adjustment for local skew tuning
set_app_options -name cts.common.enable_auto_skew_target_for_local_skew -value true

# Clock Tree Targets
set CLK1_ROOT           i_clk
set CTS_MAX_FANOUT      20
set CLK1_BUFF_MAX_TRANS [expr $MAIN_CLK * 0.02]   ;# ~66.7 ps
set CLK1_SINK_MAX_TRANS [expr $MAIN_CLK * 0.02]   ;# ~66.7 ps
set CLK1_TARGET_SKEW    [expr $MAIN_CLK * 0.02]   ;# ~66.7 ps

# Apply Target Skew
set_clock_tree_options -clocks $CLK1_ROOT -target_skew $CLK1_TARGET_SKEW

# Apply Slew / Transition limits on clock path and flip-flop CP sinks
set_max_transition $CLK1_BUFF_MAX_TRANS [get_clocks ${CLK1_ROOT}] -clock_path
set_max_transition $CLK1_SINK_MAX_TRANS [get_pins -hierarchical -filter "is_clock_pin == true"]


###############################################################################
# End off init_design
###############################################################################
save_lib
save_block -compress -as ${DESIGN_FUSION}/${DESIGN_STAGE}

unsuppress_message ATTR-12

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


###############################################################################
# 4° stage = initial_drc
###############################################################################
set LAST_STAGE $DESIGN_STAGE
set DESIGN_STAGE "initial_drc"

compile_fusion -from $LAST_STAGE -to $DESIGN_STAGE
save_block -compress -as ${DESIGN_FUSION}/${DESIGN_STAGE}

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