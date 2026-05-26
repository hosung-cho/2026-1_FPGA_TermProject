`timescale 1ns/1ns

module RV32I_AxiLite_Sample_Top #(
  parameter [31:0] CPU_RESET_PC = 32'h0000_0000,
  parameter integer DMEM_DEPTH = 32768,
  parameter DMEM_INIT_FILE = "lenet_digit7_dmem.mem",
  parameter integer C_S_AXI_ADDR_WIDTH = 14,
  parameter integer C_S_AXI_DATA_WIDTH = 32
)(
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK" *)
  (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXI, ASSOCIATED_RESET s_axi_aresetn" *)
  input                                  s_axi_aclk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_aresetn RST" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
  input                                  s_axi_aresetn,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
  input  [C_S_AXI_ADDR_WIDTH-1:0]        s_axi_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWVALID" *)
  input                                  s_axi_awvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWREADY" *)
  output reg                             s_axi_awready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WDATA" *)
  input  [C_S_AXI_DATA_WIDTH-1:0]        s_axi_wdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WSTRB" *)
  input  [(C_S_AXI_DATA_WIDTH/8)-1:0]    s_axi_wstrb,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WVALID" *)
  input                                  s_axi_wvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI WREADY" *)
  output reg                             s_axi_wready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BRESP" *)
  output reg [1:0]                       s_axi_bresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BVALID" *)
  output reg                             s_axi_bvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI BREADY" *)
  input                                  s_axi_bready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARADDR" *)
  input  [C_S_AXI_ADDR_WIDTH-1:0]        s_axi_araddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARVALID" *)
  input                                  s_axi_arvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARREADY" *)
  output reg                             s_axi_arready,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RDATA" *)
  output reg [C_S_AXI_DATA_WIDTH-1:0]    s_axi_rdata,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RRESP" *)
  output reg [1:0]                       s_axi_rresp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RVALID" *)
  output reg                             s_axi_rvalid,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI RREADY" *)
  input                                  s_axi_rready
);

  localparam [31:0] LENET_INPUT_BASE_ADDR = 32'h0001_0000;
  localparam [31:0] LENET_EXPECTED_ADDR   = 32'h0001_0EFC;
  localparam [31:0] LENET_RESULT_ADDR     = 32'h0001_0F00;
  localparam [31:0] LENET_DONE_ADDR       = 32'h0001_0F40;

  localparam [13:0] REG_CONTROL      = 14'h0000;
  localparam [13:0] REG_STATUS       = 14'h0004;
  localparam [13:0] REG_PREDICTED    = 14'h0008;
  localparam [13:0] REG_EXPECTED     = 14'h000C;
  localparam [13:0] REG_HEARTBEAT    = 14'h0010;
  localparam [13:0] REG_DEBUG_PC     = 14'h0014;
  localparam [13:0] REG_DEBUG_INST   = 14'h0018;
  localparam [13:0] REG_DATA_ADDR    = 14'h001C;
  localparam [13:0] REG_READ_DATA    = 14'h0020;
  localparam [13:0] REG_WRITE_DATA   = 14'h0024;
  localparam [13:0] REG_DATA_WE      = 14'h0028;
  localparam [13:0] SAMPLE_BASE      = 14'h1000;
  localparam [13:0] EXPECTED_OFFSET  = 14'h2000;

  wire [31:0] fetch_addr;
  wire [31:0] inst;
  wire [31:0] data_addr;
  wire [31:0] data_read_addr;
  wire [31:0] write_data;
  reg  [31:0] read_data;
  wire [3:0]  byte_enable;
  wire        data_we;

  reg         run_enable;
  reg [3:0]   predicted_digit;
  reg [31:0]  expected_digit;
  reg         done_seen;
  reg [31:0]  heartbeat;

  reg [31:0] dmem [0:DMEM_DEPTH-1];
  integer i;

  initial begin
    for (i = 0; i < DMEM_DEPTH; i = i + 1)
      dmem[i] = 32'h00000000;
    if (DMEM_INIT_FILE != "")
      $readmemh(DMEM_INIT_FILE, dmem);
    expected_digit = 32'd7;
  end

  wire cpu_reset = ~s_axi_aresetn | ~run_enable;
  wire pass_seen = done_seen && (predicted_digit == expected_digit[3:0]);
  wire fail_seen = done_seen && (predicted_digit != expected_digit[3:0]);
  wire write_accept = !s_axi_bvalid && s_axi_awvalid && s_axi_wvalid;
  wire read_accept = !s_axi_rvalid && s_axi_arvalid;
  wire aw_is_sample = (s_axi_awaddr >= SAMPLE_BASE) && (s_axi_awaddr < (SAMPLE_BASE + 14'd1024));
  wire aw_is_expected = (s_axi_awaddr == EXPECTED_OFFSET);
  wire [7:0] sample_word = (s_axi_awaddr - SAMPLE_BASE) >> 2;

  rv32i_cpu #(
    .RESET_PC (CPU_RESET_PC)
  ) u_cpu (
    .clk        (s_axi_aclk),
    .reset      (cpu_reset),
    .pc         (fetch_addr),
    .inst       (inst),
    .MemWrite   (data_we),
    .MemAddr    (data_addr),
    .MemRAddr   (data_read_addr),
    .MemWData   (write_data),
    .ByteEnable (byte_enable),
    .MemRData   (read_data)
  );

  inst_memory u_imem (
    .clock       (s_axi_aclk),
    .enable      (1'b1),
    .address     (fetch_addr[15:2]),
    .instruction (inst)
  );

  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      read_data <= 32'd0;
    end else begin
      read_data <= dmem[data_read_addr[16:2]];

      if (data_we) begin
        if (byte_enable[0]) dmem[data_addr[16:2]][7:0]   <= write_data[7:0];
        if (byte_enable[1]) dmem[data_addr[16:2]][15:8]  <= write_data[15:8];
        if (byte_enable[2]) dmem[data_addr[16:2]][23:16] <= write_data[23:16];
        if (byte_enable[3]) dmem[data_addr[16:2]][31:24] <= write_data[31:24];
      end else if (write_accept && aw_is_sample && !run_enable) begin
        if (s_axi_wstrb[0]) dmem[(LENET_INPUT_BASE_ADDR >> 2) + sample_word][7:0]   <= s_axi_wdata[7:0];
        if (s_axi_wstrb[1]) dmem[(LENET_INPUT_BASE_ADDR >> 2) + sample_word][15:8]  <= s_axi_wdata[15:8];
        if (s_axi_wstrb[2]) dmem[(LENET_INPUT_BASE_ADDR >> 2) + sample_word][23:16] <= s_axi_wdata[23:16];
        if (s_axi_wstrb[3]) dmem[(LENET_INPUT_BASE_ADDR >> 2) + sample_word][31:24] <= s_axi_wdata[31:24];
      end else if (write_accept && aw_is_expected && !run_enable) begin
        dmem[LENET_EXPECTED_ADDR >> 2] <= s_axi_wdata;
      end
    end
  end

  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      run_enable      <= 1'b0;
      predicted_digit <= 4'd0;
      expected_digit  <= 32'd7;
      done_seen       <= 1'b0;
      heartbeat       <= 32'd0;
    end else begin
      heartbeat <= heartbeat + 32'd1;

      if (!run_enable) begin
        predicted_digit <= 4'd0;
        done_seen       <= 1'b0;
      end else begin
        if (data_we && (data_addr == LENET_RESULT_ADDR))
          predicted_digit <= write_data[3:0];
        if (data_we && (data_addr == LENET_DONE_ADDR) && (write_data == 32'd1))
          done_seen <= 1'b1;
      end

      if (write_accept && (s_axi_awaddr == REG_CONTROL)) begin
        if (s_axi_wstrb[0]) begin
          run_enable <= s_axi_wdata[0];
          if (s_axi_wdata[1]) begin
            predicted_digit <= 4'd0;
            done_seen       <= 1'b0;
          end
        end
      end

      if (write_accept && aw_is_expected && !run_enable)
        expected_digit <= s_axi_wdata;
    end
  end

  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      s_axi_awready <= 1'b0;
      s_axi_wready  <= 1'b0;
      s_axi_bvalid  <= 1'b0;
      s_axi_bresp   <= 2'b00;
    end else begin
      s_axi_awready <= write_accept;
      s_axi_wready  <= write_accept;
      if (write_accept) begin
        s_axi_bvalid <= 1'b1;
        s_axi_bresp  <= 2'b00;
      end else if (s_axi_bvalid && s_axi_bready) begin
        s_axi_bvalid <= 1'b0;
      end
    end
  end

  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      s_axi_arready <= 1'b0;
      s_axi_rvalid  <= 1'b0;
      s_axi_rresp   <= 2'b00;
      s_axi_rdata   <= 32'd0;
    end else begin
      s_axi_arready <= read_accept;
      if (read_accept) begin
        s_axi_rvalid <= 1'b1;
        s_axi_rresp  <= 2'b00;
        s_axi_rdata  <= read_register(s_axi_araddr);
      end else if (s_axi_rvalid && s_axi_rready) begin
        s_axi_rvalid <= 1'b0;
      end
    end
  end

  function [31:0] read_register;
    input [13:0] addr;
    begin
      case (addr)
        REG_CONTROL:    read_register = {30'd0, 1'b0, run_enable};
        REG_STATUS:     read_register = {29'd0, fail_seen, pass_seen, done_seen};
        REG_PREDICTED:  read_register = {28'd0, predicted_digit};
        REG_EXPECTED:   read_register = expected_digit;
        REG_HEARTBEAT:  read_register = heartbeat;
        REG_DEBUG_PC:   read_register = fetch_addr;
        REG_DEBUG_INST: read_register = inst;
        REG_DATA_ADDR:  read_register = data_addr;
        REG_READ_DATA:  read_register = read_data;
        REG_WRITE_DATA: read_register = write_data;
        REG_DATA_WE:    read_register = {31'd0, data_we};
        default:        read_register = 32'd0;
      endcase
    end
  endfunction

endmodule
