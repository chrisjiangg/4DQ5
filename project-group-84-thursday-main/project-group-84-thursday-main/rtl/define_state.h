`ifndef DEFINE_STATE

// for top state - we have more states than needed
typedef enum logic [2:0] {
	S_IDLE,
	milestone1,
	milestone2,
	S_UART_RX
} top_state_type;

typedef enum logic [8:0] {
	M1_IDLE,
	S_LEADIN_0,
	S_LEADIN_1,
	S_LEADIN_2,
	S_LEADIN_3,
	S_LEADIN_4,
	S_LEADIN_5,
	S_LEADIN_6,
	S_LEADIN_7,
	S_LEADIN_8,
	S_LEADIN_9,
	S_LEADIN_10,
	S_LEADIN_11,
	S_LEADIN_12,
	S_LEADIN_13,
	S_LEADIN_14,
	S_COMMON_0,
	S_COMMON_1,
	S_COMMON_2,
	S_COMMON_3,
	S_COMMON_4,
	S_COMMON_5,
	S_COMMON_6,
	S_COMMON_7,
	S_COMMON_8,
	S_COMMON_9,
	S_COMMON_10,
	S_COMMON_11,
	S_COMMON_12,
	S_COMMON_13,
	S_LEADOUT_0
} milestone1_state;

typedef enum logic [8:0] {
	M2_IDLE,
	fetch_0,
	fetch_1,
	fetch_2,
	fetch_3,
	fetch_4,
	fetch_5,
	fetch_6,
	fetch_7,
	fetch_8,
	fetch_9,
	fetch_10,
	fetch_11,
	compute_t_0,
	compute_t_1,
	compute_t_2,
	compute_t_3,
	compute_t_4,
	compute_t_5,
	compute_t_6,
	compute_t_7,
	compute_t_8,
	compute_t_9,
	compute_t_10,
	compute_t_11,
	compute_t_12,
	compute_s,
	compute_s_0,
	compute_s_1,
	compute_s_2,
	compute_s_3,
	compute_s_4,
	compute_s_5,
	compute_s_6,
	compute_s_7,
	compute_s_8,
	compute_s_9,
	write_s_0,
	write_s_1,
	write_s_2,
	write_s_3,
	write_s_4,
	write_s_5,
	write_s_6,
	write_s_7,
	write_s_8,
	write_s_9,
	write_s_10
	
	//add states
} milestone2_state;

typedef enum logic [1:0] {
	S_RXC_IDLE,
	S_RXC_SYNC,
	S_RXC_ASSEMBLE_DATA,
	S_RXC_STOP_BIT
} RX_Controller_state_type;

typedef enum logic [2:0] {
	S_US_IDLE,
	S_US_STRIP_FILE_HEADER_1,
	S_US_STRIP_FILE_HEADER_2,
	S_US_START_FIRST_BYTE_RECEIVE,
	S_US_WRITE_FIRST_BYTE,
	S_US_START_SECOND_BYTE_RECEIVE,
	S_US_WRITE_SECOND_BYTE
} UART_SRAM_state_type;

typedef enum logic [3:0] {
	S_VS_WAIT_NEW_PIXEL_ROW,
	S_VS_NEW_PIXEL_ROW_DELAY_1,
	S_VS_NEW_PIXEL_ROW_DELAY_2,
	S_VS_NEW_PIXEL_ROW_DELAY_3,
	S_VS_NEW_PIXEL_ROW_DELAY_4,
	S_VS_NEW_PIXEL_ROW_DELAY_5,
	S_VS_FETCH_PIXEL_DATA_0,
	S_VS_FETCH_PIXEL_DATA_1,
	S_VS_FETCH_PIXEL_DATA_2,
	S_VS_FETCH_PIXEL_DATA_3
} VGA_SRAM_state_type;

//milestone 1
parameter Y_SEGMENT = 18'd0,
	U_SEGMENT = 18'd38400,
	V_SEGMENT = 18'd57600,
	RGB_SEGMENT = 18'd146944;

//milestone 2
parameter Y_SEGMENT_2 = 18'd76800,
	U_SEGMENT_2 = 18'd154600,
	V_SEGMENT_2 = 18'd192000;

parameter a = 32'd76284,
	c = 32'd104595,
	e = -32'sd25624,
	f = -32'sd53281,
	h = 32'd132251,
	y = 32'd21,
	x = -32'sd52,
	z = 32'd159,
	c1 = 32'd16,
	c2 = 32'd128,
	threethirteen = 32'd313,
	eight = 32'd8,
	seven = 32'd7;

parameter 
   VIEW_AREA_LEFT = 160,
   VIEW_AREA_RIGHT = 480,
   VIEW_AREA_TOP = 120,
   VIEW_AREA_BOTTOM = 360;

`define DEFINE_STATE 1
`endif
