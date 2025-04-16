# activate waveform simulation

view wave

# format signal names in waveform

configure wave -signalnamewidth 1
configure wave -timeline 0
configure wave -timelineunits us

# add signals to waveform

#add wave -divider -height 20 {Top-level signals}
#add wave -bin UUT/CLOCK_50_I
#add wave -bin UUT/resetn
#add wave UUT/top_state
#add wave -uns UUT/UART_timer

add wave -divider -height 10 {SRAM signals}
add wave -uns UUT/SRAM_address
add wave -hex UUT/SRAM_write_data
add wave -bin UUT/SRAM_we_n
add wave -dec UUT/SRAM_read_data

add wave -divider -height 10 {milestone2}
add wave -dec UUT/m2_unit/m2_state
#add wave -dec UUT/m2_unit/Y_SEGMENT_counter
add wave -dec UUT/m2_unit/Y_buffer
#add wave -dec UUT/m2_unit/counter2
add wave -dec {UUT/m2_unit/read_address[0]}
add wave -dec {UUT/m2_unit/write_data_b[0]}
add wave -dec UUT/m2_unit/dp_ram_address_counter
add wave -dec UUT/m2_unit/block_counter
add wave -dec UUT/m2_unit/row_counter
add wave -dec UUT/m2_unit/count
add wave -dec UUT/m2_unit/c0
add wave -dec UUT/m2_unit/c1
add wave -dec UUT/m2_unit/c2
add wave -dec UUT/m2_unit/m1_term
add wave -dec UUT/m2_unit/m2_term
add wave -dec UUT/m2_unit/m3_term
add wave -dec UUT/m2_unit/m1_result
add wave -dec UUT/m2_unit/m2_result
add wave -dec UUT/m2_unit/m3_result
add wave -dec UUT/m2_unit/T_buff_sum

#add wave -divider -height 10 {Ushiftregisters}
#add wave -hex UUT/m1_unit/shift1
#add wave -hex UUT/m1_unit/shift2
#add wave -hex UUT/m1_unit/shift3
#add wave -hex UUT/m1_unit/shift4
#add wave -hex UUT/m1_unit/shift5
#add wave -hex UUT/m1_unit/shift6
#add wave -hex UUT/m1_unit/U_buffer_odd

#add wave -divider -height 10 {Vshiftregisters}
#add wave -hex UUT/m1_unit/vshift1
#add wave -hex UUT/m1_unit/vshift2
#add wave -hex UUT/m1_unit/vshift3
#add wave -hex UUT/m1_unit/vshift4
#add wave -hex UUT/m1_unit/vshift5
#add wave -hex UUT/m1_unit/vshift6
#add wave -hex UUT/m1_unit/V_buffer_odd

add wave -divider -height 10 {Ybuffer}
#add wave -hex UUT/m1_unit/Y_buffer
#add wave -hex UUT/m1_unit/U_buffer
#add wave -hex UUT/m1_unit/V_buffer

add wave -divider -height 10 {milestone1}
#add wave -dec UUT/m1_unit/m1_state
#add wave -dec UUT/m1_unit/adder1
#add wave -dec UUT/m1_unit/adder2
#add wave -dec UUT/m1_unit/adder3
#
#add wave -dec UUT/m1_unit/m1_coeff
#add wave -dec UUT/m1_unit/m1_term
#add wave -dec UUT/m1_unit/m1_result
#
#add wave -dec UUT/m1_unit/m2_coeff
#add wave -dec UUT/m1_unit/m2_term
#add wave -dec UUT/m1_unit/m2_result
#
#add wave -dec UUT/m1_unit/m3_coeff
#add wave -dec UUT/m1_unit/m3_term
#add wave -dec UUT/m1_unit/m3_result
#
#add wave -dec UUT/m1_unit/m1
#add wave -dec UUT/m1_unit/m2
#add wave -dec UUT/m1_unit/m3
#add wave -dec UUT/m1_unit/inter_U_buffer
#add wave -dec UUT/m1_unit/inter_V_buffer
#add wave -dec UUT/m1_unit/R_even
#add wave -hex UUT/m1_unit/red_even
#add wave -dec UUT/m1_unit/G_even
#add wave -hex UUT/m1_unit/green_even
#add wave -dec UUT/m1_unit/B_even
#add wave -hex UUT/m1_unit/blue_even
#add wave -dec UUT/m1_unit/R_odd
#add wave -hex UUT/m1_unit/red_odd
#add wave -dec UUT/m1_unit/G_odd
#add wave -hex UUT/m1_unit/green_odd
#add wave -dec UUT/m1_unit/B_odd
#add wave -hex UUT/m1_unit/blue_odd

#add wave -divider -height 10 {VGA signals}
#add wave -bin UUT/VGA_unit/VGA_HSYNC_O
#add wave -bin UUT/VGA_unit/VGA_VSYNC_O
#add wave -uns UUT/VGA_unit/pixel_X_pos
#add wave -uns UUT/VGA_unit/pixel_Y_pos
#add wave -hex UUT/VGA_unit/VGA_red
#add wave -hex UUT/VGA_unit/VGA_green
#add wave -hex UUT/VGA_unit/VGA_blue