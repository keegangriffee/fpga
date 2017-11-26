module test_dram_dma_b();

	import tb_type_defines_pkg::*;
	
	int error_count;
	int timeout_count;
	int fail;
	logic [3:0] status;
	int len0 = 128;
	int READ_BUFFER_ADDR = 64'h10000;
	int WRITE_BUFFER_ADDR = 64'h0;
	logic[63:0] host_memory_buffer_addr;
	logic[7:0] write_val;
	logic[7:0] read_val;
	initial begin

		$display("[%t]", $realtime);
		$display("[%t]", $realtime);
		$display("[%t]", $realtime);

		tb.power_up(
			.clk_recipe_a(ClockRecipe::A1),
			.clk_recipe_b(ClockRecipe::B0),
			.clk_recipe_c(ClockRecipe::C0));
		
		// poke ddr to initialize	
		tb.poke_stat(.addr(8'h0c), .ddr_idx(0), .data(32'h0000_0000));
		tb.poke_stat(.addr(8'h0c), .ddr_idx(1), .data(32'h0000_0000));
		tb.poke_stat(.addr(8'h0c), .ddr_idx(2), .data(32'h0000_0000));

		tb.nsec_delay(25000);

       	tb.issue_flr();
		$display("[%t] : initializing buffers", $realtime);

		host_memory_buffer_addr = WRITE_BUFFER_ADDR;
		
		tb.que_buffer_to_cl(
			.chan(1),
			.src_addr(host_memory_buffer_addr),
			.cl_addr(64'h0),
			.len(len0)
		);

		// Initialize host memory buffer
		write_val = 8'hBB;
		for (int i = 0; i < len0; i++) begin
			tb.hm_put_byte(
				.addr(host_memory_buffer_addr), 
				.d(write_val)
			);
			host_memory_buffer_addr++; 
		end

		// transfer data from host to cl.		
		$display("[%t] : starting data transfer from host to cl.", $realtime);
		tb.start_que_to_cl(.chan(1));
		timeout_count = 0;

		do begin
			status[0] = tb.is_dma_to_cl_done(.chan(1));
			#10ns;
			timeout_count++;
		end while ((status[0] != 1'b1) && (timeout_count < 1000));

		$display("timeout_count = %d", timeout_count);

		if (timeout_count >= 1000) begin
			$display("[%t] : dma transfer from host to cl timed out.", $realtime);
		end			

		// transfer data from cl to host
        tb.que_cl_to_buffer(
			.chan(1),
			.dst_addr(READ_BUFFER_ADDR),
			.cl_addr(64'h0),
			.len(len0)
		);

		$display("[%t] : starting data transfer from cl to host.", $realtime);
		tb.start_que_to_buffer(.chan(1));	
		timeout_count = 0;
		
		do begin
			status[0] = tb.is_dma_to_buffer_done(.chan(1));
			#10ns;
			timeout_count++;
		end while ((status[0] != 1'b1) && (timeout_count < 100));
		
		$display("timeout_count = %d", timeout_count);
		
		if (timeout_count >= 100) begin
			$display("[%t] : dma transfer from cl to host timed out.", $realtime);
		end


		#1us;		
		// validate the read buffer
		host_memory_buffer_addr = READ_BUFFER_ADDR;
		for (int i = 0; i < len0; i++) begin
			read_val = tb.hm_get_byte(.addr(host_memory_buffer_addr));
			if (read_val != write_val) begin
				$display(
					"[%t] : Data mismatch. addr=%0x read_val=%0x",
					$realtime, host_memory_buffer_addr, read_val);
			end
			else begin
				$display(
					"[%t] : Data matched. addr=%0x read_val=%0x",
					$realtime, host_memory_buffer_addr, read_val);
			end	
			host_memory_buffer_addr++;
		end
		

		// Power down
		#500ns;
		tb.power_down();
		$finish;
	end

endmodule
