module test_reg_file();

	import tb_type_defines_pkg::*;
	logic[31:0] ocl_value;
	int timeout_count;
		
	initial begin
		
		// power up
		tb.power_up(
			.clk_recipe_a(ClockRecipe::A1),
			.clk_recipe_b(ClockRecipe::B0),
			.clk_recipe_c(ClockRecipe::C0)
		);

		// set start_addr
		tb.poke_ocl(.addr(32'h0000_0500), .data(32'hffff_dddd));
		#50ns;

		tb.peek_ocl(.addr(32'h0000_0500), .data(ocl_value));
		$display("value of ocl at 500: %0x", ocl_value);
		#50ns;

		// set burst_len
		tb.poke_ocl(.addr(32'h0000_0504), .data(32'haaaa_bbbb));
		#50ns;

		tb.peek_ocl(.addr(32'h0000_0504), .data(ocl_value));
		$display("value of ocl at 504: %0x", ocl_value);
		
		// set write_val
		tb.poke_ocl(.addr(32'h0000_0508), .data(32'h7777_3333));
		#50ns;

		tb.peek_ocl(.addr(32'h0000_0508), .data(ocl_value));
		$display("value of ocl at 504: %0x", ocl_value);
	
		// power down
		#500ns;	
		tb.power_down();
  		$finish;
	end
endmodule
