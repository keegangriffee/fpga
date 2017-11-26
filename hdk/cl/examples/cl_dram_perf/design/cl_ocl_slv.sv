module cl_ocl_slv(
	input clk,
	input rst_n,
	axi_bus_t.master sh_ocl_bus,
	output [31:0] start_addr,
	output [31:0] write_len,
	output [31:0] write_val
);

`define START_ADDR_REG_ADDR		32'h0000_0500
`define WRITE_LEN_REG_ADDR		32'h0000_0504
`define WRITE_VAL_REG_ADDR		32'h0000_0508
`define UNIMPLEMENTED_REG_VALUE 32'hdead_beef

reg[31:0] reg_start_addr;
reg[31:0] reg_write_len;
reg[31:0] reg_write_val;

assign start_addr = reg_start_addr;
assign write_len = reg_write_len;
assign write_val = reg_write_val;

logic awvalid;
logic[31:0] awaddr;
logic awready;

logic wvalid;
logic[31:0] wdata;
logic[3:0] wstrb;
logic wready;

logic bvalid;
logic bresp;
logic bready;

logic arvalid;
logic[31:0] araddr;
logic arready;

logic rvalid;
logic[31:0] rdata;
logic[1:0] rresp;
logic rready;

axi_register_slice_light OCL_REG_SLICE (
	.aclk (clk),
	.aresetn (rst_n),
	// s
	.s_axi_awaddr (sh_ocl_bus.awaddr),
	.s_axi_awprot (2'h0),
	.s_axi_awvalid (sh_ocl_bus.awvalid),
	.s_axi_awready (sh_ocl_bus.awready),
	.s_axi_wdata (sh_ocl_bus.wdata),
	.s_axi_wstrb (sh_ocl_bus.wstrb),
	.s_axi_wvalid (sh_ocl_bus.wvalid),
	.s_axi_wready (sh_ocl_bus.wready),
	.s_axi_bresp (sh_ocl_bus.bresp),
	.s_axi_bvalid (sh_ocl_bus.bvalid),
	.s_axi_bready (sh_ocl_bus.bready),
	.s_axi_araddr (sh_ocl_bus.araddr),
	.s_axi_arvalid (sh_ocl_bus.arvalid),
	.s_axi_arready (sh_ocl_bus.arready),
	.s_axi_rdata (sh_ocl_bus.rdata),
	.s_axi_rresp (sh_ocl_bus.rresp),
	.s_axi_rvalid (sh_ocl_bus.rvalid),
	.s_axi_rready (sh_ocl_bus.rready),
	// m
	.m_axi_awaddr (awaddr),
	.m_axi_awprot (),
	.m_axi_awvalid (awvalid),
	.m_axi_awready (awready),
	.m_axi_wdata (wdata),
	.m_axi_wstrb (wstrb),
	.m_axi_wvalid (wvalid),
	.m_axi_wready (wready),
	.m_axi_bresp (bresp),
	.m_axi_bvalid (bvalid),
	.m_axi_bready (bready),
	.m_axi_araddr (araddr),
	.m_axi_arvalid (arvalid),
	.m_axi_arready (arready),
	.m_axi_rdata (rdata),
	.m_axi_rresp (rresp),
	.m_axi_rvalid (rvalid),
	.m_axi_rready (rready)
);

// write request
reg wr_active;
reg [31:0] wr_addr;

always_ff @ (posedge clk)
	if (!rst_n) begin
		wr_active <= 0;
		wr_addr <= 0;	
	end
	else begin
		wr_active <=
			(wr_active && bvalid && bready) ? 1'b0 :
			(~wr_active && awvalid) ? 1'b1 : wr_active;
		wr_addr <= 
			(awvalid && ~wr_active) ? awaddr : wr_addr;						
	end

assign awready = ~wr_active;
assign wready = wr_active && wvalid;

// write response
always_ff @ (posedge clk)
	if (!rst_n) begin
		bvalid <= 0;
	end
	else begin
		bvalid <=
			(bvalid && bready) ? 1'b0 :
			(~bvalid && wready) ? 1'b1 : bvalid;
	end
// read request
reg arvalid_q;
reg [31:0] araddr_q;

always_ff @ (posedge clk)
	if (!rst_n) begin
		arvalid_q <= 0;
		araddr_q  <= 0;
	end
	else begin
		arvalid_q <= arvalid;
		araddr_q  <= arvalid ? araddr : araddr_q;
	end

assign arready = !arvalid_q && !rvalid;

// read response
always_ff @ (posedge clk)
	if (!rst_n)
	begin
		rvalid <= 0;
		rdata <= 0;
		rresp <= 2'b00;
	end
	else if (rvalid && rready) begin
		rvalid <= 0;
		rdata <= 0;
		rresp <= 0;
	end
	else if (arvalid_q) begin
		rvalid <= 1;
		rdata <=
			(araddr_q == `START_ADDR_REG_ADDR) ? start_addr[31:0] :
			(araddr_q == `WRITE_LEN_REG_ADDR) ? write_len[31:0] :
			(araddr_q == `WRITE_VAL_REG_ADDR) ? write_val[31:0] : `UNIMPLEMENTED_REG_VALUE;
		rresp <= 0;
	end

// writing coefficient in reg
always_ff @ (posedge clk)
	if (!rst_n) begin
		reg_start_addr[31:0] <= 32'h00000000;
		reg_write_len[31:0] <= 32'h00000000;
		reg_write_val[31:0] <= 32'h00000000;
	end
	else if (wready & (wr_addr == `START_ADDR_REG_ADDR)) begin
		reg_start_addr[31:0] <= wdata[31:0];
	end
	else if (wready & (wr_addr == `WRITE_LEN_REG_ADDR)) begin
		reg_write_len[31:0] <= wdata[31:0];
	end
	else if (wready & (wr_addr == `WRITE_VAL_REG_ADDR)) begin
		reg_write_val[31:0] <= wdata[31:0];
	end

endmodule
