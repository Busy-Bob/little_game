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
		game_data,
		game_end,
		data_update,
		p,
		p_another,
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
		address,
		car_address
//		temp_data, //用于储存temp过程中的data
//		x_axis_data,
//		y_axis_data,
//		z_axis_data
);

// ==============================================================================
// 									   Port Declarations
// ==============================================================================
			output [12:0]    address;
			output [9:0]		car_address;
			output           begin_transmission;
//			input [7:0]      recieved_data;
			input            end_transmission;
			input            clk;
//			input            rst;
			input            start;
			input [7:0]     	p;
			input [7:0]			p_another;
			input [22:0]		game_data;
			input 				game_end;
			input 				data_update;
	
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
			reg [9:0]		car_address;
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
//								  StateTYPE_wait_run = 5,
								  StateTYPE_redraw = 6,
								  StateTYPE_end = 5;
			reg [2:0]        STATE;
			reg [2:0]        previousSTATE;
//			reg [7:0]		  Z0[100:0];
//			reg [7:0]		  Z3[100:0];
//			reg [7:0]		  Z6[100:0];
// 			reg [7:0]		  Z9[100:0];
//			reg [7:0]		  Z12[100:0];
//			reg [7:0]		  Z15[100:0];
//			reg [7:0]		  C18[100:0];
//			reg [7:0]		  C19[100:0];
//			reg [7:0]		  C20[100:0];
//			reg [7:0]		  C21[100:0];
//			reg [7:0]		  C22[100:0];
					
			reg show_flag;
			reg [7:0]     		now_draw = 0;
			reg [9:0] 			previousaddress; //用于储存car_address

			// setup control register 1 to enable x, y, and z. CTRL_REG1 (0x20)
			// with read and multiple bytes not selected
			// output data rate of 100 Hz
			// will output 8.75 mdps/digit at 250 dps maximum
			// ?????设置内容？
			reg [7:0] SETUP_GYRO [50:0];
			reg [7:0] LOCATION [137:0];  //必须要设置和文件一模一样大小
			reg [7:0] RUN_BEGIN [5:0];
			// address of X_AXIS (0x28) with read and multiple bytes selected (0xC0)
			//parameter [7:0]  DATA_READ_BEGIN = 8'hE8;
			// address of TEMP (0x26) with read selected (0x80)
			//parameter [7:0]  TEMP_READ_BEGIN = 8'hA6;
			
			//parameter        MAX_BYTE_COUNT = 6;
			reg [7:0]        byte_count = 0;
			reg [4:0]			row_add = 0;
//			reg [9:0]			now_row_p_another = 0;
			
			parameter [31:0] SS_COUNT_MAX = 32'd2000000;
			reg [31:0]       ss_count;
			
			parameter [31:0] COUNT_WAIT_MAX = 32'd25000000;		//X"000FFF";
			reg [31:0]       count_wait;
//			reg [47:0]       axis_data;
			
			initial
			begin
				$readmemh("1.txt",SETUP_GYRO);
				$readmemh("2.txt",RUN_BEGIN);
				$readmemh("3.txt",LOCATION);
