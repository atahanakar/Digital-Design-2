module display_audio_intensity (
        input logic        clk,
        input logic  [7:0] audio_data,
        output logic [7:0] intensity
    );

    // State Names
    typedef enum logic [5:0] { 
        INIT            = 6'b000_000,
        CHECK           = 6'b000_001,
        ADD             = 6'b000_010,
        TAKE_AVERAGE    = 6'b000_011,
        NEG_to_POS      = 6'b000_100,
        LED_DISPLAY     = 6'b000_101
     } state_logic;

    state_logic state;

    // Essential wires
    reg     [8:0]       i;
    reg     [8:0]       j;
    reg     [8:0]       k;
    reg     [31:0]      sum;
    reg     [7:0]       value;
    reg     [7:0]       average;

    initial begin
        state = INIT;
        sum   = 0;
    end

    always_ff @ (posedge clk) begin
        case(state)
            INIT: begin
                i <= 0;
                j <= 0;
                k <= 0;
                sum <= 0;
                state <= CHECK;
		    end
            CHECK: begin 
                if(audio_data[7] == 1) begin                    //means that audio is negative
                    state <= NEG_to_POS;
                    i <= i + 1;
                end

                else begin 
                    value <= audio_data;
                    state <= ADD;
                    i <= i + 1; 
                end
		    end

            NEG_to_POS: begin 
                value <= (audio_data ^ {8{1'b1}}) + 8'b1;       //value is now positive //absolute value
                state <= ADD;
			end

            ADD: begin 	
			sum<=sum+value; //add to sum. 
                if(i == 256)
                    state <= TAKE_AVERAGE;
                else 
                    state <= CHECK;
            end

            TAKE_AVERAGE: begin 
                average <= sum / 256 + sum % 256 ;              // take the average
                state <= LED_DISPLAY;                           //reset them when done
			end 

            LED_DISPLAY: begin 
                casex(average)
                    8'b1xxx_xxxx: intensity <= 8'b1111_1111;    //ALL LEDS OPEN
                    8'b01xx_xxxx: intensity <= 8'b1111_1110;
                    8'b001x_xxxx: intensity <= 8'b1111_1100;
                    8'b0001_xxxx: intensity <= 8'b1111_1000;
                    8'b0000_1xxx: intensity <= 8'b1111_0000;
                    8'b0000_01xx: intensity <= 8'b1110_0000;
                    8'b0000_001x: intensity <= 8'b1100_0000;
                    8'b0000_0001: intensity <= 8'b1000_0000;    //ONE LED OPEN
                    8'b0000_0000: intensity <= 8'b0000_0000;    //NO LEDS ARE OPEN
                endcase

			    state<=INIT;
			end

            default: state <= INIT;

        endcase
    end

endmodule