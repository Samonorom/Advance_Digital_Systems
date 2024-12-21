onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /seven_segment_tb/clk_tb
add wave -noupdate /seven_segment_tb/reset_n_tb
add wave -noupdate /seven_segment_tb/address_tb
add wave -noupdate /seven_segment_tb/read_tb
add wave -noupdate /seven_segment_tb/readdata_tb
add wave -noupdate /seven_segment_tb/write_tb
add wave -noupdate /seven_segment_tb/writedata_tb
add wave -noupdate /seven_segment_tb/lamps_tb
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {206 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 220
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {98814 ps} {100063 ps}
