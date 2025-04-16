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

// This is the top module
// It performs debouncing on the push buttons using a 1kHz clock, and a 10-bit shift register
// When PB0 is pressed, it will stop/start the counter
module experiment5 (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock

		/////// pushbuttons/switches              ////////////
		input logic[3:0] PUSH_BUTTON_N_I,           // pushbuttons
		input logic[17:0] SWITCH_I,               // toggle switches

		/////// 7 segment displays/LEDs           ////////////
		output logic[6:0] SEVEN_SEGMENT_N_O[1:0], // 8 seven segment displays		
		output logic[8:0] LED_GREEN_O             // 9 green LEDs
);

parameter	MAX_1kHz_div_count = 24999,
		MAX_1Hz_div_count = 24999999;

logic resetn;

logic [15:0] clock_1kHz_div_count;
logic clock_1kHz, clock_1kHz_buf;

logic [24:0] clock_1Hz_div_count;
logic clock_1Hz, clock_1Hz_buf;

logic [9:0] debounce_shift_reg [3:0];
logic [3:0] push_button_status, push_button_status_buf;
logic [3:0] led_green;

logic [7:0] counter;
logic [6:0] value_7_segment0, value_7_segment1;
logic stop_count;
logic up;
logic down;
logic set;
logic led0;
logic led1;
logic led2;
logic led3;
logic led4;
logic led5;
logic led6;
logic led7;
logic led8;

assign resetn = ~SWITCH_I[17];

// Clock division for 1kHz clock
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1kHz_div_count <= 16'd0;
	end else begin
		if (clock_1kHz_div_count < MAX_1kHz_div_count) begin
			clock_1kHz_div_count <= clock_1kHz_div_count + 16'd1;
		end else 
			clock_1kHz_div_count <= 16'd0;
	end
end

