// An instruction in ID stage to be excuted may depend on a load instruction in EX stage
// In that case, the IF and ID need to be froze for one cycle
// and the instruction in EX stage need to be flushed (replaced with NOP)
module froze(
    input  wire        ex_is_load,
    input  wire [4:0]  rd_addr_ex,
    input  wire [4:0]  rs1_addr_id,
    input  wire [4:0]  rs2_addr_id,

    output wire        froze_if,
    output wire        froze_id,
    output wire        flush_en,
    output wire [31:0] nop_instr
);
    wire need_froze = ex_is_load && (rd_addr_ex != 5'd0) &&
                       ((rd_addr_ex == rs1_addr_id) || (rd_addr_ex == rs2_addr_id));

    assign froze_if   = need_froze;
    assign froze_id   = need_froze;
    assign flush_en = need_froze;
    assign nop_instr = 32'h00000013;
endmodule