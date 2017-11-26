module test_ocl();

	import tb_type_defines_pkg::*;
	logic[15:0] vdip_value;
	logic[15:0] vled_value;
	logic[31:0] ocl_value;
	int timeout_count;

	initial begin
	
		// power up
		tb.power_up(
			.clk_recipe_a(ClockRecipe::A1),
			.clk_recipe_b(ClockRecipe::B0),
			.clk_recipe_c(ClockRecipe::C0)
		);
		
		// poke ddr to initialize	
		tb.poke_stat(.addr(8'h0c), .ddr_idx(0), .data(32'h0000_0000));
		tb.poke_stat(.addr(8'h0c), .ddr_idx(1), .data(32'h0000_0000));
		tb.poke_stat(.addr(8'h0c), .ddr_idx(2), .data(32'h0000_0000));
		tb.nsec_delay(25000);
		tb.issue_flr();

		// reset vDIP to zero
		tb.set_virtual_dip_switch(.dip(16'h0000));
		vdip_value = tb.get_virtual_dip_switch();
		$display("value of vdip: %0x", vdip_value);
		#50ns;

		// set start_addr
		tb.poke_ocl(.addr(64'h0000_0000_0000_0500), .data(32'h0));
		#50ns;

		tb.peek_ocl(.addr(64'h0000_0000_0000_0500), .data(ocl_value));
		$display("value of ocl at 500: %0x", ocl_value);
		#50ns;

		// set read len
		tb.poke_ocl(.addr(64'h0000_0000_0000_0504), .data(32'h1));
		#50ns;

		tb.peek_ocl(.addr(64'h0000_0000_0000_0504), .data(ocl_value));
		$display("value of ocl at 504: %0x", ocl_value);
		#50ns;
		/*
		// trigger mem_reader
		tb.set_virtual_dip_switch(.dip(16'h0001));
		#50ns;
	
		timeout_count = 0;
		do begin
			vled_value = tb.get_virtual_led();
			#10ns;
			timeout_count++;
		end while((vled_value[0] != 1) && (timeout_count < 100));	
	
		$display("[%t] : timeout_count = %d", $realtime, timeout_count);
		
		if (timeout_count >= 100) begin
			$display("[%t] : mem_reader timed out.", $realtime);
		end

		// deactivate mem reader.
		tb.set_virtual_dip_switch(.dip(16'h0000));
		*/
		#500ns;	
		tb.power_down();
  		$finish;
	end

endmodule

