`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////////////
// Company: Digilent Inc.
// Engineer: Andrew Skreen
// 
// Create Date:    07/11/2012
// Module Name:    master_interface
// Project Name: 	 PmodGYRO_Demo
// Target Devices: Nexys3
// Tool versions:  ISE 14.1
// Description: This module manages the data that is to be written to the PmodGYRO, and
//					 produces the signals to initiate a data transfer via the spi_interface
//					 component.  Once the master_interface receives a handshake from the
//					 spi_interface component data has been read from the PmodGYRO and is stored.
//
// Revision History: 
// 						Revision 0.01 - File Created (Andrew Skreen)
//							Revision 1.00 - Added Comments and Converted to Verilog (Josh Sackos)
//////////////////////////////////////////////////////////////////////////////////////////

// ==============================================================================
// 										  Define Module
// ==============================================================================
module master_interface(
		p,
		begin_transmission,
//		recieved_data,
		end_transmission,
		clk,
//		rst,
		start,
		VCCEN,
		PMODEN,
		RES, //RES 
		slave_select, //CS
		send_data, 
		DC,//DC
		address
//		temp_data, //用于储存temp过程中的data
//		x_axis_data,
//		y_axis_data,
//		z_axis_data
);

// ==============================================================================
// 									   Port Declarations
// ==============================================================================
			output [12:0]    address;
			output           begin_transmission;
//			input [7:0]      recieved_data;
			input            end_transmission;
			input            clk;
//			input            rst;
			input            start;
			input [7:0]     p;
	
			output			  RES;
			output			  VCCEN;
			output			  PMODEN;		
			output           slave_select;
			output [7:0]     send_data;
			output           DC;
//			output [7:0]     temp_data;
//			output [15:0]    x_axis_data;
//			output [15:0]    y_axis_data;
//			output [15:0]    z_axis_data;
   
// ==============================================================================
// 								Parameters, Registers, and Wires
// ==============================================================================
			reg              begin_transmission;
			reg              slave_select;
			reg [7:0]        send_data;
			reg			  	  RES;
			reg			     VCCEN;
			reg			     PMODEN;	
			reg              DC;
			reg [12:0]       address;
//			reg [7:0]        temp_data;
//			reg [15:0]       x_axis_data;
//			reg [15:0]       y_axis_data;
//			reg [15:0]       z_axis_data;
			
			parameter [2:0]  StateTYPE_idle = 0,
								  StateTYPE_setup = 1,
//								  StateTYPE_temp = 2,
								  StateTYPE_run = 2,
								  StateTYPE_hold = 3,
								  StateTYPE_wait_ss = 4,
								  StateTYPE_wait_run = 5;
			reg [2:0]        STATE;
			reg [2:0]        previousSTATE;
   
			// setup control register 1 to enable x, y, and z. CTRL_REG1 (0x20)
			// with read and multiple bytes not selected
			// output data rate of 100 Hz
			// will output 8.75 mdps/digit at 250 dps maximum
			// ?????设置内容？
			reg [7:0] SETUP_GYRO [50:0];
			reg [7:0] RUN_BEGIN [5:0];
			// address of X_AXIS (0x28) with read and multiple bytes selected (0xC0)
			//parameter [7:0]  DATA_READ_BEGIN = 8'hE8;
			// address of TEMP (0x26) with read selected (0x80)
			//parameter [7:0]  TEMP_READ_BEGIN = 8'hA6;
			
			//parameter        MAX_BYTE_COUNT = 6;
			reg [4:0]        byte_count;
			
			parameter [31:0] SS_COUNT_MAX = 32'd25000000;
			reg [31:0]       ss_count;
			
			parameter [31:0] COUNT_WAIT_MAX = 32'd25000000;		//X"000FFF";
			reg [31:0]       count_wait;
//			reg [47:0]       axis_data;
			
			initial
			begin
				$readmemh("1.txt",SETUP_GYRO);
				$readmemh("2.txt",RUN_BEGIN);
			end
   
// ==============================================================================
// 										Implementation
// ==============================================================================
			//---------------------------------------------------
			// 				  Master Controller FSM
			//---------------------------------------------------
			always @(posedge clk)
			begin: spi_interface
				
				begin
//					if (rst == 1'b1) begin
//						slave_select <= 1'b1;
//						byte_count <= 0;
//						count_wait <= {32{1'b0}};
////						axis_data <= {48{1'b0}};
////						x_axis_data <= {16{1'b0}};
////						y_axis_data <= {16{1'b0}};
////						z_axis_data <= {16{1'b0}};
//						ss_count <= {32{1'b0}};
//						STATE <= StateTYPE_idle;
//						previousSTATE <= StateTYPE_idle;
//					end
//					else
						case (STATE)
							
							// idle
							StateTYPE_idle :
								begin
									slave_select <= 1'b1;
									if (start == 1'b1)
									begin
										byte_count <= 0;
//										axis_data <= {48{1'b0}};
										STATE <= StateTYPE_setup;
									end
								end
							
							// setup
							StateTYPE_setup :begin
									if (byte_count < 11+4)
										begin
											if(byte_count == 0) begin
													DC = 1'b0;
													RES = 1'b1;
													VCCEN = 1'b0;
													PMODEN = 1'b1;
													slave_select <= 1'b1;
													STATE <= StateTYPE_wait_ss;
												end
											else if(byte_count == 5'b1) begin
														RES = 0;
														slave_select <= 1'b1;
														STATE <= StateTYPE_wait_ss;
												end
											else if(byte_count == 5'd2) begin
														RES = 1;
														slave_select <= 1'b1;
														STATE <= STATE;
												end
											else if(byte_count == 5'd13) begin
														VCCEN = 1;
														slave_select <= 1'b1;
														STATE <= StateTYPE_wait_ss;
												end
											else
												begin
													slave_select <= 1'b0;
													begin_transmission <= 1'b1;
													if(byte_count > 5'd13)
														send_data <= SETUP_GYRO[byte_count-4];
													else
														send_data <= SETUP_GYRO[byte_count-3];
													STATE <= StateTYPE_hold;
												end
			
											byte_count <= byte_count + 1'b1;
											previousSTATE <= StateTYPE_setup;
											
										end
									else
										begin
											byte_count <= 0;
											previousSTATE <= StateTYPE_setup;
											address = 0;
											STATE <= StateTYPE_wait_run;
										end
							end
							// temp
//							StateTYPE_temp :
//								if (byte_count == 0)
//								begin
//									slave_select <= 1'b0;
//									send_data <= TEMP_READ_BEGIN;
//									byte_count <= byte_count + 1'b1;
//									begin_transmission <= 1'b1;
//									previousSTATE <= StateTYPE_temp;
//									STATE <= StateTYPE_hold;
//								end
//								else if (byte_count == 1)
//								begin
//									send_data <= 8'h00;
//									byte_count <= byte_count + 1'b1;
//									begin_transmission <= 1'b1;
//									previousSTATE <= StateTYPE_temp;
//									STATE <= StateTYPE_hold;
//								end
//								else
//								begin
//									byte_count <= 0;
//									previousSTATE <= StateTYPE_temp;
//									STATE <= StateTYPE_wait_ss;
//								end
//							
							// run
							StateTYPE_run :begin
//								if (byte_count == 0)
//								begin
//									slave_select <= 1'b0;
//									send_data <= DATA_READ_BEGIN;
//									byte_count <= byte_count + 1'b1;
//									begin_transmission <= 1'b1;
//									previousSTATE <= StateTYPE_run;
//									STATE <= StateTYPE_hold;
//								end
//								else if (byte_count <= 6)
//								begin
//									send_data <= 8'h00;
//									byte_count <= byte_count + 1'b1;
//									begin_transmission <= 1'b1;
//									previousSTATE <= StateTYPE_run;
//									STATE <= StateTYPE_hold;
//								end
//								else
//								begin
//									byte_count <= 0;
//									x_axis_data <= axis_data[15:0];
//									y_axis_data <= axis_data[31:16];
//									z_axis_data <= axis_data[47:32];
//									previousSTATE <= StateTYPE_run;
//									STATE <= StateTYPE_wait_ss;
//								end

//								if(byte_count < 5'd6)
//								begin
//									DC = 0;
//									send_data = RUN_BEGIN[byte_count];
//									byte_count <= byte_count + 1'b1;
//								end
//	
//								else if(byte_count == 5'd6)
//								begin
//									DC = 1;
//									send_data <= p[15:8];
//									byte_count <= byte_count + 1'b1;
//								end
//								else
//								begin
//									DC = 1;
//									send_data <= p[7:0];
//									byte_count <= 5'd6;
//									address = address + 1'b1;
//									if(address == 13'd6144)
//									begin
//										STATE <= StateTYPE_wait_run;
//										address = 0;
//									end
//								end
//								
								previousSTATE <= StateTYPE_run;
								begin_transmission <= 1'b1;
								STATE <= StateTYPE_hold;
								slave_select <= 1'b0;
								if(byte_count < 5'd6)
								begin
									DC = 0;
									send_data = RUN_BEGIN[byte_count];
									byte_count <= byte_count + 1'b1;
								end
								else
								begin
									DC = 1;
									send_data <= p[7:0];
									byte_count <= byte_count;
									address = address + 1'b1;
									if(address == 13'd6144)
									begin
										STATE <= StateTYPE_wait_run;
										address = 0;
									end
								end
								
							end
							
							// hold
							StateTYPE_hold :
								begin
									begin_transmission <= 1'b0;
									if (end_transmission == 1'b1)
									begin
//										if (previousSTATE == StateTYPE_temp & byte_count != 1)
//											temp_data <= recieved_data;
//										else if (previousSTATE == StateTYPE_run & byte_count != 1) begin
////												case (byte_count)
////														5'd2 : axis_data[7:0] <= recieved_data;
////														5'd3 : axis_data[15:8] <= recieved_data;
////														5'd4 : axis_data[23:16] <= recieved_data;
////														5'd5 : axis_data[31:24] <= recieved_data;
////														5'd6 : axis_data[39:32] <= recieved_data;
////														5'd7 : axis_data[47:40] <= recieved_data;
////														default : ;
////												endcase
//										end
										STATE <= previousSTATE;
									end
								end
							
							// wait_ss
							StateTYPE_wait_ss :
								begin
									slave_select = 1'b1;
									begin_transmission <= 1'b0;
									if (ss_count == SS_COUNT_MAX)
									begin
										slave_select <= 1'b1;
										ss_count <= {32{1'b0}};
										STATE <= StateTYPE_setup;
									end
									else
										ss_count <= ss_count + 1'b1;
								end

							// wait_run
							StateTYPE_wait_run :
								begin
									byte_count = 0;
									begin_transmission <= 1'b0;
									slave_select <= 1'b1;
									if (start == 1'b0)
										STATE <= StateTYPE_idle;
									if (count_wait == COUNT_WAIT_MAX)
									begin
										count_wait <= {32{1'b0}};
//										if (previousSTATE == StateTYPE_temp)
											STATE <= StateTYPE_run;
//										else
//											STATE <= StateTYPE_temp;
									end
									else
										count_wait <= count_wait + 1'b1;
								end
						endcase
				end
			end
   
endmodule


