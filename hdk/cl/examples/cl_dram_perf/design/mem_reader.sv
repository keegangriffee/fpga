module mem_reader
(
	input clk,
	input rst_n,
	input[31:0] start_addr,
	input[31:0] read_len,
	input enable,
	output done,
	axi_bus_t.slave axi
);

typedef enum logic[2:0] {
	FSM_IDLE = 3'd0,
	FSM_START = 3'd1,
	FSM_AR = 3'd2,
	FSM_R = 3'd3,
	FSM_DONE = 3'd4
} fsm_state_t;

fsm_state_t curr_state;
fsm_state_t next_state;

logic enable_q;
logic[31:0] curr_addr;
logic[29:0] read_counter;
logic[29:0] read_len_q;


// flop enable
always_ff @ (posedge clk or negedge rst_n)
	if (!rst_n) begin
		enable_q <= 1'b0;	
		curr_state <= FSM_IDLE;
	end 
	else begin
		enable_q <= enable;
		curr_state <= next_state;
	end

// flop start_addr and read_len
always_ff @ (posedge clk or negedge rst_n)
	if (!rst_n) begin
		curr_addr <= 32'b0;
		read_counter <= 30'b0;
		read_len_q <= 30'b0;
	end
	else begin
		if (curr_state == FSM_START) begin
			curr_addr <= start_addr;
			read_counter <= 30'b0;
			read_len_q <= read_len[29:0];
		end
	end

// curr_addr, read_counter logic
always_ff @ (posedge clk or negedge rst_n)
	if (curr_state == FSM_R && axi.rlast) begin
		curr_addr <= curr_addr + axi.arlen;
		read_counter <= read_counter + axi.arlen;
	end


// next state logic
always_comb
	case (curr_state)
		FSM_IDLE:
			next_state = enable_q ? FSM_START : FSM_IDLE;
		FSM_START:
			next_state = FSM_AR;
		FSM_AR:
			next_state = axi.arready ? FSM_R : FSM_AR;
		FSM_R:
			if (axi.rvalid && axi.rlast) begin
				if (read_counter + axi.arlen >= read_len_q)
					next_state = FSM_DONE;
				else
					next_state = FSM_AR;
			end
			else begin
				next_state = FSM_R;
			end
		FSM_DONE:
			next_state = enable_q ? FSM_DONE : FSM_IDLE;	
	endcase

// write signals tied off
assign axi.awid = 16'b0;
assign axi.awaddr = 64'b0;
assign axi.awlen = 8'b0;
assign axi.awsize = 3'b0;
assign axi.awvalid = 1'b0;

assign axi.wid = 16'b0;
assign axi.wdata = 512'b0;
assign axi.wstrb = 64'b0;
assign axi.wlast = 1'b0;
assign axi.wvalid = 1'b0;

assign axi.bid = 16'b0;
assign axi.bresp = 2'b0;
assign axi.bready = 1'b0;

// read signals
logic[29:0] left_len;
assign left_len = read_len_q - read_counter;
assign axi.arid = 16'h0000;
assign axi.arlen = (left_len >= 256) ? 8'hff : left_len[7:0];
assign axi.arsize = 3'b110;
assign axi.araddr = {28'b0, curr_addr[29:0], 6'b0};
assign axi.arvalid = (curr_state == FSM_AR);
assign axi.rready = (curr_state == FSM_R);

assign done = (curr_state == FSM_DONE);


endmodule

