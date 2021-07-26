module speed_controller #(
    parameter INITIAL_CLK_FREQ = 32'd22_000
)
(
    input logic clk,
    input logic [2:0] KEYS,

    output logic [31:0] out_clk_freq
);

    initial begin
        out_clk_freq = INITIAL_CLK_FREQ;
    end

    always @ (posedge clk) begin
        case(KEYS)
            3'b110: out_clk_freq = out_clk_freq + 32'd100; 
            3'b101: out_clk_freq = out_clk_freq - 32'd100;
            3'b011: out_clk_freq = INITIAL_CLK_FREQ;
            default: out_clk_freq = out_clk_freq;
        endcase
    end

endmodule