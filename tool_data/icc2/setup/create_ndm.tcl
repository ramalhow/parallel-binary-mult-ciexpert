
# ###############################################################################
# ###############################################################################
# #####                        create_ndm III                              ######
# ###############################################################################
# ###############################################################################
source ../../../scripts/setup_usr_vars.tcl

set DESIGN_STAGE "create_ndm"

set bus_delimeter {[]}
set sh_continue_on_error true 

set_app_options -as_user_default -name link.require_physical -value true; #<<<<<<<<<
set_app_options -as_user_default -name design.bus_delimiters -value $bus_delimeter; #<<<<<<<<<
set_app_options -as_user_default -name lib.logic_model.use_db_rail_names -value true; #<<<<<<<<<

create_workspace SAED32 -tech $TECH_DIR -flow exploration

set db_files [glob [join "${DB_DIR}/*.db"]]
read_db $db_files

set lef_files       [glob ${LEF_DIR}/*.lef]
read_lef $lef_files

group_libs

process_workspaces  -force -directory $NDM_DIR -output ${DESIGN_STAGE}.ndm

###############################################################################
# TODO: Antenna Setup
# Antenna Rules
###############################################################################
remove_workspace

create_workspace -flow edit $[glob ${NDM_DIR}/*.ndm]

check_workspace 

# Antenna properties

#current_lib TSMC_physical_only

#source ${ANT_DIR}/antennaRule_n65_9lm.tcl

#process_workspaces  -force -directory ${NDM_DIR} -output tsmcn65_9lmT2.ndm

#exec rm -rf ${NDM_DIR}/TSMC_physical_only.ndm
 
###############################################################################
###############################################################################
#####                   FINISH create_ndm                                ######
###############################################################################
###############################################################################
puts "Finished creating NDM Cell Library ../ndm_lib/tsmcn65_9lmT2.ndm"

