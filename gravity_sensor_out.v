module gravity_sensor_out(
	input clkcs, clk,
	output reg adress, sclk
);

//reg adress=0, sclk=0;
parameter x1=0,x2=2'b01,y1=2'b10,y2=2'b11;
reg [1:0] state=x1;
reg [15:0] xad1=16'b0000101100001111,xad2=16'b0000101100001110,yad1=16'b0000101100010001,yad2=16'b0000101100010000;
reg [23:0] beginad1=24'b000010100010110100000010;
integer c3=0,k=0,kbefore=0;
reg fbegin=0;
reg fagain=0;


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

always @ (posedge clk) begin
	if (clkcs==1) 
	begin 
		sclk=0;
		c3=0;
		k=0;
		fagain=0;
		kbefore=0;
	end
	else 
	begin
		fagain=1;
		if (c3==25)//2MHz  12     1MHz       25
		begin 
			sclk=0;
			c3=0;
			if (k<30) 
				k=k+1;
		end
		else 
			c3=c3+1;
		if (c3==13)
		begin 
			sclk=1;
		end
	end

	if (fagain==0)
	begin 
		xad1=16'b0000101100001111;
		xad2=16'b0000101100001110;
		yad1=16'b0000101100010001;
		yad2=16'b0000101100010000;
	end

	if (fbegin==0&&clkcs==0)
	begin
		if (k!=kbefore) 
		begin
			kbefore=k;
			beginad1=beginad1<<1;
			adress=beginad1[23];
		end
		if (k==28) 
			fbegin=1;
	end
	else
	begin
		case(state)
			x1:
				begin
					if (k!=kbefore) 
					begin
						kbefore=k;
						xad1=xad1<<1;
						adress=xad1[15];
					end
				end
			x2:
				begin
					if (k!=kbefore) 
					begin
						kbefore=k;
						xad2=xad2<<1;
						adress=xad2[15];
					end
				end
			y1:
				begin
					if (k!=kbefore) 
					begin
						kbefore=k;
						yad1=yad1<<1;
						adress=yad1[15];
					end
				end
			y2:
				begin
					if (k!=kbefore) 
					begin
						kbefore=k;
						yad2=yad2<<1;
						adress=yad2[15];
					end
				end
		endcase
	end
end

endmodule
