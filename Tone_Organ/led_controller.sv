module led_controller(
    input logic clk,
    output logic [7:0] leds
    );

    logic flag = 1;

    initial begin
        leds = 8'b0000_0001;
    end

    always_ff @ (posedge clk) begin
        if(flag)
            if (leds[7] == 1) begin
                flag <= 0;
                leds <= leds / 2;
			end
            
            else
                leds <= leds * 2;
        else
            if(leds[0] == 1) begin
                flag <= 1;
                leds <= leds * 2;
			end

            else 
                leds <= leds / 2;
    end


endmodule