always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1kHz <= 1'b1;
	end else begin
		if (clock_1kHz_div_count == 16'd0) 
			clock_1kHz <= ~clock_1kHz;
	end
end

always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1kHz_buf <= 1'b1;	
	end else begin
		clock_1kHz_buf <= clock_1kHz;
	end
end

// Clock division for 1Hz clock
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1Hz_div_count <= 25'd0;
	end else begin
		if (clock_1Hz_div_count < MAX_1Hz_div_count) begin
			clock_1Hz_div_count <= clock_1Hz_div_count + 25'd1;
		end else 
			clock_1Hz_div_count <= 25'd0;		
	end
end

always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1Hz <= 1'b1;
	end else begin
		if (clock_1Hz_div_count == 25'd0) 
			clock_1Hz <= ~clock_1Hz;
	end
end

always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		clock_1Hz_buf <= 1'b1;	
	end else begin
		clock_1Hz_buf <= clock_1Hz;
	end
end

// Shift register for debouncing
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		debounce_shift_reg[0] <= 10'd0;
		debounce_shift_reg[1] <= 10'd0;
		debounce_shift_reg[2] <= 10'd0;
		debounce_shift_reg[3] <= 10'd0;						
	end else begin
		if (clock_1kHz_buf == 1'b0 && clock_1kHz == 1'b1) begin
			debounce_shift_reg[0] <= {debounce_shift_reg[0][8:0], ~PUSH_BUTTON_N_I[0]};
			debounce_shift_reg[1] <= {debounce_shift_reg[1][8:0], ~PUSH_BUTTON_N_I[1]};
			debounce_shift_reg[2] <= {debounce_shift_reg[2][8:0], ~PUSH_BUTTON_N_I[2]};
			debounce_shift_reg[3] <= {debounce_shift_reg[3][8:0], ~PUSH_BUTTON_N_I[3]};
		end
	end
end

// push_button_status will contained the debounced signal
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		push_button_status <= 4'h0;
		push_button_status_buf <= 4'h0;
	end else begin
		push_button_status_buf <= push_button_status;
		push_button_status[0] <= |debounce_shift_reg[0];
		push_button_status[1] <= |debounce_shift_reg[1];
		push_button_status[2] <= |debounce_shift_reg[2];
		push_button_status[3] <= |debounce_shift_reg[3];						
	end
end

// Push button status is checked here for controlling the counter
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		led_green <= 4'h0;
		stop_count <= 1'b0;
		up <= 1'b1;
		down <= 1'b0;
		set <= 1'b0;
	end else begin
		if (push_button_status_buf[0] == 1'b0 && push_button_status[0] == 1'b1) begin //button 0 to stop the counter
			led_green[0] <= ~led_green[0];		
			stop_count <= ~stop_count;
			set <= 1'b0;
		end
		if (push_button_status_buf[1] == 1'b0 && push_button_status[1] == 1'b1) begin // button 1 to count up
			led_green[1] <= ~led_green[1];
			up <= 1'b1;
			down <= 1'b0;
		end
		if (push_button_status_buf[2] == 1'b0 && push_button_status[2] == 1'b1) begin //button 2 to count down
			led_green[2] <= ~led_green[2];
			up <= 1'b0;
			down <= 1'b1;
		end
		if (push_button_status_buf[3] == 1'b0 && push_button_status[3] == 1'b1) begin //button 2 to count down
			led_green[3] <= ~led_green[3];
			set <= 1'b1;
		end
	end
end

// Counter is incremented here
always_ff @ (posedge CLOCK_50_I or negedge resetn) begin
	if (resetn == 1'b0) begin
		counter <= 8'h00;
	end else begin
		if (clock_1Hz_buf == 1'b0 && clock_1Hz == 1'b1 && stop_count == 1'b0) begin
			counter[3:0] <= counter[3:0] + 8'd1;
			if (up) begin
				if(counter[7:4] == 8'd5 && counter[3:0] == 8'd5) begin
					counter[7:4] <= 8'd0;
					counter[3:0] <= 8'd0;
				end else if (counter[3:0] == 8'd5) begin
					counter[3:0] <= 8'd0;
					counter[7:4] <= counter[7:4] + 8'd1;
				end else begin
					counter[3:0] <= counter[3:0] + 8'd1;
				end
			end else if (down) begin
				if (counter[7:4] == 8'd0 && counter[3:0] == 8'd0) begin
					counter[7:4] <= 8'd5;
					counter[3:0] <= 8'd5;
				end else if (counter[3:0] == 8'd0) begin
					counter[3:0] <= 8'd5;
					counter[7:4] <= counter[7:4] - 8'd1;
				end else begin
					counter[3:0] <= counter[3:0] - 8'd1;
				end
			end
		end
		if(stop_count == 1'b1 && set == 1'b1)begin
			counter[7:4] <= 8'd3;
			counter[3:0] <= 8'd3;
		end
	end
end

always_ff begin
led0 <= 1'd0;
led1 <= 1'd0;
led2 <= 1'd0;
led3 <= 1'd0;
led4 <= 1'd0;
led5 <= 1'd0;
led6 <= 1'd0;
led7 <= 1'd0;
led8 <= 1'd0;
	if(&SWITCH_I[3:0]) begin
		led0 <= 1'd1;
		end
	if (^SWITCH_I[1:0]) begin
		led1 <= 1'd1;
		end
	if (~^SWITCH_I[3:2]) begin
		led2 <= 1'd1;
		end
	if (^SWITCH_I[10:4]) begin
		led3 <= 1'd1;
		end
	if (~|SWITCH_I[10:4]) begin
		led4 <= 1'd1;
		end
	if (&SWITCH_I[10:4]) begin
		led5 <= 1'd1;
		end
	if (&SWITCH_I[15:11]) begin
		led6 <= 1'd1;
		end
	if (~|SWITCH_I[15:11]) begin
		led7 <= 1'd1;
		end
	if (^SWITCH_I[15:11]) begin
		led8 <= 1'd1;
		end
end

// Instantiate modules for converting hex number to 7-bit value for the 7-segment display
convert_hex_to_seven_segment unit0 (
	.hex_value(counter[3:0]), 
	.converted_value(value_7_segment0)
);

convert_hex_to_seven_segment unit1 (
	.hex_value(counter[7:4]), 
	.converted_value(value_7_segment1)
);

assign	SEVEN_SEGMENT_N_O[0] = value_7_segment0,
		SEVEN_SEGMENT_N_O[1] = value_7_segment1;

//assign LED_GREEN_O = {1'b0, ~PUSH_BUTTON_N_I[3], led_green[3], ~PUSH_BUTTON_N_I[2], led_green[2], ~PUSH_BUTTON_N_I[1], led_green[1], ~PUSH_BUTTON_N_I[0], led_green[0]};
assign LED_GREEN_O = {led8,led7,led6,led5,led4,led3,led2,led1,led0};


endmodule
