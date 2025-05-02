module core(
    input  logic        clk,
    input  logic        reset,
    output logic [31:0] PC,
    input  logic [31:0] Instr,
    output logic        MemWrite,
    output logic [31:0] MemAddr,
    output logic [31:0] WriteData,
    input  logic [31:0] ReadData
);

    logic [6:0]  opcode;
    logic [4:0]  rd, rs1, rs2;
    logic [2:0]  funct3;
    logic [6:0]  funct7;
    logic [31:0] regfile [31:0];
    logic [31:0] imm_I, imm_S;
    logic [31:0] ALUResult;
    logic [31:0] reg1, reg2;
    logic [31:0] alu_in2;
    logic isLoad, isStore, isRType;

    assign opcode = Instr[6:0];
    assign rd     = Instr[11:7];
    assign funct3 = Instr[14:12];
    assign rs1    = Instr[19:15];
    assign rs2    = Instr[24:20];
    assign funct7 = Instr[31:25];

    assign imm_I = {{20{Instr[31]}}, Instr[31:20]};
    assign imm_S = {{20{Instr[31]}}, Instr[31:25], Instr[11:7]};

    assign reg1 = (rs1 != 0) ? regfile[rs1] : 32'd0;
    assign reg2 = (rs2 != 0) ? regfile[rs2] : 32'd0;

    assign isLoad  = (opcode == 7'b0000011); // LW
    assign isStore = (opcode == 7'b0100011); // SW
    assign isRType = (opcode == 7'b0110011); // ADD/SUB

    assign alu_in2 = (isRType) ? reg2 : (isLoad || isStore) ? imm_I : 32'd0;

    always_comb begin
        case ({isRType, funct7, funct3})
            {1'b1, 7'b0000000, 3'b000}: ALUResult = reg1 + reg2; // ADD
            {1'b1, 7'b0100000, 3'b000}: ALUResult = reg1 - reg2; // SUB
            default: ALUResult = reg1 + alu_in2; // Default for LW/SW
        endcase
    end

    assign MemWrite = isStore;
    assign MemAddr  = ALUResult;
    assign WriteData = reg2;

    always_ff @(posedge clk or posedge reset) begin
        if (reset)
            PC <= 0;
        else
            PC <= PC + 4;
    end

    always_ff @(posedge clk) begin
        if ((isRType || isLoad) && rd != 0) begin
            regfile[rd] <= (isLoad) ? ReadData : ALUResult;
        end
    end

endmodule


module imem(input logic [31:0] A, output logic [31:0] RD);
    logic [31:0] ROM [0:31];

    initial begin
        // lw x5, 0(x0); lw x6, 4(x0); add x7,x5,x6; sw x7, 8(x0); sub x8,x5,x6
        ROM[0] = 32'h00002283; // lw x5,0(x0)
        ROM[1] = 32'h00402303; // lw x6,4(x0)
        ROM[2] = 32'h006283b3; // add x7,x5,x6
        ROM[3] = 32'h00702423; // sw x7,8(x0)
        ROM[4] = 32'h40628433; // sub x8,x5,x6
    end

    assign RD = ROM[A[31:2]];
endmodule


module dmem(
    input  logic        clk,
    input  logic        WE,
    input  logic [31:0] A,
    input  logic [31:0] WD,
    output logic [31:0] RD
);
    logic [31:0] RAM [0:31];

    initial begin
        RAM[0] = 32'd100;
        RAM[1] = 32'd50;
    end

    assign RD = RAM[A[31:2]];

    //always_ff @(posedge clk)
        //if (WE)
           // RAM[A[31:2]] <= WD;
endmodule
module top(input logic clk, reset);
    logic [31:0] PC, Instr, MemAddr, WriteData, ReadData;
    logic MemWrite;

    core c(clk, reset, PC, Instr, MemWrite, MemAddr, WriteData, ReadData);
    imem im(PC, Instr);
    dmem dm(clk, MemWrite, MemAddr, WriteData, ReadData);
endmodule
