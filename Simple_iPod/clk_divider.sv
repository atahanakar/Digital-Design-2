module clk_divider #(
    parameter IN_CLOCK_FREQ = 32'd50_000_000
    )   
    (
    input logic in_clk,
    input logic [31:0] out_clk_freq,
    output logic out_clk
    );

    logic [31:0] counter = 0;

    initial begin
        out_clk = 1'b0;
    end

    always_ff @ (posedge in_clk) begin
        counter <= counter + 1;
        if(counter >= (IN_CLOCK_FREQ / out_clk_freq - 1))
            counter <= 0;
        out_clk <= (counter < (IN_CLOCK_FREQ / out_clk_freq) / 2) ? 1'b1 : 1'b0;
    end

endmodule