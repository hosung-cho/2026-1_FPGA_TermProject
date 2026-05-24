`timescale 1ns/1ns

module RV32I_Board_Top #(
  parameter [31:0] CPU_RESET_PC = 32'h0000_0000,
  parameter [31:0] EXPECTED_DIGIT = 32'd7
)(
  input        CLOCK_50,
  input        reset,
  output [7:0] LED
);

  localparam [31:0] LENET_RESULT_ADDR = 32'h0001_0F00;
  localparam [31:0] LENET_DONE_ADDR   = 32'h0001_0F40;

  wire [31:0] debug_pc;
  wire [31:0] debug_inst;
  wire [31:0] debug_data_addr;
  wire [31:0] debug_read_data;
  wire [31:0] debug_write_data;
  wire        debug_data_we;

  reg [3:0]  predicted_digit;
  reg        done_seen;
  reg [24:0] heartbeat;

  RV32I_System #(
    .CPU_RESET_PC    (CPU_RESET_PC),
    .DMEM_INIT_FILE  ("lenet_digit7_dmem.mem")
  ) u_system (
    .CLOCK_50         (CLOCK_50),
    .reset            (reset),
    .debug_pc         (debug_pc),
    .debug_inst       (debug_inst),
    .debug_data_addr  (debug_data_addr),
    .debug_read_data  (debug_read_data),
    .debug_write_data (debug_write_data),
    .debug_data_we    (debug_data_we)
  );

  always @(posedge CLOCK_50) begin
    if (!reset) begin
      predicted_digit <= 4'd0;
      done_seen       <= 1'b0;
      heartbeat       <= 25'd0;
    end else begin
      heartbeat <= heartbeat + 25'd1;

      if (debug_data_we && (debug_data_addr == LENET_RESULT_ADDR))
        predicted_digit <= debug_write_data[3:0];

      if (debug_data_we && (debug_data_addr == LENET_DONE_ADDR) && (debug_write_data == 32'd1))
        done_seen <= 1'b1;
    end
  end

  assign LED[0]   = done_seen;
  assign LED[4:1] = predicted_digit;
  assign LED[5]   = done_seen && (predicted_digit == EXPECTED_DIGIT[3:0]);
  assign LED[6]   = done_seen && (predicted_digit != EXPECTED_DIGIT[3:0]);
  assign LED[7]   = heartbeat[24];

endmodule
