module rom(
    input  wire [31:0] pc_cnt,
    output reg  [31:0] data
);
    // Simple ROM with 1024 words (4KB)
    reg [31:0] memory [0:1023];

    initial begin
        memory[0] = 32'h00000013;
        memory[1] = 32'h00000013;
        memory[2] = 32'h00000013;
    end

    always @(*) begin
        data = memory[pc_cnt[11:2]]; // 10-bit index for 1024 words
    end
endmodule