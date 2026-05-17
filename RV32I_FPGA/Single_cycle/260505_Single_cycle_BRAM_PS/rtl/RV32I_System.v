`timescale 1ns/1ns

module RV32I_System(
  input         CLOCK_50,
  input         reset,

  // =========================================================
  // BRAM Port B 인터페이스 (외부 Block Design의 BRAM과 연결될 포트들)
  // =========================================================
  
  // 1. Instruction Memory (Read Only from CPU's perspective)
  output [31:0] imem_addr,
  input  [31:0] imem_rdata,
  output        imem_en,

  // 2. Data Memory (Read/Write)
  output [31:0] dmem_addr,
  output [31:0] dmem_wdata,
  input  [31:0] dmem_rdata,
  output [3:0]  dmem_we,     // Byte Enable Write
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
  rv32i_cpu icpu (
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

  // =========================================================
  // 포트 맵핑 (Port Mapping) 및 제어 로직
  // =========================================================
  
  // [Instruction BRAM 연결]
  // PC는 이미 Byte 단위 주소이므로 BRAM의 주소에 그대로 연결합니다.
  assign imem_addr = fetch_addr;
  assign inst      = imem_rdata;
  assign imem_en   = 1'b1; // Fetch는 항상 활성화

  // [Data BRAM 연결]
  assign dmem_addr  = data_addr;
  assign dmem_wdata = write_data;
  assign read_data  = dmem_rdata;
  assign dmem_en    = 1'b1; // Single-cycle에서는 항상 활성화 상태 유지

  // ⚠️ [매우 중요한 수정 포인트: Write Enable 필터링]
  // rv32i_cpu.v 내부를 보면 LW, LH 같은 'Load' 명령어일 때도 ByteEnable 신호가 켜집니다.
  // 이 ByteEnable을 BRAM의 dmem_we에 그대로 연결하면, 읽어야 할 타이밍에 메모리를 덮어쓰는(Data Corruption) 대참사가 발생합니다.
  // 따라서, 반드시 MemWrite(data_we)가 1일 때만 ByteEnable이 나가도록 마스킹(Gating) 처리해야 합니다.
  assign dmem_we    = data_we ? ByteEnable : 4'b0000;

endmodule