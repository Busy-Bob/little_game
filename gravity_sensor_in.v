module gravity_sensor_in (
	input clkcs, sclk, data, clk1,
	output reg [1:0] car_move,
	output reg speed,
	output [2:0] random_data
);

reg [11:0] xvalue, yvalue;
parameter [1:0] x1=0,x2=2'b1,y1=2'b10,y2=2'b11;
reg [1:0] state=x1;
integer k=0;
reg fx1=1,fy1=1,fx2=1,fy2=1;

always @ (negedge clkcs) begin
	case(state)
		x1:
		state=x2;
		x2:
		state=y1;
		y1:
		state=y2;
		y2:
		state=x1;
	endcase
end

always @ (posedge sclk) begin
	case(state)
		x1:
		begin
			if (fx1==1)
				k=k+1;
			if (k==21) 
				xvalue[11]=data;
			if (k==22) 
				xvalue[10]=data;
			if (k==23) 
				xvalue[9]=data;
			if (k==24) 
				xvalue[8]=data;
			if (k>24) 
			begin 
				k=0; 
				fx1=0; 
			end
			fy2=1;
		end
		x2:
		begin
			if (fx2==1)
				k=k+1;
			if (k==17) 
				xvalue[7]=data;
			if (k==18) 
				xvalue[6]=data;
			if (k==19) 
				xvalue[5]=data;
			if (k==20) 
				xvalue[4]=data;
			if (k==21) 
				xvalue[3]=data;
			if (k==22) 
				xvalue[2]=data;
			if (k==23) 
				xvalue[1]=data;
			if (k==24) 
				xvalue[0]=data;
			if (k>24) 
			begin 
				k=0; 
				fx2=0; 
			end
			fx1=1;
		end
		y1:
		begin
			if (fy1==1)
				k=k+1;
			if (k==21) 
				yvalue[11]=data;
			if (k==22) 
				yvalue[10]=data;
			if (k==23) 
				yvalue[9]=data;
			if (k==24) 
				yvalue[8]=data;
			if (k>24) 
			begin 
				k=0; 
				fy1=0; 
			end
			fx2=1;
		end
		y2:
		begin
			if (fy2==1)
				k=k+1;
			if (k==17) 
				yvalue[7]=data;
			if (k==18) 
				yvalue[6]=data;
			if (k==19) 
				yvalue[5]=data;
			if (k==20) 
				yvalue[4]=data;
			if (k==21) 
				yvalue[3]=data;
			if (k==22) 
				yvalue[2]=data;
			if (k==23) 
				yvalue[1]=data;
			if (k==24) 
				yvalue[0]=data;
			if (k>24) 
			begin 
				k=0; 
				fy2=0; 
			end
			fy1=1;
		end
	endcase
end

always @(posedge clk1) begin
	if (yvalue[11]==1) 
		speed = 1;
	else
		speed = 0;
	if (xvalue[10:0]<=11'b11011111111&&xvalue[11]==1)
		car_move = 2'b10;
	else if (xvalue[10:0]>=11'b00101000000&&xvalue[11]==0)
		car_move = 2'b01;
	else
		car_move = 2'b00;
	

end

assign random_data = yvalue[2:0];

endmodule
