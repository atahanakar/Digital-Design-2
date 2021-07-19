
module clk_divider_tb;

    logic in_clk, out_clk;
    logic [31:0] freq_in;

    

    clk_divider DUT (
        .in_clk(in_clk),
        .out_clk(out_clk),
        .freq_in(freq_in)
    );


    initial begin 
        in_clk <= 1'b0; #2;
        forever begin
            in_clk = 1'b1;
            #2;
            in_clk = 1'b0;
            #2;
        end
    end


    initial begin
        // Do
        freq_in = 32'd523;
        #10000;

        $stop(0);
    end




endmodule