`timescale 1ns/1ns
// 최상위 모듈 (Top Module): 제어부(Controller)와 데이터패스(Datapath)를 연결하여 5단계 파이프라인 CPU를 완성합니다.
module rv32i_cpu #(
            parameter [31:0] RESET_PC = 32'h1000_0000,
            parameter integer ENABLE_CNN = 1
) (
		      input         clk, reset,
            output [31:0] pc,		  		// program counter for instruction fetch
            input  [31:0] inst, 			// incoming instruction
            output        MemWrite, 	// 'memory write' control signal
            output [31:0] MemAddr,  	// memory address 
            output [31:0] MemRAddr,  	// memory read address
            output [31:0] MemWData, 	// data to write to memory
            output [3:0]  ByteEnable,  // byte enable
            input  [31:0] MemRData); 	// data read from memory

  wire        auipc, lui;
  wire        ALUSrc, RegWrite;
  wire        CNNInstr;
  wire [4:0]  ALUcontrol;
  wire        MemtoReg;
  wire        MemWrite_ctrl;  // Control signal from controller
  wire        branch, jal, jalr;
  wire [31:0] inst_decode;  // Instruction for decode (IFID_inst)

  // Instantiate Controller
  controller i_controller(
      .opcode		(inst_decode[6:0]), 
		.funct7		(inst_decode[31:25]), 
		.funct3		(inst_decode[14:12]), 
		.auipc		(auipc),
		.lui			(lui),
		.MemtoReg	(MemtoReg),
		.MemWrite	(MemWrite_ctrl),
		.branch		(branch),
		.ALUSrc		(ALUSrc),
		.RegWrite	(RegWrite),
		.jal			(jal),
		.jalr			(jalr),
		.CNNInstr	(CNNInstr),
		.ALUcontrol	(ALUcontrol));

  // Instantiate Datapath
  datapath #(
    .RESET_PC(RESET_PC),
    .ENABLE_CNN(ENABLE_CNN)
  ) i_datapath(
		.clk				(clk),
		.reset			(reset),
		.auipc			(auipc),
		.lui				(lui),
		.MemtoReg		(MemtoReg),
		.MemWrite		(MemWrite_ctrl),
		.branch			(branch),
		.ALUSrc			(ALUSrc),
		.RegWrite		(RegWrite),
		.jal				(jal),
		.jalr				(jalr),
		.CNNInstr		(CNNInstr),
		.ALUcontrol		(ALUcontrol),
		.pc				(pc),
		.inst				(inst),
		.inst_decode	(inst_decode),
		.MemAddr			(MemAddr),
		.MemRAddr		(MemRAddr),
		.MemWData		(MemWData),
		.MemWrite_out	(MemWrite),
		.ByteEnable		(ByteEnable),
		.MemRData		(MemRData));

endmodule


//
// 제어부 (Controller): 명령어의 Opcode, funct3, funct7을 분석하여 
// 데이터패스 내의 멀티플렉서(Mux)와 ALU를 제어하는 신호들을 생성합니다.
//
module controller(input  [6:0] opcode,
                  input  [6:0] funct7,
                  input  [2:0] funct3,
                  output       auipc,
                  output       lui,
                  output       ALUSrc,
                  output [4:0] ALUcontrol,
                  output       branch,
                  output       jal,
                  output       jalr,
                  output       CNNInstr,
                  output       MemtoReg,
                  output       MemWrite,
                  output       RegWrite);

	maindec i_maindec(
		.opcode		(opcode),
		.auipc		(auipc),
		.lui			(lui),
		.MemtoReg	(MemtoReg),
		.MemWrite	(MemWrite),
		.branch		(branch),
		.ALUSrc		(ALUSrc),
		.RegWrite	(RegWrite),
		.jal			(jal),
		.jalr			(jalr),
		.CNNInstr	(CNNInstr));

	aludec i_aludec( 
		.opcode     (opcode),
		.funct7     (funct7),
		.funct3     (funct3),
		.ALUcontrol (ALUcontrol));


endmodule


//
// RV32I Opcode map = Inst[6:0]
//
`define OP_R			7'b0110011
`define OP_I_ARITH	7'b0010011
`define OP_I_LOAD  	7'b0000011
`define OP_I_JALR  	7'b1100111
`define OP_S			7'b0100011
`define OP_B			7'b1100011
`define OP_U_LUI		7'b0110111
`define OP_U_AUIPC	7'b0010111
`define OP_J_JAL		7'b1101111
`define OP_CNN      7'b0001011

//
// 메인 디코더 (Main Decoder): Opcode(7비트)만 분석하여 
// 레지스터 쓰기(RegWrite), 메모리 읽기/쓰기, 분기(branch) 등의 굵직한 제어 신호를 만듭니다.
//
module maindec(input  [6:0] opcode,
               output       auipc,
               output       lui,
               output       RegWrite,
               output       ALUSrc,
               output       MemtoReg, MemWrite,
               output       branch, 
               output       jal,
               output       jalr,
               output       CNNInstr);

  reg [9:0] controls;

  assign {auipc, lui, RegWrite, ALUSrc, 
			 MemtoReg, MemWrite, branch, jal, 
			 jalr, CNNInstr} = controls;

  always @(*)
  begin
    case(opcode)
      `OP_R: 			controls <= 10'b0010_0000_00; // R-type
      `OP_I_ARITH: 	controls <= 10'b0011_0000_00; // I-type Arithmetic
      `OP_I_LOAD: 	controls <= 10'b0011_1000_00; // I-type Load
      `OP_I_JALR: 	controls <= 10'b0011_0000_10; // I-type Jalr
      `OP_S: 			controls <= 10'b0001_0100_00; // S-type Store
      `OP_B: 			controls <= 10'b0000_0010_00; // B-type Branch
      `OP_U_LUI: 		controls <= 10'b0111_0000_00; // LUI
      `OP_U_AUIPC:	controls <= 10'b1010_0000_00; // AUIPC
      `OP_J_JAL: 		controls <= 10'b0011_0001_00; // JAL
      `OP_CNN:      controls <= 10'b0010_0000_01; // custom-0 CNN ALU
      default:    	controls <= 10'b0000_0000_00; // ???
    endcase
  end

endmodule

//
// ALU 디코더 (ALU Decoder): Opcode와 funct3, funct7을 종합적으로 분석하여
// ALU가 정확히 어떤 연산(덧셈, 뺄셈, 논리 시프트 등)을 할지 5비트 제어 신호로 만들어줍니다.
//
module aludec(input      [6:0] opcode,
              input      [6:0] funct7,
              input      [2:0] funct3,
              output reg [4:0] ALUcontrol);

  always @(*)

    case(opcode)

      `OP_R:   		// R-type
		begin
			case({funct7,funct3})
			 10'b0000000_000: ALUcontrol <= 5'b00000; // addition (add)
			 10'b0100000_000: ALUcontrol <= 5'b10000; // subtraction (sub)
			 10'b0000000_001: ALUcontrol <= 5'b00100; // shift-left logical (sll)
       	10'b0000000_010: ALUcontrol <= 5'b11000; // set less than (slt)
       	10'b0000000_011: ALUcontrol <= 5'b10111; // set less than unsigned (sltu)
			 10'b0000000_100: ALUcontrol <= 5'b00011; // xor (xor)
			 10'b0000000_101: ALUcontrol <= 5'b00101; // shift-right logical (srl)
			 10'b0100000_101: ALUcontrol <= 5'b00110; // shift-right arithmetic (sra)
			 10'b0000000_110: ALUcontrol <= 5'b00010; // or (or)
			 10'b0000000_111: ALUcontrol <= 5'b00001; // and (and)
          default:         ALUcontrol <= 5'bxxxxx; // ???
        endcase
		end

      `OP_I_ARITH:   // I-type Arithmetic
		begin
			casez({funct7,funct3})
			 10'b???????_000:  ALUcontrol <= 5'b00000; // addi (=add)
			 10'b0000000_001:  ALUcontrol <= 5'b00100; // slli (=sll)
       	10'b???????_010:  ALUcontrol <= 5'b11000; // slti (=slt)
       	10'b???????_011:  ALUcontrol <= 5'b10111; // sltiu (=sltu)
			 10'b???????_100:  ALUcontrol <= 5'b00011; // xori (=xor)
			 10'b0000000_101:  ALUcontrol <= 5'b00101; // srli (=srl)
			 10'b0100000_101:  ALUcontrol <= 5'b00110; // srai (=sra)
			 10'b???????_110:  ALUcontrol <= 5'b00010; // or (ori)
			 10'b???????_111:  ALUcontrol <= 5'b00001; // and (andi)
          default:          ALUcontrol <= 5'bxxxxx; // ???
        endcase
		end

      `OP_I_LOAD, 	// I-type Load (LW, LH, LB...)
      `OP_I_JALR, 	// I-type (JALR)
      `OP_S,   		// S-type Store (SW, SH, SB)
      `OP_U_LUI, 		// U-type (LUI)
      `OP_U_AUIPC: 	// U-type (AUIPC)
      	ALUcontrol <= 5'b00000;  // addition 

      `OP_B:   		// B-type Branch (BEQ, BNE, ...)
      	ALUcontrol <= 5'b10000;  // subtraction 

      default: 
      	ALUcontrol <= 5'b00000;  // 

    endcase
    
endmodule


//
// 데이터패스 (Datapath): 실제 데이터와 명령어 주소가 흘러가는 길입니다.
// IF(명령어 인출) -> ID(해독) -> EX(실행) -> MEM(메모리) -> WB(레지스터 쓰기) 의 5단계를 거칩니다.
//
module datapath #(
                parameter [31:0] RESET_PC = 32'h1000_0000,
                parameter integer ENABLE_CNN = 1
) (
                input         clk, reset,
                input  [31:0] inst,
                output [31:0] inst_decode,
                input         auipc,
                input         lui,
                input         RegWrite,
                input         MemtoReg,
                input         MemWrite,
                input         ALUSrc, 
                input  [4:0]  ALUcontrol,
                input         branch,
                input         jal,
                input         jalr,
                input         CNNInstr,

                output reg [31:0] pc,
                output     [31:0] MemAddr,
                output     [31:0] MemRAddr,
                output     [31:0] MemWData,
                output        MemWrite_out,
                output reg [3:0]  ByteEnable,
                input      [31:0] MemRData);

  // ========================================
  // Pipeline Registers (파이프라인 레지스터 선언부)
  // 클럭마다 각 단계(Stage)의 작업 결과를 다음 단계로 넘겨주는 창고(플립플롭) 역할을 합니다.
  // ========================================
  
  // IF/ID Pipeline Register
  reg [31:0] IFID_pc;
  reg [31:0] IFID_inst;
  
  // ID/EX Pipeline Register
  reg [31:0] IDEX_pc;
  reg [31:0] IDEX_rs1_data;
  reg [31:0] IDEX_rs2_data;
  reg [31:0] IDEX_se_imm_itype;
  reg [31:0] IDEX_se_imm_stype;
  reg [31:0] IDEX_se_br_imm;
  reg [31:0] IDEX_se_jal_imm;
  reg [31:0] IDEX_auipc_lui_imm;
  reg [4:0]  IDEX_rs1;
  reg [4:0]  IDEX_rs2;
  reg [4:0]  IDEX_rd;
  reg [2:0]  IDEX_funct3;
  reg [6:0]  IDEX_funct7;
  reg [6:0]  IDEX_opcode;
  // Control signals
  reg        IDEX_auipc;
  reg        IDEX_lui;
  reg        IDEX_RegWrite;
  reg        IDEX_MemtoReg;
  reg        IDEX_MemWrite;
  reg        IDEX_ALUSrc;
  reg [4:0]  IDEX_ALUcontrol;
  reg        IDEX_branch;
  reg        IDEX_jal;
  reg        IDEX_jalr;
  reg        IDEX_CNNInstr;
  
  // EX/MEM Pipeline Register
  reg [31:0] EXMEM_pc_plus4;
  reg [31:0] EXMEM_aluout;
  reg [31:0] EXMEM_rs2_data;
  reg [31:0] EXMEM_branch_dest;
  reg [4:0]  EXMEM_rd;
  reg [2:0]  EXMEM_funct3;
  reg        EXMEM_Zflag;
  reg        EXMEM_Nflag;
  reg        EXMEM_Cflag;
  reg        EXMEM_Vflag;
  // Control signals
  reg        EXMEM_RegWrite;
  reg        EXMEM_MemtoReg;
  reg        EXMEM_MemWrite;
  reg        EXMEM_branch;
  reg        EXMEM_jal;
  reg        EXMEM_jalr;
  reg        EXMEM_CNNInstr;
  
  // MEM/WB Pipeline Register
  reg [31:0] MEMWB_aluout;
  reg [31:0] MEMWB_MemRData2RF;
  reg [31:0] MEMWB_pc_plus4;
  reg [4:0]  MEMWB_rd;
  // Control signals
  reg        MEMWB_RegWrite;
  reg        MEMWB_MemtoReg;
  reg        MEMWB_jal;
  reg        MEMWB_jalr;
  reg        MEMWB_CNNInstr;
  
  // Hazard Detection
  wire       stall;
  wire       flush;
  wire [1:0] forwardA;
  wire [1:0] forwardB;
  
  // Branch/Jump taken signal
  wire       PCSrc;

  // ========================================
  // Stage-specific signals
  // ========================================
  
  // IF stage
  wire [31:0] pc_plus4;
  wire [31:0] next_pc;
  
  // ID stage
  wire [4:0]  rs1, rs2, rd;
  wire [2:0]  funct3;
  wire [31:0] rs1_data, rs2_data;
  wire [20:1] jal_imm;
  wire [31:0] se_jal_imm;
  wire [12:1] br_imm;
  wire [31:0] se_br_imm;
  wire [31:0] se_imm_itype;
  wire [31:0] se_imm_stype;
  wire [31:0] auipc_lui_imm;
  
  // EX stage
  reg  [31:0] alusrc1;
  reg  [31:0] alusrc2;
  reg  [31:0] forward_rs1_data;
  reg  [31:0] forward_rs2_data;
  wire [31:0] branch_dest;
  wire [31:0] aluout;  // ALU output from EX stage
  wire [31:0] mem_addr_ex;
  wire        Nflag, Zflag, Cflag, Vflag;
  wire        cnn_ap_done;
  wire        cnn_ap_idle;
  wire        cnn_ap_ready;
  wire [31:0] cnn_rd_data;
  wire [3:0]  cnn_op;
  reg         cnn_start_pulse;
  reg         cnn_busy;
  reg         cnn_result_valid;
  reg  [31:0] cnn_result_reg;
  reg  [31:0] cnn_rs1_reg;
  reg  [31:0] cnn_rs2_reg;
  reg  [3:0]  cnn_op_reg;
  wire        cnn_ex_active;
  wire        cnn_wait_stall;
  wire        load_use_stall;
  
  // MEM stage
  wire        f3beq, f3bne, f3blt, f3bge, f3bltu, f3bgeu;
  wire        beq_taken;
  wire        bne_taken;
  wire        blt_taken;
  wire        bge_taken;
  wire        bltu_taken;
  wire        bgeu_taken;
  wire        btaken;
  wire [31:0] jal_dest;
  wire [31:0] jalr_dest;
  
  // WB stage
  reg  [31:0] rd_data;
  reg  [31:0] MemRData2RF;

  // Temporary profiling counters (visible via hierarchical TB access)
  reg [63:0] dbg_stall_count;
  reg [63:0] dbg_flush_count;
  reg [63:0] dbg_flush_branch_count;
  reg [63:0] dbg_flush_jump_count;

  // Output IFID_inst for controller
  assign inst_decode = IFID_inst;

  // Decode stage assignments
  assign rs1 = IFID_inst[19:15];
  assign rs2 = IFID_inst[24:20];
  assign rd  = IFID_inst[11:7];
  assign funct3  = IFID_inst[14:12];

  //
  // PC (Program Counter) logic 
  //
  // IF stage: PC increment
  assign pc_plus4 = pc + 4;
  
  // Next PC selection (priority: JAL > JALR > Branch > PC+4)
  assign next_pc = (EXMEM_jal)  ? jal_dest :
                   (EXMEM_jalr) ? jalr_dest :
                   (btaken)     ? EXMEM_branch_dest :
                   pc_plus4;

  always @(posedge clk)
  begin
     if (reset)
       pc <= RESET_PC;
     else if (~stall)
       pc <= next_pc;
  end

  // ========================================
  // IF/ID Pipeline Register Update (명령어 인출 -> 해독 단계로 데이터 넘기기)
  // ========================================
  
  always @(posedge clk)
  begin
    if (reset || flush) begin
      IFID_pc <= 32'b0;
      IFID_inst <= 32'h00000013;  // NOP
    end
    else if (~stall) begin
      IFID_pc <= pc;
      IFID_inst <= inst;
    end
    // else: stall이면 현재 값 유지
  end

  // JAL immediate (ID stage)
  assign jal_imm[20:1] = {IFID_inst[31],IFID_inst[19:12],IFID_inst[20],IFID_inst[30:21]};
  assign se_jal_imm[31:0] = {{11{jal_imm[20]}},jal_imm[20:1],1'b0};

  // Branch immediate (ID stage)
  assign br_imm[12:1] = {IFID_inst[31],IFID_inst[7],IFID_inst[30:25],IFID_inst[11:8]};
  assign se_br_imm[31:0] = {{19{br_imm[12]}},br_imm[12:1],1'b0};
  
  // I-type immediate
  assign se_imm_itype[31:0] = {{20{IFID_inst[31]}},IFID_inst[31:20]};
  // S-type immediate
  assign se_imm_stype[31:0] = {{20{IFID_inst[31]}},IFID_inst[31:25],IFID_inst[11:7]};
  // U-type immediate
  assign auipc_lui_imm[31:0] = {IFID_inst[31:12],12'b0};



  // 
  // Register File (ID stage, write in WB stage)
  //
  regfile i_regfile(
    .clk      (clk),
    .we       (MEMWB_RegWrite),
    .rs1      (rs1),
    .rs2      (rs2),
    .rd       (MEMWB_rd),
    .rd_data  (rd_data),
    .rs1_data (rs1_data),
    .rs2_data (rs2_data));
  
  // ========================================
  // ID/EX Pipeline Register Update (해독 -> 실행 단계로 데이터 및 제어신호 넘기기)
  // ========================================
  
  always @(posedge clk)
  begin
    if (reset || flush) begin
      IDEX_pc <= 32'b0;
      IDEX_rs1_data <= 32'b0;
      IDEX_rs2_data <= 32'b0;
      IDEX_se_imm_itype <= 32'b0;
      IDEX_se_imm_stype <= 32'b0;
      IDEX_se_br_imm <= 32'b0;
      IDEX_se_jal_imm <= 32'b0;
      IDEX_auipc_lui_imm <= 32'b0;
      IDEX_rs1 <= 5'b0;
      IDEX_rs2 <= 5'b0;
      IDEX_rd <= 5'b0;
      IDEX_funct3 <= 3'b0;
      IDEX_funct7 <= 7'b0;
      IDEX_opcode <= 7'b0;
      // Control signals
      IDEX_auipc <= 1'b0;
      IDEX_lui <= 1'b0;
      IDEX_RegWrite <= 1'b0;
      IDEX_MemtoReg <= 1'b0;
      IDEX_MemWrite <= 1'b0;
      IDEX_ALUSrc <= 1'b0;
      IDEX_ALUcontrol <= 5'b0;
      IDEX_branch <= 1'b0;
      IDEX_jal <= 1'b0;
      IDEX_jalr <= 1'b0;
      IDEX_CNNInstr <= 1'b0;
    end
    else if (load_use_stall) begin
      // Insert bubble (NOP)
      IDEX_RegWrite <= 1'b0;
      IDEX_MemtoReg <= 1'b0;
      IDEX_MemWrite <= 1'b0;
      IDEX_branch <= 1'b0;
      IDEX_jal <= 1'b0;
      IDEX_jalr <= 1'b0;
      IDEX_CNNInstr <= 1'b0;
    end
    else if (cnn_wait_stall) begin
      // Hold the CNN instruction in EX until the HLS block returns ap_done.
    end
    else begin
      IDEX_pc <= IFID_pc;
      IDEX_rs1_data <= rs1_data;
      IDEX_rs2_data <= rs2_data;
      IDEX_se_imm_itype <= se_imm_itype;
      IDEX_se_imm_stype <= se_imm_stype;
      IDEX_se_br_imm <= se_br_imm;
      IDEX_se_jal_imm <= se_jal_imm;
      IDEX_auipc_lui_imm <= auipc_lui_imm;
      IDEX_rs1 <= rs1;
      IDEX_rs2 <= rs2;
      IDEX_rd <= rd;
      IDEX_funct3 <= funct3;
      IDEX_funct7 <= IFID_inst[31:25];
      IDEX_opcode <= IFID_inst[6:0];
      // Control signals
      IDEX_auipc <= auipc;
      IDEX_lui <= lui;
      IDEX_RegWrite <= RegWrite;
      IDEX_MemtoReg <= MemtoReg;
      IDEX_MemWrite <= MemWrite;
      IDEX_ALUSrc <= ALUSrc;
      IDEX_ALUcontrol <= ALUcontrol;
      IDEX_branch <= branch;
      IDEX_jal <= jal;
      IDEX_jalr <= jalr;
      IDEX_CNNInstr <= CNNInstr;
    end
  end
  
  // ========================================
  // EX Stage (실행 단계): ALU를 통해 덧셈, 논리 연산, 주소 계산 등을 실제로 수행합니다.
  // ========================================

  // EXMEM forwarding only carries values already produced in EX/MEM.
  // Load data is available through MEM/WB after the load-use bubble, so do not
  // keep a combinational data-memory-to-ALU path here.
  wire [31:0] exmem_fwd_data;
  assign exmem_fwd_data = (EXMEM_jal | EXMEM_jalr) ? EXMEM_pc_plus4 :
                          EXMEM_aluout;


  // Forwarding logic for rs1 and rs2
  always @(*)
  begin
    case (forwardA)
      2'b00: forward_rs1_data = IDEX_rs1_data;
      2'b01: forward_rs1_data = rd_data;  // Forward from WB stage
      2'b10: forward_rs1_data = exmem_fwd_data;  // Forward from MEM stage
      default: forward_rs1_data = IDEX_rs1_data;
    endcase
  end
  
  always @(*)
  begin
    case (forwardB)
      2'b00: forward_rs2_data = IDEX_rs2_data;
      2'b01: forward_rs2_data = rd_data;  // Forward from WB stage
      2'b10: forward_rs2_data = exmem_fwd_data;  // Forward from MEM stage
      default: forward_rs2_data = IDEX_rs2_data;
    endcase
  end


  //
  // ALU (EX stage)
  //
  alu i_alu(
    .a        (alusrc1),
    .b        (alusrc2),
    .alucont  (IDEX_ALUcontrol),
    .result   (aluout),
    .N        (Nflag),
    .Z        (Zflag),
    .C        (Cflag),
    .V        (Vflag));

  // Load/store addresses are always base + immediate. Keeping this separate
  // avoids routing the data-memory address through the full ALU result mux.
  assign mem_addr_ex = alusrc1 + alusrc2;

  // CNN custom instruction encoding uses the RISC-V custom-0 opcode.
  // cnn_op[2:0] comes from funct3 and cnn_op[3] comes from funct7[0].
  assign cnn_ex_active = ENABLE_CNN ? IDEX_CNNInstr : 1'b0;
  assign cnn_op = {IDEX_funct7[0], IDEX_funct3};
  assign cnn_wait_stall = cnn_ex_active & ~cnn_result_valid;

  always @(posedge clk)
  begin
    if (reset || flush) begin
      cnn_start_pulse <= 1'b0;
      cnn_busy <= 1'b0;
      cnn_result_valid <= 1'b0;
      cnn_result_reg <= 32'b0;
      cnn_rs1_reg <= 32'b0;
      cnn_rs2_reg <= 32'b0;
      cnn_op_reg <= 4'b0;
    end
    else begin
      cnn_start_pulse <= 1'b0;

      if (cnn_ap_done) begin
        cnn_busy <= 1'b0;
        cnn_result_valid <= 1'b1;
        cnn_result_reg <= cnn_rd_data;
      end

      if (cnn_ex_active && !cnn_busy && !cnn_result_valid) begin
        cnn_rs1_reg <= forward_rs1_data;
        cnn_rs2_reg <= forward_rs2_data;
        cnn_op_reg <= cnn_op;
        cnn_start_pulse <= 1'b1;
        cnn_busy <= 1'b1;
      end

      if (cnn_ex_active && cnn_result_valid && !load_use_stall) begin
        cnn_result_valid <= 1'b0;
      end
    end
  end

  generate
    if (ENABLE_CNN != 0) begin : gen_cnn_alu
      CNN_ALU_Top i_cnn_alu_top (
        .ap_clk     (clk),
        .ap_rst     (reset),
        .ap_start   (cnn_start_pulse),
        .ap_done    (cnn_ap_done),
        .ap_idle    (cnn_ap_idle),
        .ap_ready   (cnn_ap_ready),
        .rs1_data_V (cnn_rs1_reg),
        .rs2_data_V (cnn_rs2_reg),
        .cnn_op_V   (cnn_op_reg),
        .rd_data_V  (cnn_rd_data)
      );
    end else begin : gen_no_cnn_alu
      assign cnn_ap_done = 1'b0;
      assign cnn_ap_idle = 1'b1;
      assign cnn_ap_ready = 1'b0;
      assign cnn_rd_data = 32'b0;
    end
  endgenerate

  // 1st source to ALU (alusrc1) - EX stage
  always@(*)
  begin
    if      (IDEX_auipc)  alusrc1[31:0] = IDEX_pc;
    else if (IDEX_lui)    alusrc1[31:0] = 32'b0;
    else                  alusrc1[31:0] = forward_rs1_data[31:0];
  end
  
  // 2nd source to ALU (alusrc2) - EX stage
  always@(*)
  begin
    if      (IDEX_auipc | IDEX_lui)       alusrc2[31:0] = IDEX_auipc_lui_imm[31:0];
    else if (IDEX_ALUSrc & IDEX_MemWrite) alusrc2[31:0] = IDEX_se_imm_stype[31:0];
    else if (IDEX_ALUSrc)                 alusrc2[31:0] = IDEX_se_imm_itype[31:0];
    else                                  alusrc2[31:0] = forward_rs2_data[31:0];
  end
  
  // Branch/JAL destination calculation (EX stage)
  assign branch_dest = IDEX_pc + (IDEX_jal ? IDEX_se_jal_imm : IDEX_se_br_imm);
  
  // ========================================
  // EX/MEM Pipeline Register Update (실행 -> 메모리 단계로 연산 결과 넘기기)
  // ========================================
  
  always @(posedge clk)
  begin
    if (reset || flush) begin
      EXMEM_pc_plus4 <= 32'b0;
      EXMEM_aluout <= 32'b0;
      EXMEM_rs2_data <= 32'b0;
      EXMEM_branch_dest <= 32'b0;
      EXMEM_rd <= 5'b0;
      EXMEM_funct3 <= 3'b0;
      EXMEM_Zflag <= 1'b0;
      EXMEM_Nflag <= 1'b0;
      EXMEM_Cflag <= 1'b0;
      EXMEM_Vflag <= 1'b0;
      // Control signals
      EXMEM_RegWrite <= 1'b0;
      EXMEM_MemtoReg <= 1'b0;
      EXMEM_MemWrite <= 1'b0;
      EXMEM_branch <= 1'b0;
      EXMEM_jal <= 1'b0;
      EXMEM_jalr <= 1'b0;
      EXMEM_CNNInstr <= 1'b0;
    end
    else if (cnn_wait_stall) begin
      EXMEM_pc_plus4 <= 32'b0;
      EXMEM_aluout <= 32'b0;
      EXMEM_rs2_data <= 32'b0;
      EXMEM_branch_dest <= 32'b0;
      EXMEM_rd <= 5'b0;
      EXMEM_funct3 <= 3'b0;
      EXMEM_Zflag <= 1'b0;
      EXMEM_Nflag <= 1'b0;
      EXMEM_Cflag <= 1'b0;
      EXMEM_Vflag <= 1'b0;
      EXMEM_RegWrite <= 1'b0;
      EXMEM_MemtoReg <= 1'b0;
      EXMEM_MemWrite <= 1'b0;
      EXMEM_branch <= 1'b0;
      EXMEM_jal <= 1'b0;
      EXMEM_jalr <= 1'b0;
      EXMEM_CNNInstr <= 1'b0;
    end
    else begin
      EXMEM_pc_plus4 <= IDEX_pc + 4;
      EXMEM_aluout <= IDEX_CNNInstr ? cnn_result_reg :
                      ((IDEX_MemtoReg | IDEX_MemWrite) ? mem_addr_ex : aluout);
      EXMEM_rs2_data <= forward_rs2_data;
      EXMEM_branch_dest <= branch_dest;
      EXMEM_rd <= IDEX_rd;
      EXMEM_funct3 <= IDEX_funct3;
      EXMEM_Zflag <= Zflag;
      EXMEM_Nflag <= Nflag;
      EXMEM_Cflag <= Cflag;
      EXMEM_Vflag <= Vflag;
      // Control signals
      EXMEM_RegWrite <= IDEX_RegWrite;
      EXMEM_MemtoReg <= IDEX_MemtoReg;
      EXMEM_MemWrite <= IDEX_MemWrite;
      EXMEM_branch <= IDEX_branch;
      EXMEM_jal <= IDEX_jal;
      EXMEM_jalr <= IDEX_jalr;
      EXMEM_CNNInstr <= IDEX_CNNInstr;
    end
  end
  
  // ========================================
  // MEM Stage (메모리 단계): 데이터 메모리(Data Memory)를 읽거나 쓰고, 분기(Branch) 성공 여부를 판별합니다.
  // ========================================
  
  // Branch decision logic (MEM stage)
  assign f3beq  = (EXMEM_funct3 == 3'b000);
  assign f3bne  = (EXMEM_funct3 == 3'b001);
  assign f3blt  = (EXMEM_funct3 == 3'b100);
  assign f3bge  = (EXMEM_funct3 == 3'b101);
  assign f3bltu = (EXMEM_funct3 == 3'b110);
  assign f3bgeu = (EXMEM_funct3 == 3'b111);

  assign beq_taken  = EXMEM_branch & f3beq & EXMEM_Zflag;
  assign bne_taken  = EXMEM_branch & f3bne & ~EXMEM_Zflag;
  assign blt_taken  = EXMEM_branch & f3blt & (EXMEM_Nflag != EXMEM_Vflag);
  assign bge_taken  = EXMEM_branch & f3bge & (EXMEM_Nflag == EXMEM_Vflag);
  assign bltu_taken = EXMEM_branch & f3bltu & ~EXMEM_Cflag;
  assign bgeu_taken = EXMEM_branch & f3bgeu & EXMEM_Cflag;
  assign btaken     = beq_taken | bne_taken | blt_taken | bge_taken | bltu_taken | bgeu_taken;
  
  // Jump destinations (MEM stage)
  assign jal_dest  = EXMEM_branch_dest;  // JAL uses same adder as branch
  assign jalr_dest = {EXMEM_aluout[31:1], 1'b0};
  
  // Flush signal for branch/jump taken
  assign flush = btaken | EXMEM_jal | EXMEM_jalr;
  
  // Memory interface outputs (MEM stage)
  assign MemAddr = EXMEM_aluout;
  assign MemRAddr = mem_addr_ex;
  // Align store payload to selected byte lanes.
  assign MemWData = (EXMEM_funct3 == 3'b000) ? (EXMEM_rs2_data << (8  * EXMEM_aluout[1:0])) :
                    (EXMEM_funct3 == 3'b001) ? (EXMEM_rs2_data << (16 * EXMEM_aluout[1]))   :
                                                EXMEM_rs2_data;
  assign MemWrite_out = EXMEM_MemWrite;


  // ========================================
  // Hazard Detection Unit (해저드 탐지 유닛)
  // 방금 데이터를 메모리에서 불러오라(Load)고 시켰는데, 바로 다음 명령어가 그 데이터를 쓰려고 할 때 파이프라인을 잠시 멈춥니다(Stall).
  // ========================================
  
  // Load-use hazard detection
  // Check rs1 always, but only check rs2 when the instruction currently in ID
  // actually reads rs2. I-type arithmetic/load encodes immediate bits in rs2.
  wire id_uses_rs2 = (IFID_inst[6:0] == `OP_S) ||
                     (IFID_inst[6:0] == `OP_R) ||
                     (IFID_inst[6:0] == `OP_B) ||
                     (IFID_inst[6:0] == `OP_CNN);
  assign load_use_stall = (IDEX_MemtoReg &&
                           ((IDEX_rd == rs1) || (id_uses_rs2 && (IDEX_rd == rs2))) &&
                           (IDEX_rd != 5'b0));
  assign stall = load_use_stall | cnn_wait_stall;

  // Bottleneck profiling: how often the pipeline stalls/flushed.
  always @(posedge clk)
  begin
    if (reset) begin
      dbg_stall_count <= 64'b0;
      dbg_flush_count <= 64'b0;
      dbg_flush_branch_count <= 64'b0;
      dbg_flush_jump_count <= 64'b0;
    end
    else begin
      if (stall)
        dbg_stall_count <= dbg_stall_count + 1;
      if (flush)
        dbg_flush_count <= dbg_flush_count + 1;
      if (btaken)
        dbg_flush_branch_count <= dbg_flush_branch_count + 1;
      if (EXMEM_jal | EXMEM_jalr)
        dbg_flush_jump_count <= dbg_flush_jump_count + 1;
    end
  end
  
  // ========================================
  // Forwarding Unit (포워딩 유닛)
  // 아직 레지스터에 쓰이지 않은(미래 단계에 있는) 최신 계산값을 현재 단계(EX)의 ALU로 미리 끌어오는(가로채는) 역할을 합니다.
  // ========================================
  
  // Forward A (for rs1)
  assign forwardA = ((EXMEM_RegWrite) && !EXMEM_MemtoReg && (EXMEM_rd != 5'b0) && (EXMEM_rd == IDEX_rs1)) ? 2'b10 :
                    ((MEMWB_RegWrite) && (MEMWB_rd != 5'b0) && (MEMWB_rd == IDEX_rs1)) ? 2'b01 :
                    2'b00;
  
  // Forward B (for rs2)
  assign forwardB = ((EXMEM_RegWrite) && !EXMEM_MemtoReg && (EXMEM_rd != 5'b0) && (EXMEM_rd == IDEX_rs2)) ? 2'b10 :
                    ((MEMWB_RegWrite) && (MEMWB_rd != 5'b0) && (MEMWB_rd == IDEX_rs2)) ? 2'b01 :
                    2'b00;
	

  // ========================================
  // MEM/WB Pipeline Register Update (메모리 -> 레지스터 쓰기 단계로 최종 데이터 넘기기)
  // ========================================
  
  always @(posedge clk)
  begin
    if (reset) begin
      MEMWB_aluout <= 32'b0;
      MEMWB_MemRData2RF <= 32'b0;
      MEMWB_pc_plus4 <= 32'b0;
      MEMWB_rd <= 5'b0;
      // Control signals
      MEMWB_RegWrite <= 1'b0;
      MEMWB_MemtoReg <= 1'b0;
      MEMWB_jal <= 1'b0;
      MEMWB_jalr <= 1'b0;
      MEMWB_CNNInstr <= 1'b0;
    end
    else begin
      MEMWB_aluout <= EXMEM_aluout;
      MEMWB_MemRData2RF <= MemRData2RF;
      MEMWB_pc_plus4 <= EXMEM_pc_plus4;
      MEMWB_rd <= EXMEM_rd;
      // Control signals
      MEMWB_RegWrite <= EXMEM_RegWrite;
      MEMWB_MemtoReg <= EXMEM_MemtoReg;
      MEMWB_jal <= EXMEM_jal;
      MEMWB_jalr <= EXMEM_jalr;
      MEMWB_CNNInstr <= EXMEM_CNNInstr;
    end
  end
  
  // ========================================
  // WB Stage (레지스터 쓰기 단계): 메모리에서 읽어온 값이나 ALU 연산 결과를 CPU 레지스터 파일(x0~x31)에 최종적으로 저장합니다.
  // ========================================

  // Data selection for writing to RF (WB stage)
  always@(*)
  begin
    if      (MEMWB_jal | MEMWB_jalr) rd_data[31:0] = MEMWB_pc_plus4;
    else if (MEMWB_MemtoReg)         rd_data[31:0] = MEMWB_MemRData2RF;
    else                             rd_data[31:0] = MEMWB_aluout;
  end
  
  // ========================================
  // Memory Interface (MEM stage)
  // ========================================
  
  // Byte Enable to Memory for Load and Store 
  wire [1:0] Addr_Last2;

  assign Addr_Last2 = EXMEM_aluout[1:0];

  always@(*)
  begin
    case(EXMEM_funct3)

		3'b000,  // LB (Load Byte), SB (Store Byte)
		3'b100:  // LBU (Load Byte Unsigned)
		         case (Addr_Last2)
			       2'b00:   ByteEnable <= 4'b0001; 
			       2'b01:   ByteEnable <= 4'b0010;
			       2'b10:   ByteEnable <= 4'b0100;
			       2'b11:   ByteEnable <= 4'b1000;
               endcase

		3'b001,  // LH (Load Halfword), SH (Store Halfword)
		3'b101:  // LHU (Load Halfword Unsigned)
		         case (Addr_Last2)
			       2'b00:   ByteEnable <= 4'b0011; 
			       2'b10:   ByteEnable <= 4'b1100;
			       default: ByteEnable <= 4'b0000;
               endcase

		3'b010:  // LW (Load Word), SW (Store Word)
			      ByteEnable <= 4'b1111;

 	   default: ByteEnable <= 4'b0000;

    endcase
	end


	// LB, LH, LW, LBU, LHU: Data manipulation from Memory

	always@(*)
	begin
    case(EXMEM_funct3)

		3'b000:  // LB (Load Byte), sign-extension
		         case (Addr_Last2)
			       2'b00: MemRData2RF <= {{24{MemRData[7]}},  MemRData[7:0]}; 
			       2'b01: MemRData2RF <= {{24{MemRData[15]}}, MemRData[15:8]}; 
			       2'b10: MemRData2RF <= {{24{MemRData[23]}}, MemRData[23:16]}; 
			       2'b11: MemRData2RF <= {{24{MemRData[31]}}, MemRData[31:24]};
               endcase

		3'b001:  // LH (Load Halfword), sign-extension
		         case (Addr_Last2)
			       2'b00:    MemRData2RF <= {{16{MemRData[15]}}, MemRData[15:0]}; 
			       2'b10:    MemRData2RF <= {{16{MemRData[31]}}, MemRData[31:16]}; 
                default:  MemRData2RF <= {{16{MemRData[15]}}, MemRData[15:0]};
               endcase

		3'b010:  // LW (Load Word)
			      MemRData2RF <= MemRData;

		3'b100:  // LBU (Load Byte Unsigned), zero-extension
		         case (Addr_Last2)
			       2'b00: MemRData2RF <= {24'b0,MemRData[7:0]}; 
			       2'b01: MemRData2RF <= {24'b0,MemRData[15:8]}; 
			       2'b10: MemRData2RF <= {24'b0,MemRData[23:16]}; 
			       2'b11: MemRData2RF <= {24'b0,MemRData[31:24]};
               endcase

		3'b101:  // LHU (Load Halfword Unsigned), zero-extension
		         case (Addr_Last2)
			       2'b00:    MemRData2RF <= {16'b0,MemRData[15:0]}; 
			       2'b10:    MemRData2RF <= {16'b0,MemRData[31:16]}; 
                default:  MemRData2RF <= {16'b0,MemRData[15:0]};
               endcase

      default:  MemRData2RF <= MemRData[31:0]; 

    endcase
  end

endmodule
