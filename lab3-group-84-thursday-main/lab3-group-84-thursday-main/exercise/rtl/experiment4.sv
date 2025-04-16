/*
Copyright by Henry Ko and Nicola Nicolici
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada
*/

`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

module experiment4 (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// switches                          ////////////
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// VGA interface                     ////////////
		output logic VGA_CLOCK_O,                 // VGA clock
		output logic VGA_HSYNC_O,                 // VGA H_SYNC
		output logic VGA_VSYNC_O,                 // VGA V_SYNC
		output logic VGA_BLANK_O,                 // VGA BLANK
		output logic VGA_SYNC_O,                  // VGA SYNC
		output logic[7:0] VGA_RED_O,              // VGA red
		output logic[7:0] VGA_GREEN_O,            // VGA green
		output logic[7:0] VGA_BLUE_O,              // VGA blue

		/////// PS2                               ////////////
		input logic PS2_DATA_I,                   // PS2 data
		input logic PS2_CLOCK_I                   // PS2 clock
);

`include "VGA_param.h"
parameter SCREEN_BORDER_OFFSET = 32;
parameter DEFAULT_MESSAGE_LINE = 280;
parameter DEFAULT_MESSAGE_START_COL = 360;
parameter KEYBOARD_MESSAGE_LINE = 320;
parameter KEYBOARD_MESSAGE_START_COL = 360;

logic resetn, enable;

logic [7:0] VGA_red, VGA_green, VGA_blue;
logic [9:0] pixel_X_pos;
logic [9:0] pixel_Y_pos;

logic [5:0] character_address;
logic rom_mux_output;

logic screen_border_on;

assign resetn = ~SWITCH_I[17];

logic [7:0] PS2_code, PS2_reg;
logic PS2_code_ready;

logic PS2_code_ready_buf;
logic PS2_make_code;

logic key_press;
logic [7:0] key_press_count;
logic number_press;

logic v_sync_prev;
logic v_sync_neg;

logic [7:0] PP_count;
logic [9:0] FFF_count;

logic [3:0] PP_tens;
logic [3:0] PP_ones;

