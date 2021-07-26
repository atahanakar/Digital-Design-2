module sseg_controller(
  // INPUT
  input logic [3:0] in,
  
  //OUTPUT
  output logic [6:0] segs
  );

  always@ (*) begin 
    case(in)
      4'b0000: segs = 7'b1000_000;		//0
      4'b0001: segs = 7'b1111_001;		//1
      4'b0010: segs = 7'b0100_100;		//2
      4'b0011: segs = 7'b0110_000;		//3
      4'b0100: segs = 7'b0011_001;		//4
      4'b0101: segs = 7'b0010_010;		//5
      4'b0110: segs = 7'b0000_010;		//6
      4'b0111: segs = 7'b1111_000;		//7
      4'b1000: segs = 7'b0000_000;		//8
      4'b1001: segs = 7'b0010_000;		//9
      4'b1010: segs = 7'b0001_000;		//10 = A
      4'b1011: segs = 7'b0000_011;		//11 = b
      4'b1100: segs = 7'b1000_110;		//12 = C
      4'b1101: segs = 7'b0100_001;		//13 = d
      4'b1110: segs = 7'b0000_110;		//14 = E
      4'b1111: segs = 7'b0001_110;		//15 = F
      default: segs = 7'bxxxx_xxx;
    endcase
  end

endmodule