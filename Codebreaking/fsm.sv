module fsm #(
    parameter CORE_NUMBER = 4,
    parameter CORE_NO = 2
    )
    (
    input logic clk,
    input logic [31:0] core_no,
    input logic done,
    input logic rst,
    input logic [7:0] q_s,         // Coming from Working Memory RAM (S)
    input logic [7:0] q_m,         // Coming from Encrypted Message 32 x 8 ROM 

    // To Decrypted Message 32 x 8 RAM
    output logic wren_d,
    output logic [7:0] data_d,
    output logic [4:0] address_d,

    // To Encrypted Message 32 x 8 ROM
    output logic [4:0] address_m,

    // To Working Memory RAM (S) 256 x 8
    output logic wren_s,
    output logic [23:0] secret_key,
    output logic [7:0] data_s,
    output logic [7:0] address_s, 

    // To DE1-SoC to indicate fail or success flag
    output logic cracked,  // LED0
    output logic failed,   // LED1
    output logic not_done, // LED2
    output logic [23:0] final_secret_key
    );  

    // Parameters
    parameter             MESSAGE_LENGTH = 32;
    parameter             KEY_LENGTH     = 3;
    parameter             MAX_SIZE_OF_SECRET_KEY = 24'h3FFFFF;

    // Essential wires
    reg       [8:0]       i, j, k;
	reg       [7:0]       key;
    reg       [7:0]       temp_si, temp_sj;

    // Struct state_logic
    typedef enum logic [10:0] {
        INIT                = 11'b0_0_0_0_0_000000,
        INIT_S              = 11'b0_0_0_0_1_000001,
        SHUFFLE_S_1         = 11'b0_0_0_0_0_000010,
        SHUFFLE_S_2         = 11'b0_0_0_0_0_000011,
        SHUFFLE_S_3         = 11'b0_0_0_0_0_000100,
        SHUFFLE_S_4         = 11'b0_0_0_0_0_000101,
        SHUFFLE_S_5         = 11'b0_0_0_0_0_000111, 
        SHUFFLE_S_6         = 11'b0_0_0_0_0_001000,
        SHUFFLE_S_7         = 11'b0_0_0_0_0_001001,
        SHUFFLE_S_8         = 11'b0_0_0_0_1_001010,
        SHUFFLE_S_9         = 11'b0_0_0_0_0_001011,
        SHUFFLE_S_10        = 11'b0_0_0_0_1_001100,
        COMPUTE_ONE_BYTE_1  = 11'b0_0_0_0_0_001101,
        COMPUTE_ONE_BYTE_2  = 11'b0_0_0_0_0_001110,
        COMPUTE_ONE_BYTE_3  = 11'b0_0_0_0_0_001111,
        COMPUTE_ONE_BYTE_4  = 11'b0_0_0_0_0_010000,
        COMPUTE_ONE_BYTE_5  = 11'b0_0_0_0_0_010001,
        COMPUTE_ONE_BYTE_6  = 11'b0_0_0_0_0_010010,
        COMPUTE_ONE_BYTE_7  = 11'b0_0_0_0_0_010011,
        COMPUTE_ONE_BYTE_8  = 11'b0_0_0_0_1_010100,
        COMPUTE_ONE_BYTE_9  = 11'b0_0_0_0_0_010101,
        COMPUTE_ONE_BYTE_10 = 11'b0_0_0_0_1_010110,
        COMPUTE_ONE_BYTE_11 = 11'b0_0_0_0_0_010111,
        COMPUTE_ONE_BYTE_12 = 11'b0_0_0_0_0_011000,
        COMPUTE_ONE_BYTE_13 = 11'b0_0_0_0_0_011001,
        COMPUTE_ONE_BYTE_14 = 11'b0_0_0_1_0_011010,
        CRACK_RC_1          = 11'b0_0_0_0_0_011011,
        CRACK_RC_2          = 11'b0_0_0_0_0_011100,
        FAILED              = 11'b0_1_1_0_0_111110,        
        DONE                = 11'b1_0_1_0_0_111111
    } state_logic;

    state_logic state;

    assign      wren_s         = state[6];
    assign      wren_d         = state[7];
    assign      not_done       = ~state[8];
    assign      failed         = state[9];
    assign      cracked        = state[10];

    initial begin
        state = INIT;
        secret_key = CORE_NO * MAX_SIZE_OF_SECRET_KEY / CORE_NUMBER;
    end

    always_ff @ (posedge clk or posedge rst) begin
        if(rst) begin
            secret_key = CORE_NO * MAX_SIZE_OF_SECRET_KEY / CORE_NUMBER;
            state <= INIT;
        end

        else if(!done)
            case(state)
                // Initializing i, j, and k
                INIT: begin
                    i <= 0;
                    j <= 0;
                    k <= 0;
                    state <= INIT_S;
                end

                // Task 1: Initialize s array.
                INIT_S: begin
                    if(i <= 255) begin
                        address_s <= i;
                        data_s <= i;
                        i <= i + 1;
                        state <= INIT_S;
                    end

                    else begin
                        i <= 0;
                        j <= 0;
                        state <= SHUFFLE_S_1;
                    end
                end

                // Task 2

                //      Shuffling arrays 2 - a
                SHUFFLE_S_1: begin
                    address_s <= i;
                    case(i % KEY_LENGTH)
                        2: key <= secret_key[7:0];
                        1: key <= secret_key[15:8];
                        0: key <= secret_key[23:16];
                        default: key <= {8{1'bx}};
                    endcase
                    state <= SHUFFLE_S_2;
                end

                SHUFFLE_S_2: begin
                    state <= SHUFFLE_S_3;
                end

                SHUFFLE_S_3: begin
                    temp_si <= q_s;             // temp_si = s[i]
                    j <= (j + q_s + key) % 256;
                    state <= SHUFFLE_S_4;
                end

                SHUFFLE_S_4: begin
                    address_s <= j;
                    state <= SHUFFLE_S_5;
                end

                SHUFFLE_S_5: begin
                    state <= SHUFFLE_S_6;
                end

                SHUFFLE_S_6: begin
                    temp_sj   <= q_s;
                    state <= SHUFFLE_S_7;
                end

                SHUFFLE_S_7: begin
                    address_s <= j;         // s[j] = s[i];
                    data_s    <= temp_si;
                    state <= SHUFFLE_S_8;
                end

                SHUFFLE_S_8: begin
                    state <= SHUFFLE_S_9;
                end

                SHUFFLE_S_9: begin
                    address_s <= i;         // s[i] = s[j];
                    data_s    <= temp_sj;
                    state <= SHUFFLE_S_10;
                end

                SHUFFLE_S_10: begin
                    if(i < 255) begin
                        i <= i + 1;
                        state <= SHUFFLE_S_1;
                    end
                    else begin
                        i <= 1;
                        j <= 0;
                        k <= 0;
                        state <= COMPUTE_ONE_BYTE_1;
                    end
                end

                //      Computing One Byte 2 - b
                COMPUTE_ONE_BYTE_1: begin
                    address_s <= i;
                    state <= COMPUTE_ONE_BYTE_2;
                end

                COMPUTE_ONE_BYTE_2: begin
                    state <= COMPUTE_ONE_BYTE_3;
                end

                COMPUTE_ONE_BYTE_3: begin
                    j <= j + q_s;
                    temp_si <= q_s;             // temp_si = s[i]
                    state <= COMPUTE_ONE_BYTE_4;
                end

                COMPUTE_ONE_BYTE_4: begin
                    address_s <= j;                  
                    state <= COMPUTE_ONE_BYTE_5;
                end

                COMPUTE_ONE_BYTE_5: begin       
                    state <= COMPUTE_ONE_BYTE_6;
                end

                COMPUTE_ONE_BYTE_6: begin  
                    temp_sj <= q_s;     
                    state <= COMPUTE_ONE_BYTE_7;
                end

                COMPUTE_ONE_BYTE_7: begin      
                    address_s <= j;
                    data_s <= temp_si;          // s[j] = s[i];
                    state <= COMPUTE_ONE_BYTE_8;
                end

                COMPUTE_ONE_BYTE_8: begin       // Write here s **
                    state <= COMPUTE_ONE_BYTE_9;
                end

                COMPUTE_ONE_BYTE_9: begin      
                    address_s <= i;
                    data_s <= temp_sj;          // // s[j] = s[i];
                    state <= COMPUTE_ONE_BYTE_10;
                end

                COMPUTE_ONE_BYTE_10: begin       // Write here s **
                    state <= COMPUTE_ONE_BYTE_11;
                end

                COMPUTE_ONE_BYTE_11: begin
                    address_s <= temp_sj + temp_si;
                    address_m <= k;
                    state <= COMPUTE_ONE_BYTE_12;
                end 

                COMPUTE_ONE_BYTE_12: begin
                    state <= COMPUTE_ONE_BYTE_13;
                end

                COMPUTE_ONE_BYTE_13: begin
                    address_d <= k;
                    data_d <= q_s ^ q_m;        // d[k] = f ^ e[k]
                    state <= COMPUTE_ONE_BYTE_14;
                end

                COMPUTE_ONE_BYTE_14: begin      // Write here m **
                    if(k < MESSAGE_LENGTH - 1) begin
                        state <= CRACK_RC_1;
                    end
                    else begin
                        state <= DONE;
                    end
                end

                // Cracking RC
                CRACK_RC_1: begin
                    if((data_d <= 8'd122 && data_d >= 8'd97) || data_d == 8'd32) begin
                        k <= k + 1;
                        i <= i + 1;
                        state <= COMPUTE_ONE_BYTE_1;
                    end

                    else
                        state <= CRACK_RC_2;

                end

                CRACK_RC_2: begin
                    if(secret_key < MAX_SIZE_OF_SECRET_KEY) begin
                        secret_key <= secret_key + 22'b1;
                        state <= INIT;
                    end

                    else 
                        state <= FAILED;

                end

                // End
                DONE: begin
                    final_secret_key <= secret_key;
                    state <= DONE;
                end

                FAILED: begin
                    state <= FAILED;
                end

                default: state <= INIT;

            endcase

        else begin
            state <= DONE;
        end
            
    end

endmodule