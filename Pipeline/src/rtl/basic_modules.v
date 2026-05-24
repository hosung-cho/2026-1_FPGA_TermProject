`timescale 1ns/1ns
// ======================================================================
// Register File (레지스터 파일)
// RISC-V의 32개 범용 레지스터(x0~x31)를 보관하는 메모리 블록입니다.
// x0는 항상 0으로 고정되어 있으며, 클럭 상승 에지(posedge)에 맞춰 데이터를 씁니다.
// ======================================================================
module regfile(input             clk, 
               input             we, 
               input      [4:0]  rs1, rs2,
               input      [4:0]  rd, 
               input      [31:0] rd_data, 
               output reg [31:0] rs1_data, rs2_data);
	parameter DEPTH = 32;
	reg [31:0] mem [0:DEPTH-1];
	integer i;

	// Backward-compatible debug aliases used by existing testbenches.
	wire [31:0] x1  = mem[1];
	wire [31:0] x2  = mem[2];
	wire [31:0] x3  = mem[3];
	wire [31:0] x4  = mem[4];
	wire [31:0] x5  = mem[5];
	wire [31:0] x6  = mem[6];
	wire [31:0] x7  = mem[7];
	wire [31:0] x8  = mem[8];
	wire [31:0] x9  = mem[9];
	wire [31:0] x10 = mem[10];
	wire [31:0] x11 = mem[11];
	wire [31:0] x12 = mem[12];
	wire [31:0] x13 = mem[13];
	wire [31:0] x14 = mem[14];
	wire [31:0] x15 = mem[15];
	wire [31:0] x16 = mem[16];
	wire [31:0] x17 = mem[17];
	wire [31:0] x18 = mem[18];
	wire [31:0] x19 = mem[19];
	wire [31:0] x20 = mem[20];
	wire [31:0] x21 = mem[21];
	wire [31:0] x22 = mem[22];
	wire [31:0] x23 = mem[23];
	wire [31:0] x24 = mem[24];
	wire [31:0] x25 = mem[25];
	wire [31:0] x26 = mem[26];
	wire [31:0] x27 = mem[27];
	wire [31:0] x28 = mem[28];
	wire [31:0] x29 = mem[29];
	wire [31:0] x30 = mem[30];
	wire [31:0] x31 = mem[31];

	initial begin
		for (i = 0; i < DEPTH; i = i + 1)
			mem[i] = 32'b0;
	end

	always @(posedge clk)
	begin
		if (we && (rd != 5'd0))
			mem[rd] <= rd_data;
	end

	always @(*)
	begin
		// Internal forwarding: if writing and reading same register, forward the write data
		if (we && (rs2 != 5'd0) && (rs2 == rd))
			rs2_data = rd_data;
		else
			rs2_data = (rs2 == 5'd0) ? 32'b0 : mem[rs2];
	end

	always @(*)
	begin
		// Internal forwarding: if writing and reading same register, forward the write data
		if (we && (rs1 != 5'd0) && (rs1 == rd))
			rs1_data = rd_data;
		else
			rs1_data = (rs1 == 5'd0) ? 32'b0 : mem[rs1];
	end

endmodule

// ======================================================================
// ALU (Arithmetic Logic Unit, 산술 논리 연산 장치)
// 덧셈, 뺄셈, AND, OR, XOR, 시프트(Shift) 등 실제 계산을 수행하는 모듈입니다.
// 제어부에서 받은 5비트의 alucont 신호에 따라 연산 종류를 결정합니다.
// ======================================================================
module alu(input      [31:0] a, b, 
           input      [4:0]  alucont, 
           output reg [31:0] result,
           output            N,
           output            Z,
           output            C,
           output            V);

  wire [31:0] b2, sum ;
  wire        slt, sltu;

  assign b2 = alucont[4] ? ~b:b; 

  adder_32bit iadder32 (.a   (a),
			     				.b   (b2),
								.cin (alucont[4]),
								.sum (sum),
								.N   (N),
								.Z   (Z),
								.C   (C),
								.V   (V));

  // signed less than condition
  assign slt  = N ^ V ; 

  // unsigned lower (C clear) condition
  assign sltu = ~C ;   

  always@(*)
    case(alucont[3:0])
      4'b0000: result = sum;    // A + B
      4'b0001: result = a & b;
      4'b0010: result = a | b;
      4'b0011: result = a ^ b;
      4'b0100: result = a << b[4:0];  // shift left logical (sll)
      4'b0101: result = a >> b[4:0];  // shift right logical(srl)
      4'b0110: result = $signed(a) >>> b[4:0]; // shift right arithmetic(sra)
      4'b0111: result = {31'b0,sltu}; // sltu, sltiu
      4'b1000: result = {31'b0,slt};  // slt, slti
      default: result = 32'b0;
    endcase

endmodule


// ======================================================================
// 32-bit Ripple-Carry Adder (32비트 덧셈기)
// 1비트 전가산기(Full Adder) 32개를 직렬로 연결하여 만든 덧셈기입니다. (ALU 내부에서 사용)
// ======================================================================
module adder_32bit (input  [31:0] a, b, 
                    input         cin,
                    output [31:0] sum,
                    output        N,Z,C,V);

	wire [32:0]  full_sum;

	assign N = sum[31];
	assign Z = (sum == 32'b0);
	assign C = full_sum[32];
	assign V = (~(a[31] ^ b[31])) & (a[31] ^ sum[31]);

	assign full_sum = {1'b0, a} + {1'b0, b} + cin;
	assign sum = full_sum[31:0];

endmodule


module adder_1bit (input a, b, cin,
                   output sum, cout);

  assign sum  = a ^ b ^ cin;
  assign cout = (a & b) | (a & cin) | (b & cin);

endmodule



module mux2 #(parameter WIDTH = 8)
             (input  [WIDTH-1:0] d0, d1, 
              input              s, 
              output [WIDTH-1:0] y);

  assign y = s ? d1 : d0; 

endmodule
