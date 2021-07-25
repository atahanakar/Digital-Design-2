module ksa(
    input logic CLOCK_50,
    input logic [3:0] KEY,
    input logic [9:0] SW,

    output logic [9:0] LEDR,
    output logic [6:0] HEX0,
    output logic [6:0] HEX1,
    output logic [6:0] HEX2,
    output logic [6:0] HEX3,
    output logic [6:0] HEX4,
    output logic [6:0] HEX5
    );

    // Parameters
    parameter MAX_SIZE_OF_SECRET_KEY = 24'h3FFFFF;

    // Number of Cores -> Multicores
    parameter CORE_NUMBER = 4;

    // Essential wires 
    wire                                rst = ~KEY[3];
    wire                                clk = CLOCK_50;
    wire        [CORE_NUMBER - 1: 0]    cracked;
    wire        [23:0]                  init_secret_key[CORE_NUMBER]; 
	wire        [23:0]                  final_secret_key[CORE_NUMBER];    
	wire        [23:0]                  secret_key;
    logic       [CORE_NUMBER - 1: 0]    failed;
    logic       [CORE_NUMBER - 1: 0]    not_done;
    logic       [7:0]                   q_s             [CORE_NUMBER];
    logic       [7:0]                   q_m             [CORE_NUMBER];
    logic       [CORE_NUMBER - 1: 0]    wren_d;
    logic       [7:0]                   data_d          [CORE_NUMBER];
    logic       [4:0]                   address_d       [CORE_NUMBER];
    logic       [4:0]                   address_m       [CORE_NUMBER];
    logic       [CORE_NUMBER - 1: 0]    wren_s;
    logic       [7:0]                   data_s          [CORE_NUMBER];
    logic       [7:0]                   address_s       [CORE_NUMBER];    

    genvar i;

    generate
        for(i = 0; i < CORE_NUMBER; i = i + 1) begin : FOR_MULTI_CORE

            // ================= MEMORY INTERFACES ====================== //
            // S - RAM
            s_memory s_memory_inst (
                .address (address_s[i]),
                .clock (clk),
                .data (data_s[i]),
                .wren (wren_s[i]),
                .q (q_s[i])
            );
            
            // D - RAM
            d_memory	d_memory_inst (
                .address (address_d[i]),
                .clock (clk),
                .data (data_d[i]),
                .wren (wren_d[i]),
                .q ( )
            );
            
            // E - ROM
            e_rom E_ROM(
                .address(address_m[i]),
                .clock(clk),
                .q(q_m[i])
            );

            // ================= FSM ====================== //
            fsm #(
                .CORE_NUMBER(CORE_NUMBER),
                .CORE_NO(i)
                )
                RC4_CRACK(
                .clk(clk),
                .done(|cracked),
                .rst(rst),
                .secret_key(init_secret_key[i]), 
                .q_s(q_s[i]),               // Coming from Working Memory RAM (S)
                .q_m(q_m[i]),               // Coming from Encrypted Message 32 x 8 ROM 

                // To Decrypted Message 32 x 8 RAM
                .wren_d(wren_d[i]),
                .data_d(data_d[i]),
                .address_d(address_d[i]),

                // To Encrypted Message 32 x 8 ROM
                .address_m(address_m[i]),

                // To Working Memory RAM (S) 256 x 8
                .wren_s(wren_s[i]),
                .data_s(data_s[i]),
                .address_s(address_s[i]), 

                // To DE1-SoC to indicate fail or success flag
                .cracked(cracked[i]),  // LED0
                .failed(failed[i]),    // LED1 
                .not_done(not_done[i]), // LED2
                .final_secret_key(final_secret_key[i])
            );
        end
        
        reg [31:0] j;
        always @ (posedge |cracked) 
            for(j = 0; j < CORE_NUMBER; j = j + 1) begin: FOR_SECRET_KEY
                if(cracked[j])
                    secret_key <= final_secret_key[j];
            end

    endgenerate

    

    // ================= HEX DISPLAY ====================== //
    sseg_controller DISPLAY_HEX0(.in(secret_key[3:0]),   .segs(HEX0));
    sseg_controller DISPLAY_HEX1(.in(secret_key[7:4]),   .segs(HEX1));
    sseg_controller DISPLAY_HEX2(.in(secret_key[11:8]),  .segs(HEX2));
    sseg_controller DISPLAY_HEX3(.in(secret_key[15:12]), .segs(HEX3));
    sseg_controller DISPLAY_HEX4(.in(secret_key[19:16]), .segs(HEX4));
    sseg_controller DISPLAY_HEX5(.in(secret_key[23:20]), .segs(HEX5));

    // ================= LED DISPLAY ====================== //
    assign LEDR[2]   = not_done;
    assign LEDR[1]   = failed;
    assign LEDR[0]   = cracked;

endmodule


