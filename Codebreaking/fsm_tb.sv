
module fsm_tb;
    logic                   clk;
    logic                   rst;
	logic       [23:0]      secret_key;
    logic                   cracked;
    logic                   failed;
    logic       [7:0]       q_s;
    logic       [7:0]       q_m;
    logic                   wren_d;
    logic       [7:0]       data_d;
    logic       [4:0]       address_d;
    logic       [4:0]       address_m;
    logic                   wren_s;
    logic       [7:0]       data_s;
    logic       [7:0]       address_s;    

    fsm DUT(
        .clk(clk),
        .rst(rst),
        .secret_key(secret_key), // Coming from Switches
        .q_s(q_s),               // Coming from Working Memory RAM (S)
        .q_m(q_m),               // Coming from Encrypted Message 32 x 8 ROM 

        // To Decrypted Message 32 x 8 RAM
        .wren_d(wren_d),
        .data_d(data_d),
        .address_d(address_d),

        // To Encrypted Message 32 x 8 ROM
        .address_m(address_m),

        // To Working Memory RAM (S) 256 x 8
        .wren_s(wren_s),
        .data_s(data_s),
        .address_s(address_s), 

        // To DE1-SoC to indicate fail or success flag
        .cracked(cracked), // LED0
        .failed(failed)   // LED1 
    );

    initial begin
        clk = 1;
        #2;
        forever begin
            clk = 0;
            #2;
            clk = 1;
            #2;
        end
    end

    initial begin
        secret_key = 24'h000249;
        #14000;

        $stop(0);
    end
endmodule