`timescale 1ns/1ns
// ======================================================================
// 시스템 최상위 모듈 (System Top Module)
// CPU 코어(rv32i_cpu)와 명령어 메모리(inst_memory), 데이터 메모리(data_memory)를 
// 하나로 묶어 완전한 컴퓨터 시스템(SoC)을 구성하는 껍데기 모듈입니다.
// ======================================================================
module RV32I_System #(
  parameter [31:0] CPU_RESET_PC = 32'h1000_0000,
  parameter DMEM_INIT_FILE = ""
)(
  input         CLOCK_50,
  input         reset,
  output [31:0] debug_pc,
  output [31:0] debug_inst,
  output [31:0] debug_data_addr,
  output [31:0] debug_read_data,
  output [31:0] debug_write_data,
  output        debug_data_we
);

  wire clk;
  wire [31:0] fetch_addr;
  wire [31:0] inst;
  wire [31:0] data_addr;
  wire [31:0] data_read_addr;
  wire [31:0] write_data;
  wire [31:0] read_data;
  wire [3:0]  ByteEnable;
  wire        data_we;

  assign clk = CLOCK_50;
  assign debug_pc = fetch_addr;
  assign debug_inst = inst;
  assign debug_data_addr = data_addr;
  assign debug_read_data = read_data;
  assign debug_write_data = write_data;
  assign debug_data_we = data_we;

  // ========================================
  // CPU 코어 인스턴스화 (CPU Core Instantiation)
  // ========================================
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
    .ByteEnable (ByteEnable),
    .MemRData   (read_data)
  );

  // ========================================
  // 명령어 메모리 (Instruction Memory)
  // CPU가 읽어갈 프로그램 코드(.hex)가 저장된 읽기 전용(Read-only) 롬입니다.
  // ========================================
  inst_memory iIMem (
    .clock       (clk),
    .enable      (1'b1),
    .address     (fetch_addr[15:2]),  // Word address
    .instruction (inst)
  );

  // ========================================
  // 데이터 메모리 (Data Memory)
  // CPU가 계산 중인 변수나 배열을 저장하거나 읽어오는 읽기/쓰기 가능(Read/Write) 램입니다.
  // ========================================
  data_memory #(
    .DEPTH      (32768),
    .ADDR_WIDTH (15),
    .INIT_FILE  (DMEM_INIT_FILE)
  ) iDMem (
    .clock      (clk),
    .enable     (1'b1),
    .wren       (data_we),
    .read_address(data_read_addr[16:2]),  // Word address
    .write_address(data_addr[16:2]),      // Word address
    .write_data (write_data),
    .byteena    (ByteEnable),
    .read_data  (read_data)
  );

endmodule
