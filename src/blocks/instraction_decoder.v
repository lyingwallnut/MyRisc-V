module instruction_decoder(
    input  wire [31:0]  instruction,
    input  wire [31:0]  pc_count,
    
    // Decoded register addresses
    output wire [4:0]   rd_addr,
    output wire [4:0]   rs1_addr,
    output wire [4:0]   rs2_addr,

    output reg  [31:0]  imm_value,
    
    output reg          use_alu,
    output reg          use_shifter,
    output reg          use_comparator,

    output reg          alu_src1,          // 0: rs1, 1: pc
    output reg          alu_src2,          // 0: rs2, 1: imm
    output reg  [5:0]   alu_mode,
    output reg  [2:0]   shifter_mode,
    output reg  [2:0]   comparator_mode,

    output reg          reg_write_en,
    output reg          mem_read_en,
    output reg          mem_write_en
);

wire [6:0] opcode = instruction[6:0];
wire [2:0] funct3 = instruction[14:12];
wire [6:0] funct7 = instruction[31:25];

wire [4:0] rd  = instruction[11:7];
wire [4:0] rs1 = instruction[19:15];
wire [4:0] rs2 = instruction[24:20];

wire [31:0] imm_i = {{20{instruction[31]}}, instruction[31:20]};
wire [31:0] imm_s = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
wire [31:0] imm_b = {{19{instruction[31]}}, instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0};
wire [31:0] imm_u = {instruction[31:12], 12'b0};
wire [31:0] imm_j = {{11{instruction[31]}}, instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};

// instruction type
wire R_TYPE      = (opcode == 7'b0110011);
wire I_TYPE_CALC = (opcode == 7'b0010011);
wire I_TYPE_LOAD = (opcode == 7'b0000011);
wire I_TYPE_JUMP = (opcode == 7'b1100111) && (funct3 == 3'b000);
wire I_TYPE_SYNC = (opcode == 7'b1110011);
wire I_TYPE_ENV  = (opcode == 7'b1110010) && instruction[31:20] != 12'b000000000000;
wire I_TYPE_CSR  = (opcode == 7'b1110011);
wire S_TYPE      = (opcode == 7'b0100011);
wire B_TYPE      = (opcode == 7'b1100011);
wire U_TYPE      = (opcode == 7'b0110111) || (opcode == 7'b0010111);
wire J_TYPE      = (opcode == 7'b1101111);

// detail instruction params
// R_TYPE instructions
// {funct7, funct3}
parameter ADD  = 10'b0000000000,  // add                              reg[rd] = reg[rs1] + reg[rs2]
          SUB  = 10'b0100000000,  // subtract                         reg[rd] = reg[rs1] - reg[rs2]

          OR   = 10'b0000000110,  // bitwise or                       reg[rd] = reg[rs1] | reg[rs2]
          AND  = 10'b0000000111,  // bitwise and                      reg[rd] = reg[rs1] & reg[rs2]
          XOR  = 10'b0000000100,  // bitwise xor                      reg[rd] = reg[rs1] ^ reg[rs2]

          SLL  = 10'b0000000001,  // logical left shift               reg[rd] = reg[rs1] << reg[rs2]
          SRL  = 10'b0000000101,  // logical right shift              reg[rd] = reg[rs1] >> reg[rs2]
          SRA  = 10'b0100000101,  // arithmetic right shift           reg[rd] = reg[rs1] >>> reg[rs2]

          SLT  = 10'b0000000010,  // signed less than                 reg[rd] = (reg[rs1] < reg[rs2]) ? 1 : 0
          SLTU = 10'b0000000011;  // unsigned less than               reg[rd] = (reg[rs1] < reg[rs2]) ? 1 : 0

// I_TYPE instructions
// I_TYPE_CALC instructions
// {funct3}
parameter ADDI = 3'b000,  // add immediate                            reg[rd] = reg[rs1] + imm_i
          
          ORI   = 3'b110,  // bitwise or immediate                    reg[rd] = reg[rs1] | imm_i
          ANDI  = 3'b111,  // bitwise and immediate                   reg[rd] = reg[rs1] & imm_i
          XORI  = 3'b100,  // bitwise xor immediate                   reg[rd] = reg[rs1] ^ imm_i

          // {funct7, funct3}
          SLLI  = 7'b0000001,  // logical left shift immediate        reg[rd] = reg[rs1] << imm_i[4:0]
          SRLI  = 7'b0000101,  // logical right shift immediate       reg[rd] = reg[rs1] >> imm_i[4:0]
          SRAI  = 7'b0100101,  // arithmetic right shift immediate    reg[rd] = reg[rs1] >>> imm_i[4:0]
          
          // {funct3}
          SLTI  = 3'b010,  // signed less than immediate              reg[rd] = (reg[rs1] < imm_i) ? 1 : 0
          SLTIU = 3'b011,  // unsigned less than immediate            reg[rd] = (reg[rs1] < imm_i) ? 1 : 0

          // I_TYPE_LOAD instructions
          // {funct3}
          LB   = 3'b000,  // load byte                                reg[rd] = mem[reg[rs1] + imm_i][7:0]
          LH   = 3'b001,  // load halfword                            reg[rd] = mem[reg[rs1] + imm_i][15:0]
          LW   = 3'b010,  // load word                                reg[rd] = mem[reg[rs1] + imm_i][31:0]
          LBU  = 3'b100,  // load byte unsigned                       reg[rd] = zero_extend(mem[reg[rs1] + imm_i][7:0])
          LHU  = 3'b101,  // load halfword unsigned                   reg[rd] = zero_extend(mem[reg[rs1] + imm_i][15:0])

          // I_TYPE_JUMP instructions
          JALR  = 7'b0000000,  // jump and link register              reg[rd] = pc + 4; pc = reg[rs1] + imm_i

          // I_TYPE_ENV instructions
          // {imm_i}
          ECALL = 12'b000000000000,  // environment call
          EBREAK= 12'b000000000001,  // environment break

          // I_TYPE_SYNC instructions
          // {funct3}
          FENCE = 3'b000,    // memory fence
          FENCE_I = 3'b001,  // instruction fence

          // I_TYPE_CSR instructions
          // {funct3}
          CSRRW  = 3'b001,  // atomic read/write CSR                            csr[imm_i] = reg[rs1]; reg[rd] = old csr[imm_i]
          CSRRS  = 3'b010,  // atomic read and set bits in CSR                  reg[rd] = csr[imm_i]; csr[imm_i] = csr[imm_i] | reg[rs1]
          CSRRC  = 3'b011,  // atomic read and clear bits in CSR                reg[rd] = csr[imm_i]; csr[imm_i] = csr[imm_i] & ~reg[rs1]
          CSRRWI = 3'b101,  // atomic read/write CSR with immediate             csr[imm_i] = zext(rs1); reg[rd] = old csr[imm_i]
          CSRRSI = 3'b110,  // atomic read and set bits in CSR with immediate   reg[rd] = csr[imm_i]; csr[imm_i] = csr[imm_i] | zext(rs1)
          CSRRCI = 3'b111;  // atomic read and clear bits in CSR with immediate reg[rd] = csr[imm_i]; csr[imm_i] = csr[imm_i] & ~zext(rs1);


// S_TYPE instructions
// {funct3}
parameter SB  = 3'b000,  // store byte                            mem[reg[rs1] + imm_s][7:0] = reg[rs2][7:0]
          SH  = 3'b001,  // store halfword                        mem[reg[rs1] + imm_s][15:0] = reg[rs2][15:0]
          SW  = 3'b010;  // store word                            mem[reg[rs1] + imm_s][31:0] = reg[rs2][31:0]

// B_TYPE instructions
// {funct3}
parameter BEQ  = 3'b000,  // branch if equal                          if (reg[rs1] == reg[rs2]) pc = pc + imm_b
          BNE  = 3'b001,  // branch if not equal                      if (reg[rs1] != reg[rs2]) pc = pc + imm_b
          BLT  = 3'b100,  // branch if less than                      if (reg[rs1] < reg[rs2]) pc = pc + imm_b
          BGE  = 3'b101,  // branch if greater than or equal          if (reg[rs1] >= reg[rs2]) pc = pc + imm_b
          BLTU = 3'b110,  // branch if less than unsigned             if (reg[rs1] < reg[rs2]) pc = pc + imm_b
          BGEU = 3'b111;  // branch if greater than or equal unsigned if (reg[rs1] >= reg[rs2]) pc = pc + imm_b

// U_TYPE instructions
// {opcode}
parameter LUI  = 7'b0110111,  // load upper immediate                 reg[rd] = imm_u
          AUIPC= 7'b0010111;  // add upper immediate to pc            reg[rd] = pc + imm_u

// J_TYPE instructions
// {opcode}
parameter JAL  = 7'b1101111;  // jump and link                        reg[rd] = pc + 4; pc = pc + imm_j

assign rd_addr  = rd;
assign rs1_addr = rs1;
assign rs2_addr = rs2;

// ALU instructions
// control = {S[3:0], Cin, M}
parameter   ALU_SET_ZERO = 6'b000010,
            ALU_NOR      = 6'b000110,
            ALU_NOTAND   = 6'b001010,
            ALU_NOT_A    = 6'b001110,
            ALU_ANDNOT   = 6'b010010,
            ALU_NOT_B    = 6'b010110,
            ALU_XOR      = 6'b011010,
            ALU_NAND     = 6'b011110,
            ALU_AND      = 6'b100010,
            ALU_XNOR     = 6'b100110,
            ALU_PASS_B   = 6'b101010,
            ALU_NOTOR    = 6'b101110,
            ALU_PASS_A   = 6'b110010,
            ALU_ORNOT    = 6'b110110,
            ALU_OR       = 6'b111010,
            ALU_SET_ONE  = 6'b111110,
            ALU_ADD      = 6'b100101,
            ALU_SUB      = 6'b011011;

// Barrel shifter instructions
parameter SHIFT_NOP = 3'b000,
          SHIFT_LSR = 3'b001,
          SHIFT_LSL = 3'b010,
          SHIFT_ROR = 3'b011,
          SHIFT_ASR = 3'b100,
          SHIFT_ASL = 3'b101;

// Comparator modes
parameter CMP_LT  = 3'b000,
          CMP_LTU = 3'b001,
          CMP_GE  = 3'b010,
          CMP_GEU = 3'b011,
          CMP_EQ  = 3'b100,
          CMP_NEQ = 3'b101;

// Decoder logic
always @(*) begin
    imm_value <= 32'b0;
    use_alu   <= 1'b0;
    use_shifter <= 1'b0;
    use_comparator <= 1'b0;
    alu_src1   <= 1'b0;
    alu_src2   <= 1'b0;
    alu_mode  <= ALU_SET_ZERO;
    shifter_mode <= SHIFT_NOP;
    comparator_mode <= 3'b000;
    reg_write_en <= 1'b0;
    mem_read_en  <= 1'b0;
    mem_write_en <= 1'b0;
    if(R_TYPE) begin
        reg_write_en <= 1'b1;
        alu_src2 <= 1'b0; // rs2
        case({funct7, funct3})
            ADD: begin
                alu_mode <= ALU_ADD;
                use_alu  <= 1'b1;
            end 
            SUB: begin
                alu_mode <= ALU_SUB;
                use_alu  <= 1'b1;
            end
            OR: begin
                alu_mode <= ALU_OR;
                use_alu  <= 1'b1;
            end
            AND: begin
                alu_mode <= ALU_AND;
                use_alu  <= 1'b1;
            end
            XOR: begin
                alu_mode <= ALU_XOR;
                use_alu  <= 1'b1;
            end
            SLL: begin
                shifter_mode <= SHIFT_LSL;
                use_shifter  <= 1'b1;
            end
            SRL: begin
                shifter_mode <= SHIFT_LSR;
                use_shifter  <= 1'b1;
            end
            SRA: begin
                shifter_mode <= SHIFT_ASR;
                use_shifter  <= 1'b1;
            end
            SLT: begin
                comparator_mode <= CMP_LT;
                use_comparator <= 1'b1;
            end
            SLTU: begin
                comparator_mode <= CMP_LTU;
                use_comparator <= 1'b1;
            end
            default: ;
        endcase
    end else if(I_TYPE_CALC) begin
        reg_write_en <= 1'b1;
        alu_src2 <= 1'b1; // imm
        imm_value <= imm_i;
        case(funct3)
            ADDI: begin
                alu_mode <= ALU_ADD;
                use_alu  <= 1'b1;
            end
            ORI: begin
                alu_mode <= ALU_OR;
                use_alu  <= 1'b1;
            end
            ANDI: begin
                alu_mode <= ALU_AND;
                use_alu  <= 1'b1;
            end
            XORI: begin
                alu_mode <= ALU_XOR;
                use_alu  <= 1'b1;
            end
            SLTI: begin
                comparator_mode <= CMP_LT;
                use_comparator <= 1'b1;
            end
            SLTIU: begin
                comparator_mode <= CMP_LTU;
                use_comparator <= 1'b1;
            end
            default: ;
        endcase
    end else if(S_TYPE) begin
        use_alu <= 1'b1;
        alu_src2 <= 1'b1; // imm
        imm_value <= imm_s;
        alu_mode <= ALU_ADD;
        mem_write_en <= 1'b1;
    end else if(I_TYPE_LOAD) begin
        use_alu <= 1'b1;
        alu_src2 <= 1'b1; // imm
        imm_value <= imm_i;
        alu_mode <= ALU_ADD;
        mem_read_en <= 1'b1;
        reg_write_en <= 1'b1;
    end else if(U_TYPE) begin
        case(opcode)
            LUI: begin
                reg_write_en <= 1'b1;
                imm_value <= imm_u;
                alu_src2 <= 1'b1; // imm
                alu_mode <= ALU_PASS_B;
                use_alu <= 1'b1;
            end
            AUIPC: begin
                reg_write_en <= 1'b1;
                imm_value <= imm_u;
                alu_src1 <= 1'b1; // pc
                alu_src2 <= 1'b1; // imm
                alu_mode <= ALU_ADD;
                use_alu <= 1'b1;
            end
            default: ; 
        endcase 
    end else if(J_TYPE) begin
        reg_write_en <= 1'b1;
        imm_value <= 32'd4;
        alu_src1 <= 1'b1; // pc
        alu_src2 <= 1'b1; // imm
        alu_mode <= ALU_ADD;
        use_alu <= 1'b1;
    end else if(I_TYPE_JUMP) begin
        reg_write_en <= 1'b1;
        imm_value <= 32'd4;
        alu_src1 <= 1'b1; // pc
        alu_src2 <= 1'b1; // imm
        alu_mode <= ALU_ADD;
        use_alu <= 1'b1;
    end else if(B_TYPE) begin
        use_comparator <= 1'b1;
        imm_value <= imm_b;
        case(funct3)
            BEQ: begin
                comparator_mode <= CMP_EQ;
            end
            BNE: begin
                comparator_mode <= CMP_NEQ;
            end
            BLT: begin
                comparator_mode <= CMP_LT;
            end
            BGE: begin
                comparator_mode <= CMP_GE;
            end
            BLTU: begin
                comparator_mode <= CMP_LTU;
            end
            BGEU: begin
                comparator_mode <= CMP_GEU;
            end
            default: ;
        endcase
    end
end

endmodule
