
`default_nettype none
 `define USE_PACOBLAZE
module 
picoblaze_template
#(
parameter clk_freq_in_hz = 7200
) (
        input clk,
        input start_pico,
        output [7:0] output_data,
        output pico_done
           );


  
//--
//------------------------------------------------------------------------------------
//--
//-- Signals used to connect KCPSM3 to program ROM and I/O logic
//--

wire[9:0]  address;
wire[17:0]  instruction;
wire[7:0]  port_id;
wire[7:0]  out_port;
reg[7:0]  in_port;
wire  write_strobe;
wire  read_strobe;
reg  interrupt;
wire  interrupt_ack;
wire  kcpsm3_reset;
reg interrupt_locking; //this is added to regulate the interrupt

//--
//-- Signals used to generate interrupt 
//--
reg[26:0] int_count;
reg event_1hz;

//-- Signals for LCD operation
//--
//--

reg        lcd_rw_control;
reg[7:0]   lcd_output_data;
pacoblaze3 led_8seg_kcpsm
(
                  .address(address),
               .instruction(instruction),
                   .port_id(port_id),
              .write_strobe(write_strobe),
                  .out_port(out_port),
               .read_strobe(read_strobe),
                   .in_port(in_port),
                 .interrupt(interrupt),
             .interrupt_ack(interrupt_ack),
                     .reset(kcpsm3_reset),
                       .clk(clk));

 wire [19:0] raw_instruction;
  
  pacoblaze_instruction_memory 
  pacoblaze_instruction_memory_inst(
      .addr(address),
      .outdata(raw_instruction)
  );
  
  always @ (posedge clk)
  begin
        instruction <= raw_instruction[17:0];
  end

    assign kcpsm3_reset = 0;                       
  
//  ----------------------------------------------------------------------------------------------------------------------------------
//  -- Interrupt 
//  ----------------------------------------------------------------------------------------------------------------------------------
//  --
//  --
//  -- Interrupt is used to provide a 1 second time reference.
//  --
//  --
//  -- A simple binary counter is used to divide the 50MHz system clock and provide interrupt pulses.
//  --


// Note that because we are using clock enable we DO NOT need to synchronize with clk

  //always @ (posedge clk)
  //begin
      //--divide 50MHz by 50,000,000 to form 1Hz pulses
  //    if (int_count==(clk_freq_in_hz-1)) //clock enable
  //  begin
   //      int_count <= 0;
    //     event_1hz <= 1;
     // end else
    //begin
     //    int_count <= int_count + 1;
      //   event_1hz <= 0;
      //end
 //end

 always @ (posedge clk or posedge interrupt_ack)  //FF with clock "clk" and reset "interrupt_ack"
 begin
      if (interrupt_ack) //if we get reset, reset interrupt in order to wait for next clock.
            interrupt <= 0;
      else
    begin 
          //if (interrupt_on)   //clock enable
            //    interrupt <= 1;
              //else
                //interrupt <= interrupt;
      //end
 //end
        if(!interrupt_locking) //needed to add bounce back to get into interrupt only once 
        begin
            interrupt <= 1;
            interrupt_locking <= 1;
        end
        else
        begin
            if (interrupt_locking)
            begin
                interrupt <= interrupt;
                interrupt_locking <= 0;
            end
              interrupt <= interrupt;
        end
      end
    end
//  --
//  ----------------------------------------------------------------------------------------------------------------------------------
//  -- KCPSM3 input ports 
//  ----------------------------------------------------------------------------------------------------------------------------------
//  --
//  --
//  -- The inputs connect via a pipelined multiplexer
//  --

 always @ (posedge clk)
 begin
    case (port_id[7:0])
        8'h0:    in_port <= start_pico;
        default: in_port <= 8'bx;
    endcase
end
   
//
//  --
//  ----------------------------------------------------------------------------------------------------------------------------------
//  -- KCPSM3 output ports 
//  ----------------------------------------------------------------------------------------------------------------------------------
//  --
//  -- adding the output registers to the processor
//  --
//   
  always @ (posedge clk)
  begin
        //port 80 hex 
        if (write_strobe & port_id[7])  
          output_data <= out_port;

        //port 40 hex 
        if (write_strobe & port_id[6])  
          pico_done <= out_port;       
    
  end

endmodule
