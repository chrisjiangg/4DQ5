`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

module milestone1 (
		/////// board clocks                      ////////////
		input logic CLOCK_50_I,                   // 50 MHz clock
		
		/////// SRAM Interface                    ////////////
		input logic [15:0] SRAM_read_data,
		input logic Resetn,
		input logic start,
		output logic stop,
		output logic SRAM_we_n,
		output logic [15:0] SRAM_write_data,
		output logic [17:0] SRAM_address
		
);

milestone1_state m1_state;


//Milestone 1
logic [17:0] counter;
logic [17:0] Y_SEGMENT_counter;
logic [17:0] U_SEGMENT_counter;
logic [17:0] V_SEGMENT_counter;
logic [17:0] RGB_SEGMENT_counter;
logic [17:0] counter2;
logic [17:0] stop_counter;


//buffers to store values
logic [15:0] Y_buffer;

//U
logic [31:0] shift1;
logic [31:0] shift2;
logic [31:0] shift3;
logic [31:0] shift4;
logic [31:0] shift5;
logic [31:0] shift6;

logic [31:0] U_buffer_odd;

//V
logic [31:0] vshift1;
logic [31:0] vshift2;
logic [31:0] vshift3;
logic [31:0] vshift4;
logic [31:0] vshift5;
logic [31:0] vshift6;

logic [31:0] V_buffer_odd;

logic [31:0] adder1;
logic [31:0] adder2;
logic [31:0] adder3;
logic [31:0] m1;
logic [31:0] m2;
logic [31:0] m3;
logic [31:0] m1_coeff;
logic [31:0] m2_coeff;
logic [31:0] m3_coeff;
logic [31:0] m1_term;
logic [31:0] m2_term;
logic [31:0] m3_term;
logic [63:0] m1_result_long;
logic [63:0] m2_result_long;
logic [63:0] m3_result_long;
logic [31:0] m1_result;
logic [31:0] m2_result;
logic [31:0] m3_result;
logic [31:0] inter_U_buffer;
logic [31:0] inter_V_buffer;
logic [31:0] R_even;
logic [31:0] G_even;
logic [31:0] B_even;
logic [31:0] R_odd;
logic [31:0] G_odd;
logic [31:0] B_odd;
logic [31:0] inter_U;
logic [31:0] inter_V;


logic [7:0] red_even;
logic [7:0] red_odd;
logic [7:0] green_even;
logic [7:0] green_odd;
logic [7:0] blue_even;
logic [7:0] blue_odd;

//multipliers
assign m1_result_long = $signed(m1_coeff) * $signed(m1_term);
assign m1_result = m1_result_long[31:0];

assign m2_result_long = $signed(m2_coeff) * $signed(m2_term);
assign m2_result = m2_result_long[31:0];

assign m3_result_long = $signed(m3_coeff) * $signed(m3_term);
assign m3_result = m3_result_long[31:0];

//clipping
assign red_even = R_even[31] ? 8'd0 : |R_even[30:24] ? 8'd255 : R_even[23:16];
assign red_odd = R_odd[31] ? 8'd0 : |R_odd[30:24] ? 8'd255 : R_odd[23:16];
assign green_even = G_even[31] ? 8'd0 : |G_even[30:24] ? 8'd255 : G_even[23:16];
assign green_odd = G_odd[31] ? 8'd0 : |G_odd[30:24] ? 8'd255 : G_odd[23:16];
assign blue_even = B_even[31] ? 8'd0 : |B_even[30:24] ? 8'd255 : B_even[23:16];
assign blue_odd = B_odd[31] ? 8'd0 : |B_odd[30:24] ? 8'd255 : B_odd[23:16];

always_comb begin
	adder1 = 32'b0;
	adder2 = 32'b0;
	adder3 = 32'b0;
	inter_U = 32'b0;
	inter_V = 32'b0;
	
	if(m1_state == S_LEADIN_8)begin
		adder1 = shift1 + shift6;
		adder2 = shift2 + shift5;
		adder3 = shift3 + shift4;
	end
	else if(m1_state == S_LEADIN_9)begin
		adder1 = vshift1 + vshift6;
		adder2 = vshift2 + vshift5;
		adder3 = vshift3 + vshift4;
		inter_U = $signed(m1_result + m2_result + m3_result + c2) >>> 8;
	end
	else if(m1_state == S_LEADIN_10)begin
		inter_V = $signed(m1_result + m2_result + m3_result + c2) >>> 8;
	end
	else if(m1_state == S_COMMON_0)begin
		adder1 = shift1 + shift6;
		adder2 = shift2 + shift5;
		adder3 = shift3 + shift4;
	end
	else if(m1_state == S_COMMON_1)begin
		adder1 = vshift1 + vshift6;
		adder2 = vshift2 + vshift5;
		adder3 = vshift3 + vshift4;
		inter_U = $signed(m1_result + m2_result + m3_result + c2) >>> 8;
	end
	else if(m1_state == S_COMMON_2)begin
		inter_V = $signed(m1_result + m2_result + m3_result + c2) >>> 8;
	end
	else if(m1_state == S_COMMON_7)begin
		adder1 = shift1 + shift6;
		adder2 = shift2 + shift5;
		adder3 = shift3 + shift4;
	end
	else if(m1_state == S_COMMON_8)begin
		adder1 = vshift1 + vshift6;
		adder2 = vshift2 + vshift5;
		adder3 = vshift3 + vshift4;
		inter_U = $signed(m1_result + m2_result + m3_result + c2) >>> 8;
	end
	else if(m1_state == S_COMMON_9)begin
		inter_V = $signed(m1_result + m2_result + m3_result + c2) >>> 8;
	end
end

always @(posedge CLOCK_50_I or negedge Resetn) begin
	if (~Resetn) begin
		m1_state <= M1_IDLE;
		
		//INITIALIZE ALL SIGNALS
		SRAM_we_n <= 1'b1;
		
		counter <= 18'b1;
		Y_SEGMENT_counter <= 18'b0;
		U_SEGMENT_counter <= 18'b0;
		V_SEGMENT_counter <= 18'b0;
		RGB_SEGMENT_counter <= 18'b0;
		counter2 <= 18'b0;
		stop_counter <= 18'd0;
		
		Y_buffer <= 16'b0;

		//U
		shift1 <= 32'b0;
		shift2 <= 32'b0;
		shift3 <= 32'b0;
		shift4 <= 32'b0;
		shift5 <= 32'b0;
		shift6 <= 32'b0;
		
		U_buffer_odd <= 32'b0;
		
		//V
		vshift1 <= 32'b0;
		vshift2 <= 32'b0;
		vshift3 <= 32'b0;
		vshift4 <= 32'b0;
		vshift5 <= 32'b0;
		vshift6 <= 32'b0;
		
		V_buffer_odd <= 32'b0;
		
		//multipliers
		m1 <= 32'b0;
		m2 <= 32'b0;
		m3 <= 32'b0;
		m1_coeff <= 32'b0;
		m2_coeff <= 32'b0;
		m3_coeff <= 32'b0;
		m1_term <= 32'b0;
		m2_term <= 32'b0;
		m3_term <= 32'b0;
	
		inter_U_buffer <= 32'b0;
		inter_V_buffer <= 32'b0;
		R_even <= 32'b0;
		G_even <= 32'b0;
		B_even <= 32'b0;
		R_odd <= 32'b0;
		G_odd <= 32'b0;
		B_odd <= 32'b0;
		stop <= 1'b0;
		
	end else begin
	
		case (m1_state)
		M1_IDLE: begin
			if(start)begin
				SRAM_address <= Y_SEGMENT + Y_SEGMENT_counter;
				Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
				counter2 <= counter2;
				m1_state <= S_LEADIN_0;
			end
		end
		
		S_LEADIN_0: begin
			SRAM_address <= U_SEGMENT + U_SEGMENT_counter;
			U_SEGMENT_counter <= U_SEGMENT_counter + counter;
			m1_state <= S_LEADIN_1;
		end
		
		S_LEADIN_1: begin
			SRAM_address <= V_SEGMENT + V_SEGMENT_counter;
			V_SEGMENT_counter <= V_SEGMENT_counter + counter;
			m1_state <= S_LEADIN_2;
		end
		
		S_LEADIN_2: begin
			SRAM_address <= U_SEGMENT + U_SEGMENT_counter;
			U_SEGMENT_counter <= U_SEGMENT_counter + counter;
			Y_buffer <= SRAM_read_data;
			m1_state <= S_LEADIN_3;
		end
		
		S_LEADIN_3: begin
			SRAM_address <= V_SEGMENT + V_SEGMENT_counter;
			V_SEGMENT_counter <= V_SEGMENT_counter + counter;
			shift3 <= SRAM_read_data[15:8];
			shift4 <= SRAM_read_data[15:8];
			shift5 <= SRAM_read_data[15:8];
			shift6 <= SRAM_read_data[7:0];
			m1_state <= S_LEADIN_4;
		end
		
		S_LEADIN_4: begin
			vshift3 <= SRAM_read_data[15:8];
			vshift4 <= SRAM_read_data[15:8];
			vshift5 <= SRAM_read_data[15:8];
			vshift6 <= SRAM_read_data[7:0];
			m1_state <= S_LEADIN_5;
		end
		
		S_LEADIN_5: begin
			shift1 <= shift3;
			shift2 <= shift4;
			shift3 <= shift5;
			shift4 <= shift6;
			shift5 <= SRAM_read_data[15:8];
			shift6 <= SRAM_read_data[7:0];
			m1_state <= S_LEADIN_6;
		end
		
		S_LEADIN_6: begin
			vshift1 <= vshift3;
			vshift2 <= vshift4;
			vshift3 <= vshift5;
			vshift4 <= vshift6;
			vshift5 <= SRAM_read_data[15:8];
			vshift6 <= SRAM_read_data[7:0];
			m1_coeff <= a;
			m1_term <= {24'd0,Y_buffer[15:8]} - c1;
			m2_coeff <= h;
			m2_term <= shift3 - c2;
			m3_coeff <= e; 
			m3_term <= shift3 - c2;
			m1_state <= S_LEADIN_7;
		end
		
		S_LEADIN_7: begin
			m1_coeff <= f;
			m1_term <= vshift3 - c2;
			m2_coeff <= c;
			m2_term <= vshift3 - c2;
			m1 <= m1_result;
			m2 <= m2_result;
			m3 <= m3_result;
			m1_state <= S_LEADIN_8;
		end
		
		S_LEADIN_8: begin
			SRAM_address <= Y_SEGMENT + Y_SEGMENT_counter;
			Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
			counter2 <= counter2+ counter;
			m1_coeff <= y;
			m1_term <= adder1;
			m2_coeff <= x;
			m2_term <= adder2;
			m3_coeff <= z;
			m3_term <= adder3;
			R_even <= m1 + m2_result;
			G_even <= m1 + m3 + m1_result;
			B_even <= m1 + m2;
			m1_state <= S_LEADIN_9;
		end
		
		S_LEADIN_9: begin
			SRAM_address <= U_SEGMENT + U_SEGMENT_counter;
			U_SEGMENT_counter <= U_SEGMENT_counter + counter;
			m1_coeff <= y;
			m1_term <= adder1;
			m2_coeff <= x;
			m2_term <= adder2;
			m3_coeff <= z;
			m3_term <= adder3;
			inter_U_buffer <= inter_U;
			m1_state <= S_LEADIN_10;
		end
		
		S_LEADIN_10: begin
			SRAM_address <= V_SEGMENT + V_SEGMENT_counter;
			V_SEGMENT_counter <= V_SEGMENT_counter + counter;
			m1_coeff <= a;
			m1_term <= {24'd0,Y_buffer[7:0]} - c1;
			m2_coeff <= h;
			m2_term <= inter_U_buffer - c2;
			m3_coeff <= e;
			m3_term <= inter_U_buffer - c2;
			inter_V_buffer <= inter_V;
			m1_state <= S_LEADIN_11;
		end
		
		S_LEADIN_11: begin
			Y_buffer <= SRAM_read_data;
			m1_coeff <= f;
			m1_term <= inter_V_buffer - c2;
			m2_coeff <= c;
			m2_term <= inter_V_buffer - c2;
			m1 <= m1_result;
			m2 <= m2_result;
			m3 <= m3_result;
			m1_state <= S_LEADIN_12;
		end
		
		S_LEADIN_12: begin
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_SEGMENT + RGB_SEGMENT_counter;
			RGB_SEGMENT_counter <= RGB_SEGMENT_counter + counter;
			SRAM_write_data <= {red_even,green_even};
			shift1 <= shift2;
			shift2 <= shift3;
			shift3 <= shift4;
			shift4 <= shift5;
			shift5 <= shift6;
			shift6 <= SRAM_read_data[15:8];
			U_buffer_odd <= SRAM_read_data[7:0];
			R_odd <= m1 + m2_result;
			G_odd <= m1 + m3 + m1_result;
			B_odd <= m1 + m2;
			m1_state <= S_LEADIN_13;
		end
			
		S_LEADIN_13: begin
			SRAM_address <= RGB_SEGMENT + RGB_SEGMENT_counter;
			RGB_SEGMENT_counter <= RGB_SEGMENT_counter + counter;
			SRAM_write_data <= {blue_even,red_odd};
			vshift1 <= vshift2;
			vshift2 <= vshift3;
			vshift3 <= vshift4;
			vshift4 <= vshift5;
			vshift5 <= vshift6;
			vshift6 <= SRAM_read_data[15:8];
			V_buffer_odd <= SRAM_read_data[7:0];
			m1_coeff <= a;
			m1_term <= {24'd0,Y_buffer[15:8]} - c1;
			m2_coeff <= h;
			m2_term <= shift3 - c2;
			m3_coeff <= e; 
			m3_term <= shift3 - c2;
			m1_state <= S_LEADIN_14;
		end
		
		S_LEADIN_14: begin
				m1_coeff <= f;
				m1_term <= vshift3 - c2;
				m2_coeff <= c;
				m2_term <= vshift3 - c2;
				m1 <= m1_result;
				m2 <= m2_result;
				m3 <= m3_result;
				SRAM_address <= RGB_SEGMENT + RGB_SEGMENT_counter;
				RGB_SEGMENT_counter <= RGB_SEGMENT_counter + counter;
				SRAM_write_data <= {green_odd,blue_odd};
				m1_state <= S_COMMON_0;

		end
		
		S_COMMON_0: begin
			SRAM_we_n <= 1'b1;
			if(counter2 < 18'sd159) begin
				SRAM_address <= Y_SEGMENT + Y_SEGMENT_counter;
				Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
				counter2 <= counter2+ counter;
			end
				m1_coeff <= y;
				m1_term <= adder1;
				m2_coeff <= x;
				m2_term <= adder2;
				m3_coeff <= z;
				m3_term <= adder3;
				R_even <= m1 + m2_result;
				G_even <= m1 + m3 + m1_result;
				B_even <= m1 + m2;
				m1_state <= S_COMMON_1;
		end
		
		S_COMMON_1: begin
			m1_coeff <= y;
			m1_term <= adder1;
			m2_coeff <= x;
			m2_term <= adder2;
			m3_coeff <= z;
			m3_term <= adder3;
			inter_U_buffer <= inter_U;
			m1_state <= S_COMMON_2;
		end
		
		S_COMMON_2: begin
			m1_coeff <= a;
			m1_term <= {24'd0,Y_buffer[7:0]} - c1;
			m2_coeff <= h;
			m2_term <= inter_U_buffer - c2;
			m3_coeff <= e;
			m3_term <= inter_U_buffer - c2;
			inter_V_buffer <= inter_V;
			m1_state <= S_COMMON_3;
		end
		
		S_COMMON_3: begin
			if(counter2 < 18'sd159)begin
				Y_buffer <= SRAM_read_data;
			end
			m1_coeff <= f;
			m1_term <= inter_V_buffer - c2;
			m2_coeff <= c;
			m2_term <= inter_V_buffer - c2;
			m1 <= m1_result;
			m2 <= m2_result;
			m3 <= m3_result;
			m1_state <= S_COMMON_4;
		end
		
		S_COMMON_4: begin
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_SEGMENT + RGB_SEGMENT_counter;
			RGB_SEGMENT_counter <= RGB_SEGMENT_counter + counter;
			SRAM_write_data <= {red_even, green_even};
			R_odd <= m1 + m2_result;
			G_odd <= m1 + m3 + m1_result;
			B_odd <= m1 + m2;
			m1_state <= S_COMMON_5;
			if(counter2 > 18'sd156)begin
				shift1 <= shift2;
				shift2 <= shift3;
				shift3 <= shift4;
				shift4 <= shift5;
				shift5 <= shift6;
				shift6 <= shift6;
			end
			else begin
				shift1 <= shift2;
				shift2 <= shift3;
				shift3 <= shift4;
				shift4 <= shift5;
				shift5 <= shift6;
				shift6 <= U_buffer_odd[7:0];
			end
		end

		S_COMMON_5: begin
			SRAM_address <= RGB_SEGMENT + RGB_SEGMENT_counter;
			RGB_SEGMENT_counter <= RGB_SEGMENT_counter + counter;
			SRAM_write_data <= {blue_even, red_odd};
			m1_coeff <= a;
			m1_term <= {24'd0,Y_buffer[15:8]} - c1;
			m2_coeff <= h;
			m2_term <= shift3 - c2;
			m3_coeff <= e; 
			m3_term <= shift3 - c2;
			m1_state <= S_COMMON_6;
			if(counter2 > 18'sd156)begin
				vshift1 <= vshift2;
				vshift2 <= vshift3;
				vshift3 <= vshift4;
				vshift4 <= vshift5;
				vshift5 <= vshift6;
				vshift6 <= vshift6;
			end
			else begin
				vshift1 <= vshift2;
				vshift2 <= vshift3;
				vshift3 <= vshift4;
				vshift4 <= vshift5;
				vshift5 <= vshift6;
				vshift6 <= V_buffer_odd[7:0];
			end
		end
		
		S_COMMON_6: begin
				m1_coeff <= f;
				m1_term <= vshift3 - c2;
				m2_coeff <= c;
				m2_term <= vshift3 - c2;
				m1 <= m1_result;
				m2 <= m2_result;
				m3 <= m3_result;
				if(counter2 == 18'sd159)begin
					SRAM_address <= RGB_SEGMENT + RGB_SEGMENT_counter;
					RGB_SEGMENT_counter <= RGB_SEGMENT_counter + counter;
					SRAM_write_data <= {green_odd,blue_odd};
					m1_state <= S_LEADOUT_0; 
				end
				else begin
					SRAM_address <= RGB_SEGMENT + RGB_SEGMENT_counter;
					RGB_SEGMENT_counter <= RGB_SEGMENT_counter + counter;
					SRAM_write_data <= {green_odd,blue_odd};
					m1_state <= S_COMMON_7; 
				end
		end
		
		S_COMMON_7: begin
			SRAM_we_n <= 1'b1;
			SRAM_address <= Y_SEGMENT + Y_SEGMENT_counter;
			Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
			counter2 <= counter2+ counter;
			m1_coeff <= y;
			m1_term <= adder1;
			m2_coeff <= x;
			m2_term <= adder2;
			m3_coeff <= z;
			m3_term <= adder3;
			R_even <= m1 + m2_result;
			G_even <= m1 + m3 + m1_result;
			B_even <= m1 + m2;
			m1_state <= S_COMMON_8; 
		end
		
		S_COMMON_8: begin
			if(counter2 < 18'sd157)begin
				SRAM_address <= U_SEGMENT + U_SEGMENT_counter;
				U_SEGMENT_counter <= U_SEGMENT_counter + counter;
			end
			m1_coeff <= y;
			m1_term <= adder1;
			m2_coeff <= x;
			m2_term <= adder2;
			m3_coeff <= z;
			m3_term <= adder3;
			inter_U_buffer <= inter_U;
			m1_state <= S_COMMON_9;
		end
		
		S_COMMON_9: begin
			if(counter2 < 18'sd157)begin
				SRAM_address <= V_SEGMENT + V_SEGMENT_counter;
				V_SEGMENT_counter <= V_SEGMENT_counter + counter;
			end
			m1_coeff <= a;
			m1_term <= {24'd0,Y_buffer[7:0]} - c1;
			m2_coeff <= h;
			m2_term <= inter_U_buffer - c2;
			m3_coeff <= e;
			m3_term <= inter_U_buffer - c2;
			inter_V_buffer <= inter_V;
			m1_state <= S_COMMON_10; 
		end

		S_COMMON_10: begin
			Y_buffer <= SRAM_read_data;
			m1_coeff <= f;
			m1_term <= inter_V_buffer - c2;
			m2_coeff <= c;
			m2_term <= inter_V_buffer - c2;
			m1 <= m1_result;
			m2 <= m2_result;
			m3 <= m3_result;
			m1_state <= S_COMMON_11;
		end
		
		S_COMMON_11: begin
			SRAM_we_n <= 1'b0;
			SRAM_address <= RGB_SEGMENT + RGB_SEGMENT_counter;
			RGB_SEGMENT_counter <= RGB_SEGMENT_counter + counter;
			SRAM_write_data <= {red_even, green_even};
			R_odd <= m1 + m2_result;
			G_odd <= m1 + m3 + m1_result;
			B_odd <= m1 + m2;
			m1_state <= S_COMMON_12;
			if(counter2 > 18'sd156)begin
				shift1 <= shift2;
				shift2 <= shift3;
				shift3 <= shift4;
				shift4 <= shift5;
				shift5 <= shift6;
				shift6 <= shift6;
			end
			else begin
				shift1 <= shift2;
				shift2 <= shift3;
				shift3 <= shift4;
				shift4 <= shift5;
				shift5 <= shift6;
				shift6 <= SRAM_read_data[15:8];
				U_buffer_odd <= SRAM_read_data[7:0];
			end
		end

		S_COMMON_12: begin
			SRAM_address <= RGB_SEGMENT + RGB_SEGMENT_counter;
			RGB_SEGMENT_counter <= RGB_SEGMENT_counter + counter;
			SRAM_write_data <= {blue_even, red_odd};
	
			m1_coeff <= a;
			m1_term <= {24'd0,Y_buffer[15:8]} - c1;
			m2_coeff <= h;
			m2_term <= shift3 - c2;
			m3_coeff <= e; 
			m3_term <= shift3 - c2;
			m1_state <= S_LEADIN_14;
			if(counter2 > 18'sd156)begin
				vshift1 <= vshift2;
				vshift2 <= vshift3;
				vshift3 <= vshift4;
				vshift4 <= vshift5;
				vshift5 <= vshift6;
				vshift6 <= vshift6;
			end
			else begin
				vshift1 <= vshift2;
				vshift2 <= vshift3;
				vshift3 <= vshift4;
				vshift4 <= vshift5;
				vshift5 <= vshift6;
				vshift6 <= SRAM_read_data[15:8];
				V_buffer_odd <= SRAM_read_data[7:0];
			end
		end
		
		S_LEADOUT_0: begin
			SRAM_we_n  <= 1'b1;
			SRAM_address <= Y_SEGMENT + Y_SEGMENT_counter;
			Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
			stop_counter <= stop_counter + counter;
			counter2 <= 18'd0;
			shift1 <= 32'b0;
			shift2 <= 32'b0;
			shift3 <= 32'b0;
			shift4 <= 32'b0;
			shift5 <= 32'b0;
			shift6 <= 32'b0;
			vshift1 <= 32'b0;
			vshift2 <= 32'b0;
			vshift3 <= 32'b0;
			vshift4 <= 32'b0;
			vshift5 <= 32'b0;
			vshift6 <= 32'b0;
			if(stop_counter < 18'sd239)begin
				m1_state <= S_LEADIN_0;
			end
			else begin
				stop <= 1'b1;
			end
		end
		
		endcase
	end
end
endmodule
