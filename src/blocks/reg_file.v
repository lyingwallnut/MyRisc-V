module reg_file(
    input  wire        clk,
    input  wire        rstn,
    input  wire        write_en,
    input  wire [4:0]  write_addr,
    input  wire [31:0] write_data,
    input  wire        rd1_en,
    input  wire [4:0]  rd1_addr,
    input  wire        rd2_en,
    input  wire [4:0]  rd2_addr,
    output wire [31:0] rd1_data,
    output wire [31:0] rd2_data
);
    reg [31:0] registers [0:31];
    integer i;

    // Write operation
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'b0;
            end
        end else if (write_en && write_addr != 5'b00000) begin
            registers[write_addr] <= write_data;
        end
    end

    // Read operation
    assign rd1_data = (rd1_en) ? registers[rd1_addr] : 32'b0;
    assign rd2_data = (rd2_en) ? registers[rd2_addr] : 32'b0;
endmodule