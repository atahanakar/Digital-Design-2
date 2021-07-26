module read_flash(
    // Inputs
    input logic clk, // Clock 50MHz
    input logic address_ready,
    input logic flash_mem_waitrequest, 
    input logic flash_mem_readdatavalid,

    // Outputs
    output logic flash_mem_read,
    output logic [3:0] flash_mem_byteenable,
    output logic [6:0] flash_mem_burstcount,
    output logic get_address
);  

    // We are not using these signals. ** DEFAULT VALUES ** 
    assign flash_mem_byteenable = 4'b1111;
    assign flash_mem_burstcount = 7'b000_001;

    typedef enum logic [4:0] {

        READ_MEM = 5'b000_01,
        GET_DATA = 5'b001_01,
        DONE     = 5'b001_10

    } state_logic;

    state_logic state;

    // Output Logic 
    assign flash_mem_read = state[0];
    assign get_address    = state[1];

    initial begin
        state = DONE;
    end

    always @ (posedge clk) begin
        case(state)
            
            READ_MEM: begin
                if(~flash_mem_waitrequest)
                    state <= GET_DATA;
                else 
                    state <= READ_MEM; 
            end

            GET_DATA: begin
                if(flash_mem_readdatavalid)
                    state <= DONE;
                else 
                    state <= GET_DATA;
            end

            DONE: begin
                if(address_ready)
                    state <= READ_MEM;
                else
                    state <= DONE;

            end

            default: state <= DONE;
        endcase
    end

endmodule   