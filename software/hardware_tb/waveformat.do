onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /testbench/clk
add wave -noupdate /testbench/rst
add wave -noupdate /testbench/i
add wave -noupdate /testbench/writedata
add wave -noupdate /testbench/vga_ball0/din_a
add wave -noupdate /testbench/vga_ball0/wa_a
add wave -noupdate /testbench/vga_ball0/din_g
add wave -noupdate /testbench/vga_ball0/wa_g
add wave -noupdate /testbench/vga_ball0/sp0/ra_a
add wave -noupdate /testbench/vga_ball0/sp0/dout_a
add wave -noupdate /testbench/vga_ball0/sp0/ra_g
add wave -noupdate /testbench/vga_ball0/sp0/dout_g
add wave -noupdate -radix unsigned /testbench/vga_ball0/sp0/down_counter
add wave -noupdate -radix unsigned /testbench/vga_ball0/sp0/shift_pos
add wave -noupdate /testbench/vga_ball0/sp0/sprite_offset
add wave -noupdate /testbench/vga_ball0/sp0/shift_reg
add wave -noupdate /testbench/vga_ball0/sp0/display_pixel
add wave -noupdate -radix unsigned /testbench/vga_ball0/sp0/vcount
add wave -noupdate -radix unsigned /testbench/vga_ball0/sp0/hcount
add wave -noupdate /testbench/vga_ball0/sp0/state
add wave -noupdate /testbench/vga_ball0/sp0/state_next
add wave -noupdate -radix unsigned /testbench/write
add wave -noupdate -radix unsigned /testbench/chipselect
add wave -noupdate -radix unsigned /testbench/address
add wave -noupdate /testbench/VGA_R
add wave -noupdate /testbench/VGA_G
add wave -noupdate /testbench/VGA_B
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3 ns} 0}
quietly wave cursor active 1
configure wave -namecolwidth 223
configure wave -valuecolwidth 89
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
WaveRestoreZoom {0 ns} {12 ns}


