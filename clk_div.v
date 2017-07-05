module clk_div
(
	input clk,
	output reg clk_out
);

reg [16:0] cnt; 

always @(posedge clk) begin
	if (cnt == 17'd124999)
		begin
			cnt <= 17'd0;
			clk_out <= ~clk_out;
		end
	else 
		cnt <= cnt + 17'd1;
end

endmodule
