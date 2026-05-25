`timescale 1ns/1ns

module RV32I_ExternalDmem_System #(
  parameter [31:0] CPU_RESET_PC = 32'h1000_0000
)(
  input         CLOCK_50,
  input         reset,
  output [31:0] debug_pc,
  output [31:0] debug_inst,
  output [31:0] debug_data_addr,
  output [31:0] debug_read_data,
  output [31:0] debug_write_data,
  output        debug_data_we,

  output        dmem_rd_clk,
  output        dmem_rd_en,
  output [14:0] dmem_rd_addr,
  input  [31:0] dmem_rd_dout,
  output        dmem_wr_clk,
  output        dmem_wr_en,
  output [3:0]  dmem_wr_we,
  output [14:0] dmem_wr_addr,
  output [31:0] dmem_wr_din
);

  wire clk;
  wire [31:0] fetch_addr;
  wire [31:0] inst;
  wire [31:0] data_addr;
  wire [31:0] data_read_addr;
  wire [31:0] write_data;
  wire [3:0]  byte_enable;
  wire        data_we;

  assign clk = CLOCK_50;
  assign debug_pc = fetch_addr;
  assign debug_inst = inst;
  assign debug_data_addr = data_addr;
  assign debug_read_data = dmem_rd_dout;
  assign debug_write_data = write_data;
  assign debug_data_we = data_we;

  assign dmem_rd_clk = clk;
  assign dmem_rd_en = 1'b1;
  assign dmem_rd_addr = data_read_addr[16:2];

  assign dmem_wr_clk = clk;
  assign dmem_wr_en = data_we;
  assign dmem_wr_we = data_we ? byte_enable : 4'b0000;
  assign dmem_wr_addr = data_addr[16:2];
  assign dmem_wr_din = write_data;

  rv32i_cpu #(
    .RESET_PC (CPU_RESET_PC)
  ) icpu (
    .clk        (clk),
    .reset      (~reset),
    .pc         (fetch_addr),
    .inst       (inst),
    .MemWrite   (data_we),
    .MemAddr    (data_addr),
    .MemRAddr   (data_read_addr),
    .MemWData   (write_data),
    .ByteEnable (byte_enable),
    .MemRData   (dmem_rd_dout)
  );

  inst_memory iIMem (
    .clock       (clk),
    .enable      (1'b1),
    .address     (fetch_addr[15:2]),
    .instruction (inst)
  );

endmodule
