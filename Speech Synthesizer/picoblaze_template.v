
`default_nettype none
 `define USE_PACOBLAZE
module picoblaze_template
      #(
        parameter clk_freq_in_hz = 7200
      ) (
        input             clk,
        input             start_pico,
        output reg [7:0]  output_data,
        output reg        pico_done
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
  

 always @ (posedge clk or posedge interrupt_ack)  //FF with clock "clk" and reset "interrupt_ack"
 begin
      if (interrupt_ack) //if we get reset, reset interrupt in order to wait for next clock.
            interrupt <= 0;
      else
    begin 

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
        if (write_strobe & port_id[7])  //clock enable 
          output_data <= out_port; //pico_done


        //port 40 hex 
        if (write_strobe & port_id[6])  //clock enable 
          pico_done <= out_port;       //port number 40 is used for pico_done
  
            
  end

endmodule
