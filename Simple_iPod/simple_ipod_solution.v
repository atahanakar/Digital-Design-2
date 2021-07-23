`default_nettype none
module simple_ipod_solution(

    //////////// CLOCK //////////
    CLOCK_50,
    TD_CLK27,

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
    FPGA_I2C_SDAT,
    
    
    //////// PS2 //////////
    PS2_CLK,
    PS2_DAT,
    
    //////// SDRAM //////////
    DRAM_ADDR,
    DRAM_BA,
    DRAM_CAS_N,
    DRAM_CKE,
    DRAM_CLK,
    DRAM_CS_N,
    DRAM_DQ,
    DRAM_LDQM,
    DRAM_UDQM,
    DRAM_RAS_N,
    DRAM_WE_N,
    
    //////// GPIO //////////
    GPIO_0,
    GPIO_1
    
);
`define zero_pad(width,signal)  {{((width)-$size(signal)){1'b0}},(signal)}
//=======================================================
//  PORT declarations
//=======================================================

//////////// CLOCK //////////
input                       CLOCK_50;
input                       TD_CLK27;

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

//////////// PS2 //////////
inout                       PS2_CLK;
inout                       PS2_DAT;

//////////// GPIO //////////
inout           [35:0]      GPIO_0;
inout           [35:0]      GPIO_1;
                
                
//////////// SDRAM //////////
output          [12:0]      DRAM_ADDR;
output          [1:0]       DRAM_BA;
output                      DRAM_CAS_N;
output                      DRAM_CKE;
output                      DRAM_CLK;
output                      DRAM_CS_N;
inout           [15:0]      DRAM_DQ;
output                      DRAM_LDQM;
output                      DRAM_UDQM;
output                      DRAM_RAS_N;
output                      DRAM_WE_N;


//=======================================================
//  REG/WIRE declarations
//=======================================================
// Input and output declarations
logic CLK_50M;
logic  [9:0] LED;
assign CLK_50M =  CLOCK_50;
assign LEDR[9:0] = LED[9:0];

wire Clock_1KHz, Clock_1Hz;

//=======================================================================================================================

wire            flash_mem_read;
wire            flash_mem_waitrequest;
wire    [22:0]  flash_mem_address;
wire    [31:0]  flash_mem_readdata;
wire            flash_mem_readdatavalid;
wire    [3:0]   flash_mem_byteenable;
wire	[6:0]	 flash_mem_burstcount;

wire            get_address;
wire            address_ready;
wire            Clock_22KHz;
wire            Sync_Clock_22KHz;
wire    [7:0]   audio_data;
wire    [31:0]  out_clk_freq;
wire            speed_up_raw;
wire            speed_down_raw;
wire            speed_up_event;
wire            speed_down_event;
wire            speed_reset_event;
wire            speed_up_event_trigger;
wire            speed_down_event_trigger; 
wire            Sync_Clock_1Hz;

// ==================================================================== //

// Reading Flash Memory 
read_flash FLASH_READ (
    .clk(CLK_50M),
    .address_ready(address_ready),
    .flash_mem_waitrequest(flash_mem_waitrequest),
    .flash_mem_readdatavalid(flash_mem_readdatavalid),
    .flash_mem_read(flash_mem_read),
    .flash_mem_byteenable(flash_mem_byteenable),
    .flash_mem_burstcount(flash_mem_burstcount),
    .get_address(get_address)
);

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

speed_controller #(
        .INITIAL_CLK_FREQ(32'd22_000)
    ) CONTROL_SPEED(
        .clk(Sync_Clock_1Hz),
        .KEYS(KEY[2:0]),
        .out_clk_freq(out_clk_freq)
    );

// Generating the 22KHz clk
clk_divider #(
        .IN_CLOCK_FREQ(32'd27_000_000)
    )
    CLOCK22KHz (
        .in_clk(TD_CLK27),
        .out_clk_freq(out_clk_freq),
        .out_clk(Clock_22KHz)
    );

doublesync SYNC_CLOCK22KHz (   
        .indata(Clock_22KHz),
        .outdata(Sync_Clock_22KHz),
        .clk(CLK_50M),
        .reset(1'b1)
    );

// Getting the address of the sample
address_fsm ADDRESS_CONTROLLER(
        .clk(Sync_Clock_22KHz),
        .flash_mem_address(flash_mem_address),
        .flash_mem_readdata(flash_mem_readdata),
        .audio_data(audio_data),
        .get_address(get_address),
        .address_ready(address_ready),
        .PLAY_BUTTON(SW[0]),  // Up = Play, Down = Pause
        .REVERSE_BUTTON(SW[1]),
		.RESTART_BUTTON(SW[2])
    );

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
sseg_controller SSEG0(.in(flash_mem_address[3:0]),   .segs(HEX0));
sseg_controller SSEG1(.in(flash_mem_address[7:4]),   .segs(HEX1));
sseg_controller SSEG2(.in(flash_mem_address[11:8]),  .segs(HEX2));
sseg_controller SSEG3(.in(flash_mem_address[15:12]), .segs(HEX3));
sseg_controller SSEG5(.in(flash_mem_address[19:16]), .segs(HEX4));
sseg_controller SSEG6(.in(flash_mem_address[22:20]), .segs(HEX5));

// Picoblaze 
picoblaze_template    #(
                            .clk_freq_in_hz(25000000)
                            ) 
                    PICO_INST(
                            .clk(CLK_50M),
                            .input_data(audio_data),
                            .UPPER_LEDS(LED[9:2]),
                            .LED0(LED[0]),
                            .interrupt(address_ready)
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
