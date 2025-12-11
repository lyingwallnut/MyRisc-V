module barrel_shifter (
    input  wire [31:0] data_in,
    input  wire [2:0]  shift_op,
    // 000: data_in
    // 001: LSR
    // 010: LSL
    // 011: ROR
    // 100: ASR
    // 101: ASL
    // 110: x
    // 111: x
    input  wire [4:0]  shift_cnt,
    output wire [31:0] data_out
);

    wire [31:0] lsr, lsl, ror, asr, asl;

    // Logical shift right
    assign lsr = data_in >> shift_cnt;

    // Logical shift left
    assign lsl = data_in << shift_cnt;

    // Rotate right
    assign ror = ((data_in >> shift_cnt) | (data_in << (6'd32 - shift_cnt)));

    // Arithmetic shift right
    assign asr = $signed(data_in) >>> shift_cnt;

    // Arithmetic shift left (same as logical shift left)
    assign asl = lsl;

    assign data_out = (shift_op == 3'b000) ? data_in :
                      (shift_op == 3'b001) ? lsr     :
                      (shift_op == 3'b010) ? lsl     :
                      (shift_op == 3'b011) ? ror     :
                      (shift_op == 3'b100) ? asr     :
                      (shift_op == 3'b101) ? asl     :
                                             32'bx;

endmodule

