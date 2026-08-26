########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: setup_fc.tcl
# Description: Technology Setup to Parallel Binary Multiplier to the test SAED32 EDK
# Version: 2026-07-02
# Author: Arthur Ramalho
#########################################################################

source ../../../scripts/setup_usr_vars.tcl


set TCL_MV_SETUP_FILE		""	;# A Tcl script placeholder for your MV setup commands,such as create_voltage_area,
								;# placement bound, power switch creation and level shifter insertion, etc   

set TCL_PG_CREATION_FILE	""	;# A Tcl script placeholder for your power ground network creation commands, 
								;# such as create_pg*, set_pg_strategy, compile_pg, etc

set TIE_LIB_CELL_PATTERN_LIST "*/TIE*"	;# A list of TIE lib cell patterns to be included for optimization;

set CTS_LIB_CELL_PATTERN_LIST 	"*/NBUFF*LVT */NBUFF*RVT */INVX*_LVT */INVX*_RVT */CG* */AOBUFX*_LVT */AOINV* */*DFF*" 	;# List of CTS lib cell patterns to be used by CTS;
					;# Please include repeaters, always-on repeaters (for MV-CTS), 
					;# and gates (for sizing pre-existing gates)/always-on buffers;
					;# Please also include flops as CCD can size flops to improve timing.
				   	;# example : set CTS_LIB_CELL_PATTERN_LIST "*/NBUF* */AOBUF* */AOINV* */SDFF*".
 
# Min clock routing layer for set_clock_routing_rules command which $CTS_NDR_RULE_NAME will be applied to.
set CTS_NDR_MIN_ROUTING_LAYER	"M4"

# Max clock routing layer for set_clock_routing_rules command which $CTS_NDR_RULE_NAME will be applied to.
set CTS_NDR_MAX_ROUTING_LAYER	"M5"


# Min routing layer for set_clock_routing_rules command which icc2rm_leaf will be applied to.
set CTS_LEAF_NDR_MIN_ROUTING_LAYER $CTS_NDR_MIN_ROUTING_LAYER

# Max routing layer for set_clock_routing_rules command which icc2rm_leaf will be applied to.
set CTS_LEAF_NDR_MAX_ROUTING_LAYER $CTS_NDR_MAX_ROUTING_LAYER 

lappend search_path ./scripts ./ORCA_TOP_design_data ./ORCA_TOP_constraints

set_host_options -max_cores 8
set sh_continue_on_error false

# If label is used, the following will be used as label name while $DESIGN_NAME is the block name
set INIT_DESIGN_BLOCK_NAME init_design			;# Name of the block to be saved for init_design.tcl
set PLACE_OPT_BLOCK_NAME place_opt			;# Name of the block to be saved for place_opt.tcl
set CLOCK_OPT_CTS_BLOCK_NAME clock_opt_cts		;# Name of the block to be saved for clock_opt_cts.tcl
set CLOCK_OPT_OPTO_BLOCK_NAME clock_opt_opto		;# Name of the block to be saved for clock_opt_opto.tcl
set CLOCK_OPT_BLOCK_NAME clock_opt      		;# CES: Name of the block to be saved after clock_opt
set ROUTE_AUTO_BLOCK_NAME route_auto			;# Name of the block to be saved for route_auto.tcl
set ROUTE_OPT_BLOCK_NAME route_opt			;# Name of the block to be saved for route_opt.tcl
set SIGNOFF_DRC_BLOCK_NAME signoff_drc 			;# Name of the block to be saved for signoff_drc.tcl
set CHIP_FINISH_BLOCK_NAME chip_finish			;# Name of the block to be saved for chip_finish.tcl
set PT_ECO_BLOCK_NAME pt_eco				;# Name of the block to be saved for pt_eco.tcl

set PT_ECO_FROM_BLOCK_NAME $ROUTE_OPT_BLOCK_NAME 	;# Name of the starting block name for the pt_eco step
set WRITE_DATA_BLOCK_NAME $CHIP_FINISH_BLOCK_NAME 	;# Name of the starting block for the write_data step


puts "RM-info: Completed script [info script]\n"