module keyboard (
	input v1, v2, v3, v4, clk,
	
	output hold1, hold2, hold3, hold4
);

reg hold, ok;
wire push;
assign push = v1|v2|v3|v4;
reg [17:0] time_cnt;

always @ (negedge clk) begin
	if (!ok && push)
		ok <= 1;
	else
	begin
		if (time_cnt < 18'd250000)
			time_cnt <= time_cnt + 18'd1;
		else
		begin
			time_cnt <= 0;
			if (push) 
				hold <= 1;
			else
			begin
				ok <= 0;
				hold <= 0;
			end
		end
	end
end

assign hold1 = v1 & hold;
assign hold2 = v2 & hold;
assign hold3 = v3 & hold;
assign hold4 = v4 & hold;

endmodule 