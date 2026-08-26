########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: setup_dc.tcl
# Description: Design Compiler's script for setting up the project  
# Version: 2026-07-02
# Author: Arthur Ramalho
########################################################################

source ../../../scripts/setup_vars.tcl

########################################################################
# Work library
########################################################################

# Maps a design library to a UNIX directory.
# in this case, we're mapping the current working dir to save the outputs
# as long as we're using this script.

define_design_lib WORK -path .

########################################################################
# Multicore setup
########################################################################

set_host_options -max_cores 8

########################################################################
# Library setup
########################################################################

# Search path
set search_path "$DB_DIR $RTL_DIR"

# Target libraries
set design_libraries [glob ${DB_DIR}/*.db]
set target_library $design_libraries

# Synthetic library
# will be generated on the compile phases
set synthetic_library ""

# Link library
set link_library "* $target_library $synthetic_library"

########################################################################
# HDL setup
########################################################################

# More detailed messages during elaboration
set hdlin_reporting_level comprehensive

# Treat always blocks with set/reset as synchronous when applicable
set hdlin_ff_always_sync_set_reset true

# Warning/error control for inferred latches
set_app_var hdlin_check_no_latch true

########################################################################
# SVF setup for Formality
########################################################################

set_svf ${OUT_DIR}/${DESIGN}.svf

# Enable hierarchical guide map flow
set_app_var hdlin_enable_hier_map true
