`timescale 1ns/1ns

module BramPortA_RunMux (
  input         select_cpu,

  input         axi_clk,
  input         axi_rst,
  input         axi_en,
  input  [3:0]  axi_we,
  input  [16:0] axi_addr,
  input  [31:0] axi_din,
  output [31:0] axi_dout,

  input         cpu_clk,
  input         cpu_en,
  input  [3:0]  cpu_we,
  input  [14:0] cpu_addr,
  input  [31:0] cpu_din,

  output        bram_clk,
  output        bram_rst,
  output        bram_en,
  output [3:0]  bram_we,
  output [14:0] bram_addr,
  output [31:0] bram_din,
  input  [31:0] bram_dout
);

  assign axi_dout = bram_dout;

  assign bram_clk = select_cpu ? cpu_clk : axi_clk;
  assign bram_rst = select_cpu ? 1'b0 : axi_rst;
  assign bram_en = select_cpu ? cpu_en : axi_en;
  assign bram_we = select_cpu ? cpu_we : axi_we;
  assign bram_addr = select_cpu ? cpu_addr : axi_addr[16:2];
  assign bram_din = select_cpu ? cpu_din : axi_din;

endmodule
