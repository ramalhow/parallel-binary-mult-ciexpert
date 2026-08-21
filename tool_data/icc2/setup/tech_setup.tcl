########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: setup_dc.tcl
# Description: Technology Setup to Parallel Binary Multiplier to the test SAED32 EDK
# Version: 2026-07-02
# Author: Arthur Ramalho
#########################################################################

source ../../../scripts/setup_usr_vars.tcl

###############################################################################
# Power/Ground Variables
###############################################################################

# Set power and ground ports
set POWER_PORT              VDD  
set GROUND_PORT             VSS   

# Set power and ground nets
set POWER_NET               VDD    
set GROUND_NET              VSS

# Set Std cells PG pins
set STD_CELLS_POWER_PIN     VDD
set STD_CELLS_GROUND_PIN    VSS

###############################################################################
# Std cells Definitions
###############################################################################

# STD Cell site height
set SITE_HEIGHT              1.672

# TODO: definir isso tambem?
# STD Cell site width
#set SITE_WIDTH               0.200 ????

# Tie cells
set TIE_HIGH                 "TIEH_LVT"
set TIE_LOW                  "TIEL_LVT"

# Max fanout
set MAX_FANOUT              8

# Clock Buffers
set CLOCK_BUFFERS           "NBUFFX32_LVT NBUFFX16_LVT NBUFFX8_LVT NBUFFX4_LVT NBUFFX2_LVT \
							IBUFFX32_LVT IBUFFX16_LVT IBUFFX8_LVT IBUFFX4_LVT IBUFFX2_LVT"

set CLOCK_BUFFERS_INV       "INVX32_LVT INVX16_LVT INVX8_LVT INVX4_LVTINVX2_LVT INVX1_LVT INVX0_LVT"


# Delay cells
set DELAY_CELLS             "DELLN3X2_LVT DELLN2X2_LVT DELLN1X2_LVT"

# Filler cells
# By default, tool insert cells in order specified. Specify from the largest to smallest. 
set FILLER_CELLS          " SHFILL128_LVT \
                            SHFILL64_LVT \
			                SHFILL3_LVT \
			                SHFILL2_LVT \
			                SHFILL1_LVT "

# Decap cells
# By default, tool insert cells in order specified. Specify from the largest to smallest. 
set DECAP_CELLS            "DCAP_LVT"

# Antenna cells
set ANTENNA_DIODES          "ANTENNA_LVT"

###############################################################################
# TODO: descobrir onde tem spare, endcap e tap cells no pdk
# Spare cells
# set SPARE_CELLS            "GBUFFD1 \
#                             GINVD1 \
#                             GND2D1 \
#                             GNR2D1"

# set ENDCAP_CELLS            "GFILL1"

# TAP CELL (well/substrate)
set TAP_CELL                "GFILL"
set TAP_CELL_DISTANCE       "40"
# set IO_FILLER_CELLS         ""
###############################################################################


###############################################################################
# Finish tech_setup
###############################################################################
echo "********************************************************************************"
echo "********************************************************************************"
puts "\[VIRTUS-CC\] INFO: The Technology Setup for the ${DESIGN} has been completed."
echo "********************************************************************************"
echo "********************************************************************************"
