########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: scenarios.tcl
# Description: Script para a criação dos principais cenários/modes/corners do projeto
# Version: 2026-08-25
# Author: Arthur Ramalho
########################################################################

# Define the current design library to apply these scenarios
if {[string length $CURRENT_DLIB] > 0} {
    puts "\[INFO\] SCENARIOS: creating the scenarios to the ${CURRENT_DLIB} library"
    
} else {
    error "\[ERROR\] SCENARIOS: CURRENT_DLIB is NOT defined!"
    after 2000
}

# Removing any previous scenarios, modes and corners
remove_scenarios -all
remove_modes     -all
remove_corners   -all

# Creating modes by name
set modeNames [list slow_mode typical_mode ]
foreach modeName $modeNames {
    create_mode $modeName
}

# Creating corners by name
set cornerNames [list SS125_0P70 TT25_0P85 ]
foreach cornerName $cornerNames {
    create_corner $cornerName
}

########################################################################
# Corner Setup
########################################################################

#------------------------------------------------------------------
# Corner: Slow-Slow 125°C 0.70 V
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
                            -library ${CURRENT_DLIB}.dlib
#------------------------------------------------------------------

#------------------------------------------------------------------
# Corner: Typical-Typical 25°C 0.85 V
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
                            -library ${CURRENT_DLIB}.dlib
#------------------------------------------------------------------

########################################################################
# Scenario Setup
########################################################################

create_scenario -name wc -mode slow_mode    -corner SS125_0P70
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

#set_scenario_status -active true [all_scenarios]

#set_scenario_status -active true [all_scenarios]

# Removes duplicate Scenarios, Modes and Corners for the current block
remove_duplicate_timing_contexts

# Folders for the results
file mkdir ${OUT_DIR}/${CURRENT_DLIB}/
file mkdir ${RPT_DIR}/${CURRENT_DLIB}/

# Folders for the results
file mkdir ${OUT_DIR}/${CURRENT_DLIB}/
file mkdir ${RPT_DIR}/${CURRENT_DLIB}/

# Generates a TCL script to check the constraints of each mode, corner and scenario
#write_script -force -output ${OUT_DIR}/${CURRENT_DLIB}/${DESIGN}_wscript
#write_script -force -output ${OUT_DIR}/${CURRENT_DLIB}/${DESIGN}_wscript

# Write SDC to check the loaded constraints
write_sdc    -output ${OUT_DIR}/${CURRENT_DLIB}/write_sdc_${DESIGN}.sdc

###############################################################################
# Checks and reports
###############################################################################
check_timing          > ${RPT_DIR}/${CURRENT_DLIB}/check_timing.rpt
report_scenarios -all > ${RPT_DIR}/${CURRENT_DLIB}/report_scenarios.rpt
report_scenarios -all > ${RPT_DIR}/${CURRENT_DLIB}/report_scenarios.rpt

set scenarioNames [list wc tc]
foreach scenario $scenarioNames {
    current_scenario $scenario
    report_exceptions        > ${RPT_DIR}/${CURRENT_DLIB}/report_exceptions_$scenario.rpt
    report_case_analysis     > ${RPT_DIR}/${CURRENT_DLIB}/report_case_analysis_$scenario.rpt
    report_disable_timing    > ${RPT_DIR}/${CURRENT_DLIB}/report_disable_timing_$scenario.rpt
    report_exceptions        > ${RPT_DIR}/${CURRENT_DLIB}/report_exceptions_$scenario.rpt
    report_case_analysis     > ${RPT_DIR}/${CURRENT_DLIB}/report_case_analysis_$scenario.rpt
    report_disable_timing    > ${RPT_DIR}/${CURRENT_DLIB}/report_disable_timing_$scenario.rpt
}
