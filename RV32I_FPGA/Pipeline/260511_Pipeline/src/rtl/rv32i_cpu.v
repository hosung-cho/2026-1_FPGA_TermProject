`timescale 1ns/1ns

module rv32i_cpu #(
            parameter [31:0] RESET_PC = 32'h0000_0000
) (
		      input         clk, reset,
            output [31:0] pc,		  		// program counter for instruction fetch
            input  [31:0] inst, 			// incoming instruction
            output        MemWrite, 	// 'memory write' control signal
            output [31:0] MemAddr,  	// memory address 
            output [31:0] MemWData, 	// data to write to memory
            output [3:0]  ByteEnable,  // byte enable
            input  [31:0] MemRData); 	// data read from memory

  wire        auipc, lui;
  wire        ALUSrc, RegWrite;
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
		.ALUcontrol	(ALUcontrol));

  // Instantiate Datapath
  datapath #(
    .RESET_PC(RESET_PC)
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
		.ALUcontrol		(ALUcontrol),
		.pc				(pc),
		.inst				(inst),
		.inst_decode	(inst_decode),
		.MemAddr			(MemAddr),
		.MemWData		(MemWData),
		.MemWrite_out	(MemWrite),
		.ByteEnable		(ByteEnable),
		.MemRData		(MemRData));

endmodule


//
// Instruction Decoder 
// to generate control signals for datapath
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
		.jalr			(jalr));

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

//
// Main decoder generates all control signals except ALUcontrol 
//
//
module maindec(input  [6:0] opcode,
               output       auipc,
               output       lui,
               output       RegWrite,
               output       ALUSrc,
               output       MemtoReg, MemWrite,
               output       branch, 
               output       jal,
               output       jalr);

  reg [8:0] controls;

  assign {auipc, lui, RegWrite, ALUSrc, 
			 MemtoReg, MemWrite, branch, jal, 
			 jalr} = controls;

  always @(*)
  begin
    case(opcode)
      `OP_R: 			controls <= 9'b0010_0000_0; // R-type
      `OP_I_ARITH: 	controls <= 9'b0011_0000_0; // I-type Arithmetic
      `OP_I_LOAD: 	controls <= 9'b0011_1000_0; // I-type Load
      `OP_I_JALR: 	controls <= 9'b0011_0000_1; // I-type Jalr
      `OP_S: 			controls <= 9'b0001_0100_0; // S-type Store
      `OP_B: 			controls <= 9'b0000_0010_0; // B-type Branch
      `OP_U_LUI: 		controls <= 9'b0111_0000_0; // LUI
      `OP_U_AUIPC:	controls <= 9'b1010_0000_0; // AUIPC
      `OP_J_JAL: 		controls <= 9'b0011_0001_0; // JAL
      default:    	controls <= 9'b0000_0000_0; // ???
    endcase
  end

endmodule

