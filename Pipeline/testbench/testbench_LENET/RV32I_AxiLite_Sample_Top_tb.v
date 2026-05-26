`timescale 1ns/1ns

module RV32I_AxiLite_Sample_Top_tb();

  localparam [13:0] REG_CONTROL   = 14'h0000;
  localparam [13:0] REG_STATUS    = 14'h0004;
  localparam [13:0] REG_PREDICTED = 14'h0008;
  localparam [13:0] REG_EXPECTED  = 14'h000C;
  localparam [13:0] REG_HEARTBEAT = 14'h0010;
  localparam [13:0] REG_DEBUG_PC  = 14'h0014;
  localparam [13:0] SAMPLE_BASE   = 14'h1000;
  localparam [13:0] EXPECTED_OFF  = 14'h2000;

  parameter IMEM_HEX = "../../../FPGA_proj/firmware/lenet_infer_imem.hex";
  parameter DMEM_HEX = "../../../FPGA_proj/firmware/lenet_digit7_dmem.mem";
  parameter integer TIMEOUT_CYCLES = 20000000;

  reg clk;
  reg aresetn;
  reg [13:0] awaddr;
  reg awvalid;
  wire awready;
  reg [31:0] wdata;
  reg [3:0] wstrb;
  reg wvalid;
  wire wready;
  wire [1:0] bresp;
  wire bvalid;
  reg bready;
  reg [13:0] araddr;
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
  reg init_done;
  reg fast_status_stim;

  RV32I_AxiLite_Sample_Top #(
    .CPU_RESET_PC(32'h0000_0000),
    .DMEM_INIT_FILE("")
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
    awaddr = 14'd0;
    awvalid = 1'b0;
    wdata = 32'd0;
    wstrb = 4'h0;
    wvalid = 1'b0;
    bready = 1'b0;
    araddr = 14'd0;
    arvalid = 1'b0;
    rready = 1'b0;
    cycle_count = 0;
    check_errors = 0;
    init_done = 1'b0;
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
    $display("[SAMPLE_TB] Loading IMEM: %0s", imem_hex);
    $readmemh(imem_hex, dut.u_imem.mem);
    $display("[SAMPLE_TB] Loading DMEM: %0s", dmem_hex);
    $readmemh(dmem_hex, dut.dmem);

    repeat (4) @(posedge clk);
    aresetn = 1'b1;
    $display("[SAMPLE_TB] AXI reset released");

    axi_read(REG_CONTROL, status_value);
    if (status_value[0] !== 1'b0) begin
      $display("[SAMPLE_TB][CHECK_FAIL] sample top should reset halted, control=0x%08h", status_value);
      check_errors = check_errors + 1;
    end

    axi_write(EXPECTED_OFF, 32'd7, 4'hF);
    axi_read(REG_EXPECTED, expected_value);
    if (expected_value !== 32'd7) begin
      $display("[SAMPLE_TB][CHECK_FAIL] expected write/read got=%0d", expected_value);
      check_errors = check_errors + 1;
    end

    axi_write(REG_CONTROL, 32'h0000_0003, 4'h1);
    init_done = 1'b1;
  end

  always @(posedge clk) begin
    if (aresetn && init_done)
      cycle_count <= cycle_count + 1;
  end

  initial begin
    wait(init_done == 1'b1);
    status_value = 32'd0;

    if (fast_status_stim) begin
      @(negedge clk);
      force dut.data_we = 1'b1;
      force dut.data_addr = 32'h0001_0F00;
      force dut.write_data = 32'd7;
      @(posedge clk);
      @(negedge clk);
      force dut.data_addr = 32'h0001_0F40;
      force dut.write_data = 32'd1;
      @(posedge clk);
      @(negedge clk);
      release dut.data_we;
      release dut.data_addr;
      release dut.write_data;
      repeat (2) @(posedge clk);

      axi_read(REG_STATUS, status_value);
      axi_read(REG_PREDICTED, predicted_value);
      axi_read(REG_EXPECTED, expected_value);
      $display("[SAMPLE_TB] fast status=0x%08h predicted=%0d expected=%0d",
               status_value, predicted_value, expected_value);

      if (status_value[0] !== 1'b1 || status_value[1] !== 1'b1 || status_value[2] !== 1'b0)
        check_errors = check_errors + 1;
      if (predicted_value !== 32'd7)
        check_errors = check_errors + 1;

      axi_write(REG_CONTROL, 32'h0000_0002, 4'h1);
      axi_read(REG_STATUS, status_value);
      if (status_value[0] !== 1'b0)
        check_errors = check_errors + 1;

      if (check_errors == 0)
        $display("[SAMPLE_TB][PASS] Sample-load AXI smoke test passed");
      else
        $display("[SAMPLE_TB][FAIL] check_errors=%0d", check_errors);
      $finish;
    end

    while ((status_value[0] !== 1'b1) && (cycle_count <= TIMEOUT_CYCLES)) begin
      repeat (100000) @(posedge clk);
      axi_read(REG_STATUS, status_value);
      axi_read(REG_PREDICTED, predicted_value);
      axi_read(REG_DEBUG_PC, debug_pc_value);
      $display("[SAMPLE_TB] progress cycles=%0d status=0x%08h predicted=%0d pc=0x%08h",
               cycle_count, status_value, predicted_value, debug_pc_value);
    end

    if (cycle_count > TIMEOUT_CYCLES) begin
      $display("[SAMPLE_TB][FAIL] Timeout cycles=%0d status=0x%08h", cycle_count, status_value);
      $finish;
    end

    axi_read(REG_STATUS, status_value);
    axi_read(REG_PREDICTED, predicted_value);
    axi_read(REG_EXPECTED, expected_value);
    axi_read(REG_HEARTBEAT, heartbeat_value);
    axi_read(REG_DEBUG_PC, debug_pc_value);

    $display("[SAMPLE_TB] Done at cycle %0d", cycle_count);
    $display("[SAMPLE_TB] status=0x%08h predicted=%0d expected=%0d heartbeat=%0d pc=0x%08h",
             status_value, predicted_value, expected_value, heartbeat_value, debug_pc_value);

    if (status_value[0] !== 1'b1 || status_value[1] !== 1'b1 || status_value[2] !== 1'b0) begin
      $display("[SAMPLE_TB][CHECK_FAIL] invalid status=0x%08h", status_value);
      check_errors = check_errors + 1;
    end
    if (predicted_value !== 32'd7) begin
      $display("[SAMPLE_TB][CHECK_FAIL] predicted got=%0d expected=7", predicted_value);
      check_errors = check_errors + 1;
    end

    if (check_errors == 0)
      $display("[SAMPLE_TB][PASS] Sample-load AXI wrapper matched LeNet result");
    else
      $display("[SAMPLE_TB][FAIL] check_errors=%0d", check_errors);

    $finish;
  end

  task axi_read;
    input [13:0] addr;
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
    input [13:0] addr;
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
