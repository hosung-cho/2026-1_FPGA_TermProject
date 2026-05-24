`timescale 1 ns / 1 ns
// ======================================================================
// 데이터 메모리 (Data Memory)
// CPU가 연산 중인 데이터를 임시로 보관하는 RAM(램) 역할을 합니다.
// Store 명령어(sw, sh, sb)로 데이터를 쓰고, Load 명령어(lw, lh, lb)로 데이터를 읽습니다.
// ======================================================================
module data_memory #(
    parameter DEPTH = 32768,
    parameter ADDR_WIDTH = 15,
    parameter INIT_FILE = ""
) (
    input               clock,
    input               enable,
    input               wren,           // write enable
    input      [ADDR_WIDTH-1:0] read_address,
    input      [ADDR_WIDTH-1:0] write_address,
    input      [31:0]   write_data,
    input      [3:0]    byteena,        // byte enable
    output reg [31:0]   read_data
);

    // Data memory array
    reg [31:0] mem [0:DEPTH-1];
    
    integer i;

    // ========================================
    // 메모리 초기화 (Initialization)
    // 시뮬레이션 시작 시 모든 데이터를 0으로 덮어씌웁니다.
    // ========================================
    initial begin
        // Initialize all memory to 0
        for (i = 0; i < DEPTH; i = i + 1) begin
            mem[i] = 32'h00000000;
        end
        
        if (INIT_FILE != "") begin
            $readmemh(INIT_FILE, mem);
        end
        
        $display("Data Memory initialized at time %t", $time);
    end

    // ========================================
    // 동기식 쓰기 (Synchronous Write)
    // 클럭이 뛰는 순간(posedge clock)에 쓰기 활성화(wren)가 켜져 있으면 메모리에 값을 씁니다.
    // byteena(바이트 활성화) 신호에 따라 1~4바이트 단위로 쪼개서 쓸 수 있습니다.
    // ========================================
    always @(posedge clock) begin
        if (enable && wren) begin
            // Byte-addressable write
            if (byteena[0]) mem[write_address][7:0]   <= write_data[7:0];
            if (byteena[1]) mem[write_address][15:8]  <= write_data[15:8];
            if (byteena[2]) mem[write_address][23:16] <= write_data[23:16];
            if (byteena[3]) mem[write_address][31:24] <= write_data[31:24];
        end
    end
    
    // ========================================
    // 비동기식 읽기 (Asynchronous Read)
    // 클럭과 무관하게, 주소(address)가 들어오면 즉시 해당 주소의 데이터를 출력합니다.
    // (파이프라인 타이밍을 맞추기 위해 읽기는 비동기로 설계됨)
    // ========================================
    always @(posedge clock) begin
        if (enable)
            read_data <= mem[read_address];
        else
            read_data <= 32'h00000000;
    end

endmodule
