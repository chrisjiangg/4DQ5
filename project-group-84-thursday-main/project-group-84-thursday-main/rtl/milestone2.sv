`timescale 1ns/100ps
`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

/*
- input data is 16 bits signed
- computation  do all arithmetic on 32 bits signed
- 2 matrix multiplications per output 8x8 block
- up to 3 dual-port memories (4Kb capacity and no more than 32 bits per location)
- 3 multipliers with at least 85% utilization
- output is 8 bits unsigned values are written to the SRAM 2 values per SRAM location
*/

module milestone2 (
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

milestone2_state m2_state;

logic [6:0] read_address [2:0];
logic [6:0] write_address [2:0];
logic [31:0] write_data_a [2:0];
logic [31:0] write_data_b [2:0];
logic write_enable_a [2:0];
logic write_enable_b [2:0];
logic [31:0] read_data_a [2:0];
logic [31:0] read_data_b [2:0];

//dual port ram
dual_port_RAM0 RAM_inst0 (
    .address_a ( read_address[0] ),
    .address_b ( write_address[0] ),
    .clock ( CLOCK_50_I ),
    .data_a ( write_data_a[0] ),
    .data_b ( write_data_b[0] ),
    .wren_a ( write_enable_a[0] ),
    .wren_b ( write_enable_b[0] ),
    .q_a ( read_data_a[0] ),
    .q_b ( read_data_b[0] )
    );

dual_port_RAM1 RAM_inst1 (
    .address_a ( read_address[1] ),
    .address_b ( write_address[1] ),
    .clock ( CLOCK_50_I ),
    .data_a ( write_data_a[1] ),
    .data_b ( write_data_b[1] ),
    .wren_a ( write_enable_a[1] ),
    .wren_b ( write_enable_b[1] ),
    .q_a ( read_data_a[1] ),
    .q_b ( read_data_b[1] )
    );
	 
dual_port_RAM2 RAM_inst2 (
    .address_a ( read_address[2] ),
    .address_b ( write_address[2] ),
    .clock ( CLOCK_50_I ),
    .data_a ( write_data_a[2] ),
    .data_b ( write_data_b[2] ),
    .wren_a ( write_enable_a[2] ),
    .wren_b ( write_enable_b[2] ),
    .q_a ( read_data_a[2] ),
    .q_b ( read_data_b[2] )
    );

	 // the top port is used only for reading for both memories
// hence we disable the write enable for the top port 
assign write_enable_a [0] = 1'b0;
assign write_enable_a [1] = 1'b0;
assign write_enable_a [2] = 1'b0;
// since write enable is disabled for the top port we can 
// assign write data on the top port to some dummy values
assign write_data_a[0] = 8'd0;
assign write_data_a[1] = 8'd0;
assign write_data_a[2] = 8'd0;
	 
//addressing registers
logic [17:0] counter;
logic [17:0] Y_SEGMENT_counter;
logic [17:0] U_SEGMENT_counter;
logic [17:0] V_SEGMENT_counter;
logic [17:0] counter2;
logic [17:0] dp_ram_address_counter;
logic [17:0] dp_ram_address_counter_2;
logic [17:0] block_counter;
logic [17:0] row_counter;
logic [17:0] col_counter;

//stopping register
logic [17:0] stop_counter;
logic flag;

//buffers
logic [31:0] Y_buffer;
logic [31:0] S_buffer;
logic [17:0] hold;

logic [63:0] Y_buff_1;
logic [63:0] Y_buff_2;
logic [31:0] T_buff_sum;
logic [31:0] S_buff_1;
logic [31:0] S_buff_2;

//multiplication registers
logic [31:0] c0;
logic [31:0] c1;
logic [31:0] c2;
logic [31:0] m1;
logic [31:0] m2;
logic [31:0] m3;
logic [31:0] m1_term;
logic [31:0] m2_term;
logic [31:0] m3_term;
logic [63:0] m1_result_long;
logic [63:0] m2_result_long;
logic [63:0] m3_result_long;
logic [31:0] m1_result;
logic [31:0] m2_result;
logic [31:0] m3_result;

//row and column
//integer i, j;
//
logic [3:0] row_id;
logic [3:0] col_id;

logic signed [31:0] C0 [7:0][7:0];
logic signed [31:0] C1 [7:0][7:0];
logic signed [31:0] C2 [7:0][7:0];
logic [31:0] ct [7:0][7:0];
logic [4:0]count; //row_id

//clipping
logic [7:0] write_s0;
logic [7:0] write_s1;
logic [7:0] write_s2;

always_comb begin
	C0[0][0] = 32'sd1448;
	C0[0][1] = 32'sd1448;
   C0[0][2] = 32'sd1448;
   C0[0][3] = 32'sd1448;
   C0[0][4] = 32'sd1448;
   C0[0][5] = 32'sd1448;
   C0[0][6] = 32'sd1448;
   C0[0][7] = 32'sd1448;

   C0[1][0] = 32'sd2008;
   C0[1][1] = 32'sd1702;
   C0[1][2] = 32'sd1137;
   C0[1][3] = 32'sd399;
   C0[1][4] = -32'sd399;
   C0[1][5] = -32'sd1137;
   C0[1][6] = -32'sd1702;
   C0[1][7] = -32'sd2008;

   C0[2][0] = 32'sd1892;
   C0[2][1] = 32'sd783;
   C0[2][2] = -32'sd783;
   C0[2][3] = -32'sd1892;
   C0[2][4] = -32'sd1892;
   C0[2][5] = -32'sd783;
   C0[2][6] = 32'sd783;
	C0[2][7] = 32'sd1892;

	C0[3][0] = 32'sd1702;
   C0[3][1] = -32'sd399;
   C0[3][2] = -32'sd2008;
   C0[3][3] = -32'sd1137;
   C0[3][4] = 32'sd1137;
   C0[3][5] = 32'sd2008;
   C0[3][6] = 32'sd399;
   C0[3][7] = -32'sd1702;

   C0[4][0] = 32'sd1448;
   C0[4][1] = -32'sd1448;
   C0[4][2] = -32'sd1448;
   C0[4][3] = 32'sd1448;
   C0[4][4] = 32'sd1448;
   C0[4][5] = -32'sd1448;
   C0[4][6] = -32'sd1448;
   C0[4][7] = 32'sd1448;

   C0[5][0] = 32'sd1137;
   C0[5][1] = -32'sd2008;
   C0[5][2] = 32'sd399;
   C0[5][3] = 32'sd1702;
   C0[5][4] = -32'sd1702;
   C0[5][5] = -32'sd399;
   C0[5][6] = 32'sd2008;
   C0[5][7] = -32'sd1137;
	
   C0[6][0] = 32'sd783;
   C0[6][1] = -32'sd1892;
   C0[6][2] = 32'sd1892;
   C0[6][3] = -32'sd783;
   C0[6][4] = -32'sd783;
   C0[6][5] = 32'sd1892;
   C0[6][6] = -32'sd1892;
   C0[6][7] = 32'sd783;

   C0[7][0] = 32'sd399;
   C0[7][1] = -32'sd1137;
   C0[7][2] = 32'sd1702;
   C0[7][3] = -32'sd2008;
   C0[7][4] = 32'sd2008;
   C0[7][5] = -32'sd1702;
   C0[7][6] = 32'sd1137;
   C0[7][7] = -32'sd399;
	
	C1[0][0] = 32'sd1448;
	C1[0][1] = 32'sd1448;
   C1[0][2] = 32'sd1448;
   C1[0][3] = 32'sd1448;
   C1[0][4] = 32'sd1448;
   C1[0][5] = 32'sd1448;
   C1[0][6] = 32'sd1448;
   C1[0][7] = 32'sd1448;

   C1[1][0] = 32'sd2008;
   C1[1][1] = 32'sd1702;
   C1[1][2] = 32'sd1137;
   C1[1][3] = 32'sd399;
   C1[1][4] = -32'sd399;
   C1[1][5] = -32'sd1137;
   C1[1][6] = -32'sd1702;
   C1[1][7] = -32'sd2008;

   C1[2][0] = 32'sd1892;
   C1[2][1] = 32'sd783;
   C1[2][2] = -32'sd783;
   C1[2][3] = -32'sd1892;
   C1[2][4] = -32'sd1892;
   C1[2][5] = -32'sd783;
   C1[2][6] = 32'sd783;
	C1[2][7] = 32'sd1892;

	C1[3][0] = 32'sd1702;
   C1[3][1] = -32'sd399;
   C1[3][2] = -32'sd2008;
   C1[3][3] = -32'sd1137;
   C1[3][4] = 32'sd1137;
   C1[3][5] = 32'sd2008;
   C1[3][6] = 32'sd399;
   C1[3][7] = -32'sd1702;

   C1[4][0] = 32'sd1448;
   C1[4][1] = -32'sd1448;
   C1[4][2] = -32'sd1448;
   C1[4][3] = 32'sd1448;
   C1[4][4] = 32'sd1448;
   C1[4][5] = -32'sd1448;
   C1[4][6] = -32'sd1448;
   C1[4][7] = 32'sd1448;

   C1[5][0] = 32'sd1137;
   C1[5][1] = -32'sd2008;
   C1[5][2] = 32'sd399;
   C1[5][3] = 32'sd1702;
   C1[5][4] = -32'sd1702;
   C1[5][5] = -32'sd399;
   C1[5][6] = 32'sd2008;
   C1[5][7] = -32'sd1137;
	
   C1[6][0] = 32'sd783;
   C1[6][1] = -32'sd1892;
   C1[6][2] = 32'sd1892;
   C1[6][3] = -32'sd783;
   C1[6][4] = -32'sd783;
   C1[6][5] = 32'sd1892;
   C1[6][6] = -32'sd1892;
   C1[6][7] = 32'sd783;

   C1[7][0] = 32'sd399;
   C1[7][1] = -32'sd1137;
   C1[7][2] = 32'sd1702;
   C1[7][3] = -32'sd2008;
   C1[7][4] = 32'sd2008;
   C1[7][5] = -32'sd1702;
   C1[7][6] = 32'sd1137;
   C1[7][7] = -32'sd399;
	
	C2[0][0] = 32'sd1448;
	C2[0][1] = 32'sd1448;
   C2[0][2] = 32'sd1448;
   C2[0][3] = 32'sd1448;
   C2[0][4] = 32'sd1448;
   C2[0][5] = 32'sd1448;
   C2[0][6] = 32'sd1448;
   C2[0][7] = 32'sd1448;

   C2[1][0] = 32'sd2008;
   C2[1][1] = 32'sd1702;
   C2[1][2] = 32'sd1137;
   C2[1][3] = 32'sd399;
   C2[1][4] = -32'sd399;
   C2[1][5] = -32'sd1137;
   C2[1][6] = -32'sd1702;
   C2[1][7] = -32'sd2008;

   C2[2][0] = 32'sd1892;
   C2[2][1] = 32'sd783;
   C2[2][2] = -32'sd783;
   C2[2][3] = -32'sd1892;
   C2[2][4] = -32'sd1892;
   C2[2][5] = -32'sd783;
   C2[2][6] = 32'sd783;
	C2[2][7] = 32'sd1892;

	C2[3][0] = 32'sd1702;
   C2[3][1] = -32'sd399;
   C2[3][2] = -32'sd2008;
   C2[3][3] = -32'sd1137;
   C2[3][4] = 32'sd1137;
   C2[3][5] = 32'sd2008;
   C2[3][6] = 32'sd399;
   C2[3][7] = -32'sd1702;

   C2[4][0] = 32'sd1448;
   C2[4][1] = -32'sd1448;
   C2[4][2] = -32'sd1448;
   C2[4][3] = 32'sd1448;
   C2[4][4] = 32'sd1448;
   C2[4][5] = -32'sd1448;
   C2[4][6] = -32'sd1448;
   C2[4][7] = 32'sd1448;

   C2[5][0] = 32'sd1137;
   C2[5][1] = -32'sd2008;
   C2[5][2] = 32'sd399;
   C2[5][3] = 32'sd1702;
   C2[5][4] = -32'sd1702;
   C2[5][5] = -32'sd399;
   C2[5][6] = 32'sd2008;
   C2[5][7] = -32'sd1137;
	
   C2[6][0] = 32'sd783;
   C2[6][1] = -32'sd1892;
   C2[6][2] = 32'sd1892;
   C2[6][3] = -32'sd783;
   C2[6][4] = -32'sd783;
   C2[6][5] = 32'sd1892;
   C2[6][6] = -32'sd1892;
   C2[6][7] = 32'sd783;

   C2[7][0] = 32'sd399;
   C2[7][1] = -32'sd1137;
   C2[7][2] = 32'sd1702;
   C2[7][3] = -32'sd2008;
   C2[7][4] = 32'sd2008;
   C2[7][5] = -32'sd1702;
   C2[7][6] = 32'sd1137;
   C2[7][7] = -32'sd399;
	
	ct[0][0] = 32'sd1448;
	ct[1][0] = 32'sd1448;
   ct[2][0] = 32'sd1448;
   ct[3][0] = 32'sd1448;
   ct[4][0] = 32'sd1448;
   ct[5][0] = 32'sd1448;
   ct[6][0] = 32'sd1448;
   ct[7][0] = 32'sd1448;

   ct[0][1] = 32'sd2008;
   ct[1][1] = 32'sd1702;
   ct[2][1] = 32'sd1137;
   ct[3][1] = 32'sd399;
   ct[4][1] = -32'sd399;
   ct[5][1] = -32'sd1137;
   ct[6][1] = -32'sd1702;
   ct[7][1] = -32'sd2008;

   ct[0][2] = 32'sd1892;
   ct[1][2] = 32'sd783;
   ct[2][2] = -32'sd783;
   ct[3][2] = -32'sd1892;
   ct[4][2] = -32'sd1892;
   ct[5][2] = -32'sd783;
   ct[6][2] = 32'sd783;
	ct[7][2] = 32'sd1892;

	ct[0][3] = 32'sd1702;
   ct[1][3] = -32'sd399;
   ct[2][3] = -32'sd2008;
   ct[3][3] = -32'sd1137;
   ct[4][3] = 32'sd1137;
   ct[5][3] = 32'sd2008;
   ct[6][3] = 32'sd399;
   ct[7][3] = -32'sd1702;

   ct[0][4] = 32'sd1448;
   ct[1][4] = -32'sd1448;
   ct[2][4] = -32'sd1448;
   ct[3][4] = 32'sd1448;
   ct[4][4] = 32'sd1448;
   ct[5][4] = -32'sd1448;
   ct[6][4] = -32'sd1448;
   ct[7][4] = 32'sd1448;

   ct[0][5] = 32'sd1137;
   ct[1][5] = -32'sd2008;
   ct[2][5] = 32'sd399;
   ct[3][5] = 32'sd1702;
   ct[4][5] = -32'sd1702;
   ct[5][5] = -32'sd399;
   ct[6][5] = 32'sd2008;
   ct[7][5] = -32'sd1137;
	
   ct[0][6] = 32'sd783;
   ct[1][6] = -32'sd1892;
   ct[2][6] = 32'sd1892;
   ct[3][6] = -32'sd783;
   ct[4][6] = -32'sd783;
   ct[5][6] = 32'sd1892;
   ct[6][6] = -32'sd1892;
   ct[7][6] = 32'sd783;

   ct[0][7] = 32'sd399;
   ct[1][7] = -32'sd1137;
   ct[2][7] = 32'sd1702;
   ct[3][7] = -32'sd2008;
   ct[4][7] = 32'sd2008;
   ct[5][7] = -32'sd1702;
   ct[6][7] = 32'sd1137;
   ct[7][7] = -32'sd399;
	
	
end
	
	
//	if(m2_state == M2_IDLE)begin
//		for(i = 0; i < 8; i = i + counter)begin
//			for(j = 0; j < 8; j = j + counter)begin
//					SRAM_address = Y_SEGMENT_2 + counter;
//			end
//			Y_SEGMENT_2 = Y_SEGMENT_2 + threetwenty - eight;
//		end
//	end
	
	
//C is c matrix
//m_term is from SRAM


//multipliers
assign m1_result_long = $signed(c0) * $signed(m1_term);
assign m1_result = m1_result_long[31:0];

assign m2_result_long = $signed(c1) * $signed(m2_term);
assign m2_result = m2_result_long[31:0];

assign m3_result_long = $signed(c2) * $signed(m3_term);
assign m3_result = m3_result_long[31:0];

//clipping
assign write_s0 = m1_result[31] ? 8'd0 : |m1_result[30:24] ? 8'd255 : m1_result[23:16];
assign write_s1 = m2_result[31] ? 8'd0 : |m2_result[30:24] ? 8'd255 : m2_result[23:16];
assign write_s2 = m3_result[31] ? 8'd0 : |m3_result[30:24] ? 8'd255 : m3_result[23:16];


always @(posedge CLOCK_50_I or negedge Resetn) begin
	if (~Resetn) begin
		m2_state <= M2_IDLE;
		
		//INITIALIZE ALL SIGNALS
		SRAM_we_n <= 1'b1;
		
		Y_SEGMENT_counter <= Y_SEGMENT_2;
		U_SEGMENT_counter <= 18'b0;
		V_SEGMENT_counter <= 18'b0;
		counter <= 18'b1;
		stop_counter <= 18'd0;
		counter2 <= 18'b0;
		block_counter <= 18'b0;
		dp_ram_address_counter <= 18'b0;
		dp_ram_address_counter_2 <= 18'b0;
		row_counter <= 18'b0;
		col_counter <= 18'b0;
		count <= 4'd0;
		
		flag <= 1'b0;
		
		Y_buffer <= 32'b0;
		Y_buff_1 <= 32'sb0;
		Y_buff_2 <= 32'sb0;
		T_buff_sum <= 32'sb0;
		S_buffer <= 32'b0;
		S_buff_1 <= 32'b0;
		S_buff_2 <= 32'b0;
		
		//multipliers
		c0 <= 32'b0;
		c1 <= 32'b0;
		c2 <= 32'b0;
		m1 <= 32'b0;
		m2 <= 32'b0;
		m3 <= 32'b0;
		m1_term <= 32'b0;
		m2_term <= 32'b0;
		m3_term <= 32'b0;
		
		//row
		row_id <= 32'b0;
		col_id <= 32'b0;
		//ram
		read_address[0] <= 7'd0;
		write_address[0] <= 7'd0;
		read_address[1] <= 7'd0;
		write_address[1] <= 7'd0;
		read_address[2] <= 7'd0;
		write_address[2] <= 7'd0;	
		write_enable_b[0] <= 1'b0;
		write_enable_b[1] <= 1'b0;
		write_enable_b[2] <= 1'b0;
	
		stop <= 1'b0;
		
	end else begin
	
		case (m2_state)
		M2_IDLE: begin
			if(start)begin
				if(row_counter == 18'd0)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd1)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd2)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd3)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd4)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd5)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd6)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd7)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				col_counter <= 18'd0;
				m2_state <= fetch_0;
			end
		end
		
		fetch_0: begin
				if(row_counter == 18'd0)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd1)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd2)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd3)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd4)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd5)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd6)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd7)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
			col_counter <= col_counter + counter;
			m2_state <= fetch_1;
		end
		
		fetch_1: begin
				if(row_counter == 18'd0)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd1)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd2)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd3)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd4)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd5)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd6)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd7)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
			write_enable_b[0] <= 1'b1;
			col_counter <= col_counter + counter;
			m2_state <= fetch_2;
		end
		
		fetch_2: begin
				if(row_counter == 18'd0)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd1)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd2)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd3)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd4)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd5)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd6)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd7)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
			read_address[0] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			write_data_b[0] <= $signed(SRAM_read_data);
			col_counter <= col_counter + counter;
			m2_state <= fetch_3;
		end
		
		fetch_3: begin
				if(row_counter == 18'd0)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd1)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd2)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd3)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd4)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd5)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd6)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd7)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
			read_address[0] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			write_data_b[0] <= $signed(SRAM_read_data);
			col_counter <= col_counter + counter;
			m2_state <= fetch_4;
		end
		
		fetch_4: begin
			if(row_counter == 18'd0)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd1)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd2)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd3)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd4)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd5)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd6)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd7)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
			read_address[0] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			write_data_b[0] <= $signed(SRAM_read_data);
			col_counter <= col_counter + counter;
			m2_state <= fetch_5;
		end
		
		fetch_5: begin
				if(row_counter == 18'd0)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd1)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd2)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd3)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd4)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd5)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd6)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd7)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
			read_address[0] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			write_data_b[0] <= $signed(SRAM_read_data);
			col_counter <= col_counter + counter;
			m2_state <= fetch_6;
		end
		
		fetch_6: begin
				if(row_counter == 18'd0)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + threethirteen;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd1)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + threethirteen;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd2)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + threethirteen;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd3)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + threethirteen;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd4)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + threethirteen;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd5)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + threethirteen;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd6)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + threethirteen;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd7)begin
						SRAM_address <= Y_SEGMENT_counter;
						Y_SEGMENT_counter <= Y_SEGMENT_counter + threethirteen;
						counter2 <= counter2 + counter;
				end
			col_counter <= col_counter + counter;
			read_address[0] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			write_data_b[0] <= $signed(SRAM_read_data);
			m2_state <= fetch_7;
		end
		
		fetch_7: begin
			read_address[0] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			write_data_b[0] <= $signed(SRAM_read_data);
			m2_state <= fetch_8;
		end
		
		fetch_8: begin
			read_address[0] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			write_data_b[0] <= $signed(SRAM_read_data);
			if(row_counter == 18'd7 && col_counter == 18'd7)begin //increment new block
				block_counter <= block_counter + counter;
			end
			m2_state <= fetch_9;
		end
		
		fetch_9: begin 
			if(block_counter == 18'd1 && row_counter == 18'd7 && col_counter == 18'd7)begin //goes to the start of the new block
//				Y_SEGMENT_counter <= Y_SEGMENT_counter - 18'd2552;
				write_enable_b[0] <= 1'b0;
				read_address[0] <= 7'd0;
				write_address[0] <= 7'd0;
				m2_state <= compute_t_0;
			end
				read_address[0] <= dp_ram_address_counter;
				dp_ram_address_counter <= dp_ram_address_counter + counter;
				write_data_b[0] <= $signed(SRAM_read_data);
				m2_state <= fetch_10;
		end
		
		fetch_10: begin
			
				if(row_counter == 18'd0)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd1)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd2)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd3)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd4)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd5)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd6)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				else if(row_counter == 18'd7)begin
					SRAM_address <= Y_SEGMENT_counter;
					Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
					counter2 <= counter2 + counter;
				end
				if(dp_ram_address_counter >= 18'd63)begin
					dp_ram_address_counter <= 18'd0;
				end
			write_enable_b[0] <= 1'b0;
			row_counter <= row_counter + counter;
			col_counter <= 18'd0;
			m2_state <= fetch_0;
		end
		
		
		compute_t_0: begin
			read_address[0] <= 7'd0;
			write_address[1] <= 7'd0;
			write_enable_b[1] <= 1'd0;
			T_buff_sum <= 31'd0;
			row_counter <= 7'd0;
			
			m2_state <= compute_t_1;
		end
		
		compute_t_1: begin
			read_address[0] <= read_address[0]; //sets the read address for ram0
			m2_state <= compute_t_2;
		end
		
		compute_t_2: begin
			read_address[0] <= read_address[0] + 7'd1;
			m2_state <= compute_t_3;
		end
		
		compute_t_3: begin
			Y_buff_1[31:0] <= read_data_a[0];
			
			m2_state <= compute_t_4;
		end
		
		compute_t_4: begin
			read_address[0] <= read_address[0] + 7'd1;
			
			m2_state <= compute_t_5;
		end
		
		compute_t_5: begin
			Y_buff_1[63:32] <= read_data_a[0];
			m2_state <= compute_t_6;
		end
		
		compute_t_6: begin
			m1_term <= $signed(Y_buff_1[15:0]);
			c0 <= C0[row_counter][1];
			
			m2_term <= $signed(Y_buff_1[31:16]);
			c1 <= C0[row_counter][2];
		
			m3_term <= $signed(Y_buff_1[47:32]);
			c2 <= C0[row_counter][3];
			read_address[0] <= read_address[0] + 7'd1;

			m2_state <= compute_t_7;
		end
		
		compute_t_7: begin
			Y_buff_2[31:0] <= read_data_a[0];
			read_address[0] <= read_address[0] + 7'd1;
			T_buff_sum <= T_buff_sum + m1_result + m2_result + m3_result;
			m2_state <= compute_t_8;
		end
		
		compute_t_8: begin
			Y_buff_2[63:32] <= read_data_a[0];
			
			m2_state <= compute_t_9;
		end

		compute_t_9: begin
			m1_term <= $signed(Y_buff_2[15:0]);
			c0 <= C0[row_counter][4];
			
			m2_term <= $signed(Y_buff_2[31:16]);
			c1 <= C0[row_counter][5];
		
			m3_term <= $signed(Y_buff_2[47:32]);
			c2 <= C0[row_counter][6];
			
			m2_state <= compute_t_10;
		end
		
		compute_t_10: begin
			m1_term <= $signed(Y_buff_1[63:48]);
			c0 <= C0[row_counter][3];
			
			m2_term <= $signed(Y_buff_2[63:48]);
			c1 <= C0[row_counter][7];
		
			m3_term <= 1'd0;
			c2 <= 1'd0;
			
			T_buff_sum <= T_buff_sum + m1_result + m2_result + m3_result;

			m2_state <= compute_t_11;
		end
		
		compute_t_11: begin
			T_buff_sum <= T_buff_sum + m1_result + m2_result + m3_result;
			row_counter <= row_counter + 1'd1;
			m2_state <= compute_t_12;
		end
		
		compute_t_12: begin
			write_data_b[1] <= $signed(T_buff_sum);
			if(row_counter > 8)begin
				m2_state <= compute_t_1;
			end
			m2_state <= compute_s;
		end

		compute_s:begin
			if(row_id == 32'b0)begin
				read_address[1] <= dp_ram_address_counter; //read dp0 
				dp_ram_address_counter <= dp_ram_address_counter + counter;
				m2_state <= compute_s_0;
			end
		end
// S = CT * T	
		compute_s_0: begin
			read_address[1] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			m2_state <= compute_s_1;
		end
		
		compute_s_1: begin
			read_address[1] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			write_enable_b[2] <= 1'b1;
			m2_state <= compute_s_2;
		end
		
		compute_s_2: begin
			c0 <= ct[row_id][col_id];
			m1_term <= read_data_b[1];
			row_id <= row_id + counter;
			read_address[1] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			read_address[2] <= dp_ram_address_counter_2;
			dp_ram_address_counter_2 <= dp_ram_address_counter_2 + counter;
			write_data_b[2] <= m1_result;
			m2_state <= compute_s_3;
		end
		
		compute_s_3: begin
		// m1 result
			c1 <= ct[row_id][col_id];
			m2_term <= read_data_b[1];
			row_id <= row_id + counter;
			read_address[1] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			read_address[2] <= dp_ram_address_counter_2;
			dp_ram_address_counter_2 <= dp_ram_address_counter_2 + counter;
			write_data_b[2] <= m2_result;
			m2_state <= compute_s_4;
		end
		
		compute_s_4: begin
		//m2 result
			c2 <= ct[row_id][col_id];
			m3_term <= read_data_b[1];
			row_id <= row_id + counter;
			read_address[1] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			read_address[2] <= dp_ram_address_counter_2;
			dp_ram_address_counter_2 <= dp_ram_address_counter_2 + counter;
			write_data_b[2] <= m3_result;
			m2_state <= compute_s_5;
		end
		
		compute_s_5: begin
		//m3 result
			c0 <= ct[row_id][col_id];
			m1_term <= read_data_b[1];
			row_id <= row_id + counter;
			read_address[1] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			read_address[2] <= dp_ram_address_counter_2;
			dp_ram_address_counter_2 <= dp_ram_address_counter_2 + counter;
			write_data_b[2] <= m1_result;
			m2_state <= compute_s_6;
		end
		
		compute_s_6: begin
		//m1 result
			c1 <= ct[row_id][col_id];
			m2_term <= read_data_b[1];
			row_id <= row_id + counter;
			read_address[1] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			read_address[2] <= dp_ram_address_counter_2;
			dp_ram_address_counter_2 <= dp_ram_address_counter_2 + counter;
			write_data_b[2] <= m2_result;
			m2_state <= compute_s_7;
		end
		
		compute_s_7: begin
		//m2 result
			c2 <= ct[row_id][col_id];
			m3_term <= read_data_b[1];
			row_id <= row_id + counter;
			read_address[2] <= dp_ram_address_counter_2;
			dp_ram_address_counter_2 <= dp_ram_address_counter_2 + counter;
			write_data_b[2] <= m3_result;
			m2_state <= compute_s_8;
		end
		
		compute_s_8: begin
		//m3 result
			c0 <= ct[row_id][col_id];
			m1_term <= read_data_b[1];
			row_id <= row_id + counter;
			read_address[2] <= dp_ram_address_counter_2;
			dp_ram_address_counter_2 <= dp_ram_address_counter_2 + counter;
			write_data_b[2] <= m1_result;
			m2_state <= compute_s_9;
		end
		
		compute_s_9: begin
		//m1 result
			c1 <= ct[row_id][col_id];
			m2_term <= read_data_b[1];
			row_id <= 32'b0;
			col_id <= col_id + counter;
			read_address[2] <= dp_ram_address_counter_2;
			dp_ram_address_counter_2 <= dp_ram_address_counter_2 + counter;
			write_data_b[2] <= m2_result;
			if(row_id == 32'd7 && col_id == 32'd7)begin
				dp_ram_address_counter <= 18'd0;
				dp_ram_address_counter_2 <= 18'd0;
				m2_state <= write_s_0;
			end
			m2_state <= compute_t_10;
		end
		write_s_0:begin
			read_address[2] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			m2_state <= write_s_1;
		end
		
		write_s_1:begin
			read_address[2] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			m2_state <= write_s_2;
		end
		
		write_s_2:begin
			read_address[2] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			m2_state <= write_s_3;
		end
		
		write_s_3:begin
			read_address[2] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			SRAM_we_n <= 1'b0;
			SRAM_address <= Y_SEGMENT + Y_SEGMENT_counter;
			Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
			SRAM_write_data <= {read_data_b[2][7:0], read_data_b[2][15:0]};
			m2_state <= write_s_4;
		end
		
		write_s_4:begin
			read_address[2] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			SRAM_address <= Y_SEGMENT + Y_SEGMENT_counter;
			Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
			SRAM_write_data <= {read_data_b[2][7:0], read_data_b[2][15:0]};
			m2_state <= write_s_5;
		end
		
		write_s_5:begin
			read_address[2] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			SRAM_address <= Y_SEGMENT + Y_SEGMENT_counter;
			Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
			SRAM_write_data <= {read_data_b[2][7:0], read_data_b[2][15:0]};
			m2_state <= write_s_6;
		end
		
		write_s_6:begin
			read_address[2] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			SRAM_address <= Y_SEGMENT + Y_SEGMENT_counter;
			Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
			SRAM_write_data <= {read_data_b[2][7:0], read_data_b[2][15:0]};
			m2_state <= write_s_7;
		end
		
		write_s_7:begin
			read_address[2] <= dp_ram_address_counter;
			dp_ram_address_counter <= dp_ram_address_counter + counter;
			SRAM_address <= Y_SEGMENT + Y_SEGMENT_counter;
			Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
			SRAM_write_data <= {read_data_b[2][7:0], read_data_b[2][15:0]};
			m2_state <= write_s_8;
		end
			
		write_s_8:begin
			SRAM_address <= Y_SEGMENT + Y_SEGMENT_counter;
			Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
			SRAM_write_data <= {read_data_b[2][7:0], read_data_b[2][15:0]};
			m2_state <= write_s_9;
		end
			
		write_s_9:begin
			SRAM_address <= Y_SEGMENT + Y_SEGMENT_counter;
			Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
			SRAM_write_data <= {read_data_b[2][7:0], read_data_b[2][15:0]};
			m2_state <= write_s_10;
		end
			
		write_s_10:begin
			SRAM_address <= Y_SEGMENT + Y_SEGMENT_counter;
			Y_SEGMENT_counter <= Y_SEGMENT_counter + counter;
			SRAM_write_data <= {read_data_b[2][7:0], read_data_b[2][15:0]};
			m2_state <= write_s_0;
		end
			
		endcase
	end
end
endmodule