//				$readmemh("Z0.txt",Z0);
//				$readmemh("Z3.txt",Z3);
//				$readmemh("Z6.txt",Z6);
//				$readmemh("Z9.txt",Z9);
//				$readmemh("Z12.txt",Z12);
//				$readmemh("Z15.txt",Z15);
//				
//				$readmemh("C18.txt",C18);
//				$readmemh("C19.txt",C19);
//				$readmemh("C20.txt",C20);
//				$readmemh("C21.txt",C21);
//				$readmemh("C22.txt",C22);
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
									if (byte_count < 45+4)
										begin
											if(byte_count == 0) begin
													DC = 1'b0;
													RES = 1'b1;
													VCCEN = 1'b0;
													PMODEN = 1'b1;
													slave_select <= 1'b1;
													STATE <= StateTYPE_wait_ss;
												end
											else if(byte_count == 8'b1) begin
														RES = 0;
														slave_select <= 1'b1;
														STATE <= StateTYPE_wait_ss;
												end
											else if(byte_count == 8'd2) begin
														RES = 1;
														slave_select <= 1'b1;
														STATE <= STATE;
												end
											else if(byte_count == 8'd37) begin
														VCCEN = 1;
														slave_select <= 1'b1;
														STATE <= StateTYPE_wait_ss;
												end
											else
												begin
													slave_select <= 1'b0;
													begin_transmission <= 1'b1;
													if(byte_count > 8'd37)
														send_data <= SETUP_GYRO[byte_count-4];
													else
														send_data <= SETUP_GYRO[byte_count-3];
													STATE <= StateTYPE_hold;
												end
			
											byte_count <= byte_count + 1'b1;
											previousSTATE <= StateTYPE_setup;
											
										end
									else // 初始化地方
										begin
											byte_count <= 0;
											now_draw <= 0;
											previousSTATE <= StateTYPE_setup;
											address = 0;
											STATE <= StateTYPE_run;
											show_flag <= 0;
//											now_row_p_another <= 0;
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
								if(!show_flag)
									begin
										previousSTATE <= StateTYPE_run;
										begin_transmission <= 1'b1;
										STATE <= StateTYPE_hold;
										slave_select <= 1'b0;
										if(byte_count < 8'd6)
										begin
											DC <= 0;
											send_data <= RUN_BEGIN[byte_count];
											byte_count <= byte_count + 1'b1;
										end
										else
										begin
											DC <= 1;
											send_data <= p[7:0];
											byte_count <= byte_count;
											address <= address + 1'b1;
											if(address == 13'd6144)
											begin
												STATE <= StateTYPE_run;
												address <= 0;
												show_flag <= 1;
												slave_select <= 1'b1;
												byte_count <= 0;
											end
										end
									end
								else if(data_update)  //初始化地方
									begin
										previousSTATE <= StateTYPE_run;
										STATE <= StateTYPE_redraw;
										address <= LOCATION[4] * 13'd96 + LOCATION[1];
										car_address <= 0;
										byte_count <= 0;
										row_add <= 0;
										now_draw <= 0;
//										now_row_p_another <= 0;
									end
								if(!start)
										STATE <= StateTYPE_end;
							end
							
							StateTYPE_redraw:  // 每个地方都要处理address
								begin
									if(game_end)
										begin
										
										end
									else if(now_draw == 8'd23)
										begin
											STATE <= StateTYPE_run;
											now_draw <= 0;
										end
										
									else		
										begin
											if(game_data[now_draw])
												begin
													address <= LOCATION[4+(now_draw+1)*6] * 13'd96 + LOCATION[1+(now_draw+1)*6]; //为了使得下次可以直接运算，不用等待
													previousSTATE <= StateTYPE_redraw;
													begin_transmission <= 1'b1;
													STATE <= StateTYPE_hold;
													slave_select <= 1'b0;
													if(byte_count < 8'd6)
													begin
														DC = 0;
														send_data <= LOCATION[byte_count+6*now_draw];
														byte_count <= byte_count + 1'b1;
														//增加一个赋值给previousaddress的
														previousaddress <= car_address;
													end
													else
													begin
														DC = 1;
														send_data <= p_another[7:0];
														byte_count <= byte_count;
														car_address <= car_address + 1'b1;
														if(car_address - previousaddress >= (LOCATION[6*now_draw+2]-LOCATION[6*now_draw+1]+1)*(LOCATION[6*now_draw+5]-LOCATION[6*now_draw+4]+1))
														begin
															now_draw <= now_draw + 1;
															byte_count <= 0;
															STATE <= StateTYPE_redraw;
															car_address <= car_address;
															slave_select <= 1'b1;
															begin_transmission <= 1'b0;
														end
													end
												end
											else
												begin
													previousSTATE <= StateTYPE_redraw;
													begin_transmission <= 1'b1;
													STATE <= StateTYPE_hold;
													slave_select <= 1'b0;
													if(byte_count == 8'd0)
													begin
														DC = 0;
														send_data <= LOCATION[byte_count+6*now_draw];
														byte_count <= byte_count + 1'b1;
														car_address <= car_address + (LOCATION[6*now_draw+2]-LOCATION[6*now_draw+1]+1)*(LOCATION[6*now_draw+5]-LOCATION[6*now_draw+4]+1); 
													end
													else if(byte_count < 8'd6)
													begin
														DC = 0;
														send_data <= LOCATION[byte_count+6*now_draw];
														byte_count <= byte_count + 1'b1;
													end
													else
													begin
														DC = 1;
														send_data <= p[7:0];
														byte_count <= byte_count;
														if(address < (LOCATION[4+now_draw*6]+row_add)*13'd96 + LOCATION[2+now_draw*6])
															address <= address + 1'b1;
														else
															begin
																address <= address + 13'd96 - {{5'b0},LOCATION[2+now_draw*6]} + {{5'b0},LOCATION[1+now_draw*6]};
																row_add <= row_add + 1'b1;
															end
														if(row_add > LOCATION[5+now_draw*6] - LOCATION[4+now_draw*6])
														begin
															now_draw <= now_draw + 1;
															byte_count <= 0;
															STATE <= StateTYPE_redraw;
															address <= LOCATION[4+(now_draw+1)*6] * 13'd96 + LOCATION[1+(now_draw+1)*6];
															slave_select <= 1'b1;
															begin_transmission <= 1'b0;
															row_add <= 0; 
														end
													end
												end
										end
										
									if(!start)
										STATE <= StateTYPE_end;
								
								
								
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
/*							StateTYPE_wait_run :
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
								*/
							StateTYPE_end: 
								begin
									if(show_flag)
										begin
											DC = 1'b0;
											slave_select <= 1'b0;
											begin_transmission <= 1'b1;
											send_data <= 8'hAE;
											show_flag <= 0;
										end
									else	
										begin
											VCCEN = 0;
											STATE = StateTYPE_idle;
										end
								
								end
						endcase
				end
			end
   
endmodule


