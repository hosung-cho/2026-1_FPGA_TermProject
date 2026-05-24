`timescale 1ns/1ns
`include "lenet_mem_map.vh"

module RV32I_System_tb();

  reg clk;
  reg reset;
  integer cycle_count;
  integer cnn_start_count;
  integer cnn_done_count;
  integer cnn_wait_cycles;
  integer load_use_stall_cycles;
  integer total_stall_cycles;
  integer flush_count;
  integer check_errors;
  reg [1023:0] imem_hex;
  reg [1023:0] dmem_hex;
  reg [255:0] sample_name;
  integer expected_label;
  wire [31:0] debug_pc_unused;
  wire [31:0] debug_inst_unused;
  wire [31:0] debug_data_addr_unused;
  wire [31:0] debug_read_data_unused;
  wire [31:0] debug_write_data_unused;
  wire        debug_data_we_unused;

  parameter IMEM_HEX = "../../../FPGA_proj/firmware/lenet_infer_imem.hex";
  parameter DMEM_HEX = "../../../FPGA_proj/firmware/lenet_digit7_dmem.mem";
  parameter integer TIMEOUT_CYCLES = 20000000;

  localparam integer RESULT_WORD = `LENET_RESULT_WORD;
  localparam integer DONE_WORD   = `LENET_DONE_WORD;
  localparam integer DEBUG_WORD  = `LENET_DEBUG_WORD;
  localparam integer EXPECTED_WORD = `LENET_EXPECTED_WORD;

  RV32I_System #(
    .CPU_RESET_PC(32'h0000_0000)
  ) iRV32I_System (
    .CLOCK_50(clk),
    .reset(reset),
    .debug_pc(debug_pc_unused),
    .debug_inst(debug_inst_unused),
    .debug_data_addr(debug_data_addr_unused),
    .debug_read_data(debug_read_data_unused),
    .debug_write_data(debug_write_data_unused),
    .debug_data_we(debug_data_we_unused)
  );

  initial begin
    clk = 1'b0;
    forever #10 clk = ~clk;
  end

  initial begin
    reset = 1'b0;
    cycle_count = 0;
    cnn_start_count = 0;
    cnn_done_count = 0;
    cnn_wait_cycles = 0;
    load_use_stall_cycles = 0;
    total_stall_cycles = 0;
    flush_count = 0;
    check_errors = 0;
    imem_hex = IMEM_HEX;
    dmem_hex = DMEM_HEX;
    sample_name = "digit7";

    if (!$value$plusargs("IMEM_HEX=%s", imem_hex)) begin
      imem_hex = IMEM_HEX;
    end
    if (!$value$plusargs("DMEM_HEX=%s", dmem_hex)) begin
      dmem_hex = DMEM_HEX;
    end
    if (!$value$plusargs("SAMPLE=%s", sample_name)) begin
      sample_name = "digit7";
    end

    repeat (8) @(posedge clk);
    $display("[LENET_TB] Loading IMEM: %0s", imem_hex);
    $readmemh(imem_hex, iRV32I_System.iIMem.mem);
    $display("[LENET_TB] Loading DMEM: %0s sample=%0s", dmem_hex, sample_name);
    $readmemh(dmem_hex, iRV32I_System.iDMem.mem);

    @(negedge clk);
    reset = 1'b1;
    $display("[LENET_TB] Reset released");
  end

  always @(posedge clk) begin
    if (reset) begin
      cycle_count <= cycle_count + 1;
      if (iRV32I_System.icpu.i_datapath.cnn_start_pulse)
        cnn_start_count <= cnn_start_count + 1;
      if (iRV32I_System.icpu.i_datapath.cnn_ap_done)
        cnn_done_count <= cnn_done_count + 1;
      if (iRV32I_System.icpu.i_datapath.cnn_wait_stall)
        cnn_wait_cycles <= cnn_wait_cycles + 1;
      if (iRV32I_System.icpu.i_datapath.load_use_stall)
        load_use_stall_cycles <= load_use_stall_cycles + 1;
      if (iRV32I_System.icpu.i_datapath.stall)
        total_stall_cycles <= total_stall_cycles + 1;
      if (iRV32I_System.icpu.i_datapath.flush)
        flush_count <= flush_count + 1;
    end
  end

  always @(posedge clk) begin
    if (reset && (cycle_count % 1000000) == 0 && cycle_count != 0) begin
      $display("[LENET_TB] progress cycles=%0d pc=0x%08h done=%0d result=%0d",
               cycle_count,
               iRV32I_System.icpu.pc,
               iRV32I_System.iDMem.mem[DONE_WORD],
               iRV32I_System.iDMem.mem[RESULT_WORD]);
    end

    if (reset && iRV32I_System.iDMem.mem[DONE_WORD] == 32'd1) begin
      expected_label = iRV32I_System.iDMem.mem[RESULT_WORD + 1];
      $display("[LENET_TB] Done at cycle %0d", cycle_count);
      $display("[LENET_TB][PERF] sample=%0s cycles=%0d cnn_start=%0d cnn_done=%0d cnn_wait_cycles=%0d load_use_stall_cycles=%0d total_stall_cycles=%0d flushes=%0d",
               sample_name,
               cycle_count,
               cnn_start_count,
               cnn_done_count,
               cnn_wait_cycles,
               load_use_stall_cycles,
               total_stall_cycles,
               flush_count);
      $display("[LENET_TB] sample=%0s predicted=%0d expected=%0d",
               sample_name,
               iRV32I_System.iDMem.mem[RESULT_WORD],
               expected_label);
      $display("[LENET_TB] logits: %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d",
               iRV32I_System.iDMem.mem[RESULT_WORD + 2],
               iRV32I_System.iDMem.mem[RESULT_WORD + 3],
               iRV32I_System.iDMem.mem[RESULT_WORD + 4],
               iRV32I_System.iDMem.mem[RESULT_WORD + 5],
               iRV32I_System.iDMem.mem[RESULT_WORD + 6],
               iRV32I_System.iDMem.mem[RESULT_WORD + 7],
               iRV32I_System.iDMem.mem[RESULT_WORD + 8],
               iRV32I_System.iDMem.mem[RESULT_WORD + 9],
               iRV32I_System.iDMem.mem[RESULT_WORD + 10],
               iRV32I_System.iDMem.mem[RESULT_WORD + 11]);
      $display("[LENET_TB] debug c1=%0d p1=%0d c2=%0d p2=%0d c3=%0d fc1=%0d",
               iRV32I_System.iDMem.mem[DEBUG_WORD + 0],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 1],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 2],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 3],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 4],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 5]);
      $display("[LENET_TB] debug c3_0_7: %0d %0d %0d %0d %0d %0d %0d %0d",
               iRV32I_System.iDMem.mem[DEBUG_WORD + 8],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 9],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 10],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 11],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 12],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 13],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 14],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 15]);
      $display("[LENET_TB] debug fc1_0_7: %0d %0d %0d %0d %0d %0d %0d %0d",
               iRV32I_System.iDMem.mem[DEBUG_WORD + 16],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 17],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 18],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 19],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 20],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 21],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 22],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 23]);
      $display("[LENET_TB] debug p2_ch0_0_7: %0d %0d %0d %0d %0d %0d %0d %0d",
               iRV32I_System.iDMem.mem[DEBUG_WORD + 24],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 25],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 26],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 27],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 28],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 29],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 30],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 31]);
      $display("[LENET_TB] debug p2_ch_0_7_00: %0d %0d %0d %0d %0d %0d %0d %0d",
               iRV32I_System.iDMem.mem[DEBUG_WORD + 32],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 33],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 34],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 35],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 36],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 37],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 38],
               iRV32I_System.iDMem.mem[DEBUG_WORD + 39]);

      check_errors = 0;
      if (iRV32I_System.iDMem.mem[RESULT_WORD] !== expected_label) begin
        $display("[LENET_TB][CHECK_FAIL] predicted got=%0d expected=%0d sample=%0s",
                 iRV32I_System.iDMem.mem[RESULT_WORD],
                 expected_label,
                 sample_name);
        check_errors = check_errors + 1;
      end

      if (expected_label == 7 && iRV32I_System.iDMem.mem[DEBUG_WORD + 3] !== 32'd11) begin
        $display("[LENET_TB][CHECK_FAIL] p2[0][0][0] got=%0d expected=11",
                 iRV32I_System.iDMem.mem[DEBUG_WORD + 3]);
        check_errors = check_errors + 1;
      end
      if (expected_label == 7 && iRV32I_System.iDMem.mem[DEBUG_WORD + 9] !== 32'd42) begin
        $display("[LENET_TB][CHECK_FAIL] c3[1] got=%0d expected=42",
                 iRV32I_System.iDMem.mem[DEBUG_WORD + 9]);
        check_errors = check_errors + 1;
      end
      if (expected_label == 7 && iRV32I_System.iDMem.mem[DEBUG_WORD + 13] !== 32'd20) begin
        $display("[LENET_TB][CHECK_FAIL] c3[5] got=%0d expected=20",
                 iRV32I_System.iDMem.mem[DEBUG_WORD + 13]);
        check_errors = check_errors + 1;
      end
      if (expected_label == 7 && iRV32I_System.iDMem.mem[DEBUG_WORD + 16] !== 32'd64) begin
        $display("[LENET_TB][CHECK_FAIL] fc1[0] got=%0d expected=64",
                 iRV32I_System.iDMem.mem[DEBUG_WORD + 16]);
        check_errors = check_errors + 1;
      end
      if (expected_label == 7 && iRV32I_System.iDMem.mem[RESULT_WORD + 9] !== 32'd26311) begin
        $display("[LENET_TB][CHECK_FAIL] logit[7] got=%0d expected=26311",
                 iRV32I_System.iDMem.mem[RESULT_WORD + 9]);
        check_errors = check_errors + 1;
      end

      if (check_errors != 0) begin
        $display("[LENET_TB][FAIL] golden checks failed count=%0d", check_errors);
        $finish;
      end else begin
        $display("[LENET_TB][PASS] LeNet E2E sample matched");
        $finish;
      end
    end

    if (reset && cycle_count > TIMEOUT_CYCLES) begin
      $display("[LENET_TB][FAIL] Timeout at cycle %0d pc=0x%08h", cycle_count, iRV32I_System.icpu.pc);
      $display("[LENET_TB] inst=0x%08h stall=%b cnn_wait=%b cnn_busy=%b cnn_valid=%b cnn_start=%b cnn_done=%b",
               iRV32I_System.inst,
               iRV32I_System.icpu.i_datapath.stall,
               iRV32I_System.icpu.i_datapath.cnn_wait_stall,
               iRV32I_System.icpu.i_datapath.cnn_busy,
               iRV32I_System.icpu.i_datapath.cnn_result_valid,
               iRV32I_System.icpu.i_datapath.cnn_start_pulse,
               iRV32I_System.icpu.i_datapath.cnn_ap_done);
      $display("[LENET_TB] stalls=%0d flushes=%0d branch_flushes=%0d jump_flushes=%0d",
               iRV32I_System.icpu.i_datapath.dbg_stall_count,
               iRV32I_System.icpu.i_datapath.dbg_flush_count,
               iRV32I_System.icpu.i_datapath.dbg_flush_branch_count,
               iRV32I_System.icpu.i_datapath.dbg_flush_jump_count);
      $display("[LENET_TB] regs ra=%08h sp=%08h s0=%08h s1=%08h s2=%08h s3=%08h a0=%08h a5=%08h",
               iRV32I_System.icpu.i_datapath.i_regfile.mem[1],
               iRV32I_System.icpu.i_datapath.i_regfile.mem[2],
               iRV32I_System.icpu.i_datapath.i_regfile.mem[8],
               iRV32I_System.icpu.i_datapath.i_regfile.mem[9],
               iRV32I_System.icpu.i_datapath.i_regfile.mem[18],
               iRV32I_System.icpu.i_datapath.i_regfile.mem[19],
               iRV32I_System.icpu.i_datapath.i_regfile.mem[10],
               iRV32I_System.icpu.i_datapath.i_regfile.mem[15]);
      $display("[LENET_TB] helper t1=%08h a1=%08h a3=%08h a6=%08h a7=%08h rd=%0d rd_data=%08h RegWrite=%b",
               iRV32I_System.icpu.i_datapath.i_regfile.mem[6],
               iRV32I_System.icpu.i_datapath.i_regfile.mem[11],
               iRV32I_System.icpu.i_datapath.i_regfile.mem[13],
               iRV32I_System.icpu.i_datapath.i_regfile.mem[16],
               iRV32I_System.icpu.i_datapath.i_regfile.mem[17],
               iRV32I_System.icpu.i_datapath.MEMWB_rd,
               iRV32I_System.icpu.i_datapath.rd_data,
               iRV32I_System.icpu.i_datapath.MEMWB_RegWrite);
      $finish;
    end
  end

endmodule
