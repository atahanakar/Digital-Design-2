`default_nettype none
module simple_ipod_solution(

    //////////// CLOCK //////////
    CLOCK_50,

    //////////// LED //////////
    LEDR,

    //////////// KEY //////////
    KEY,

    //////////// SW //////////
    SW,

    //////////// SEG7 //////////
    HEX0,
    HEX1,
    HEX2,
    HEX3,
    HEX4,
    HEX5,

    //////////// Audio //////////
    AUD_ADCDAT,
    AUD_ADCLRCK,
    AUD_BCLK,
    AUD_DACDAT,
    AUD_DACLRCK,
    AUD_XCK,

    //////////// I2C for Audio  //////////
    FPGA_I2C_SCLK,
    FPGA_I2C_SDAT

);

`define zero_pad(width,signal)  {{((width)-$size(signal)){1'b0}},(signal)}
//=======================================================
//  PORT declarations
//=======================================================

//////////// CLOCK //////////
input                       CLOCK_50;

//////////// LED //////////
output           [9:0]      LEDR;

//////////// KEY //////////
input            [3:0]      KEY;

//////////// SW //////////
input            [9:0]      SW;

//////////// SEG7 //////////
output           [6:0]      HEX0;
output           [6:0]      HEX1;
output           [6:0]      HEX2;
output           [6:0]      HEX3;
output           [6:0]      HEX4;
output           [6:0]      HEX5;



//////////// Audio //////////
input                       AUD_ADCDAT;
inout                       AUD_ADCLRCK;
inout                       AUD_BCLK;
output                      AUD_DACDAT;
inout                       AUD_DACLRCK;
output                      AUD_XCK;

//////////// I2C for Audio  //////////
output                      FPGA_I2C_SCLK;
inout                       FPGA_I2C_SDAT;

//=======================================================
//  REG/WIRE declarations
//=======================================================
// Input and output declarations
logic CLK_50M;
logic  [9:0] LED;
assign CLK_50M =  CLOCK_50;
assign LEDR[9:0] = LED[9:0];

wire Clock_1KHz;

//=======================================================================================================================

wire            flash_mem_read;
wire            flash_mem_waitrequest;
wire    [22:0]  flash_mem_address;
wire    [31:0]  flash_mem_readdata;
wire            flash_mem_readdatavalid;
wire    [3:0]   flash_mem_byteenable;
wire	[6:0]	 flash_mem_burstcount;

wire            get_address;
wire            pico_done;
wire            start_pico;
wire            audio_done;
wire 	          start_audio;
wire            silent;
wire            decoded_silent;
wire            start_flash;
wire    [7:0]   audio_data;
wire    [31:0]  out_clk_freq;
wire            Clock_1Hz;
wire            Sync_Clock_1Hz;
wire            Clock_7200Hz;
wire            Sync_Clock_7200Hz;
wire    [23:0]  start_address;
wire    [23:0]  end_address;
wire    [9:0]   encoded_audio_data;
wire    [7:0]   decoded_audio_data;
wire    [7:0]   raw_audio_data;
wire    [7:0]   phoneme_sel;

// ==================================================================== //

// Controlling the speed 
clk_divider #(
        .IN_CLOCK_FREQ(32'd50_000_000)
    ) CLOCK1Hz(
        .in_clk(CLK_50M),
        .out_clk_freq(32'd1),
        .out_clk(Clock_1Hz)
    );

doublesync SYNC_CLOCK1Hz (   
        .indata(Clock_1Hz),
        .outdata(Sync_Clock_1Hz),
        .clk(CLK_50M),
        .reset(1'b1)
    );

// Speed Controller
speed_controller #(
        .INITIAL_CLK_FREQ(32'd7200) // Speed of the clk we are using address fsm
    ) CONTROL_SPEED(
        .clk(Sync_Clock_1Hz),
        .KEYS(KEY[2:0]),
        .out_clk_freq(out_clk_freq)
    );

// Generating the 7.2KHz clk
clk_divider #(
        .IN_CLOCK_FREQ(32'd50_000_000) 
    )
    CLOCK22KHz (
        .in_clk(CLK_50M),
        .out_clk_freq(32'd7200),
        .out_clk(Clock_7200Hz)
    );

doublesync SYNC_CLOCK22KHz (   
        .indata(Clock_7200Hz),
        .outdata(Sync_Clock_7200Hz),
        .clk(CLK_50M),
        .reset(1'b1)
    );

// Audio Controller
audio_player AUDIO (
        .clk(Sync_Clock_7200Hz),
        .faster_clk(CLK_50M),
        .PLAY_BUTTON(SW[0]),
        .flash_mem_readdata(flash_mem_readdata),
        .start_audio(start_audio),
        .silent(silent),
        .audio_done(audio_done),
        .audio_data(raw_audio_data)
      );

// Flash Controller
read_flash FLASH_READER (
        .clk(CLK_50M),
        .flash_mem_read(flash_mem_read),
        .start_flash(start_flash),
        .flash_mem_waitrequest(flash_mem_waitrequest),
        .flash_mem_readdatavalid(flash_mem_readdatavalid),
        .start_audio(start_audio),
        .flash_mem_byteenable(flash_mem_byteenable),
        .flash_mem_burstcount(flash_mem_burstcount)
      );

// Narrator 
narrator_ctrl NARRATOR(
        .clk(CLK_50M),
        .start_address(start_address),
        .end_address(end_address),
        .silent(silent),
        .phoneme_sel(phoneme_sel)
      );

// Flash Memory Address Controller
address_fsm ADDRESS(
        .clk(Sync_Clock_7200Hz),
        .faster_clk(CLK_50M),
        .PLAY_BUTTON(SW[0]),
        .pico_done(pico_done),
        .audio_done(audio_done),
        .start_address(start_address), // 24 bits
        .end_address(end_address),     // 24 bits

        .start_pico(start_pico),
        .start_flash(start_flash),
        .flash_mem_address(flash_mem_address)
    );
        
    assign LED[0] = start_pico;
    assign LED[1] = pico_done;

// Flash Instantiation
flash flash_inst (
        .clk_clk                 (CLK_50M),
        .reset_reset_n           (1'b1),
        .flash_mem_write         (1'b0),
        .flash_mem_burstcount    (flash_mem_burstcount),
        .flash_mem_waitrequest   (flash_mem_waitrequest),
        .flash_mem_read          (flash_mem_read),
        .flash_mem_address       (flash_mem_address),
        .flash_mem_writedata     (32'b0),
        .flash_mem_readdata      (flash_mem_readdata),
        .flash_mem_readdatavalid (flash_mem_readdatavalid),
        .flash_mem_byteenable    (flash_mem_byteenable)
    );

// Displaying speed to HEX
sseg_controller SSEG0(.in(end_address[3:0]),   .segs(HEX0));
sseg_controller SSEG1(.in(end_address[7:4]),   .segs(HEX1));
sseg_controller SSEG2(.in(end_address[11:8]),  .segs(HEX2));
sseg_controller SSEG3(.in(end_address[15:12]), .segs(HEX3));
sseg_controller SSEG5(.in(end_address[19:16]), .segs(HEX4));
sseg_controller SSEG6(.in(end_address[22:20]), .segs(HEX5));

// Picoblaze 
picoblaze_template  #(
                    .clk_freq_in_hz(32'd25_000_000)
                    ) 
            PICO_INST(
                    .clk(CLK_50M),
                    .start_pico(start_pico),
                    .output_data(phoneme_sel), // Going to narrator
                    .pico_done(pico_done)
                    );

//8b to 10b 
encoder_8b10b ENCODE(
      
                    // --- Resets //input
                    .reset(),

                    // --- Clocks //input
                    .SBYTECLK(CLK_50M),
                        
                    // --- Control (K) input   
                    .K(silent),
                        
                    // --- Eight Bt input bus    //input
                    .ebi(raw_audio_data),
                        
                    // --- TB (Ten Bt Interface) output bus
                    .tbi(encoded_audio_data), 

                    .disparity()  //output
                );

 //10b to 8b 
decoder_8b10b DECODE(
      
                    // --- Resets ---
                    .reset(),

                    // --- Clocks ---
                    .RBYTECLK(CLK_50M),
                        
                    // --- TBI (Ten Bit Interface) input bus
                    .tbi(encoded_audio_data),

                    // --- Control (K) //output
                    .K_out(decoded_silent),
                        
                    // -- Eight bit output bus
                    .ebi(decoded_audio_data), 

                    // --- 8B/10B RX coding error --- // output
                    .coding_err(),
                        
                    // --- 8B/10B RX disparity --- //output
                    .disparity(),
                    
                    // --- 8B/10B RX disparity error --- //output
                    .disparity_err()
                );   

assign audio_data = decoded_silent ? 8'b0 : decoded_audio_data;

// Display audio intensity on LEDs
display_audio_intensity DISPLAY_AUDIO(
                    .clk(Sync_Clock_7200Hz),
                    .audio_data(audio_data),
                    .intensity(LED[9:2])
                );

//=======================================================================================================================
//
//   Audio controller code - do not touch
//
//========================================================================================================================
wire [$size(audio_data)-1:0] actual_audio_data_left, actual_audio_data_right;
wire audio_left_clock, audio_right_clock;

to_slow_clk_interface 
interface_actual_audio_data_right
 (.indata(audio_data),
  .outdata(actual_audio_data_right),
  .inclk(CLK_50M),
  .outclk(audio_right_clock));
   
   
to_slow_clk_interface 
interface_actual_audio_data_left
 (.indata(audio_data),
  .outdata(actual_audio_data_left),
  .inclk(CLK_50M),
  .outclk(audio_left_clock));
   

audio_controller 
audio_control(
  // Clock Input (50 MHz)
  .iCLK_50(CLK_50M), // 50 MHz
  .iCLK_28(), // 27 MHz
  //  7-SEG Displays
  // I2C
  .I2C_SDAT(FPGA_I2C_SDAT), // I2C Data
  .oI2C_SCLK(FPGA_I2C_SCLK), // I2C Clock
  // Audio CODEC
  .AUD_ADCLRCK(AUD_ADCLRCK),                    //  Audio CODEC ADC LR Clock
  .iAUD_ADCDAT(AUD_ADCDAT),                 //  Audio CODEC ADC Data
  .AUD_DACLRCK(AUD_DACLRCK),                    //  Audio CODEC DAC LR Clock
  .oAUD_DACDAT(AUD_DACDAT),                 //  Audio CODEC DAC Data
  .AUD_BCLK(AUD_BCLK),                      //  Audio CODEC Bit-Stream Clock
  .oAUD_XCK(AUD_XCK),                       //  Audio CODEC Chip Clock
  .audio_outL({actual_audio_data_left,8'b1}), 
  .audio_outR({actual_audio_data_right,8'b1}),
  .audio_right_clock(audio_right_clock), 
  .audio_left_clock(audio_left_clock)
);

//=======================================================================================================================
//
//   End Audio controller code
//
//========================================================================================================================               
            
endmodule
