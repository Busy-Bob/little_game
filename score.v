module score (
	input clk, gameover, rst, speed,
	
	output reg [3:0] seg_sel,
	output reg [7:0] SM
);

reg [32:0] time_cnt, time_max;
reg [3:0] sd1, sd2, sd3, sd4, disresult;

always @ (*) begin
	if (speed)
		time_max <= 32'd999999;
	else
		time_max <= 32'd1999999;
end

always @ (posedge clk or posedge rst) begin
	if (rst)
	begin
		sd1 <= 0;
		sd2 <= 0;
		sd3 <= 0;
		sd4 <= 0;
		time_cnt <= 0;
	end
	else if (~gameover)
	begin
		if (time_cnt > time_max)
		begin
			if (sd1 == 4'd9)
			begin
				sd1 <= 4'd0;
				if (sd2 == 4'd9)
				begin
					sd2 <= 4'd0;
					if (sd3 == 4'd9)
					begin
						sd3 <= 4'd0;
						if (sd4 == 4'd9)
							sd4 <= 0;
						else
							sd4 <= sd4 + 4'd1;
					end
					else
						sd3 <= sd3 + 4'd1;
				end
				else
					sd2 <= sd2 + 4'd1;
			end
			else
				sd1 <= sd1 + 4'd1;
			time_cnt <= 32'd0;
		end
		else
			time_cnt <= time_cnt + 32'd1;
	end
	else
	begin
		if (time_cnt > time_max)
			time_cnt <= 32'd0;
		else 
			time_cnt <= time_cnt + 32'd1;
	end
end

always @ (*) begin
	case (time_cnt[5:4])
		0:
		begin
			seg_sel <= 4'b0001;
			disresult <= sd1;
		end
		1:
		begin
			seg_sel <= 4'b0010;
			disresult <= sd2;
		end
		2:
		begin
			seg_sel <= 4'b0100;
			disresult <= sd3;
		end
		3:
		begin
			seg_sel <= 4'b1000;
			disresult <= sd4;
		end
	endcase
end

always @ (*) begin
	case (disresult)
		4'b0001:
			SM <= 8'b10011111;
		4'b0010:
			SM <= 8'b00100101;
		4'b0011:
			SM <= 8'b00001101;
		4'b1010:
			SM <= 8'b00010001;
			
		4'b0100:
			SM <= 8'b10011001;
		4'b0101:
			SM <= 8'b01001001;
		4'b0110:
			SM <= 8'b01000001;
		4'b1011:
			SM <= 8'b11000001;
			
		4'b0111:
			SM <= 8'b00011111;
		4'b1000:
			SM <= 8'b00000001;
		4'b1001:
			SM <= 8'b00001001;
		4'b1100:
			SM <= 8'b01100011;
			
		4'b0000:
			SM <= 8'b00000011;
		4'b1111:
			SM <= 8'b11111111;
		4'b1110:
			SM <= 8'b01100001;
		4'b1101:
			SM <= 8'b10000101;
	endcase
end

endmodule
