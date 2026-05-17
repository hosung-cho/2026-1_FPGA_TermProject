`timescale 1ns/1ns

module RV32I_System_tb();

  reg           clk;
  reg           reset;
  integer       cycle_count;
  reg [31:0]    prev_pc;
  integer       halt_stable_count;
  reg [31:0]    prev_pc_rate;
  reg [1023:0]  pc_change_hist;
  integer       pc_change_sum;
  integer       pc_change_samples;
  integer       pc_change_rate_x100;
  integer       stuck_lowrate_streak;
  reg           pc_changed_now;
  reg           pc_hist_oldest;
  reg [31:0]    interval_pc_min;
  reg [31:0]    interval_pc_max;
  reg [31:0]    interval_last_pc;
  integer       interval_sample_count;
  integer       interval_samepc_count;
  integer       interval_samepc_rate_x100;
  integer       loop_pattern_streak;
  reg [63:0]    prev_stall_count;
  reg [63:0]    prev_flush_count;
  reg [63:0]    prev_branch_count;
  reg [63:0]    prev_jump_count;
  reg [63:0]    stall_delta;
  reg [63:0]    flush_delta;
  reg [63:0]    branch_delta;
  reg [63:0]    jump_delta;

  parameter integer RESET_CYCLES   = 8;
  // TFLM startup/data-copy loops can take much longer than simple unit tests.
  // Set to 0 to disable timeout.
  parameter integer TIMEOUT_CYCLES = 500000000;
  parameter integer PROGRESS_CYCLES = 1000000;
  parameter integer CLI_TIME_LOG_MS = 10;
  parameter integer ENABLE_RUNTIME_STATS = 1;
  localparam integer NS_PER_MS = 1000000;
  parameter integer PC_RATE_WINDOW = 1024;
  parameter integer PC_STUCK_RATE_X100 = 500;  // 5.00%
  parameter integer STUCK_WARN_STREAK = 3;
  parameter integer LOOP_SPAN_MAX = 256;
  parameter integer LOOP_JUMP_DELTA_MIN = 100000;
  parameter integer LOOP_WARN_STREAK = 2;
  parameter [31:0] STACK_INIT_SP = 32'h2001_0000;
  parameter integer DUMP_DMEM_AFTER_HALT = 1;
  parameter [31:0] DUMP_BASE_ADDR = 32'h2000_F000;
  parameter integer DUMP_BYTE_COUNT = 128;
  parameter IMEM_HEX = "imem.hex";
  parameter DMEM_HEX = "dmem.hex";

  wire [31:0] imem_addr;
  wire [31:0] imem_rdata;
  wire        imem_en;
  wire [31:0] dmem_addr;
  wire [31:0] dmem_wdata;
  wire [31:0] dmem_rdata;
  wire [3:0]  dmem_we;
  wire        dmem_en;
  wire [13:0] imem_addr_word;
  wire [13:0] dmem_addr_word;

  assign imem_addr_word = imem_addr[15:2];
  assign dmem_addr_word = dmem_addr[15:2];

  // Robust halt signature from pipeline MEM stage:
  // jal x0,0 executes when jal is set, rd==x0, and branch_dest == pc (self-loop).
  wire mem_halt_jal_x0_self;
  assign mem_halt_jal_x0_self = iRV32I_System.icpu.i_datapath.EXMEM_jal &&
                                (iRV32I_System.icpu.i_datapath.EXMEM_rd == 5'd0) &&
                                ((iRV32I_System.icpu.i_datapath.EXMEM_branch_dest + 32'd4) ==
                                  iRV32I_System.icpu.i_datapath.EXMEM_pc_plus4);

  task dump_dmem_window;
    integer word_base;
    integer word_count;
    integer i;
    integer b0;
    integer b1;
    integer b2;
    integer b3;
    reg [31:0] w;
    begin
      word_base = (DUMP_BASE_ADDR - 32'h2000_0000) >> 2;
      word_count = (DUMP_BYTE_COUNT + 3) >> 2;
      if (word_base < 0)
        word_base = 0;
      if (word_base >= 16384)
        word_base = 16383;
      if (word_count < 0)
        word_count = 0;
      if ((word_base + word_count) > 16384)
        word_count = 16384 - word_base;

      $display("[TB][DMEM] dump base=0x%08h bytes=%0d words=%0d", DUMP_BASE_ADDR, DUMP_BYTE_COUNT, word_count);
      for (i = 0; i < word_count; i = i + 1) begin
        w = iDMem.mem[word_base + i];
        b0 = w[7:0];
        b1 = w[15:8];
        b2 = w[23:16];
        b3 = w[31:24];
        if (b0 >= 128) b0 = b0 - 256;
        if (b1 >= 128) b1 = b1 - 256;
        if (b2 >= 128) b2 = b2 - 256;
        if (b3 >= 128) b3 = b3 - 256;
        $display("[TB][DMEM] 0x%08h : 0x%08h | s8={%0d,%0d,%0d,%0d}",
                 DUMP_BASE_ADDR + (i * 4), w, b0, b1, b2, b3);
      end
    end
  endtask

  // instantiate device to be tested
    RV32I_System #(
      .CPU_RESET_PC (32'h0000_0000)
    ) iRV32I_System (
        .CLOCK_50  (clk),
        .reset     (reset),
        .imem_addr (imem_addr),
        .imem_rdata(imem_rdata),
        .imem_en   (imem_en),
        .dmem_addr (dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_rdata(dmem_rdata),
        .dmem_we   (dmem_we),
        .dmem_en   (dmem_en)
  );

  inst_memory iIMem (
      .clock      (clk),
      .enable     (imem_en),
      .address    (imem_addr_word),
      .instruction(imem_rdata)
  );

  data_memory iDMem (
      .clock     (clk),
      .enable    (dmem_en),
      .wren      (|dmem_we),
      .address   (dmem_addr_word),
      .write_data(dmem_wdata),
      .byteena   (dmem_we),
      .read_data (dmem_rdata)
  );

  // Clock
  initial begin
    clk = 1'b0;
    forever #10 clk = ~clk;
  end

  // Keep reset asserted, load memory images, then release reset.
  initial begin
    reset = 1'b0;
    cycle_count = 0;
    prev_pc = 32'b0;
    halt_stable_count = 0;
    prev_pc_rate = 32'b0;
    pc_change_hist = 1024'b0;
    pc_change_sum = 0;
    pc_change_samples = 0;
    pc_change_rate_x100 = 0;
    stuck_lowrate_streak = 0;
    pc_changed_now = 1'b0;
    pc_hist_oldest = 1'b0;
    interval_pc_min = 32'hffff_ffff;
    interval_pc_max = 32'h0000_0000;
    interval_last_pc = 32'b0;
    interval_sample_count = 0;
    interval_samepc_count = 0;
    interval_samepc_rate_x100 = 0;
    loop_pattern_streak = 0;
    prev_stall_count = 64'b0;
    prev_flush_count = 64'b0;
    prev_branch_count = 64'b0;
    prev_jump_count = 64'b0;
    stall_delta = 64'b0;
    flush_delta = 64'b0;
    branch_delta = 64'b0;
    jump_delta = 64'b0;

    repeat (RESET_CYCLES) @(posedge clk);

    $display("[TB] Loading %0s into IMEM", IMEM_HEX);
    $readmemh(IMEM_HEX, iIMem.mem);
    $display("[TB] Loading %0s into DMEM", DMEM_HEX);
    $readmemh(DMEM_HEX, iDMem.mem);
    // Bootcode-less binary support: initialize x2(sp) before entering main.
    iRV32I_System.icpu.i_datapath.i_regfile.mem[2] = STACK_INIT_SP;
    $display("[TB] Initialized x2(sp) to 0x%08h", STACK_INIT_SP);

    @(negedge clk);
    reset = 1'b1;
    $display("[TB] Reset released at %t", $time);
  end

  // Cycle counter after reset release.
  always @(posedge clk) begin
    if (reset)
      cycle_count <= cycle_count + 1;
  end

  // Periodic wall-clock style heartbeat for CLI visibility.
  initial begin
    if (CLI_TIME_LOG_MS > 0) begin
      forever begin
        #(CLI_TIME_LOG_MS * NS_PER_MS);
        if (reset)
          $display("[TB][TIME] sim_time=%0t (%0d ms)", $time, $time / NS_PER_MS);
      end
    end
  end

  // Progress log for long-running TFLM simulations.
  always @(posedge clk) begin
    if (ENABLE_RUNTIME_STATS && reset && PROGRESS_CYCLES > 0 && cycle_count > 0 && (cycle_count % PROGRESS_CYCLES) == 0) begin
      stall_delta  = iRV32I_System.icpu.i_datapath.dbg_stall_count - prev_stall_count;
      flush_delta  = iRV32I_System.icpu.i_datapath.dbg_flush_count - prev_flush_count;
      branch_delta = iRV32I_System.icpu.i_datapath.dbg_flush_branch_count - prev_branch_count;
      jump_delta   = iRV32I_System.icpu.i_datapath.dbg_flush_jump_count - prev_jump_count;
      if (interval_sample_count > 0)
        interval_samepc_rate_x100 = (interval_samepc_count * 10000) / interval_sample_count;
      else
        interval_samepc_rate_x100 = 0;

      $display("[TB] progress: cycles=%0d PC=0x%08h INST=0x%08h", cycle_count,
               iRV32I_System.icpu.pc, iRV32I_System.icpu.inst);
      if (pc_change_samples >= PC_RATE_WINDOW) begin
        $display("[TB] stats: pc_change_rate=%0d.%02d%% over last %0d cycles, stall=%0d, flush=%0d (branch=%0d, jump=%0d)",
                 pc_change_rate_x100 / 100, pc_change_rate_x100 % 100, PC_RATE_WINDOW,
                 iRV32I_System.icpu.i_datapath.dbg_stall_count,
                 iRV32I_System.icpu.i_datapath.dbg_flush_count,
                 iRV32I_System.icpu.i_datapath.dbg_flush_branch_count,
                 iRV32I_System.icpu.i_datapath.dbg_flush_jump_count);
      end
      if (interval_sample_count > 0) begin
        $display("[TB] window: pc_min=0x%08h pc_max=0x%08h span=%0d same_pc=%0d.%02d%%, delta(stall=%0d flush=%0d branch=%0d jump=%0d)",
                 interval_pc_min, interval_pc_max,
                 (interval_pc_max - interval_pc_min),
                 interval_samepc_rate_x100 / 100, interval_samepc_rate_x100 % 100,
                 stall_delta, flush_delta, branch_delta, jump_delta);
      end
      if (stuck_lowrate_streak >= STUCK_WARN_STREAK) begin
        $display("[TB][WARN] Low PC-change rate persisted (%0d.%02d%%). Possible stuck/slow loop. PC=0x%08h INST=0x%08h",
                 pc_change_rate_x100 / 100, pc_change_rate_x100 % 100,
                 iRV32I_System.icpu.pc, iRV32I_System.icpu.inst);
      end

      if ((interval_sample_count > 0) &&
          ((interval_pc_max - interval_pc_min) <= LOOP_SPAN_MAX) &&
          (stall_delta == 0) &&
          (branch_delta == 0) &&
          (jump_delta >= LOOP_JUMP_DELTA_MIN)) begin
        loop_pattern_streak <= loop_pattern_streak + 1;
      end
      else begin
        loop_pattern_streak <= 0;
      end

      if (loop_pattern_streak >= LOOP_WARN_STREAK) begin
        $display("[TB][WARN] Jump-dominant narrow loop suspected: span<=%0d, delta(stall/branch)=0, jump_delta=%0d, PC=0x%08h INST=0x%08h",
                 LOOP_SPAN_MAX, jump_delta,
                 iRV32I_System.icpu.pc, iRV32I_System.icpu.inst);
      end

      prev_stall_count <= iRV32I_System.icpu.i_datapath.dbg_stall_count;
      prev_flush_count <= iRV32I_System.icpu.i_datapath.dbg_flush_count;
      prev_branch_count <= iRV32I_System.icpu.i_datapath.dbg_flush_branch_count;
      prev_jump_count <= iRV32I_System.icpu.i_datapath.dbg_flush_jump_count;
      interval_pc_min <= iRV32I_System.icpu.pc;
      interval_pc_max <= iRV32I_System.icpu.pc;
      interval_last_pc <= iRV32I_System.icpu.pc;
      interval_sample_count <= 1;
      interval_samepc_count <= 0;
    end
  end

  // Halt/timeout monitor.
  always @(posedge clk) begin
    if (reset) begin
      if (ENABLE_RUNTIME_STATS) begin
        if (interval_sample_count == 0) begin
          interval_pc_min <= iRV32I_System.icpu.pc;
          interval_pc_max <= iRV32I_System.icpu.pc;
          interval_last_pc <= iRV32I_System.icpu.pc;
          interval_sample_count <= 1;
        end
        else begin
          if (iRV32I_System.icpu.pc < interval_pc_min)
            interval_pc_min <= iRV32I_System.icpu.pc;
          if (iRV32I_System.icpu.pc > interval_pc_max)
            interval_pc_max <= iRV32I_System.icpu.pc;
          if (iRV32I_System.icpu.pc == interval_last_pc)
            interval_samepc_count <= interval_samepc_count + 1;
          interval_last_pc <= iRV32I_System.icpu.pc;
          interval_sample_count <= interval_sample_count + 1;
        end

        pc_changed_now = (iRV32I_System.icpu.pc != prev_pc_rate);
        if (pc_change_samples < PC_RATE_WINDOW) begin
          pc_change_hist[pc_change_samples] <= pc_changed_now;
          if (pc_changed_now)
            pc_change_sum <= pc_change_sum + 1;
          pc_change_samples <= pc_change_samples + 1;
        end
        else begin
          pc_hist_oldest = pc_change_hist[PC_RATE_WINDOW-1];
          pc_change_hist <= {pc_change_hist[PC_RATE_WINDOW-2:0], pc_changed_now};
          pc_change_sum <= pc_change_sum + (pc_changed_now ? 1 : 0) - (pc_hist_oldest ? 1 : 0);
        end

        if (pc_change_samples >= PC_RATE_WINDOW) begin
          pc_change_rate_x100 <= (pc_change_sum * 10000) / PC_RATE_WINDOW;
          if (pc_change_rate_x100 <= PC_STUCK_RATE_X100)
            stuck_lowrate_streak <= stuck_lowrate_streak + 1;
          else
            stuck_lowrate_streak <= 0;
        end

        prev_pc_rate <= iRV32I_System.icpu.pc;
      end
    end

    // In a pipeline, IF-stage instruction bus can briefly show wrong-path instructions.
    // Prefer MEM-stage execution signature, and keep legacy IF-stage stable check as fallback.
    if (reset && (mem_halt_jal_x0_self ||
                  (iRV32I_System.icpu.inst == 32'h0000006f && iRV32I_System.icpu.pc == prev_pc)))
      halt_stable_count <= halt_stable_count + 1;
    else if (!reset)
      halt_stable_count <= 0;

    prev_pc <= iRV32I_System.icpu.pc;

    if (reset && halt_stable_count >= 2) begin
      $display("\n==============================================");
      $display(" TFLM program finished (stable jal x0,0 detected)");
      $display(" Time: %t", $time);
      $display(" Cycles: %0d", cycle_count);
      $display(" PC=0x%08h INST=0x%08h", iRV32I_System.icpu.pc, iRV32I_System.icpu.inst);
      if (ENABLE_RUNTIME_STATS && pc_change_samples >= PC_RATE_WINDOW)
        $display(" PC change rate(last %0d): %0d.%02d%%", PC_RATE_WINDOW,
                 pc_change_rate_x100 / 100, pc_change_rate_x100 % 100);
      $display(" stall=%0d, flush=%0d (branch=%0d, jump=%0d)",
               iRV32I_System.icpu.i_datapath.dbg_stall_count,
               iRV32I_System.icpu.i_datapath.dbg_flush_count,
               iRV32I_System.icpu.i_datapath.dbg_flush_branch_count,
               iRV32I_System.icpu.i_datapath.dbg_flush_jump_count);
      $display(" x10 (a0): %0d (0x%08h)", iRV32I_System.icpu.i_datapath.i_regfile.x10,
               iRV32I_System.icpu.i_datapath.i_regfile.x10);
      $display(" dmem[0]=0x%08h dmem[1]=0x%08h dmem[2]=0x%08h dmem[3]=0x%08h",
               iDMem.mem[0], iDMem.mem[1],
               iDMem.mem[2], iDMem.mem[3]);
      if (DUMP_DMEM_AFTER_HALT)
        dump_dmem_window();
      $display("==============================================\n");
      $finish;
    end

    if (reset && TIMEOUT_CYCLES > 0 && cycle_count >= TIMEOUT_CYCLES) begin
      $display("\n[TB][ERROR] Timeout after %0d cycles", TIMEOUT_CYCLES);
      $display(" PC=0x%08h INST=0x%08h", iRV32I_System.icpu.pc, iRV32I_System.icpu.inst);
      if (ENABLE_RUNTIME_STATS && pc_change_samples >= PC_RATE_WINDOW)
        $display(" PC change rate(last %0d): %0d.%02d%%", PC_RATE_WINDOW,
                 pc_change_rate_x100 / 100, pc_change_rate_x100 % 100);
      $display(" stall=%0d, flush=%0d (branch=%0d, jump=%0d)",
               iRV32I_System.icpu.i_datapath.dbg_stall_count,
               iRV32I_System.icpu.i_datapath.dbg_flush_count,
               iRV32I_System.icpu.i_datapath.dbg_flush_branch_count,
               iRV32I_System.icpu.i_datapath.dbg_flush_jump_count);
      if (DUMP_DMEM_AFTER_HALT)
        dump_dmem_window();
      $finish;
    end
  end

endmodule
