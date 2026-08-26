
puts "\[INFO\] Running script: 0_init_design.tcl"
after 2000
source -echo -verbose ../0_init_design.tcl

puts "\[INFO\] Running script: 1_floorplan.tcl"
after 2000
source -echo -verbose ../1_floorplan.tcl

puts "\[INFO\] Running script: 2_placement.tcl"
after 2000
source -echo -verbose ../2_placement.tcl

puts "\[INFO\] Running script: 3_cts.tcl"
after 2000
source -echo -verbose ../3_cts.tcl

puts "\[INFO\] Running script: 4_route.tcl"
after 2000
source -echo -verbose ../4_route.tcl