`timescale 1ns/1ns

module RV32I_AxiLite_Top_tb();

  localparam [5:0] REG_CONTROL   = 6'h00;
  localparam [5:0] REG_STATUS    = 6'h04;
  localparam [5:0] REG_PREDICTED = 6'h08;
  localparam [5:0] REG_EXPECTED  = 6'h0C;
  localparam [5:0] REG_HEARTBEAT = 6'h10;
  localparam [5:0] REG_DEBUG_PC  = 6'h14;

  parameter IMEM_HEX = "../../../FPGA_proj/firmware/lenet_infer_imem.hex";
  parameter DMEM_HEX = "../../../FPGA_proj/firmware/lenet_digit7_dmem.mem";
  parameter integer TIMEOUT_CYCLES = 20000000;

  reg clk;
  reg aresetn;
  reg [5:0] awaddr;
  reg awvalid;
  wire awready;
  reg [31:0] wdata;
  reg [3:0] wstrb;
  reg wvalid;
  wire wready;
  wire [1:0] bresp;
  wire bvalid;
  reg bready;
  reg [5:0] araddr;
  reg arvalid;
  wire arready;
  wire [31:0] rdata;
  wire [1:0] rresp;
  wire rvalid;
  reg rready;

  integer cycle_count;
  integer check_errors;
  reg [31:0] status_value;
  reg [31:0] predicted_value;
  reg [31:0] expected_value;
  reg [31:0] heartbeat_value;
  reg [31:0] debug_pc_value;
  reg [1023:0] imem_hex;
  reg [1023:0] dmem_hex;
  reg init_checks_done;
  reg fast_status_stim;

  RV32I_AxiLite_Top #(
    .CPU_RESET_PC(32'h0000_0000),
    .EXPECTED_DIGIT(32'd7)
  ) dut (
    .s_axi_aclk(clk),
    .s_axi_aresetn(aresetn),
    .s_axi_awaddr(awaddr),
    .s_axi_awvalid(awvalid),
    .s_axi_awready(awready),
    .s_axi_wdata(wdata),
    .s_axi_wstrb(wstrb),
    .s_axi_wvalid(wvalid),
    .s_axi_wready(wready),
    .s_axi_bresp(bresp),
    .s_axi_bvalid(bvalid),
    .s_axi_bready(bready),
    .s_axi_araddr(araddr),
    .s_axi_arvalid(arvalid),
    .s_axi_arready(arready),
    .s_axi_rdata(rdata),
    .s_axi_rresp(rresp),
    .s_axi_rvalid(rvalid),
    .s_axi_rready(rready)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  initial begin
    aresetn = 1'b0;
    awaddr = 6'd0;
    awvalid = 1'b0;
    wdata = 32'd0;
    wstrb = 4'h0;
    wvalid = 1'b0;
    bready = 1'b0;
    araddr = 6'd0;
    arvalid = 1'b0;
    rready = 1'b0;
    cycle_count = 0;
    check_errors = 0;
    init_checks_done = 1'b0;
    fast_status_stim = 1'b0;
    imem_hex = IMEM_HEX;
    dmem_hex = DMEM_HEX;

    if (!$value$plusargs("IMEM_HEX=%s", imem_hex))
      imem_hex = IMEM_HEX;
    if (!$value$plusargs("DMEM_HEX=%s", dmem_hex))
      dmem_hex = DMEM_HEX;
    if ($test$plusargs("FAST_STATUS_STIM"))
      fast_status_stim = 1'b1;

    repeat (8) @(posedge clk);
    $display("[AXI_TB] Loading IMEM: %0s", imem_hex);
    $readmemh(imem_hex, dut.u_system.iIMem.mem);
    $display("[AXI_TB] Loading DMEM: %0s", dmem_hex);
    $readmemh(dmem_hex, dut.u_system.iDMem.mem);

    repeat (4) @(posedge clk);
    aresetn = 1'b1;
    $display("[AXI_TB] AXI reset released");

    axi_read(REG_CONTROL, status_value);
    if (status_value[0] !== 1'b1) begin
      $display("[AXI_TB][CHECK_FAIL] run_enable reset value got=0x%08h expected bit0=1", status_value);
      check_errors = check_errors + 1;
    end

    axi_read(REG_EXPECTED, expected_value);
    if (expected_value !== 32'd7) begin
      $display("[AXI_TB][CHECK_FAIL] expected digit got=%0d expected=7", expected_value);
      check_errors = check_errors + 1;
    end
    init_checks_done = 1'b1;
  end

  always @(posedge clk) begin
    if (aresetn)
      cycle_count <= cycle_count + 1;
  end

  initial begin
    wait(init_checks_done == 1'b1);
    status_value = 32'd0;

    if (fast_status_stim) begin
      @(negedge clk);
      force dut.debug_data_we = 1'b1;
      force dut.debug_data_addr = 32'h0001_0F00;
      force dut.debug_write_data = 32'd7;
      @(posedge clk);
      @(negedge clk);
      force dut.debug_data_addr = 32'h0001_0F40;
      force dut.debug_write_data = 32'd1;
      @(posedge clk);
      @(negedge clk);
      release dut.debug_data_we;
      release dut.debug_data_addr;
      release dut.debug_write_data;
      repeat (2) @(posedge clk);

      axi_read(REG_STATUS, status_value);
      axi_read(REG_PREDICTED, predicted_value);
      axi_read(REG_EXPECTED, expected_value);

      $display("[AXI_TB] fast status=0x%08h predicted=%0d expected=%0d",
               status_value, predicted_value, expected_value);

      if (status_value[0] !== 1'b1 || status_value[1] !== 1'b1 || status_value[2] !== 1'b0) begin
        $display("[AXI_TB][CHECK_FAIL] fast status bits invalid, status=0x%08h", status_value);
        check_errors = check_errors + 1;
      end
      if (predicted_value !== 32'd7) begin
        $display("[AXI_TB][CHECK_FAIL] fast predicted got=%0d expected=7", predicted_value);
        check_errors = check_errors + 1;
      end

      axi_write(REG_CONTROL, 32'h0000_0002, 4'h1);
      axi_read(REG_STATUS, status_value);
      if (status_value[0] !== 1'b0) begin
        $display("[AXI_TB][CHECK_FAIL] fast clear did not clear done, status=0x%08h", status_value);
        check_errors = check_errors + 1;
      end

      if (check_errors == 0)
        $display("[AXI_TB][PASS] AXI-Lite fast status wrapper smoke test passed");
      else
        $display("[AXI_TB][FAIL] check_errors=%0d", check_errors);

      $finish;
    end

    while ((status_value[0] !== 1'b1) && (cycle_count <= TIMEOUT_CYCLES)) begin
      repeat (100000) @(posedge clk);
      axi_read(REG_STATUS, status_value);
      axi_read(REG_PREDICTED, predicted_value);
      axi_read(REG_DEBUG_PC, debug_pc_value);
      $display("[AXI_TB] progress cycles=%0d status=0x%08h predicted=%0d pc=0x%08h",
               cycle_count, status_value, predicted_value, debug_pc_value);
    end

    if (cycle_count > TIMEOUT_CYCLES) begin
      $display("[AXI_TB][FAIL] Timeout cycles=%0d status=0x%08h", cycle_count, status_value);
      $finish;
    end

    axi_read(REG_STATUS, status_value);
    axi_read(REG_PREDICTED, predicted_value);
    axi_read(REG_EXPECTED, expected_value);
    axi_read(REG_HEARTBEAT, heartbeat_value);
    axi_read(REG_DEBUG_PC, debug_pc_value);

    $display("[AXI_TB] Done at cycle %0d", cycle_count);
    $display("[AXI_TB] status=0x%08h predicted=%0d expected=%0d heartbeat=%0d pc=0x%08h",
             status_value, predicted_value, expected_value, heartbeat_value, debug_pc_value);

    if (status_value[0] !== 1'b1) begin
      $display("[AXI_TB][CHECK_FAIL] done bit was not set");
      check_errors = check_errors + 1;
    end
    if (status_value[1] !== 1'b1) begin
      $display("[AXI_TB][CHECK_FAIL] pass bit was not set");
      check_errors = check_errors + 1;
    end
    if (status_value[2] !== 1'b0) begin
      $display("[AXI_TB][CHECK_FAIL] fail bit was set");
      check_errors = check_errors + 1;
    end
    if (predicted_value !== 32'd7) begin
      $display("[AXI_TB][CHECK_FAIL] predicted got=%0d expected=7", predicted_value);
      check_errors = check_errors + 1;
    end

    axi_write(REG_CONTROL, 32'h0000_0002, 4'h1);
    axi_read(REG_STATUS, status_value);
    if (status_value[0] !== 1'b0) begin
      $display("[AXI_TB][CHECK_FAIL] clear status did not clear done bit, status=0x%08h", status_value);
      check_errors = check_errors + 1;
    end

    if (check_errors == 0)
      $display("[AXI_TB][PASS] AXI-Lite status wrapper matched LeNet result");
    else
      $display("[AXI_TB][FAIL] check_errors=%0d", check_errors);

    $finish;
  end

  task axi_read;
    input [5:0] addr;
    output [31:0] data;
    begin
      @(posedge clk);
      araddr <= addr;
      arvalid <= 1'b1;
      rready <= 1'b1;
      wait (arready == 1'b1);
      @(posedge clk);
      arvalid <= 1'b0;
      wait (rvalid == 1'b1);
      data = rdata;
      @(posedge clk);
      rready <= 1'b0;
    end
  endtask

  task axi_write;
    input [5:0] addr;
    input [31:0] data;
    input [3:0] strb;
    begin
      @(posedge clk);
      awaddr <= addr;
      awvalid <= 1'b1;
      wdata <= data;
      wstrb <= strb;
      wvalid <= 1'b1;
      bready <= 1'b1;
      wait (awready == 1'b1 && wready == 1'b1);
      @(posedge clk);
      awvalid <= 1'b0;
      wvalid <= 1'b0;
      wait (bvalid == 1'b1);
      @(posedge clk);
      bready <= 1'b0;
      wstrb <= 4'h0;
    end
  endtask

endmodule