assign PP_tens = (PP_count / 8'd10) % 8'd10;
assign PP_ones = PP_count % 8'd10;

logic [3:0] FFF_hundreds;
logic [3:0] FFF_tens;
logic [3:0] FFF_ones;

assign FFF_hundreds = (FFF_count / 10'd100) % 4'd10;
assign FFF_tens = (FFF_count / 10'd10) % 4'd10;
assign FFF_ones = FFF_count % 10'd10;

logic [3:0] current_digit;

logic [3:0] max_digit;
logic [9:0] max_FFF;
logic [7:0] max_PP;

logic [7:0] prev_PP;
logic [3:0] prev_digit;

logic [3:0] max_PP_tens;
logic [3:0] max_PP_ones;

assign max_PP_tens = (max_PP / 8'd10) % 8'd10;
assign max_PP_ones = max_PP % 8'd10;

logic [3:0] max_FFF_hundreds;
logic [3:0] max_FFF_tens;
logic [3:0] max_FFF_ones;

assign max_FFF_hundreds = (max_FFF / 10'd100) % 4'd10;
assign max_FFF_tens = (max_FFF / 10'd10) % 4'd10;
assign max_FFF_ones = max_FFF % 10'd10;


// PS/2 controller
PS2_controller ps2_unit (
	.Clock_50(CLOCK_50_I),
	.Resetn(resetn),
	.PS2_clock(PS2_CLOCK_I),
	.PS2_data(PS2_DATA_I),
	.PS2_code(PS2_code),
	.PS2_code_ready(PS2_code_ready),
	.PS2_make_code(PS2_make_code)
);

// Putting the PS2 code into a register
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
    if (resetn == 1'b0) begin
        PS2_code_ready_buf <= 1'b0;
        PS2_reg <= 8'd0;
        number_press <= 1'b0;
		  current_digit <= 4'b0;
		  prev_digit <= 4'b0;
    end else begin
        PS2_code_ready_buf <= PS2_code_ready;
        if (PS2_code_ready && ~PS2_code_ready_buf && PS2_make_code) begin
            if (PS2_code == 8'h45 || PS2_code == 8'h16 || PS2_code == 8'h1E || 
                PS2_code == 8'h26 || PS2_code == 8'h25 || PS2_code == 8'h2E || 
                PS2_code == 8'h36 || PS2_code == 8'h3D || PS2_code == 8'h3E || 
                PS2_code == 8'h46) begin
                // Scan code detected
                PS2_reg <= PS2_code;
                number_press <= 1'b1;
					prev_digit <= current_digit;
					 case (PS2_code)
						  8'h45:   current_digit = 4'd0; // 0
						  8'h16:   current_digit = 4'd1; // 1
						  8'h1E:   current_digit = 4'd2; // 2
						  8'h26:   current_digit = 4'd3; // 3
						  8'h25:   current_digit = 4'd4; // 4
						  8'h2E:   current_digit = 4'd5; // 5
						  8'h36:   current_digit = 4'd6; // 6
						  8'h3D:   current_digit = 4'd7; // 7
						  8'h3E:   current_digit = 4'd8; // 8
						  8'h46:   current_digit = 4'd9; // 9
						  default: current_digit = 4'd0; // default 0
					 endcase
            end else begin
                number_press <= 1'b0;
            end
        end else begin
            number_press <= 1'b0;
        end
    end
end


VGA_controller VGA_unit(
	.clock(CLOCK_50_I),
	.resetn(resetn),
	.enable(enable),

	.iRed(VGA_red),
	.iGreen(VGA_green),
	.iBlue(VGA_blue),
	.oCoord_X(pixel_X_pos),
	.oCoord_Y(pixel_Y_pos),
	
	// VGA Side
	.oVGA_R(VGA_RED_O),
	.oVGA_G(VGA_GREEN_O),
	.oVGA_B(VGA_BLUE_O),
	.oVGA_H_SYNC(VGA_HSYNC_O),
	.oVGA_V_SYNC(VGA_VSYNC_O),
	.oVGA_SYNC(VGA_SYNC_O),
	.oVGA_BLANK(VGA_BLANK_O)
);

logic [2:0] delay_X_pos;

always_ff @(posedge CLOCK_50_I or negedge resetn) begin
	if(!resetn) begin
		delay_X_pos[2:0] <= 3'd0;
	end else begin
		delay_X_pos[2:0] <= pixel_X_pos[2:0];
	end
end


always_ff @(posedge CLOCK_50_I or negedge resetn) begin //code for turning on screen off numeric keys
	if(!resetn) begin //if reset clicked flag is off
		key_press <= 1'b0;
		key_press_count <= 8'b0;
	end else if (number_press) begin //only when key is pressed flag is on
		key_press <= 1'b1;
		key_press_count <= key_press_count + 8'b1;
	end
end


always_ff @(posedge CLOCK_50_I or negedge resetn) begin //pp counter
	if(!resetn) begin 
		PP_count <= 8'd0;
		prev_PP <= 8'd0;
	end else if (number_press) begin 
		if(PP_count == 8'd99) begin
			PP_count <= 8'd0;
		end else begin
			PP_count <= PP_count + 8'd1;
		end
		prev_PP <= PP_count;
	end
end


always_ff @(posedge CLOCK_50_I or negedge resetn) begin //edge detection
	if(!resetn) begin 
		v_sync_prev <= 1'b1;
		v_sync_neg <= 1'b0;
	end else begin
		v_sync_prev <= VGA_VSYNC_O;
		v_sync_neg <= ~VGA_VSYNC_O && v_sync_prev;
	end
end


always_ff @(posedge CLOCK_50_I or negedge resetn) begin //FFF count
	if(!resetn) begin 
		FFF_count <= 10'd0;
	end else if (!key_press) begin
		FFF_count <= 10'd0;
	end else if (number_press) begin
		FFF_count <= 10'd0;
	end else if (v_sync_neg) begin
		if (FFF_count < 10'd999) begin
			FFF_count <= FFF_count + 10'd1;
		end else begin
			FFF_count <= FFF_count;
		end
	end
end


always_ff @(posedge CLOCK_50_I or negedge resetn) begin //max number pointer
	if(!resetn) begin 
		max_FFF <= 10'b0;
		max_PP <= 8'b0;
		max_digit <= 1'b0;
	end else if (number_press) begin
		if (FFF_count > max_FFF) begin
			max_FFF <= FFF_count;
			max_PP <= prev_PP + 8'd1;
			max_digit <= prev_digit;
		end
	end
end

function automatic [5:0] number_to_character(input[3:0] num);
	case(num)
		4'd0: number_to_character = 6'o60;
		4'd1: number_to_character = 6'o61;
		4'd2: number_to_character = 6'o62;
		4'd3: number_to_character = 6'o63;
		4'd4: number_to_character = 6'o64;
		4'd5: number_to_character = 6'o65;
		4'd6: number_to_character = 6'o66;
		4'd7: number_to_character = 6'o67;
		4'd8: number_to_character = 6'o70;
		4'd9: number_to_character = 6'o71;
		default: number_to_character = 6'o40;
	endcase
endfunction


// Character ROM
char_rom char_rom_unit (
	.Clock(CLOCK_50_I),
	.Character_address(character_address),
	.Font_row(pixel_Y_pos[2:0]),
	.Font_col(delay_X_pos[2:0]),
	.Rom_mux_output(rom_mux_output)
);

// this experiment is in the 800x600 @ 72 fps mode
assign enable = 1'b1;
assign VGA_CLOCK_O = ~CLOCK_50_I;

always_comb begin
	screen_border_on = 0;
	if (pixel_X_pos == SCREEN_BORDER_OFFSET || pixel_X_pos == H_SYNC_ACT-SCREEN_BORDER_OFFSET)
		if (pixel_Y_pos >= SCREEN_BORDER_OFFSET && pixel_Y_pos < V_SYNC_ACT-SCREEN_BORDER_OFFSET)
			screen_border_on = 1'b1;
	if (pixel_Y_pos == SCREEN_BORDER_OFFSET || pixel_Y_pos == V_SYNC_ACT-SCREEN_BORDER_OFFSET)
		if (pixel_X_pos >= SCREEN_BORDER_OFFSET && pixel_X_pos < H_SYNC_ACT-SCREEN_BORDER_OFFSET)
			screen_border_on = 1'b1;
end



// Display text
always_comb begin
    character_address = 6'o40; // Show space by default

    if (key_press) begin
        // 8 x 8 characters
        if (pixel_Y_pos[9:3] == (DEFAULT_MESSAGE_LINE >> 3)) begin
            // Reach the section where the text is displayed
            case (pixel_X_pos[9:3] - (DEFAULT_MESSAGE_START_COL >> 3))
                0: character_address = 6'o20; // P
                1: character_address = 6'o22; // R
                2: character_address = 6'o26; // V
                3: character_address = 6'o40; // space
                4: character_address = number_to_character(current_digit); // <D>
                5: character_address = 6'o40; // space
                6: character_address = number_to_character(PP_tens); // PP tens
                7: character_address = number_to_character(PP_ones); // PP units
                8: character_address = 6'o40; // space
                9: character_address = number_to_character(FFF_hundreds); // FFF hundreds
                10: character_address = number_to_character(FFF_tens); // FFF tens
                11: character_address = number_to_character(FFF_ones); // FFF units
                default: character_address = 6'o40; // space
            endcase
        end
	  end
    
	if(key_press_count >= 2) begin
    // 8 x 8 characters
    if (pixel_Y_pos[9:3] == (KEYBOARD_MESSAGE_LINE >> 3)) begin
        // Reach the section where the text is displayed
        case (pixel_X_pos[9:3] - (KEYBOARD_MESSAGE_START_COL >> 3))
            0: character_address = 6'o15; // M
            1: character_address = 6'o01; // A
            2: character_address = 6'o30; // X
            3: character_address = 6'o40; // space
            4: character_address = number_to_character(max_digit); // <D>
            5: character_address = 6'o40; // space
            6: character_address = number_to_character(max_PP_tens); // PP tens
            7: character_address = number_to_character(max_PP_ones); // PP units
            8: character_address = 6'o40; // space
            9: character_address = number_to_character(max_FFF_hundreds); // FFF hundreds
            10: character_address = number_to_character(max_FFF_tens); // FFF tens
            11: character_address = number_to_character(max_FFF_ones); // FFF units
            default: character_address = 6'o40; // space
        endcase
		 end
    end
end


// RGB signals
always_comb begin
		VGA_red = 8'h00;
		VGA_green = 8'h00;
		VGA_blue = 8'h00;

if(key_press) begin
		if (screen_border_on) begin
			// blue border
			VGA_blue = 8'hFF;
		end
		
		if (rom_mux_output) begin
			// yellow text
			VGA_red = 8'hFF;
			VGA_green = 8'hFF;
		end
	end
end

endmodule
