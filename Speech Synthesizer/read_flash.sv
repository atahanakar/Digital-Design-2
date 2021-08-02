module read_flash(
    // Inputs
    input logic clk,                    // Clock 50MHz
    input logic start_flash,            // start_flash from address_fsm
    input logic flash_mem_waitrequest,
    input logic flash_mem_readdatavalid,

    // Outputs
    output logic flash_mem_read,
    output logic [3:0] flash_mem_byteenable,
    output logic [6:0] flash_mem_burstcount,
    output logic start_audio            // Goes to the audio_player
);

    // We are not using these signals. ** DEFAULT VALUES **
    assign flash_mem_byteenable = 4'b1111;
    assign flash_mem_burstcount = 7'b000_001;

    typedef enum logic [4:0] {
        IDLE     = 5'b001_10,
        READ_MEM = 5'b000_01,
        GET_DATA = 5'b001_01
    } state_logic;

    state_logic state;

    // Output Logic
    assign flash_mem_read = state[0];
    assign start_audio    = state[1];

    initial begin
        state = IDLE;
    end

    always_ff @ (posedge clk) begin
        case(state)
            IDLE: begin
                if(start_flash)
                    state <= READ_MEM;
                else
                    state <= IDLE;
            end

            READ_MEM: begin
                if(~flash_mem_waitrequest)
                    state <= GET_DATA;
                else
                    state <= READ_MEM;
            end

            GET_DATA: begin
                if(flash_mem_readdatavalid)
                    state <= IDLE;
                else
                    state <= GET_DATA;
            end

            default: state <= IDLE;

        endcase
    end

endmodule
