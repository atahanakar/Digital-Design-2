module address_fsm(
        input logic clk,            // Clock
        input logic faster_clk,     // Faster clk
        input logic pico_done,
        input logic PLAY_BUTTON,    // SW[0]
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
        INIT_ADDRESS      = 7'b0101_001,
        WAIT_FOR_AUDIO    = 7'b0000_010,
        CHECK_PLAY_BUTTON = 7'b0000_011,
        INCREMENT_ADDRESS = 7'b0110_100
    } state_logic;

    state_logic state;

    assign assign_init_address = state[3];
    assign increment_counter   = state[4];
    assign start_flash         = state[5];
    assign start_pico          = state[6];

    always_ff @ (posedge clk or posedge pico_done or posedge audio_done) begin
          case (state)
              IDLE: begin                               // Start the picoblaze and wait for pico_done signal
                  if(pico_done == 1 && PLAY_BUTTON == 1)
                      state <= INIT_ADDRESS;
                  else
                      state <= IDLE;
              end

              INIT_ADDRESS: state <= CHECK_PLAY_BUTTON;    // Assign the initial value of the flash_mem_address to start_address coming from the narrotor_ctrl block

              CHECK_PLAY_BUTTON: begin                  // Checks Play Button if it is 1 then start flash controller
                  if(PLAY_BUTTON == 1)
                    state <= WAIT_FOR_AUDIO;
                  else
                    state <= CHECK_PLAY_BUTTON;
              end

              WAIT_FOR_AUDIO: begin                      // Start Flash Read here with the new address
                  if (flash_mem_address >= end_address)
                      state <= IDLE;
                  else if(audio_done)
                      state <= INCREMENT_ADDRESS;
                  else
                      state <= CHECK_PLAY_BUTTON;
              end

              INCREMENT_ADDRESS: state <= CHECK_PLAY_BUTTON; // Increment the Address only if audio is done

              default: state <= IDLE;

          endcase
    end

    always_ff @ (posedge faster_clk) begin
        if(assign_init_address == 1)
            flash_mem_address <= start_address;

        if(increment_counter == 1)
            if(PLAY_BUTTON == 1)
                flash_mem_address <= flash_mem_address + 4;
    end

endmodule
