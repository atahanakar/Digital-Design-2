module audio_player(
        // Inputs
        input logic clk,                            // Clk 7.2 KHz
        input logic faster_clk,                     // Clk 50M
        input logic [31:0] flash_mem_readdata,      // Comes from Flash
        input logic PLAY_BUTTON,                    // If it is 0 then don't play
        input logic start_audio,                    // Comes from Flash Controller
        input logic silent,                         // Comes from Narrator

        // Outputs
        output logic audio_done,                    // Goes to Address FSM
        output logic [7:0] audio_data               // raw_audio_data, goes to Encoder/Decoder
    );
    // Essential wires
    logic [3:0] samples;

    typedef enum logic [8:0] {       //  876543_210
                IDLE                = 9'b100000_001,
                READ_FIRST_SAMPLE   = 9'b000001_010,
                READ_SECOND_SAMPLE  = 9'b000010_011,
                READ_THIRD_SAMPLE   = 9'b000100_100,
                READ_FOURTH_SAMPLE  = 9'b011000_101
    } state_logic;

    state_logic state;

    // Output Logic
    assign samples       = state[6:3];
    assign audio_done    = state[7];

    always_ff @(posedge clk) begin
        case(state)
            IDLE: begin
                if(start_audio)
                    state <= READ_FIRST_SAMPLE;
                else
                    state <= IDLE;
            end

            READ_FIRST_SAMPLE: state <= READ_SECOND_SAMPLE;

            READ_SECOND_SAMPLE: state <= READ_THIRD_SAMPLE;

            READ_THIRD_SAMPLE: state <= READ_FOURTH_SAMPLE;

            READ_FOURTH_SAMPLE: state <= IDLE;

            default: state <= IDLE;

        endcase
    end

    always_ff @ (posedge faster_clk) begin
        if(silent && ~PLAY_BUTTON)
            audio_data <= 8'b0;
        else
            case (samples)
                4'b0001: audio_data <= flash_mem_readdata[7:0];
                4'b0010: audio_data <= flash_mem_readdata[15:8];
                4'b0100: audio_data <= flash_mem_readdata[23:16];
                4'b1000: audio_data <= flash_mem_readdata[31:24];
                default: audio_data <= 8'b0;
            endcase
    end

endmodule
