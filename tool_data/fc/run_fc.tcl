source -echo -verbose ../load_design.tcl

puts "\[INFO\] Running script: 1_design_syn.tcl"
after 2000
source -echo -verbose ../1_design_syn.tcl

puts "\[INFO\] Running script: 2_floorplan.tcl"
after 2000
source -echo -verbose ../2_floorplan.tcl

# puts "\[INFO\] Running script: 2_cts_opt.tcl"
# after 2000

# puts "\[INFO\] Running script: 3_route.tcl"
# after 2000

#puts "\[INFO\] Running script: 4_pos_route.tcl"
#after 2000