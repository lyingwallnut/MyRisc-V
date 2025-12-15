// if decoder detects a jump or branch, it sends a signal to the bubble module
// the bubble module will insert two NOP instruction (buble) into the pipeline
// the destination of the jump/branch instruction is unknown until the EX stage down
// which means that the IF and ID stages need to be stalled for two cycles
module bubble(
    input wire         need_bubble_id,
    input wire         need_bubble_ex,
    output wire        bubble_en,
    output wire [31:0] bubble_instrn
);

    assign bubble_en = need_bubble_id | need_bubble_ex;
    assign bubble_instrn = 32'b000000000000_000_000_000_0010011; // NOP instruction (ADDI x0, x0, 0)

endmodule