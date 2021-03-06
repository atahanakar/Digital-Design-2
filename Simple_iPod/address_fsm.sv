module address_fsm(
        input logic clk, // Clock 22 KHz
        input logic PLAY_BUTTON, // SW 0 
        input logic REVERSE_BUTTON, // SW 1
        input logic RESTART_BUTTON,
        input logic get_address,
        input logic [31:0] flash_mem_readdata,

        output logic address_ready,
        output logic [31:0] flash_mem_address,
        output logic [7:0] audio_data
    );

    // Parameters: Address Width
    parameter START_ADDRESS = 32'h000000;
    parameter END_ADDRESS   = 32'h07FFFF;

    // Essential wires
    logic increment_counter;

    typedef enum logic [4:0] {  
        READ_FIRST_SAMPLE  = 5'b000_00,
        READ_SECOND_SAMPLE = 5'b001_11
    } state_logic;

    state_logic state;

    assign address_ready = state[0];
    assign increment_counter = state[1];

    initial begin
        state = READ_FIRST_SAMPLE;
    end

    always @ (posedge clk) begin
        case (state)
            READ_FIRST_SAMPLE: begin
                if(get_address && PLAY_BUTTON) begin
                    audio_data <= REVERSE_BUTTON ? flash_mem_readdata[31:24] : flash_mem_readdata[7:0];
                    state <= READ_SECOND_SAMPLE;
                end

                else begin
                    audio_data <= 8'b0;
                    state <= READ_FIRST_SAMPLE;
                end
            end

            READ_SECOND_SAMPLE: begin
                audio_data <= REVERSE_BUTTON ? flash_mem_readdata[7:0] : flash_mem_readdata[31:24];
                state <= READ_FIRST_SAMPLE;
            end

            default: state <= READ_FIRST_SAMPLE;
        endcase
    end

    always @ (posedge increment_counter) begin
        if(RESTART_BUTTON == 1'b1)
            flash_mem_address <= START_ADDRESS;
            
        else if(REVERSE_BUTTON == 1'b0) begin
            if(flash_mem_address < END_ADDRESS)
                flash_mem_address <= flash_mem_address + 32'b1;

            else if(flash_mem_address == END_ADDRESS)
                flash_mem_address <= START_ADDRESS;
        end

        else if(REVERSE_BUTTON == 1'b1) begin
            if(flash_mem_address > START_ADDRESS)
                flash_mem_address <= flash_mem_address - 32'b1;

            else if(flash_mem_address == START_ADDRESS)
                flash_mem_address <= END_ADDRESS;
        end
                
    end 

endmodule