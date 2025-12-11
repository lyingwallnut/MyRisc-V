module program_counter (
    input  wire         clk,
    input  wire         rstn,
    input  wire         branch_en,
    input  wire [31:0]  branch_addr,
    output reg  [31:0]  pc_cnt
);

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            pc_cnt <= 32'b0;
        end else if (branch_en) begin
            pc_cnt <= branch_addr;
        end else begin
            pc_cnt <= pc_cnt + 32'd4;
        end
    end
endmodule