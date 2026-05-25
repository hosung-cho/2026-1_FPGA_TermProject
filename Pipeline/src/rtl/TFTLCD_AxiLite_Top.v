`timescale 1ns/1ns

module TFTLCD_AxiLite_Top #(
  parameter integer C_S_AXI_ADDR_WIDTH = 19,
  parameter integer C_S_AXI_DATA_WIDTH = 32,
  parameter integer FRAME_WIDTH = 480,
  parameter integer FRAME_HEIGHT = 272
)(
  input                                  lcd_clk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK" *)
  (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF S_AXI, ASSOCIATED_RESET s_axi_aresetn" *)
  input                                  s_axi_aclk,
  (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_aresetn RST" *)
  (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
  input                                  s_axi_aresetn,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWADDR" *)
  input  [C_S_AXI_ADDR_WIDTH-1:0]        s_axi_awaddr,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI AWPROT" *)
  input  [2:0]                           s_axi_awprot,
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
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 S_AXI ARPROT" *)
  input  [2:0]                           s_axi_arprot,
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

  output reg                             opclk,
  output reg                             Vsync,
  output reg                             Hsync,
  output wire [4:0]                      R,
  output wire [5:0]                      G,
  output wire [4:0]                      B,
  output wire                            TFTLCD_DE_out,
  output wire                            TFTLCD_Tpower
);

  localparam integer FRAME_PIXELS = FRAME_WIDTH * FRAME_HEIGHT;
  localparam [16:0] FRAME_PIXELS_17 = FRAME_PIXELS[16:0];
  localparam [16:0] FRAME_WIDTH_17 = FRAME_WIDTH[16:0];
  localparam [16:0] FRAME_LAST = FRAME_PIXELS[16:0] - 17'd1;
  localparam integer H_LAST = 524;
  localparam integer V_LAST = 285;
  localparam integer H_DE_START = 43;
  localparam integer H_DE_END = 522;
  localparam integer V_DE_START = 12;
  localparam integer V_DE_END = 283;

  wire unused_prot = |s_axi_awprot | |s_axi_arprot;

  reg [C_S_AXI_ADDR_WIDTH-1:0] awaddr_hold;
  reg [C_S_AXI_DATA_WIDTH-1:0] wdata_hold;
  reg [(C_S_AXI_DATA_WIDTH/8)-1:0] wstrb_hold;
  reg aw_hold_valid;
  reg w_hold_valid;
  reg [16:0] rd_addr;
  reg [16:0] rd_addr_next;
  reg [16:0] line_addr;
  reg [15:0] pixel_data;
  reg [9:0] h_count;
  reg [8:0] v_count;
  reg de_d1;
  reg de_d2;
  wire [15:0] fb_rd_data;

  wire write_have_aw = aw_hold_valid || s_axi_awvalid;
  wire write_have_w = w_hold_valid || s_axi_wvalid;
  wire write_accept = !s_axi_bvalid && write_have_aw && write_have_w;
  wire [C_S_AXI_ADDR_WIDTH-1:0] write_addr = aw_hold_valid ? awaddr_hold : s_axi_awaddr;
  wire [C_S_AXI_DATA_WIDTH-1:0] write_data = w_hold_valid ? wdata_hold : s_axi_wdata;
  wire [(C_S_AXI_DATA_WIDTH/8)-1:0] write_strb = w_hold_valid ? wstrb_hold : s_axi_wstrb;
  wire [16:0] write_pixel_addr = write_addr[18:2];
  wire write_pixel_valid = write_pixel_addr < FRAME_PIXELS_17;

  wire read_accept = !s_axi_rvalid && s_axi_arvalid;
  wire h_de = (h_count > H_DE_START[9:0]) && (h_count <= H_DE_END[9:0]);
  wire v_de = (v_count > V_DE_START[8:0]) && (v_count <= V_DE_END[8:0]);
  wire de = h_de && v_de;
  wire [16:0] next_line_addr = (line_addr >= (FRAME_PIXELS_17 - FRAME_WIDTH_17)) ? 17'd0 :
                               (line_addr + FRAME_WIDTH_17);

  assign TFTLCD_DE_out = 1'b1;
  assign TFTLCD_Tpower = 1'b1;
  assign R = pixel_data[15:11];
  assign G = pixel_data[10:5];
  assign B = pixel_data[4:0];

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
        s_axi_bvalid  <= 1'b1;
        s_axi_bresp   <= 2'b00;
      end else if (s_axi_bvalid && s_axi_bready) begin
        s_axi_bvalid <= 1'b0;
      end

    end
  end

  TFTLCD_Framebuffer u_framebuffer (
    .wr_clk  (s_axi_aclk),
    .wr_en   (write_accept && write_pixel_valid),
    .wr_strb (write_strb[1:0]),
    .wr_addr (write_pixel_addr),
    .wr_data (write_data[15:0]),
    .rd_clk  (opclk),
    .rd_en   (de),
    .rd_addr (rd_addr_next),
    .rd_data (fb_rd_data)
  );

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
        s_axi_rdata  <= 32'd0;
      end else if (s_axi_rvalid && s_axi_rready) begin
        s_axi_rvalid <= 1'b0;
      end
    end
  end

  always @(negedge lcd_clk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn)
      opclk <= 1'b0;
    else
      opclk <= ~opclk;
  end

  always @(negedge opclk or negedge s_axi_aresetn) begin
    if (!s_axi_aresetn) begin
      h_count <= 10'd0;
      v_count <= 9'd0;
      Hsync <= 1'b0;
      Vsync <= 1'b0;
      de_d1 <= 1'b0;
      de_d2 <= 1'b0;
      rd_addr <= 17'd0;
      rd_addr_next <= 17'd0;
      line_addr <= 17'd0;
      pixel_data <= 16'd0;
    end else begin
      if (h_count < H_LAST[9:0])
        h_count <= h_count + 10'd1;
      else begin
        h_count <= 10'd0;
        if (v_count < V_LAST[8:0])
          v_count <= v_count + 9'd1;
        else
          v_count <= 9'd0;
      end

      Hsync <= (h_count > 10'd40);
      Vsync <= (v_count > 9'd9);
      de_d1 <= de;
      de_d2 <= de_d1;

      if ((h_count == 10'd0) && (v_count == 9'd0)) begin
        rd_addr_next <= 17'd0;
        line_addr <= 17'd0;
      end else if (h_count == H_LAST[9:0]) begin
        if (v_de) begin
          line_addr <= next_line_addr;
          rd_addr_next <= next_line_addr;
        end else begin
          rd_addr_next <= line_addr;
        end
      end

      if (de) begin
        rd_addr <= rd_addr_next;
        if (rd_addr_next == FRAME_LAST)
          rd_addr_next <= 17'd0;
        else
          rd_addr_next <= rd_addr_next + 17'd1;
      end

      if (de_d1)
        pixel_data <= fb_rd_data;
      else if (!de_d2)
        pixel_data <= 16'd0;
    end
  end

endmodule

module TFTLCD_Framebuffer (
  input             wr_clk,
  input             wr_en,
  input      [1:0]  wr_strb,
  input      [16:0] wr_addr,
  input      [15:0] wr_data,
  input             rd_clk,
  input             rd_en,
  input      [16:0] rd_addr,
  output reg [15:0] rd_data
);

  (* ram_style = "block" *) reg [15:0] mem [0:131071];

  always @(posedge wr_clk) begin
    if (wr_en) begin
      if (wr_strb[0])
        mem[wr_addr][7:0] <= wr_data[7:0];
      if (wr_strb[1])
        mem[wr_addr][15:8] <= wr_data[15:8];
    end
  end

  always @(posedge rd_clk) begin
    if (rd_en)
      rd_data <= mem[rd_addr];
  end

endmodule
