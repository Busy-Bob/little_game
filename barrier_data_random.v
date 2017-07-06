module barrier_data_random (
	input [7:0] cnt,
	input [2:0] random_data,
	output reg [2:0] barrier_out
);

always @ (*) begin
	if	(cnt < 8'd7)
		barrier_out <= 0;
	else if (random_data == 3'b111)
		barrier_out <= cnt[2:0];
	else if (cnt[0] == 0)
		barrier_out <= 3'b000;
	else if (random_data == 3'b101 || random_data == 3'b011 || random_data == 3'b110)
		barrier_out <= ~random_data;
	else
		barrier_out <= random_data;
		
end

endmodule
