module cl_dram_perf 
(
   `include "cl_ports.vh"
);

// headers
`include "cl_common_defines.vh"
`include "cl_id_defines.vh"
`include "cl_dram_perf_defines.vh"

// tied-off ports
logic rst_main_n_sync;
`include "unused_pcim_template.inc"
`include "unused_cl_sda_template.inc"
`include "unused_sh_bar1_template.inc"
`include "unused_apppf_irq_template.inc"
`include "unused_dma_pcis_template.inc"
`include "unused_ddr_a_b_d_template.inc"
`include "unused_ddr_c_template.inc"

assign cl_sh_id0[31:0] = `CL_SH_ID0;
assign cl_sh_id1[31:0] = `CL_SH_ID1;

assign cl_sh_status1 = 32'hee_ee_ee_00;

// clock
logic clk;
assign clk = clk_main_a0;

// reset sync
(* dont_touch = "true" *) logic pipe_rst_n;
lib_pipe #(.WIDTH(1), .STAGES(4)) PIPE_RST_N (.clk(clk), .rst_n(1'b1), .in_bus(rst_main_n), .out_bus(pipe_rst_n));

logic pre_sync_rst_n;
(* dont_touch = "true" *) logic sync_rst_n;
always_ff @ (posedge clk or negedge pipe_rst_n)
   if (!pipe_rst_n) begin
      pre_sync_rst_n  <= 0;
      sync_rst_n <= 0;
   end
   else begin
      pre_sync_rst_n  <= 1;
      sync_rst_n <= pre_sync_rst_n;
   end

// FLR response
logic sh_cl_flr_assert_q;
always_ff @(posedge clk or negedge sync_rst_n)
	if (!sync_rst_n) begin
		sh_cl_flr_assert_q <= 0;
		cl_sh_flr_done <= 0;
	end
	else begin
		sh_cl_flr_assert_q <= sh_cl_flr_assert;
		cl_sh_flr_done <= sh_cl_flr_assert_q && !cl_sh_flr_done;
	end


// ocl
axi_bus_t sh_ocl_bus();

assign sh_ocl_bus.awvalid = sh_ocl_awvalid;
assign sh_ocl_bus.awaddr[31:0] = sh_ocl_awaddr;
assign ocl_sh_awready = sh_ocl_bus.awready;

assign sh_ocl_bus.wvalid = sh_ocl_wvalid;
assign sh_ocl_bus.wdata[31:0] = sh_ocl_wdata;
assign sh_ocl_bus.wstrb[3:0] = sh_ocl_wstrb;
assign ocl_sh_wready = sh_ocl_bus.wready;

assign ocl_sh_bvalid = sh_ocl_bus.bvalid;
assign ocl_sh_bresp = sh_ocl_bus.bresp;
assign sh_ocl_bus.bready = sh_ocl_bready;

assign sh_ocl_bus.arvalid = sh_ocl_arvalid;
assign sh_ocl_bus.araddr[31:0] = sh_ocl_araddr;
assign ocl_sh_arready = sh_ocl_bus.arready;

assign ocl_sh_rvalid = sh_ocl_bus.rvalid;
assign ocl_sh_rresp = sh_ocl_bus.rresp;
assign ocl_sh_rdata = sh_ocl_bus.rdata[31:0];
assign sh_ocl_bus.rready = sh_ocl_rready;

wire[31:0] start_addr;
wire[31:0] burst_len;
wire[31:0] write_val;

reg_file REG_FILE(
	.clk(clk),
	.rst_n(sync_rst_n),
	.axi_bus(sh_ocl_bus),
	.start_addr(start_addr),
	.burst_len(burst_len),
	.write_val(write_val)
);

/*
// DMA PCIS AXI-4
axi_bus_t dma_pcis_bus();
axi_bus_t ddr_a_out();
axi_bus_t ddr_b_out();
axi_bus_t ddr_c_out();
axi_bus_t ddr_d_out();

assign dma_pcis_bus.awid = {10'b0, sh_cl_dma_pcis_awid[5:0]};
assign dma_pcis_bus.awaddr = sh_cl_dma_pcis_awaddr;
assign dma_pcis_bus.awlen = sh_cl_dma_pcis_awlen;
assign dma_pcis_bus.awsize = sh_cl_dma_pcis_awsize;
assign dma_pcis_bus.awvalid = sh_cl_dma_pcis_awvalid;
assign cl_sh_dma_pcis_awready = dma_pcis_bus.awready;

assign dma_pcis_bus.wdata = sh_cl_dma_pcis_wdata;
assign dma_pcis_bus.wstrb = sh_cl_dma_pcis_wstrb;
assign dma_pcis_bus.wlast = sh_cl_dma_pcis_wlast;
assign dma_pcis_bus.wvalid = sh_cl_dma_pcis_wvalid;
assign cl_sh_dma_pcis_wready = dma_pcis_bus.wready;

assign cl_sh_dma_pcis_bid = dma_pcis_bus.bid;
assign cl_sh_dma_pcis_bresp = dma_pcis_bus.bresp;
assign cl_sh_dma_pcis_bvalid = dma_pcis_bus.bvalid;
assign dma_pcis_bus.bready = sh_cl_dma_pcis_bready;

assign dma_pcis_bus.arid = {10'b0, sh_cl_dma_pcis_arid[5:0]};
assign dma_pcis_bus.araddr = sh_cl_dma_pcis_araddr;
assign dma_pcis_bus.arlen = sh_cl_dma_pcis_arlen;
assign dma_pcis_bus.arsize = sh_cl_dma_pcis_arsize;
assign dma_pcis_bus.arvalid = sh_cl_dma_pcis_arvalid;
assign cl_sh_dma_pcis_arready = dma_pcis_bus.arready;

assign cl_sh_dma_pcis_rid = dma_pcis_bus.rid;
assign cl_sh_dma_pcis_rdata = dma_pcis_bus.rdata;
assign cl_sh_dma_pcis_rresp = dma_pcis_bus.rresp;
assign cl_sh_dma_pcis_rlast = dma_pcis_bus.rlast;
assign cl_sh_dma_pcis_rvalid = dma_pcis_bus.rvalid;
assign dma_pcis_bus.rready = sh_cl_dma_pcis_rready;

(* dont_touch="true" *) logic dma_pcis_slv_sync_rst_n;
lib_pipe #(.WIDTH(4), .STAGES(4)) DMA_PCIS_SLV_SLC_RST_N (
	.clk(clk), 
	.rst_n(1'b1), 
	.in_bus(sync_rst_n),
	.out_bus(dma_pcis_slv_sync_rst_n)
);
cl_dma_pcis_slv CL_DMA_PCIS_SLV(
	.clk(clk),
	.rst_n(dma_pcis_slv_sync_rst_n),
	.dma_pcis_bus(dma_pcis_bus),
	.ddr_a_out(ddr_a_out),
	.ddr_b_out(ddr_b_out),
	.ddr_c_out(ddr_c_out),
	.ddr_d_out(ddr_d_out),
	.mem_reader_axi(mem_reader_axi)
);


// connecting to DDR C
assign cl_sh_ddr_awid = ddr_c_out.awid;
assign cl_sh_ddr_awaddr = ddr_c_out.awaddr;
assign cl_sh_ddr_awlen = ddr_c_out.awlen;
assign cl_sh_ddr_awsize = ddr_c_out.awsize;
assign cl_sh_ddr_awvalid = ddr_c_out.awvalid;
assign ddr_c_out.awready = sh_cl_ddr_awready;

assign cl_sh_ddr_wid = 16'b0;
assign cl_sh_ddr_wdata = ddr_c_out.wdata;
assign cl_sh_ddr_wstrb = ddr_c_out.wstrb;
assign cl_sh_ddr_wlast = ddr_c_out.wlast;
assign cl_sh_ddr_wvalid = ddr_c_out.wvalid;
assign ddr_c_out.wready = sh_cl_ddr_wready;

assign ddr_c_out.bid = sh_cl_ddr_bid;
assign ddr_c_out.bresp = sh_cl_ddr_bresp;
assign ddr_c_out.bvalid = sh_cl_ddr_bvalid;
assign cl_sh_ddr_bready = ddr_c_out.bready;

assign cl_sh_ddr_arid = ddr_c_out.arid;
assign cl_sh_ddr_araddr = ddr_c_out.araddr;
assign cl_sh_ddr_arlen = ddr_c_out.arlen;
assign cl_sh_ddr_arsize = ddr_c_out.arsize;
assign cl_sh_ddr_arvalid = ddr_c_out.arvalid;
assign ddr_c_out.arready = sh_cl_ddr_arready;

assign ddr_c_out.rid = sh_cl_ddr_rid;
assign ddr_c_out.rresp = sh_cl_ddr_rresp;
assign ddr_c_out.rvalid = sh_cl_ddr_rvalid;
assign ddr_c_out.rdata = sh_cl_ddr_rdata;
assign ddr_c_out.rlast = sh_cl_ddr_rlast;
assign cl_sh_ddr_rready = ddr_c_out.rready;


// connecting to sh_ddr
logic[15:0] ddr_out_2d_awid[2:0];
logic[63:0] ddr_out_2d_awaddr[2:0];
logic[7:0] ddr_out_2d_awlen[2:0];
logic[2:0] ddr_out_2d_awsize[2:0];
logic ddr_out_2d_awvalid[2:0];
logic[2:0] ddr_out_2d_awready;

logic[15:0] ddr_out_2d_wid[2:0];
logic[511:0] ddr_out_2d_wdata[2:0];
logic[63:0] ddr_out_2d_wstrb[2:0];
logic[2:0] ddr_out_2d_wlast;
logic[2:0] ddr_out_2d_wvalid;
logic[2:0] ddr_out_2d_wready;

logic[15:0] ddr_out_2d_bid[2:0];
logic[1:0] ddr_out_2d_bresp[2:0];
logic[2:0] ddr_out_2d_bvalid;
logic[2:0] ddr_out_2d_bready;

logic[15:0] ddr_out_2d_arid[2:0];
logic[63:0] ddr_out_2d_araddr[2:0];
logic[7:0] ddr_out_2d_arlen[2:0];
logic[2:0] ddr_out_2d_arsize[2:0];
logic[2:0] ddr_out_2d_arvalid;
logic[2:0] ddr_out_2d_arready;

logic[15:0] ddr_out_2d_rid[2:0];
logic[511:0] ddr_out_2d_rdata[2:0];
logic[1:0] ddr_out_2d_rresp[2:0];
logic[2:0] ddr_out_2d_rlast;
logic[2:0] ddr_out_2d_rvalid;
logic[2:0] ddr_out_2d_rready;
 
assign ddr_out_2d_awid = '{ddr_d_out.awid, ddr_b_out.awid, ddr_a_out.awid};
assign ddr_out_2d_awaddr = '{ddr_d_out.awaddr, ddr_b_out.awaddr, ddr_a_out.awaddr};
assign ddr_out_2d_awlen = '{ddr_d_out.awlen, ddr_b_out.awlen, ddr_a_out.awlen};
assign ddr_out_2d_awsize = '{ddr_d_out.awsize, ddr_b_out.awsize, ddr_a_out.awsize};
assign ddr_out_2d_awvalid = '{ddr_d_out.awvalid, ddr_b_out.awvalid, ddr_a_out.awvalid};
assign {ddr_d_out.awready, ddr_b_out.awready, ddr_a_out.awready} = ddr_out_2d_awready;

assign ddr_out_2d_wid = '{ddr_d_out.wid, ddr_b_out.wid, ddr_a_out.wid};
assign ddr_out_2d_wdata = '{ddr_d_out.wdata, ddr_b_out.wdata, ddr_a_out.wdata};
assign ddr_out_2d_wstrb = '{ddr_d_out.wstrb, ddr_b_out.wstrb, ddr_a_out.wstrb};
assign ddr_out_2d_wlast = {ddr_d_out.wlast, ddr_b_out.wlast, ddr_a_out.wlast};
assign ddr_out_2d_wvalid = {ddr_d_out.wvalid, ddr_b_out.wvalid, ddr_a_out.wvalid};
assign {ddr_d_out.wready, ddr_b_out.wready, ddr_a_out.wready} = ddr_out_2d_wready;

assign {ddr_d_out.bid, ddr_b_out.bid, ddr_a_out.bid} = {
	ddr_out_2d_bid[2],
	ddr_out_2d_bid[1],
	ddr_out_2d_bid[0]
};
assign {ddr_d_out.bresp, ddr_b_out.bresp, ddr_a_out.bresp} = {
	ddr_out_2d_bresp[2],
	ddr_out_2d_bresp[1],
	ddr_out_2d_bresp[0]
};
assign {ddr_d_out.bvalid, ddr_b_out.bvalid, ddr_a_out.bvalid} = ddr_out_2d_bvalid;
assign ddr_out_2d_bready = {ddr_d_out.bready, ddr_b_out.bready, ddr_a_out.bready};

assign ddr_out_2d_arid = '{ddr_d_out.arid, ddr_b_out.arid, ddr_a_out.arid};
assign ddr_out_2d_araddr = '{ddr_d_out.araddr, ddr_b_out.araddr, ddr_a_out.araddr};
assign ddr_out_2d_arlen = '{ddr_d_out.arlen, ddr_b_out.arlen, ddr_a_out.arlen};
assign ddr_out_2d_arsize = '{ddr_d_out.arsize, ddr_b_out.arsize, ddr_a_out.arsize};
assign ddr_out_2d_arvalid = {ddr_d_out.arvalid, ddr_b_out.arvalid, ddr_a_out.arvalid};
assign {ddr_d_out.arready, ddr_b_out.arready, ddr_a_out.arready} = ddr_out_2d_arready;

assign {ddr_d_out.rid, ddr_b_out.rid, ddr_a_out.rid} = {
	ddr_out_2d_rid[2],
	ddr_out_2d_rid[1],
	ddr_out_2d_rid[0]
};
assign {ddr_d_out.rresp, ddr_b_out.rresp, ddr_a_out.rresp} = {
	ddr_out_2d_rresp[2],
	ddr_out_2d_rresp[1],
	ddr_out_2d_rresp[0]
};
assign {ddr_d_out.rdata, ddr_b_out.rdata, ddr_a_out.rdata} = {
	ddr_out_2d_rdata[2],
	ddr_out_2d_rdata[1],
	ddr_out_2d_rdata[0]
};
assign {ddr_d_out.rlast, ddr_b_out.rlast, ddr_a_out.rlast} = ddr_out_2d_rlast;
assign {ddr_d_out.rvalid, ddr_b_out.rvalid, ddr_a_out.rvalid} = ddr_out_2d_rvalid;
assign ddr_out_2d_rready = {ddr_d_out.rready, ddr_b_out.rready, ddr_a_out.rready};

logic[7:0] sh_ddr_stat_addr_q[2:0];
logic[2:0] sh_ddr_stat_wr_q;
logic[2:0] sh_ddr_stat_rd_q; 
logic[31:0] sh_ddr_stat_wdata_q[2:0];
logic[2:0] ddr_sh_stat_ack_q;
logic[31:0] ddr_sh_stat_rdata_q[2:0];
logic[7:0] ddr_sh_stat_int_q[2:0];

lib_pipe #(
	.WIDTH(1+1+8+32),
	.STAGES(8)
) PIPE_DDR_STAT0 (
	.clk(clk), .rst_n(sync_rst_n),
    .in_bus({sh_ddr_stat_wr0, sh_ddr_stat_rd0, sh_ddr_stat_addr0, sh_ddr_stat_wdata0}),
	.out_bus({sh_ddr_stat_wr_q[0], sh_ddr_stat_rd_q[0], sh_ddr_stat_addr_q[0], sh_ddr_stat_wdata_q[0]})
);

lib_pipe #(
	.WIDTH(1+8+32),
	.STAGES(8)
) PIPE_DDR_STAT_ACK0 (
	.clk(clk), .rst_n(sync_rst_n),
	.in_bus({ddr_sh_stat_ack_q[0], ddr_sh_stat_int_q[0], ddr_sh_stat_rdata_q[0]}),
	.out_bus({ddr_sh_stat_ack0, ddr_sh_stat_int0, ddr_sh_stat_rdata0})
);


lib_pipe #(
	.WIDTH(1+1+8+32),
	.STAGES(8)
) PIPE_DDR_STAT1 (
	.clk(clk), .rst_n(sync_rst_n),
	.in_bus({sh_ddr_stat_wr1, sh_ddr_stat_rd1, sh_ddr_stat_addr1, sh_ddr_stat_wdata1}),
	.out_bus({sh_ddr_stat_wr_q[1], sh_ddr_stat_rd_q[1], sh_ddr_stat_addr_q[1], sh_ddr_stat_wdata_q[1]})
);


lib_pipe #(
	.WIDTH(1+8+32),
	.STAGES(8)
) PIPE_DDR_STAT_ACK1 (
	.clk(clk), .rst_n(sync_rst_n),
	.in_bus({ddr_sh_stat_ack_q[1], ddr_sh_stat_int_q[1], ddr_sh_stat_rdata_q[1]}),
	.out_bus({ddr_sh_stat_ack1, ddr_sh_stat_int1, ddr_sh_stat_rdata1})
);

lib_pipe #(
	.WIDTH(1+1+8+32),
	.STAGES(8)
) PIPE_DDR_STAT2 (
	.clk(clk), .rst_n(sync_rst_n),
	.in_bus({sh_ddr_stat_wr2, sh_ddr_stat_rd2, sh_ddr_stat_addr2, sh_ddr_stat_wdata2}),
	.out_bus({sh_ddr_stat_wr_q[2], sh_ddr_stat_rd_q[2], sh_ddr_stat_addr_q[2], sh_ddr_stat_wdata_q[2]})
);


lib_pipe #(
	.WIDTH(1+8+32),
	.STAGES(8)
) PIPE_DDR_STAT_ACK2 (
	.clk(clk), .rst_n(sync_rst_n),
	.in_bus({ddr_sh_stat_ack_q[2], ddr_sh_stat_int_q[2], ddr_sh_stat_rdata_q[2]}),
	.out_bus({ddr_sh_stat_ack2, ddr_sh_stat_int2, ddr_sh_stat_rdata2})
);

logic sh_ddr_sync_rst_n;
lib_pipe #(
	.WIDTH(1),
	.STAGES(4)
) SH_DDR_SLC_RST_N (
	.clk(clk),
	.rst_n(1'b1),
	.in_bus(sync_rst_n),
	.out_bus(sh_ddr_sync_rst_n)
);
sh_ddr #(
	.DDR_A_PRESENT(1),
	.DDR_B_PRESENT(0),
	.DDR_D_PRESENT(0)
) SH_DDR (
	// clock / reset
	.clk(clk),
	.rst_n(sh_ddr_sync_rst_n),
	// stat clock / reset
	.stat_clk(clk),
	.stat_rst_n(sh_ddr_sync_rst_n),
	// DDR A
	.CLK_300M_DIMM0_DP(CLK_300M_DIMM0_DP),
	.CLK_300M_DIMM0_DN(CLK_300M_DIMM0_DN),
	.M_A_ACT_N(M_A_ACT_N),
	.M_A_MA(M_A_MA),
	.M_A_BA(M_A_BA),
	.M_A_BG(M_A_BG),
	.M_A_CKE(M_A_CKE),
	.M_A_ODT(M_A_ODT),
	.M_A_CS_N(M_A_CS_N),
	.M_A_CLK_DN(M_A_CLK_DN),
	.M_A_CLK_DP(M_A_CLK_DP),
	.M_A_PAR(M_A_PAR),
	.M_A_DQ(M_A_DQ),
	.M_A_ECC(M_A_ECC),
	.M_A_DQS_DP(M_A_DQS_DP),
	.M_A_DQS_DN(M_A_DQS_DN),
	.cl_RST_DIMM_A_N(cl_RST_DIMM_A_N),
	// DDR B
	.CLK_300M_DIMM1_DP(CLK_300M_DIMM1_DP),
	.CLK_300M_DIMM1_DN(CLK_300M_DIMM1_DN),
	.M_B_ACT_N(M_B_ACT_N),
	.M_B_MA(M_B_MA),
	.M_B_BA(M_B_BA),
	.M_B_BG(M_B_BG),
	.M_B_CKE(M_B_CKE),
	.M_B_ODT(M_B_ODT),
	.M_B_CS_N(M_B_CS_N),
	.M_B_CLK_DN(M_B_CLK_DN),
	.M_B_CLK_DP(M_B_CLK_DP),
	.M_B_PAR(M_B_PAR),
	.M_B_DQ(M_B_DQ),
	.M_B_ECC(M_B_ECC),
	.M_B_DQS_DP(M_B_DQS_DP),
	.M_B_DQS_DN(M_B_DQS_DN),
	.cl_RST_DIMM_B_N(cl_RST_DIMM_B_N),
	// DDR D
	.CLK_300M_DIMM3_DP(CLK_300M_DIMM3_DP),
	.CLK_300M_DIMM3_DN(CLK_300M_DIMM3_DN),
	.M_D_ACT_N(M_D_ACT_N),
	.M_D_MA(M_D_MA),
	.M_D_BA(M_D_BA),
	.M_D_BG(M_D_BG),
	.M_D_CKE(M_D_CKE),
	.M_D_ODT(M_D_ODT),
	.M_D_CS_N(M_D_CS_N),
	.M_D_CLK_DN(M_D_CLK_DN),
	.M_D_CLK_DP(M_D_CLK_DP),
	.M_D_PAR(M_D_PAR),
	.M_D_DQ(M_D_DQ),
	.M_D_ECC(M_D_ECC),
	.M_D_DQS_DP(M_D_DQS_DP),
	.M_D_DQS_DN(M_D_DQS_DN),
	.cl_RST_DIMM_D_N(cl_RST_DIMM_D_N),
	// DDR 4 (AXI-4)
	.cl_sh_ddr_awid(ddr_out_2d_awid),
	.cl_sh_ddr_awaddr(ddr_out_2d_awaddr),
	.cl_sh_ddr_awlen(ddr_out_2d_awlen),
	.cl_sh_ddr_awsize(ddr_out_2d_awsize),
	.cl_sh_ddr_awvalid(ddr_out_2d_awvalid),
	.sh_cl_ddr_awready(ddr_out_2d_awready),

	.cl_sh_ddr_wid(ddr_out_2d_wid),
	.cl_sh_ddr_wdata(ddr_out_2d_wdata),
	.cl_sh_ddr_wstrb(ddr_out_2d_wstrb),
	.cl_sh_ddr_wlast(ddr_out_2d_wlast),
	.cl_sh_ddr_wvalid(ddr_out_2d_wvalid),
	.sh_cl_ddr_wready(ddr_out_2d_wready),

	.sh_cl_ddr_bid(ddr_out_2d_bid),
	.sh_cl_ddr_bresp(ddr_out_2d_bresp),
	.sh_cl_ddr_bvalid(ddr_out_2d_bvalid),
	.cl_sh_ddr_bready(ddr_out_2d_bready),

	.cl_sh_ddr_arid(ddr_out_2d_arid),
	.cl_sh_ddr_araddr(ddr_out_2d_araddr),
	.cl_sh_ddr_arlen(ddr_out_2d_arlen),
	.cl_sh_ddr_arsize(ddr_out_2d_arsize),
	.cl_sh_ddr_arvalid(ddr_out_2d_arvalid),
	.sh_cl_ddr_arready(ddr_out_2d_arready),

	.sh_cl_ddr_rid(ddr_out_2d_rid),
	.sh_cl_ddr_rdata(ddr_out_2d_rdata),
	.sh_cl_ddr_rresp(ddr_out_2d_rresp),
	.sh_cl_ddr_rlast(ddr_out_2d_rlast),
	.sh_cl_ddr_rvalid(ddr_out_2d_rvalid),
	.cl_sh_ddr_rready(ddr_out_2d_rready),
	
	.sh_cl_ddr_is_ready(),
	// ddr stat
	.sh_ddr_stat_addr0  (sh_ddr_stat_addr_q[0]),
   	.sh_ddr_stat_wr0    (sh_ddr_stat_wr_q[0]), 
   	.sh_ddr_stat_rd0    (sh_ddr_stat_rd_q[0]), 
   	.sh_ddr_stat_wdata0 (sh_ddr_stat_wdata_q[0]), 
   	.ddr_sh_stat_ack0   (ddr_sh_stat_ack_q[0]),
   	.ddr_sh_stat_rdata0 (ddr_sh_stat_rdata_q[0]),
   	.ddr_sh_stat_int0   (ddr_sh_stat_int_q[0]),

  	.sh_ddr_stat_addr1  (sh_ddr_stat_addr_q[1]), 
   	.sh_ddr_stat_wr1    (sh_ddr_stat_wr_q[1]), 
   	.sh_ddr_stat_rd1    (sh_ddr_stat_rd_q[1]), 
	.sh_ddr_stat_wdata1 (sh_ddr_stat_wdata_q[1]), 
	.ddr_sh_stat_ack1   (ddr_sh_stat_ack_q[1]),
	.ddr_sh_stat_rdata1 (ddr_sh_stat_rdata_q[1]),
	.ddr_sh_stat_int1   (ddr_sh_stat_int_q[1]),

	.sh_ddr_stat_addr2  (sh_ddr_stat_addr_q[2]),
	.sh_ddr_stat_wr2    (sh_ddr_stat_wr_q[2]), 
	.sh_ddr_stat_rd2    (sh_ddr_stat_rd_q[2]), 
	.sh_ddr_stat_wdata2 (sh_ddr_stat_wdata_q[2]), 
	.ddr_sh_stat_ack2   (ddr_sh_stat_ack_q[2]) ,
	.ddr_sh_stat_rdata2 (ddr_sh_stat_rdata_q[2]),
	.ddr_sh_stat_int2   (ddr_sh_stat_int_q[2]) 
);
*/
endmodule
