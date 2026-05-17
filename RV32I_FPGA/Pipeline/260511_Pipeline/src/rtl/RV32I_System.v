`timescale 1ns/1ns

module RV32I_System #(
  parameter [31:0] CPU_RESET_PC = 32'h0000_0000
)(
  input         CLOCK_50,
  input         reset,

  // Instruction memory (BRAM Port B)
  output [31:0] imem_addr,
  input  [31:0] imem_rdata,
  output        imem_en,

  // Data memory (BRAM Port B)
  output [31:0] dmem_addr,
  output [31:0] dmem_wdata,
  input  [31:0] dmem_rdata,
  output [3:0]  dmem_we,
  output        dmem_en
);

  wire clk;
  assign clk = CLOCK_50;

  // 디버깅용 mark_debug 신호들 유지
  (* mark_debug = "true" *) wire [31:0] fetch_addr;
  (* mark_debug = "true" *) wire [31:0] inst;
  (* mark_debug = "true" *) wire [31:0] data_addr;
  (* mark_debug = "true" *) wire [31:0] write_data;
  (* mark_debug = "true" *) wire [31:0] read_data;
  (* mark_debug = "true" *) wire [3:0]  ByteEnable;
  (* mark_debug = "true" *) wire        data_we;
  (* mark_debug = "true" *) wire        is_halted = (inst == 32'h0000006f);


  // CPU instantiation
  rv32i_cpu #(
    .RESET_PC (CPU_RESET_PC)
  ) icpu (
    .clk        (clk), 
    .reset      (~reset),
    .pc         (fetch_addr),
    .inst       (inst),
    .MemWrite   (data_we),
    .MemAddr    (data_addr), 
    .MemWData   (write_data),
    .ByteEnable (ByteEnable),
    .MemRData   (read_data)
  );

  // Instruction memory port mapping
  assign imem_addr = fetch_addr;
  assign inst      = imem_rdata;
  assign imem_en   = 1'b1;

  // Data memory port mapping
  assign dmem_addr  = data_addr;
  assign dmem_wdata = write_data;
  assign read_data  = dmem_rdata;
  assign dmem_en    = 1'b1;

  // Gate byte enables to avoid unintended writes on load instructions.
  assign dmem_we    = data_we ? ByteEnable : 4'b0000;

endmodule
