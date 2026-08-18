########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: run_dc.tcl
# Description: Design Compiler's full setup and compilation script
# Version: 2026-07-02
# Author: Arthur Ramalho
########################################################################

########################################################################
# Project Setup
########################################################################

# Source the setup file
source ../setup_dc.tcl

########################################################################
# Reading RTL
########################################################################
analyze -format verilog "${RTL_DIR}/${DESIGN}.v" -work WORK
elaborate ${DESIGN}

current_design ${DESIGN}

########################################################################
# SVF flow commands
########################################################################

set_verification_top

########################################################################
# Link and uniquify
########################################################################

link
uniquify

########################################################################
# Check design before synthesis
########################################################################

list_designs
current_design ${DESIGN}

########################################################################
# Load Constraints
########################################################################
source ../../../scripts/constraints.tcl

########################################################################
# Generating the precompile reports
########################################################################

# Logical folder separation for this prelayout phase
set PRELAYOUT_DIR "${RPT_DIR}/PRELAYOUT"

set STAGE "01_precompile"
file mkdir ${PRELAYOUT_DIR}/${STAGE}

check_design  > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_check_design.rpt
check_timing  > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_check_timing.rpt
report_clock  > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_clock.rpt

# Save unmapped/generic design
write_file -format ddc -hier -out ${OUT_DIR}/${DESIGN}_gtech.ddc

########################################################################
# COMPILATION PHASE 1
########################################################################

# Avoid assign statements in the mapped netlist
set_fix_multiple_port_nets -all -buffer_constants [all_designs]

# First compile
compile_ultra -incremental -no_autoungroup

########################################################################
# Reports from compilation phase 1
########################################################################

set STAGE "02_compile"
file mkdir ${PRELAYOUT_DIR}/${STAGE}

report_timing                       > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_timing.rpt
report_qor                          > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_qor.rpt
report_area -designware             > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_area_dw.rpt
report_area -hierarchy -nosplit     > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_area_hierarchy.rpt
report_power -verbose               > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_power.rpt
report_clock_gating                 > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_clock_gating.rpt
analyze_datapath                    > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_analyze_datapath.rpt

########################################################################
# COMPILATION PHASE 2 - INCREMENTAL
########################################################################

compile_ultra -incremental -no_autoungroup -timing_high_effort_script

########################################################################
# Reports from compilation phase 2
########################################################################

set STAGE "03_incrcompile"
file mkdir ${PRELAYOUT_DIR}/${STAGE}

report_timing                       > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_timing.rpt
report_qor                          > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_qor.rpt
report_power -verbose               > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_power.rpt
report_clock_gating                 > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_clock_gating.rpt

########################################################################
# COMPILATION PHASE 3 - AREA OPTMIZATION
########################################################################

optimize_netlist -area -no_boundary_optimization

########################################################################
# Reports from compilation phase 3
########################################################################

set STAGE "04_optnetlist"
file mkdir ${PRELAYOUT_DIR}/${STAGE}

report_timing                       > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_timing.rpt
report_qor                          > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_qor.rpt
report_power -verbose               > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_power.rpt
report_clock_gating                 > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_clock_gating.rpt

########################################################################
# Save the final design
########################################################################

# Save mapped design
file mkdir "${OUT_DIR}/PRE_LAYOUT"

write_file -format ddc     -hier -out ${OUT_DIR}/PRE_LAYOUT/${DESIGN}.ddc
write_file -format verilog -hier -out ${OUT_DIR}/PRE_LAYOUT/${DESIGN}.v

# Save constraints
write_sdc ${SDC_DIR}/${DESIGN}.sdc

# Save SDF
write_sdf ${OUT_DIR}/${DESIGN}.sdf
exec gzip -f ${OUT_DIR}/${DESIGN}.sdf

# Save parasitics only if running in topographical mode
if {[shell_is_in_topographical_mode]} {
    write_parasitics -format reduced -out ${OUT_DIR}/${DESIGN}_mapped.spf
}

########################################################################
# Final design report 
########################################################################

set STAGE "05_final"
file mkdir ${PRELAYOUT_DIR}/${STAGE}

# General checks
check_design                        > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_check_design.rpt
check_timing                        > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_check_timing.rpt

# Timing reports
report_constraint -all_violators -significant_digits 4 \
                                    > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_constraints_violators.rpt

report_timing -significant_digits 4 \
                                    > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_timing_setup.rpt

report_timing -delay_type min -significant_digits 4 \
                                    > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_timing_hold.rpt

# QoR reports
report_qor -significant_digits 4    > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_qor.rpt
report_clock_gating                 > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_clock_gating.rpt
report_disable_timing               > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_disable_timing.rpt

# Area and power
report_area -designware             > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_area_dw.rpt
report_area -hierarchy -nosplit     > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_area_hierarchy.rpt
report_power -hierarchy -verbose    > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_power.rpt

# Cells
report_cell                         > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_report_cell.rpt

########################################################################
# Inferred Latch Report
########################################################################

echo " " > ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_latch_inferred.rpt

redirect -tee ${PRELAYOUT_DIR}/${STAGE}/${DESIGN}_latch_inferred.rpt -append {
    echo "**********************************"
    echo "* Inferred Latches Report"
    echo "* Design Name: $DESIGN"
    echo "**********************************"
    echo " "

    echo "${DESIGN} has [sizeof_collection [all_registers -level_sensitive]] latches"
    echo " "

    if {[sizeof_collection [all_registers -level_sensitive]] > 0} {
        foreach instance [get_object_name [all_registers -level_sensitive]] {
            echo "Latch instance name: $instance -> latch cell name: [get_attr $instance ref_name]"
        }
    }
}

########################################################################
# Closing the SVF
########################################################################

set_svf -append ${OUT_DIR}/${DESIGN}.svf

########################################################################
############################ EXIT ######################################
########################################################################
echo "*********************************************************************************"
echo "*********************************************************************************"
puts "\[VIRTUS-CC\] Logic synthesis for ${DESIGN} has been completed."
echo "*********************************************************************************"
echo "*********************************************************************************"
start_gui
