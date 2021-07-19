module clk_divider(
    input logic in_clk,
    input logic[31:0] freq_in,

    output logic out_clk
);
    // Frequency of the DE1-SoC clk 
    parameter CONSTANT_CLK = 32'd50_000_000; 

    logic [31:0] counter = 0;

    initial begin
        out_clk = 1'b0;
    end

    always_ff @ (posedge in_clk) begin
        counter <= counter + 1;
        if(counter >= (CONSTANT_CLK / freq_in - 1))
            counter <= 0;
        out_clk <= (counter < (CONSTANT_CLK / freq_in) / 2) ? 1'b1 : 1'b0;
    end

endmodule