//
// ALU decoder generates ALU control signal (ALUcontrol)
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
// CPU datapath (5-stage pipeline)
//
module datapath #(
                parameter [31:0] RESET_PC = 32'h0000_0000
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

                output reg [31:0] pc,
                output     [31:0] MemAddr,
                output     [31:0] MemWData,
                output        MemWrite_out,
                output reg [3:0]  ByteEnable,
                input      [31:0] MemRData);

  // ========================================
  // Pipeline Registers
  // ========================================
  
  // IF/ID Pipeline Register
  reg [31:0] IFID_pc;
  reg [31:0] IFID_inst;
  reg [31:0] IF1_pc;
  reg        flush_d;
  
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

  // MEM2 Pipeline Register (for synchronous memory read)
  reg [31:0] MEM2_pc_plus4;
  reg [31:0] MEM2_aluout;
  reg [4:0]  MEM2_rd;
  reg [2:0]  MEM2_funct3;
  // Control signals
  reg        MEM2_RegWrite;
  reg        MEM2_MemtoReg;
  reg        MEM2_jal;
  reg        MEM2_jalr;
  
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
  wire        Nflag, Zflag, Cflag, Vflag;
  
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
  reg [1:0]  load_use_hold;

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

  // Track issued fetch addresses for synchronous instruction memory
  always @(posedge clk)
  begin
    if (reset) begin
      IF1_pc <= RESET_PC;
      flush_d <= 1'b0;
    end
    else begin
      flush_d <= flush;
      if (~stall)
        IF1_pc <= pc;
    end
  end

  // Save instruction when stall begins
  reg [31:0] stalled_inst;
  reg was_stalled;
  always @(posedge clk) begin
      if (reset) begin
          stalled_inst <= 32'h00000013;
          was_stalled <= 1'b0;
      end else begin
          was_stalled <= stall;
          if (~was_stalled && stall) // stall starts
              stalled_inst <= inst;
      end
  end

  // ========================================
  // IF/ID Pipeline Register Update
  // ========================================
  
  always @(posedge clk)
  begin
    if (reset || flush || flush_d) begin
      IFID_pc <= 32'b0;
      IFID_inst <= 32'h00000013;  // NOP
    end
    else if (~stall) begin
      IFID_pc <= IF1_pc;
      IFID_inst <= (was_stalled) ? stalled_inst : inst;
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
  // ID/EX Pipeline Register
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
    end
    else if (stall) begin
      // Insert bubble (NOP)
      IDEX_RegWrite <= 1'b0;
      IDEX_MemtoReg <= 1'b0;
      IDEX_MemWrite <= 1'b0;
      IDEX_branch <= 1'b0;
      IDEX_jal <= 1'b0;
      IDEX_jalr <= 1'b0;
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
    end
  end
  
  // ========================================
  // EX Stage: Execute
  // ========================================

  // EXMEM stage value that will eventually be written back.
  // For Load instructions, forward the memory data; otherwise forward ALU output.
  wire [31:0] exmem_fwd_data;
  wire [31:0] mem2_fwd_data;
  assign exmem_fwd_data = (EXMEM_jal | EXMEM_jalr) ? EXMEM_pc_plus4 :
                          EXMEM_aluout;  // Load data is available in MEM2 stage
  assign mem2_fwd_data = (MEM2_jal | MEM2_jalr) ? MEM2_pc_plus4 :
                         (MEM2_MemtoReg) ? MemRData2RF :
                         MEM2_aluout;


  // Forwarding logic for rs1 and rs2
  always @(*)
  begin
    case (forwardA)
      2'b00: forward_rs1_data = IDEX_rs1_data;
      2'b01: forward_rs1_data = rd_data;  // Forward from WB stage
      2'b10: forward_rs1_data = exmem_fwd_data;  // Forward from MEM stage
      2'b11: forward_rs1_data = mem2_fwd_data;  // Forward from MEM2 stage
      default: forward_rs1_data = IDEX_rs1_data;
    endcase
  end
  
  always @(*)
  begin
    case (forwardB)
      2'b00: forward_rs2_data = IDEX_rs2_data;
      2'b01: forward_rs2_data = rd_data;  // Forward from WB stage
      2'b10: forward_rs2_data = exmem_fwd_data;  // Forward from MEM stage
      2'b11: forward_rs2_data = mem2_fwd_data;  // Forward from MEM2 stage
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
  // EX/MEM Pipeline Register
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
    end
    else begin
      EXMEM_pc_plus4 <= IDEX_pc + 4;
      EXMEM_aluout <= aluout;
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
    end
  end
  
  // ========================================
  // MEM Stage: Memory Access
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
  // Align store payload to selected byte lanes.
  assign MemWData = (EXMEM_funct3 == 3'b000) ? (EXMEM_rs2_data << (8  * EXMEM_aluout[1:0])) :
                    (EXMEM_funct3 == 3'b001) ? (EXMEM_rs2_data << (16 * EXMEM_aluout[1]))   :
                                                EXMEM_rs2_data;
  assign MemWrite_out = EXMEM_MemWrite;


  // ========================================
  // Hazard Detection Unit
  // ========================================
  
  // Load-use hazard detection
  // Check rs1 always, but only check rs2 for S-type and R-type instructions
  // (I-type arithmetic and load instructions use rs2 bits as immediate, not register)
  wire [6:0] id_opcode = IFID_inst[6:0];
  wire is_S_type = (id_opcode == 7'b0100011);  // Store
  wire is_R_type = (id_opcode == 7'b0110011);  // R-type
  wire is_B_type = (id_opcode == 7'b1100011);  // Branch
  wire load_use_hazard = (IDEX_MemtoReg &&
                          ((IDEX_rd == rs1) || ((is_S_type || is_R_type || is_B_type) && (IDEX_rd == rs2))) &&
                          (IDEX_rd != 5'b0));
  wire stall_req = load_use_hazard | (load_use_hold != 2'b00);
  always @(posedge clk)
  begin
    if (reset || flush)
      load_use_hold <= 2'b00;
    else if (load_use_hazard)
      load_use_hold <= 2'b01;
    else if (load_use_hold != 2'b00)
      load_use_hold <= load_use_hold - 1'b1;
  end

  assign stall = stall_req & ~flush;

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
  // Forwarding Unit
  // ========================================
  
  // Forward A (for rs1)
  assign forwardA = ((EXMEM_RegWrite) && ~EXMEM_MemtoReg && (EXMEM_rd != 5'b0) && (EXMEM_rd == IDEX_rs1)) ? 2'b10 :
                    ((MEM2_RegWrite) && (MEM2_rd != 5'b0) && (MEM2_rd == IDEX_rs1)) ? 2'b11 :
                    ((MEMWB_RegWrite) && (MEMWB_rd != 5'b0) && (MEMWB_rd == IDEX_rs1)) ? 2'b01 :
                    2'b00;
	

  // ========================================
  // MEM2 Pipeline Register
  // ========================================

  always @(posedge clk)
  begin
    if (reset) begin
      MEM2_pc_plus4 <= 32'b0;
      MEM2_aluout <= 32'b0;
      MEM2_rd <= 5'b0;
      MEM2_funct3 <= 3'b0;
      // Control signals
      MEM2_RegWrite <= 1'b0;
      MEM2_MemtoReg <= 1'b0;
      MEM2_jal <= 1'b0;
      MEM2_jalr <= 1'b0;
    end
    else begin
      MEM2_pc_plus4 <= EXMEM_pc_plus4;
      MEM2_aluout <= EXMEM_aluout;
      MEM2_rd <= EXMEM_rd;
      MEM2_funct3 <= EXMEM_funct3;
      // Control signals
      MEM2_RegWrite <= EXMEM_RegWrite;
      MEM2_MemtoReg <= EXMEM_MemtoReg;
      MEM2_jal <= EXMEM_jal;
      MEM2_jalr <= EXMEM_jalr;
    end
  end
  
  // Forward B (for rs2)
  assign forwardB = ((EXMEM_RegWrite) && ~EXMEM_MemtoReg && (EXMEM_rd != 5'b0) && (EXMEM_rd == IDEX_rs2)) ? 2'b10 :
                    ((MEM2_RegWrite) && (MEM2_rd != 5'b0) && (MEM2_rd == IDEX_rs2)) ? 2'b11 :
                    ((MEMWB_RegWrite) && (MEMWB_rd != 5'b0) && (MEMWB_rd == IDEX_rs2)) ? 2'b01 :
                    2'b00;
	

  // ========================================
  // MEM/WB Pipeline Register
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
    end
    else begin
      MEMWB_aluout <= MEM2_aluout;
      MEMWB_MemRData2RF <= MemRData2RF;
      MEMWB_pc_plus4 <= MEM2_pc_plus4;
      MEMWB_rd <= MEM2_rd;
      // Control signals
      MEMWB_RegWrite <= MEM2_RegWrite;
      MEMWB_MemtoReg <= MEM2_MemtoReg;
      MEMWB_jal <= MEM2_jal;
      MEMWB_jalr <= MEM2_jalr;
    end
  end
  
  // ========================================
  // WB Stage: Write Back
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
  wire [1:0] exmem_addr_last2;
  wire [1:0] mem2_addr_last2;

  assign exmem_addr_last2 = EXMEM_aluout[1:0];
  assign mem2_addr_last2 = MEM2_aluout[1:0];

  always@(*)
  begin
    case(EXMEM_funct3)

		3'b000,  // LB (Load Byte), SB (Store Byte)
		3'b100:  // LBU (Load Byte Unsigned)
             case (exmem_addr_last2)
			       2'b00:   ByteEnable <= 4'b0001; 
			       2'b01:   ByteEnable <= 4'b0010;
			       2'b10:   ByteEnable <= 4'b0100;
			       2'b11:   ByteEnable <= 4'b1000;
               endcase

		3'b001,  // LH (Load Halfword), SH (Store Halfword)
		3'b101:  // LHU (Load Halfword Unsigned)
             case (exmem_addr_last2)
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
    case(MEM2_funct3)

		3'b000:  // LB (Load Byte), sign-extension
             case (mem2_addr_last2)
			       2'b00: MemRData2RF <= {{24{MemRData[7]}},  MemRData[7:0]}; 
			       2'b01: MemRData2RF <= {{24{MemRData[15]}}, MemRData[15:8]}; 
			       2'b10: MemRData2RF <= {{24{MemRData[23]}}, MemRData[23:16]}; 
			       2'b11: MemRData2RF <= {{24{MemRData[31]}}, MemRData[31:24]};
               endcase

		3'b001:  // LH (Load Halfword), sign-extension
             case (mem2_addr_last2)
			       2'b00:    MemRData2RF <= {{16{MemRData[15]}}, MemRData[15:0]}; 
			       2'b10:    MemRData2RF <= {{16{MemRData[31]}}, MemRData[31:16]}; 
                default:  MemRData2RF <= {{16{MemRData[15]}}, MemRData[15:0]};
               endcase

		3'b010:  // LW (Load Word)
			      MemRData2RF <= MemRData;

		3'b100:  // LBU (Load Byte Unsigned), zero-extension
             case (mem2_addr_last2)
			       2'b00: MemRData2RF <= {24'b0,MemRData[7:0]}; 
			       2'b01: MemRData2RF <= {24'b0,MemRData[15:8]}; 
			       2'b10: MemRData2RF <= {24'b0,MemRData[23:16]}; 
			       2'b11: MemRData2RF <= {24'b0,MemRData[31:24]};
               endcase

		3'b101:  // LHU (Load Halfword Unsigned), zero-extension
             case (mem2_addr_last2)
			       2'b00:    MemRData2RF <= {16'b0,MemRData[15:0]}; 
			       2'b10:    MemRData2RF <= {16'b0,MemRData[31:16]}; 
                default:  MemRData2RF <= {16'b0,MemRData[15:0]};
               endcase

      default:  MemRData2RF <= MemRData[31:0]; 

    endcase
  end

endmodule
