source -echo -verbose ../load_design.tcl

puts "\[INFO\] Running script: 1_logic_syn.tcl"
after 2000
source -echo -verbose ../1_logic_syn.tcl

puts "\[INFO\] Running script: 2_floorplan.tcl"
after 2000
source -echo -verbose ../2_floorplan.tcl

puts "\[INFO\] Running script: 3_cts.tcl"
after 2000
source -echo -verbose ../3_cts.tcl

puts "\[INFO\] Running script: 4_route.tcl"
after 2000
source -echo -verbose ../4_route.tcl

#puts "\[INFO\] Running script: 5_pos_route.tcl"
#after 2000