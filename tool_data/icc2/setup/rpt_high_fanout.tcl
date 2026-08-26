set high_fanout $MAX_FANOUT
#set high_fanout [get_attribute [current_design] max_fanout]

echo "################################################################################"
echo "# INFO: Reporting all nets with fanout > $high_fanout (including clock nets)"
echo "################################################################################"

# *** NOTE *** Fixed to work for hierarchical design
set gan [get_nets -top_net_of_hierarchical_group -hierarchical]

foreach_in_collection gg $gan {
    set ggname [get_attribute $gg full_name]
    set gpins [get_pins -leaf -quiet -of $gg]
    set gpins_in [filter_collection $gpins "direction==in"]
    set gpins_in_soc [sizeof_collection $gpins_in]

    if { $gpins_in_soc > $high_fanout } {
        echo "INFO: Net $ggname is a high fanout net $gpins_in_soc greater than $high_fanout connections"
    }
}