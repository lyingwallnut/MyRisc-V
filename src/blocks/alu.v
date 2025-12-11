module alu(
    input wire [31:0]  opA,
                        opB,
    input wire [3:0]    S,    // select operation mode
    input wire          M,    // logical(0)/arithmetical(1) mode
                        Cin,

    output reg [31:0]  DO,   // data output
    output reg          C,    // carry out
                        V,    // overflow flag
                        N,    // negative flag
                        Z     // zero flag
);
    wire [5:0] control = {S, Cin, M};

    parameter   SET_ZERO = 6'b000010,
                NOR      = 6'b000110,
                NOTAND   = 6'b001010,
                NOT_A    = 6'b001110,
                ANDNOT   = 6'b010010,
                NOT_B    = 6'b010110,
                XOR      = 6'b011010,
                NAND     = 6'b011110,
                AND      = 6'b100010,
                XNOR     = 6'b100110,
                PASS_B   = 6'b101010,
                NOTOR    = 6'b101110,
                PASS_A   = 6'b110010,
                ORNOT    = 6'b110110,
                OR       = 6'b111010,
                SET_ONE  = 6'b111110,
                ADD      = 6'b100101,
                SUB      = 6'b011011;
                
    always @(*) begin
        case(control)
            SET_ZERO: {C,DO} = {1'b0, {n{1'b0}}};
            NOR:      {C,DO} = {1'b0, ~opA & ~opB};
            NOTAND:   {C,DO} = {1'b0, ~opA & opB};
            NOT_A:    {C,DO} = {1'b0, ~opA};
            ANDNOT:   {C,DO} = {1'b0, opA & ~opB};
            NOT_B:    {C,DO} = {1'b0, ~opB};
            XOR:      {C,DO} = {1'b0, opA ^ opB};
            NAND:     {C,DO} = {1'b0, ~(opA & opB)};
            AND:      {C,DO} = {1'b0, opA & opB};
            XNOR:     {C,DO} = {1'b0, ~(opA ^ opB)};
            PASS_B:   {C,DO} = {1'b0, opB};
            NOTOR:    {C,DO} = {1'b0, ~opA | opB};
            PASS_A:   {C,DO} = {1'b0, opA};
            ORNOT:    {C,DO} = {1'b0, opA | ~opB};
            OR:       {C,DO} = {1'b0, opA | opB};
            SET_ONE:  {C,DO} = {1'b0, {n{1'b1}}};
            ADD:      {C,DO} = opA + opB + Cin;
            SUB:      {C,DO} = opA - opB - Cin;
            default:  {C,DO} = {1'b0, {n{1'b0}}};
        endcase
    end

    always @(*) begin
        N = DO[n-1];
        Z = (DO == {n{1'b0}}) ? 1'b1 : 1'b0;
        V = {opA[n-1], opB[n-1], DO[n-1], M} == 4'b0010 || 
            {opA[n-1], opB[n-1], DO[n-1], M} == 4'b1100 ? 1'b1 : 1'b0;
    end


endmodule