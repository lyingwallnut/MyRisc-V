// An instruction in ID stage may need to access a register
// whose data is being computed in EX of being loaded from memory in MEM
// In case of that, the forwarding unit will forward the data from EX/MEM to ID stage
module forwarding(
    input wire [4:0]  rs1_addr_id,
    input wire [4:0]  rs2_addr_id,
    input wire [4:0]  rd_addr_ex,
    input wire [4:0]  rd_addr_mem,
    input wire        reg_write_en_ex,
    input wire        reg_write_en_mem,

    input wire [31:0] cal_result_ex,
    input wire [31:0] wb_data_mem,

    output reg [31:0] rs1_data_id,
    output reg [31:0] rs2_data_id,
    output reg        rs1_forward_en,
    output reg        rs2_forward_en
);
    wire [1:0] need_forward_rs1;
    wire [1:0] need_forward_rs2;

    wire rs1_match_ex  = reg_write_en_ex  && (rs1_addr_id != 5'd0) && (rd_addr_ex  != 5'd0) && (rs1_addr_id == rd_addr_ex);
    wire rs1_match_mem = reg_write_en_mem && (rs1_addr_id != 5'd0) && (rd_addr_mem != 5'd0) && (rs1_addr_id == rd_addr_mem);
    assign need_forward_rs1 = {rs1_match_mem, rs1_match_ex};

    wire rs2_match_ex  = reg_write_en_ex  && (rs2_addr_id != 5'd0) && (rd_addr_ex  != 5'd0) && (rs2_addr_id == rd_addr_ex);
    wire rs2_match_mem = reg_write_en_mem && (rs2_addr_id != 5'd0) && (rd_addr_mem != 5'd0) && (rs2_addr_id == rd_addr_mem);
    assign need_forward_rs2 = {rs2_match_mem, rs2_match_ex};

    always @(*) begin
        case (need_forward_rs1)
            2'b01: begin rs1_data_id = cal_result_ex; rs1_forward_en = 1'b1; end
            2'b10: begin rs1_data_id = wb_data_mem;   rs1_forward_en = 1'b1; end
            2'b11: begin rs1_data_id = cal_result_ex; rs1_forward_en = 1'b1; end
            default: begin rs1_data_id = 32'b0; rs1_forward_en = 1'b0; end
        endcase
    end

    always @(*) begin
        case (need_forward_rs2)
            2'b01: begin rs2_data_id = cal_result_ex; rs2_forward_en = 1'b1; end
            2'b10: begin rs2_data_id = wb_data_mem;   rs2_forward_en = 1'b1; end
            2'b11: begin rs2_data_id = cal_result_ex; rs2_forward_en = 1'b1; end
            default: begin rs2_data_id = 32'b0; rs2_forward_en = 1'b0; end
        endcase
    end
endmodule