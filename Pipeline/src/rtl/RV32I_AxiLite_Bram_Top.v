`timescale 1ns/1ns

module RV32I_AxiLite_Bram_Top #(
  parameter [31:0] CPU_RESET_PC = 32'h0000_0000,
  parameter [31:0] EXPECTED_DIGIT = 32'd7,
  parameter integer ENABLE_CNN = 1,
  parameter integer C_S_AXI_ADDR_WIDTH = 6,
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
  input                                  s_axi_rready,

  output                                 cpu_active,
  output                                 dmem_rd_clk,
  output                                 dmem_rd_en,
  output [14:0]                          dmem_rd_addr,
  input  [31:0]                          dmem_rd_dout,
  output                                 dmem_wr_clk,
  output                                 dmem_wr_en,
  output [3:0]                           dmem_wr_we,
  output [14:0]                          dmem_wr_addr,
  output [31:0]                          dmem_wr_din
);

  localparam [31:0] LENET_RESULT_ADDR = 32'h0001_0F00;
  localparam [31:0] LENET_DONE_ADDR   = 32'h0001_0F40;

  localparam [5:0] REG_CONTROL      = 6'h00;
  localparam [5:0] REG_STATUS       = 6'h04;
  localparam [5:0] REG_PREDICTED    = 6'h08;
  localparam [5:0] REG_EXPECTED     = 6'h0C;
  localparam [5:0] REG_HEARTBEAT    = 6'h10;
  localparam [5:0] REG_DEBUG_PC     = 6'h14;
  localparam [5:0] REG_DEBUG_INST   = 6'h18;
  localparam [5:0] REG_DATA_ADDR    = 6'h1C;
  localparam [5:0] REG_READ_DATA    = 6'h20;
  localparam [5:0] REG_WRITE_DATA   = 6'h24;
  localparam [5:0] REG_DATA_WE      = 6'h28;
  localparam [5:0] REG_CYCLE_COUNT  = 6'h2C;

  wire [31:0] debug_pc;
  wire [31:0] debug_inst;
  wire [31:0] debug_data_addr;
  wire [31:0] debug_read_data;
  wire [31:0] debug_write_data;
  wire        debug_data_we;

  reg         run_enable;
  reg [3:0]   predicted_digit;
  reg         done_seen;
  reg [31:0]  heartbeat;
  reg [31:0]  cycle_count;

  wire system_run = s_axi_aresetn && run_enable;
  assign cpu_active = run_enable;
  wire pass_seen = done_seen && (predicted_digit == EXPECTED_DIGIT[3:0]);
  wire fail_seen = done_seen && (predicted_digit != EXPECTED_DIGIT[3:0]);
  wire read_accept = !s_axi_rvalid && s_axi_arvalid;

  reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_hold;
  reg [C_S_AXI_DATA_WIDTH-1:0] wdata_hold;
  reg [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb_hold;
  reg aw_hold_valid;
  reg w_hold_valid;

  wire write_have_aw = aw_hold_valid || s_axi_awvalid;
  wire write_have_w = w_hold_valid || s_axi_wvalid;
  wire write_accept = !s_axi_bvalid && write_have_aw && write_have_w;
  wire [C_S_AXI_ADDR_WIDTH-1:0] write_addr = aw_hold_valid ? awaddr_hold : s_axi_awaddr;
  wire [C_S_AXI_DATA_WIDTH-1:0] write_data = w_hold_valid ? wdata_hold : s_axi_wdata;
  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] write_strb = w_hold_valid ? wstrb_hold : s_axi_wstrb;

  RV32I_ExternalDmem_System #(
    .CPU_RESET_PC (CPU_RESET_PC),
    .ENABLE_CNN   (ENABLE_CNN)
  ) u_system (
    .CLOCK_50         (s_axi_aclk),
    .reset            (system_run),
    .debug_pc         (debug_pc),
    .debug_inst       (debug_inst),
    .debug_data_addr  (debug_data_addr),
    .debug_read_data  (debug_read_data),
    .debug_write_data (debug_write_data),
    .debug_data_we    (debug_data_we),
    .dmem_rd_clk      (dmem_rd_clk),
    .dmem_rd_en       (dmem_rd_en),
    .dmem_rd_addr     (dmem_rd_addr),
    .dmem_rd_dout     (dmem_rd_dout),
    .dmem_wr_clk      (dmem_wr_clk),
    .dmem_wr_en       (dmem_wr_en),
    .dmem_wr_we       (dmem_wr_we),
    .dmem_wr_addr     (dmem_wr_addr),
    .dmem_wr_din      (dmem_wr_din)
  );

  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      run_enable      <= 1'b0;
      predicted_digit <= 4'd0;
      done_seen       <= 1'b0;
      heartbeat       <= 32'd0;
      cycle_count     <= 32'd0;
    end else begin
      heartbeat <= heartbeat + 32'd1;

      if (!run_enable) begin
        predicted_digit <= 4'd0;
        done_seen       <= 1'b0;
        cycle_count     <= 32'd0;
      end else begin
        if (!done_seen)
          cycle_count <= cycle_count + 32'd1;

        if (debug_data_we && (debug_data_addr == LENET_RESULT_ADDR))
          predicted_digit <= debug_write_data[3:0];

        if (debug_data_we && (debug_data_addr == LENET_DONE_ADDR) && (debug_write_data == 32'd1))
          done_seen <= 1'b1;
      end

      if (write_accept && (write_addr[5:0] == REG_CONTROL)) begin
        if (write_strb[0]) begin
          run_enable <= write_data[0];
          if (write_data[1]) begin
            predicted_digit <= 4'd0;
            done_seen       <= 1'b0;
            cycle_count     <= 32'd0;
          end
        end
      end
    end
  end

  always @(posedge s_axi_aclk) begin
    if (!s_axi_aresetn) begin
      s_axi_awready <= 1'b0;
      s_axi_wready  <= 1'b0;
      s_axi_bvalid  <= 1'b0;
      s_axi_bresp   <= 2'b00;
      aw_hold_valid <= 1'b0;
      w_hold_valid  <= 1'b0;
      awaddr_hold   <= {C_S_AXI_ADDR_WIDTH{1'b0}};
      wdata_hold    <= {C_S_AXI_DATA_WIDTH{1'b0}};
      wstrb_hold    <= {(C_S_AXI_DATA_WIDTH/8){1'b0}};
    end else begin
      s_axi_awready <= !aw_hold_valid && !s_axi_bvalid;
      s_axi_wready  <= !w_hold_valid && !s_axi_bvalid;

      if (!aw_hold_valid && s_axi_awvalid && !write_accept) begin
        aw_hold_valid <= 1'b1;
        awaddr_hold   <= s_axi_awaddr;
      end

      if (!w_hold_valid && s_axi_wvalid && !write_accept) begin
        w_hold_valid <= 1'b1;
        wdata_hold   <= s_axi_wdata;
        wstrb_hold   <= s_axi_wstrb;
      end

      if (write_accept) begin
        aw_hold_valid <= 1'b0;
        w_hold_valid  <= 1'b0;
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
        s_axi_rdata  <= read_register(s_axi_araddr[5:0]);
      end else if (s_axi_rvalid && s_axi_rready) begin
        s_axi_rvalid <= 1'b0;
      end
    end
  end

  function [31:0] read_register;
    input [5:0] addr;
    begin
      case (addr)
        REG_CONTROL:    read_register = {30'd0, 1'b0, run_enable};
        REG_STATUS:     read_register = {29'd0, fail_seen, pass_seen, done_seen};
        REG_PREDICTED:  read_register = {28'd0, predicted_digit};
        REG_EXPECTED:   read_register = EXPECTED_DIGIT;
        REG_HEARTBEAT:  read_register = heartbeat;
        REG_DEBUG_PC:   read_register = debug_pc;
        REG_DEBUG_INST: read_register = debug_inst;
        REG_DATA_ADDR:  read_register = debug_data_addr;
        REG_READ_DATA:  read_register = debug_read_data;
        REG_WRITE_DATA: read_register = debug_write_data;
        REG_DATA_WE:    read_register = {31'd0, debug_data_we};
        REG_CYCLE_COUNT: read_register = cycle_count;
        default:        read_register = 32'd0;
      endcase
    end
  endfunction

endmodule
