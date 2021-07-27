module address_fsm(
        input logic clk,            // Clock 7.2 KHz
        input logic pico_done,
        input logic audio_done,
        input logic [23:0] start_address,
        input logic [23:0] end_address,

        output logic start_flash,
        output logic start_pico,
        output logic [31:0] flash_mem_address
    );

    // Essential wires
    logic increment_counter;
    logic assign_init_address;

    typedef enum logic [6:0] {
        IDLE              = 7'b1000_000,
        INIT_ADDRESS      = 7'b0001_000,
        WAIT_FOR_AUDIO    = 7'b0100_010,
        INCREMENT_ADDRESS = 7'b0010_000
    } state_logic;

    state_logic state;

    assign assign_init_address = state[3];
    assign increment_counter   = state[4];
    assign start_flash         = state[5];
    assign start_pico          = state[6];


    always_ff @ (posedge clk or posedge pico_done or posedge audio_done) begin
        case (state)
            IDLE: begin
                if(pico_done == 1)
                    state <= INIT_ADDRESS;
                else
                    state <= IDLE;
            end

            INIT_ADDRESS: state <= WAIT_FOR_AUDIO;

            WAIT_FOR_AUDIO: begin
                if (flash_mem_address >= end_address)
                    state <= IDLE;
                else if(audio_done)
                    state <= INCREMENT_ADDRESS;
                else
                    state <= WAIT_FOR_AUDIO;
            end

            INCREMENT_ADDRESS: state <= WAIT_FOR_AUDIO;

            default: state <= IDLE;

        endcase
    end

    always_ff @ (posedge clk) begin
        if(assign_init_address == 1)
            flash_mem_address <= start_address;

        if(increment_counter == 1)
            flash_mem_address <= flash_mem_address + 1;
    end

endmodule
