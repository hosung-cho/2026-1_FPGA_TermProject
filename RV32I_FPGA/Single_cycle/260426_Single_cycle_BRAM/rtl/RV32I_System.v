`timescale 1ns/1ns

module RV32I_System(
);

  wire clk_50, clk_200;
  // 보고 싶은 신호에 mark_debug 속성 추가 (로직 삭제 방지 및 디버깅용)
  (* mark_debug = "true" *) wire [31:0] fetch_addr;
  (* mark_debug = "true" *) wire [31:0] inst;
  (* mark_debug = "true" *) wire [31:0] data_addr;
  (* mark_debug = "true" *) wire [31:0] write_data;
  (* mark_debug = "true" *) wire [31:0] read_data;
  (* mark_debug = "true" *) wire [3:0]  ByteEnable;
  (* mark_debug = "true" *) wire        data_we;
  
    wire ps_resetn;  // Zynq 기본 리셋 (Active Low)
    wire vio_reset;  // VIO 리셋 (Active High)
    wire locked;     // 클럭 안정화 신호 (1일 때 안정)

    // 1. 블록 디자인 래퍼 불러오기
    design_1_wrapper ps_system (
        .clk_50_0      (clk_50),
        .clk_200_0    (clk_200),
        .pl_resetn0 (ps_resetn),
        .vio_reset  (vio_reset),
        .locked_0     (locked)      // 추가됨!
    );

    // 2. 완벽한 안전 리셋 조합 (CPU가 Active High 리셋일 경우)
    // 조건 1: Zynq가 리셋 중일 때 (~ps_resetn)
    // 조건 2: VIO 버튼을 눌렀을 때 (vio_reset)
    // 조건 3: 클럭 위상이 아직 안 맞춰졌을 때 (~locked)
    wire final_cpu_reset = (~ps_resetn) | vio_reset | (~locked);

  // CPU가 끝났는지 확인하기 위한 디버그 신호 (예: jal x0, 0 이면 halt)
  (* mark_debug = "true" *) wire        is_halted = (inst == 32'h0000006f);

  // CPU instantiation
  rv32i_cpu icpu (
    .clk        (clk_50), 
    .reset      (~final_cpu_reset),
    .pc         (fetch_addr),
    .inst       (inst),
    .MemWrite   (data_we),
    .MemAddr    (data_addr), 
    .MemWData   (write_data),
    .ByteEnable (ByteEnable),
    .MemRData   (read_data)
  );

  // Instruction Memory (separate, read-only)
  inst_memory iIMem (
    .clock       (clk_200),
    .enable      (1'b1),
    .address     (fetch_addr[15:2]),  // Word address (64KB)
    .instruction (inst)
  );

  // Data Memory (separate, read/write)
  data_memory iDMem (
    .clock      (clk_200),
    .enable     (1'b1),
    .wren       (safe_wren),
    .address    (data_addr[15:2]),   // Word address (64KB)
    .write_data (write_data),
    .byteena    (ByteEnable),
    .read_data  (read_data)
  );
  
  // Top 모듈에서 dmem으로 가는 write enable 신호 수정
  wire safe_wren; // BRAM으로 들어갈 안전한 쓰기 신호
    
  // CPU 클럭(50MHz)이 '0'으로 떨어진 안정적인 후반부에만 쓰기를 허용
  assign safe_wren = data_we & (~clk_50);

endmodule
