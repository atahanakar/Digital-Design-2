module address_fsm(
        input logic clk, // Clock 22 KHz
        input logic PLAY_BUTTON, // SW 0 
        input logic REVERSE_BUTTON, // SW 1
        input logic RESTART_BUTTON,
        input logic pico_done,
        input logic get_address,
        input logic silent,
        input logic [23:0] start_address,
        input logic [23:0] end_address,
        input logic [31:0] flash_mem_readdata,

        output logic address_ready,
        output logic start_pico,
        output logic [31:0] flash_mem_address,
        output logic [7:0] audio_data
    );

    // Essential wires
    logic           increment_counter;
    logic           done_address;
    logic   [7:0]   fake_audio_data; 

    typedef enum logic [5:0] {  
                INIT               = 6'b101_110,
                READ_FIRST_SAMPLE  = 6'b000_000,
                READ_SECOND_SAMPLE = 6'b001_000,
                READ_THIRD_SAMPLE  = 6'b010_000,
                READ_FOURTH_SAMPLE = 6'b011_011
    } state_logic;

    state_logic         p_state;
    state_logic         n_state;

    assign address_ready     = p_state[0];
    assign increment_counter = p_state[1];
    assign start_pico        = p_state[2];

    initial begin
        n_state = INIT;
    end

    always @ (posedge clk) begin
        p_state <= n_state;
        audio_data <= fake_audio_data;
    end

    always @ (*) begin
        case(p_state)
            INIT: begin
                    if(pico_done == 1'b1) begin
                        flash_mem_address = start_address;
                        n_state = READ_FIRST_SAMPLE;
                    end

                    else
                        n_state = INIT;
            end

            READ_FIRST_SAMPLE: begin
                if(flash_mem_address >= end_address)
                    n_state = INIT;
						  
                else if(get_address && PLAY_BUTTON) begin
                    if(silent == 1'b0)
                        fake_audio_data = REVERSE_BUTTON ? flash_mem_readdata[31:24] : flash_mem_readdata[7:0];
                    else 
                        fake_audio_data = 8'b0;

                    n_state = READ_SECOND_SAMPLE;
                end

                else begin
                    fake_audio_data = 8'b0;
                    n_state = READ_FIRST_SAMPLE;
                end
            end

            READ_SECOND_SAMPLE: begin
                if(silent == 1'b0) 
                    fake_audio_data = REVERSE_BUTTON ? flash_mem_readdata[23:16] : flash_mem_readdata[15:8];
                else 
                    fake_audio_data = 8'b0;
                
                n_state = READ_THIRD_SAMPLE;
            end

            READ_THIRD_SAMPLE: begin
                if(silent == 1'b0) 
                    fake_audio_data = REVERSE_BUTTON ? flash_mem_readdata[15:8] : flash_mem_readdata[23:16];
                else
                    fake_audio_data = 8'b0;
                
                n_state = READ_FOURTH_SAMPLE;
            end

            READ_FOURTH_SAMPLE: begin
                if(silent == 1'b0)
                    fake_audio_data = REVERSE_BUTTON ? flash_mem_readdata[7:0] : flash_mem_readdata[31:24];
                else
                    fake_audio_data = 8'b0;
                flash_mem_address <= flash_mem_address + 1;
                n_state = READ_FIRST_SAMPLE;
            end

            default: n_state = INIT;

        endcase
    end

endmodule