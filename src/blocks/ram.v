module ram(
    input  wire         clk,
    input  wire         rstn,
    input  wire         write_en,
    input  wire [1:0]   mode,        // 00: byte, 01: halfword, 10: word
    input  wire [31:0]  addr,        // byte address
    input  wire [31:0]  write_data,
    output reg  [31:0]  read_data
);
    // 1Mb RAM = 32,768 words (128KB)
    reg [31:0] memory [0:32767];
    integer i;
    always @(posedge clk or negedge rstn) begin
        if(rstn) begin
            for(i = 0; i < 32768; i = i + 1) begin
                memory[i] <= 32'b0;
            end
        end else begin
            read_data <= memory[addr[16:2]];
            case(mode)
                2'b00: begin // byte
                    if(write_en) begin
                        case(addr[1:0])
                            2'b00: memory[addr[16:2]][7:0]   <= write_data[7:0];
                            2'b01: memory[addr[16:2]][15:8]  <= write_data[7:0];
                            2'b10: memory[addr[16:2]][23:16] <= write_data[7:0];
                            2'b11: memory[addr[16:2]][31:24] <= write_data[7:0];
                        endcase
                    end
                end
                2'b01: begin // halfword
                    if(write_en) begin
                        case(addr[1])
                            1'b0: memory[addr[16:2]][15:0]  <= write_data[15:0];
                            1'b1: memory[addr[16:2]][31:16] <= write_data[15:0];
                        endcase
                    end
                end
                2'b10: begin // word
                    if(write_en) begin
                        memory[addr[16:2]] <= write_data;
                    end
                end
                default: begin
                    read_data <= 32'b0;
                end
            endcase
        end
    end


endmodule