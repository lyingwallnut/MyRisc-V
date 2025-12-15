module program_counter (
    input  wire         clk,
    input  wire         rstn,
    input  wire [1:0]   pc_src,  // 00: pc+4, 01: pc+offset(JAL/BRANCH), 10: (rs1 + offset) & ~1 (JALR)
    input  wire [31:0]  rs1,
    input  wire [31:0]  offset,
    output reg  [31:0]  pc_cnt
);

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            pc_cnt <= 32'b0;
        end else begin
            case (pc_src)
                2'b00: pc_cnt <= pc_cnt + 4;
                2'b01: pc_cnt <= pc_cnt + offset;
                2'b10: pc_cnt <= (rs1 + offset) & ~32'b1;
                default: pc_cnt <= pc_cnt + 4;
            endcase
        end
    end
endmodule