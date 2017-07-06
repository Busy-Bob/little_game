module game_ctrl (
	input clk, rst, speed, wudi,
	input [1:0] car_move,
	input [2:0] barrier_in,
	
	output [22:0] disdata,
	output reg gameover, dis,
	output reg [7:0] cnt,
	output reg [6:0] wudidis
	
);

reg [22:0] displaydata;
reg [2:0] state;
reg [1:0] car_mov;
reg [4:0] car_state;
reg [2:0] car_sta;
reg [2:0] wudi_cnt;
reg [1:0] wudi_time;
reg [31:0] time_cnt;
reg [2:0] barrier [7:0];

always @ (posedge clk or posedge rst) begin
	if (rst)
	begin
		state <= 0;
		car_state <= 5'b00100;
		car_sta <= 3'b010;
		cnt <= 0;
		time_cnt <= 0;
		wudi_cnt <= 3'd4;
		wudi_time <= 2'd0;
		dis <= 0;
		gameover <= 0;
		barrier[0] <= 0;
		barrier[1] <= 0;
		barrier[2] <= 0;
		barrier[3] <= 0;
		barrier[4] <= 0;
		barrier[5] <= 0;
		barrier[6] <= 0;
		barrier[7] <= 0;
	end
	else
	begin
		time_cnt <= time_cnt + 32'd1;
		case (state)
			0:	//初始化障碍物信息
			begin
				dis <= 0;
				if (time_cnt == 32'd8)
				begin
					barrier[0] <= barrier[1];
					barrier[1] <= barrier[2];
					barrier[2] <= barrier[3];
					barrier[3] <= barrier[4];
					barrier[4] <= barrier[5];
					barrier[5] <= barrier[6];
					barrier[6] <= barrier[7];
					barrier[7] <= barrier_in;
					cnt <= cnt + 8'd1;
				end
				if (time_cnt == 32'd16)
					state <= 1;
			end
			1:	//读取汽车移动信号
			begin
				if (time_cnt == 32'd24)
				begin
					car_mov <= car_move;
					if (car_state == 5'b10000 && car_move == 2'b01)
						car_state <= 5'b01000;
					else if (car_state == 5'b00100 && car_move == 2'b01) 
						car_state <= 5'b00010;
					else if (car_state == 5'b00100 && car_move == 2'b10)
						car_state <= 5'b01000;
					else if (car_state == 5'b00001 && car_move == 2'b10)
						car_state <= 5'b00010;
					
				end
				if (time_cnt == 32'd32)
					state <= 2;
			end
			2:	//输出过程动画
			begin
				if (time_cnt == 32'd48)
					displaydata <= {barrier[7], barrier[6], barrier[5], barrier[4], barrier[3], barrier[2], car_state};
				if (time_cnt == 32'd64)
					dis <= 1;
				if (time_cnt == 32'd65)
					dis <= 0;
				if (time_cnt == 32'd80)
					state <= 3;
			end
			3:	//更新最终画面
			begin
				if (time_cnt == 32'd4250008)
				begin
					barrier[0] <= barrier[1];
					barrier[1] <= barrier[2];
					barrier[2] <= barrier[3];
					barrier[3] <= barrier[4];
					barrier[4] <= barrier[5];
					barrier[5] <= barrier[6];
					barrier[6] <= barrier[7];
					barrier[7] <= 3'd0;
					if (car_state == 5'b01000 && car_mov == 2'b01)
						car_state <= 5'b00100;
					else if (car_state == 5'b00010 && car_mov == 2'b01) 
						car_state <= 5'b00001;
					else if (car_state == 5'b01000 && car_mov == 2'b10)
						car_state <= 5'b10000;
					else if (car_state == 5'b00010 && car_mov == 2'b10)
						car_state <= 5'b00100;
				end
				if (time_cnt == 32'd4250016)
				begin
					state <= 4;
					car_sta <= {car_state[4],car_state[2],car_state[0]};
				end
			end
			4:	//判断是否死亡
			begin
				if (time_cnt == 32'd4250020)
					if (wudi && wudi_cnt != 3'd0) 
						wudi_time <= 2'd3;
				if (time_cnt == 32'd4250024)
					if (wudi_time != 2'd0 && wudi_cnt != 3'd0)
					begin
						gameover <= 0;
						wudi_time <= wudi_time - 2'd1;
					end
					else
					begin
						if ((barrier[0] & car_sta) != 3'd0)
						begin
							gameover <= 1;
							state <= 7;
						end
					end
				if (time_cnt == 32'd4250028)
					if (wudi_time == 2'd1)
						wudi_cnt <= wudi_cnt - 3'd1;
				if (time_cnt == 32'd4250032)
					state <= 5;
			end
			5:	//输出最终画面
			begin
				if (speed) 
				begin
					time_cnt <= time_cnt + 32'd2;
				end
				if (time_cnt == 32'd6250048 || time_cnt == 32'd6250049)
					displaydata <= {barrier[6], barrier[5], barrier[4], barrier[3], barrier[2], barrier[1], car_state};
				if (time_cnt == 32'd6250064 || time_cnt == 32'd6250065)
					dis <= 1;
				if (time_cnt == 32'd6250066 || time_cnt == 32'd6250067)
					dis <= 0;
				if (time_cnt == 32'd6250080 || time_cnt == 32'd6250081)
					state <= 6;
			end
			6:	//延时
			begin
				if (speed)
				begin
					time_cnt <= time_cnt + 32'd2;
				end
				if (time_cnt == 32'd12500000 || time_cnt == 32'd12500001)
				begin
					time_cnt <= 32'd0;
					state <= 0;
				end
			end
			7:	//结束状态
			begin
				state <= 7;
			end
		endcase
	end
end

always @ (*) begin
	case (wudi_cnt)
		0:	wudidis <= 7'b0000000;
		1: wudidis <= 7'b1000000;
		2: wudidis <= 7'b1100000;
		3: wudidis <= 7'b1110000;
		4: wudidis <= 7'b1111000;
		5: wudidis <= 7'b1111100;
		6: wudidis <= 7'b1111110;
		7: wudidis <= 7'b1111111;
	endcase
end

assign disdata[22] = displaydata[0];
assign disdata[21] = displaydata[1];
assign disdata[20] = displaydata[2];
assign disdata[19] = displaydata[3];
assign disdata[18] = displaydata[4];
assign disdata[17] = displaydata[5];
assign disdata[16] = displaydata[6];
assign disdata[15] = displaydata[7];
assign disdata[14] = displaydata[8];
assign disdata[13] = displaydata[9];
assign disdata[12] = displaydata[10];
assign disdata[11] = displaydata[11];
assign disdata[10] = displaydata[12];
assign disdata[9] = displaydata[13];
assign disdata[8] = displaydata[14];
assign disdata[7] = displaydata[15];
assign disdata[6] = displaydata[16];
assign disdata[5] = displaydata[17];
assign disdata[4] = displaydata[18];
assign disdata[3] = displaydata[19];
assign disdata[2] = displaydata[20];
assign disdata[1] = displaydata[21];
assign disdata[0] = displaydata[22];


endmodule








//===========================================================
////第一代版本：不能调速
//
//module game_ctrl (
//	input clk, rst,
//	input [1:0] car_move,
//	input [2:0] barrier_in,
//	
//	output reg [22:0] displaydata,
//	output reg gameover, dis,
//	output reg [7:0] cnt
//	
//);
//
//reg [2:0] state;
//reg [1:0] car_mov;
//reg [4:0] car_state;
//reg [2:0] car_sta;
//reg [31:0] time_cnt;
//reg [2:0] barrier [7:0];
//
//always @ (posedge clk or posedge rst) begin
//	if (rst)
//	begin
//		state <= 0;
//		car_state <= 5'b00100;
//		car_sta <= 3'b010;
//		cnt <= 0;
//		time_cnt <= 0;
//		dis <= 0;
//		gameover <= 0;
//		barrier[0] <= 0;
//		barrier[1] <= 0;
//		barrier[2] <= 0;
//		barrier[3] <= 0;
//		barrier[4] <= 0;
//		barrier[5] <= 0;
//		barrier[6] <= 0;
//		barrier[7] <= 0;
//	end
//	else
//	begin
//		time_cnt <= time_cnt + 32'd1;
//		case (state)
//			0:	//初始化障碍物信息
//			begin
//				dis <= 0;
//				if (time_cnt == 32'd8)
//				begin
//					barrier[0] <= barrier[1];
//					barrier[1] <= barrier[2];
//					barrier[2] <= barrier[3];
//					barrier[3] <= barrier[4];
//					barrier[4] <= barrier[5];
//					barrier[5] <= barrier[6];
//					barrier[6] <= barrier[7];
//					barrier[7] <= barrier_in;
//					cnt <= cnt + 8'd1;
//				end
//				else if (time_cnt == 32'd16)
//					state <= 1;
//			end
//			1:	//读取汽车移动信号
//			begin
//				if (time_cnt == 32'd24)
//				begin
//					car_mov <= car_move;
//					if (car_state == 5'b10000 && car_move == 2'b01)
//						car_state <= 5'b01000;
//					else if (car_state == 5'b00100 && car_move == 2'b01) 
//						car_state <= 5'b00010;
//					else if (car_state == 5'b00100 && car_move == 2'b10)
//						car_state <= 5'b01000;
//					else if (car_state == 5'b00001 && car_move == 2'b10)
//						car_state <= 5'b00010;
//					
//				end
//				else if (time_cnt == 32'd32)
//					state <= 2;
//			end
//			2:	//输出过程动画
//			begin
//				if (time_cnt == 32'd48)
//					displaydata <= {barrier[7], barrier[6], barrier[5], barrier[4], barrier[3], barrier[2], car_state};
//				else if (time_cnt == 32'd64)
//					dis <= 1;
//				else if (time_cnt == 32'd65)
//					dis <= 0;
//				else if (time_cnt == 32'd80)
//					state <= 3;
//			end
//			3:	//更新最终画面
//			begin
//				if (time_cnt == 32'd88)
//				begin
//					barrier[0] <= barrier[1];
//					barrier[1] <= barrier[2];
//					barrier[2] <= barrier[3];
//					barrier[3] <= barrier[4];
//					barrier[4] <= barrier[5];
//					barrier[5] <= barrier[6];
//					barrier[6] <= barrier[7];
//					barrier[7] <= 3'd0;
//					if (car_state == 5'b01000 && car_mov == 2'b01)
//						car_state <= 5'b00100;
//					else if (car_state == 5'b00010 && car_mov == 2'b01) 
//						car_state <= 5'b00001;
//					else if (car_state == 5'b01000 && car_mov == 2'b10)
//						car_state <= 5'b10000;
//					else if (car_state == 5'b00010 && car_mov == 2'b10)
//						car_state <= 5'b00100;
//				end
//				else if (time_cnt == 32'd96)
//				begin
//					state <= 4;
//					car_sta <= {car_state[4],car_state[2],car_state[0]};
//				end
//			end
//			4:	//判断是否死亡
//			begin
//				if (time_cnt == 32'd112)
//					if (barrier[0] & car_sta != 3'd0)
//					begin
//						gameover <= 1;
//						state <= 7;
//					end
//				else if (time_cnt == 32'd128)
//					state <= 5;
//			end
//			5:	//输出最终画面
//			begin
//				if (time_cnt == 32'd6250048)
//					displaydata <= { barrier[7], barrier[6], barrier[5], barrier[4], barrier[3], barrier[2], car_state};
//				else if (time_cnt == 32'd6250064)
//					dis <= 1;
//				else if (time_cnt == 32'd6250065)
//					dis <= 0;
//				else if (time_cnt == 32'd6250080)
//					state <= 6;
//			end
//			6:	//延时
//			begin
//				if (time_cnt == 32'd12500000)
//				begin
//					time_cnt <= 32'd0;
//					state <= 0;
//				end
//			end
//			7:	//结束状态
//			begin
//				state <= 7;
//			end
//		endcase
//	end
//end
//
//
//endmodule
//=====================================================================





//=====================================================================
////第二代版本：可以调速，不能无敌
//module game_ctrl (
//	input clk, rst, speed,
//	input [1:0] car_move,
//	input [2:0] barrier_in,
//	
//	output reg [22:0] displaydata,
//	output reg gameover, dis,
//	output reg [7:0] cnt
//	
//);
//
//reg [2:0] state;
//reg [1:0] car_mov;
//reg [4:0] car_state;
//reg [2:0] car_sta;
//reg [31:0] time_cnt;
//reg [2:0] barrier [7:0];
//
//always @ (posedge clk or posedge rst) begin
//	if (rst)
//	begin
//		state <= 0;
//		car_state <= 5'b00100;
//		car_sta <= 3'b010;
//		cnt <= 0;
//		time_cnt <= 0;
//		dis <= 0;
//		gameover <= 0;
//		barrier[0] <= 0;
//		barrier[1] <= 0;
//		barrier[2] <= 0;
//		barrier[3] <= 0;
//		barrier[4] <= 0;
//		barrier[5] <= 0;
//		barrier[6] <= 0;
//		barrier[7] <= 0;
//	end
//	else
//	begin
//		time_cnt <= time_cnt + 32'd1;
//		case (state)
//			0:	//初始化障碍物信息
//			begin
//				dis <= 0;
//				if (time_cnt == 32'd8)
//				begin
//					barrier[0] <= barrier[1];
//					barrier[1] <= barrier[2];
//					barrier[2] <= barrier[3];
//					barrier[3] <= barrier[4];
//					barrier[4] <= barrier[5];
//					barrier[5] <= barrier[6];
//					barrier[6] <= barrier[7];
//					barrier[7] <= barrier_in;
//					cnt <= cnt + 8'd1;
//				end
//				if (time_cnt == 32'd16)
//					state <= 1;
//			end
//			1:	//读取汽车移动信号
//			begin
//				if (time_cnt == 32'd24)
//				begin
//					car_mov <= car_move;
//					if (car_state == 5'b10000 && car_move == 2'b01)
//						car_state <= 5'b01000;
//					else if (car_state == 5'b00100 && car_move == 2'b01) 
//						car_state <= 5'b00010;
//					else if (car_state == 5'b00100 && car_move == 2'b10)
//						car_state <= 5'b01000;
//					else if (car_state == 5'b00001 && car_move == 2'b10)
//						car_state <= 5'b00010;
//					
//				end
//				if (time_cnt == 32'd32)
//					state <= 2;
//			end
//			2:	//输出过程动画
//			begin
//				if (time_cnt == 32'd48)
//					displaydata <= {barrier[7], barrier[6], barrier[5], barrier[4], barrier[3], barrier[2], car_state};
//				if (time_cnt == 32'd64)
//					dis <= 1;
//				if (time_cnt == 32'd65)
//					dis <= 0;
//				if (time_cnt == 32'd80)
//					state <= 3;
//			end
//			3:	//更新最终画面
//			begin
//				if (time_cnt == 32'd4250008)
//				begin
//					barrier[0] <= barrier[1];
//					barrier[1] <= barrier[2];
//					barrier[2] <= barrier[3];
//					barrier[3] <= barrier[4];
//					barrier[4] <= barrier[5];
//					barrier[5] <= barrier[6];
//					barrier[6] <= barrier[7];
//					barrier[7] <= 3'd0;
//					if (car_state == 5'b01000 && car_mov == 2'b01)
//						car_state <= 5'b00100;
//					else if (car_state == 5'b00010 && car_mov == 2'b01) 
//						car_state <= 5'b00001;
//					else if (car_state == 5'b01000 && car_mov == 2'b10)
//						car_state <= 5'b10000;
//					else if (car_state == 5'b00010 && car_mov == 2'b10)
//						car_state <= 5'b00100;
//				end
//				if (time_cnt == 32'd4250016)
//				begin
//					state <= 4;
//					car_sta <= {car_state[4],car_state[2],car_state[0]};
//				end
//			end
//			4:	//判断是否死亡
//			begin
//				if (time_cnt == 32'd4250024)
//					if (barrier[0] & car_sta != 3'd0)
//					begin
//						gameover <= 1;
//						state <= 7;
//					end
//				if (time_cnt == 32'd4250032)
//					state <= 5;
//			end
//			5:	//输出最终画面
//			begin
//				if (speed) 
//				begin
//					if (time_cnt == 32'd4250048)
//						displaydata <= {barrier[6], barrier[5], barrier[4], barrier[3], barrier[2], barrier[1], car_state};
//					if (time_cnt == 32'd4250064)
//						dis <= 1;
//					if (time_cnt == 32'd4250065)
//						dis <= 0;
//					if (time_cnt == 32'd4250080)
//						state <= 6;
//				end
//				else
//				begin
//					if (time_cnt == 32'd6250048)
//						displaydata <= {barrier[6], barrier[5], barrier[4], barrier[3], barrier[2], barrier[1], car_state};
//					if (time_cnt == 32'd6250064)
//						dis <= 1;
//					if (time_cnt == 32'd6250065)
//						dis <= 0;
//					if (time_cnt == 32'd6250080)
//						state <= 6;
//				end
//			end
//			6:	//延时
//			begin
//				if (speed)
//				begin
//					if (time_cnt == 32'd8500000)
//					begin
//						time_cnt <= 32'd0;
//						state <= 0;
//					end
//				end
//				else
//				begin
//					if (time_cnt == 32'd12500000)
//					begin
//						time_cnt <= 32'd0;
//						state <= 0;
//					end
//				end
//			end
//			7:	//结束状态
//			begin
//				state <= 7;
//			end
//		endcase
//	end
//end
//
//
//endmodule
//=============================================================








