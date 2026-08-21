########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: setup_dc.tcl
# Description: Technology Setup to Parallel Binary Multiplier to the test SAED32 EDK
# Version: 2026-07-02
# Author: Arthur Ramalho
#########################################################################

set DESIGN      "parallel_binary_mult"

#set PRJT_BASE   "/home/arthur.alves/parallel-binary-mult-ciexpert"
set PRJT_BASE   "/home/xmen-aluno/physical_design_arthur/parallel-binary-mult-ciexpert"

set SDC_DIR     "${PRJT_BASE}/constraints"
set DB_DIR      "${PRJT_BASE}/db"
set DLIB_DIR    "${PRJT_BASE}/dlib"
set LEF_DIR     "${PRJT_BASE}/lef"
set LIBS_DIR    "${PRJT_BASE}/libs"
set NDM_DIR     "${PRJT_BASE}/ndm_lib"
set OUT_DIR     "${PRJT_BASE}/outputs"
set RPT_DIR     "${PRJT_BASE}/rpt"
set RTL_DIR     "${PRJT_BASE}/rtl"
set TECH_DIR    "${PRJT_BASE}/tech"
set ANT_DIR     "${PRJT_BASE}/tech"
set OUT_DIR     "${PRJT_BASE}/outputs"

###############################################################################
# Tech Files Variables
###############################################################################
set TECH_FILE           "${TECH_DIR}/saed32nm_1p9m.tf"
set REFERENCE_LIBRARY   [glob ${NDM_DIR}/*.ndm]

#-----------------------------------------------------------------------------------------------
# TLU plus file (similar to captable)
set TLUPLUS_TYP_FILE   "$TECH_DIR/saed32nm_1p9m_nominal.tluplus"
set MAX_TLUPLUS_FILE   "$TECH_DIR/saed32nm_1p9m_Cmax.tluplus"
set MIN_TLUPLUS_FILE   "$TECH_DIR/saed32nm_1p9m_Cmin.tluplus"
set TLUPLUS_MAP_FILE   "$TECH_DIR/saed32nm_tf_itf_tluplus.map"
#-----------------------------------------------------------------------------------------------

###############################################################################
# Fusion Compiler Settings
###############################################################################
set TCL_MCMM_SETUP_FILE ""

set ROUTING_LAYER_DIRECTION_OFFSET_LIST "{M1 horizontal} {M2 vertical} {M3 horizontal} {M4 vertical} {M5 horizontal} {M6 vertical} {M7 horizontal} {M8 vertical} {M9 horizontal} {MRDL vertical} "
set MIN_ROUTING_LAYER	  	  "M1"
set MAX_ROUTING_LAYER 		  "M8"
