module notes(
        input logic [2:0] switches,
        output logic [31:0] notes
    );

    parameter DO = 523; 
    parameter RE = 587;
    parameter MI = 659;
    parameter FA = 698;
    parameter SOL = 783;
    parameter LA = 880;
    parameter SI = 987;
    parameter DO2 = 1046;

    always @ ( * ) begin
        case(switches)
            3'b000: notes = DO;
            3'b001: notes = RE;
            3'b010: notes = MI;
            3'b011: notes = FA;
            3'b100: notes = SOL;
            3'b101: notes = LA;
            3'b110: notes = SI;
            3'b111: notes = DO2;
            default: notes = 0;
        endcase
    end

endmodule