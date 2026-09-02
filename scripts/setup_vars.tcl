########################################################################
# Project: CI Expert 2026 - Parallel Binary Multiplier
# Id: setup_usr_vars.tcl
# Description: Defines user environment variables and project directory paths,
#              for Synopsys synthesis and physical design flows. 
# Version: 2026-08-25
# Author: Arthur Ramalho
#########################################################################

set DESIGN      "parallel_binary_mult"

set PRJT_BASE   "/home/arthur.alves/parallel-binary-mult-ciexpert"
#set PRJT_BASE   "/home/xmen-aluno/physical_design_arthur/parallel-binary-mult-ciexpert"

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

echo "*****************************************************************************************"
puts "\[INFO\] SETUP: All the user variables and paths haven been defined successfully."
echo "*****************************************************************************************"
