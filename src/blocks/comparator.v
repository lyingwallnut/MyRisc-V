module comparator(
    input  wire [31:0] A,
    input  wire [31:0] B,
    input  wire [2:0]  mode,   // 000: LT, 001: LTU, 010: GE, 011: GEU, 100: EQ, 101: NEQ
    output reg         result  // single boolean output
);

    localparam LT  = 3'b000;
    localparam LTU = 3'b001;
    localparam GE  = 3'b010;
    localparam GEU = 3'b011;
    localparam EQ  = 3'b100;
    localparam NEQ = 3'b101;

    wire lt_signed   = ($signed(A) < $signed(B));
    wire ge_signed   = ($signed(A) >= $signed(B));
    wire lt_unsigned = (A < B);
    wire ge_unsigned = (A >= B);
    wire eq          = (A == B);

    always @(*) begin
        case (mode)
            LT:   result = lt_signed;
            LTU:  result = lt_unsigned;
            GE:   result = ge_signed;
            GEU:  result = ge_unsigned;
            EQ:   result = eq;
            NEQ:  result = ~eq;
            default:  result = 1'b0;
        endcase
    end
endmodule