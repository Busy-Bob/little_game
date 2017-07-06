module choose_mode(input IN_control, input IN_left, input IN_right, input IN_speed_key, input [1:0] IN_car_move, input IN_speed_sensor,
						output [1:0] OUT_car_move, output OUT_speed);
	assign OUT_car_move[0] = IN_control? IN_car_move[0] : IN_left;
	assign OUT_car_move[1] = IN_control? IN_car_move[1] : IN_right;
	assign OUT_speed = IN_control? IN_speed_sensor : IN_speed_key;
endmodule
	