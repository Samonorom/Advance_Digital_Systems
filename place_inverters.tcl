proc place_inverters {ro_count ro_length} {
    for {set i 0} {$i < $ro_count} {incr i} {
        set base_x [expr {$i * 10}]
        for {set j 0} {$j < $ro_length} {incr j} {
            set x [expr {$base_x + ($j % 5)}]
            set y [expr {$j / 5}]
            set inv_Y [expr {$j + 1}]
            # Construct the hierarchical name for each element in the chain
            set chain_element "ro_puf:puf|ring_oscillator:\\gen_ro:$i:ro|inverter:\\gen_inverters:$j:inv|output" 
            post_message "Placing $chain_element at ($x, $y)"
            set_location_assignment -to $chain_element "X${x}_Y${y}"
        }
    }
}

# Call the function with the number of ROs and the length of each RO
place_inverters 16 12