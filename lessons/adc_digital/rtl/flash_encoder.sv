`timescale 1ns/1ps
// AD03: therm[0] is the lowest threshold. Limited three-point bubble filter.
module flash_encoder(input wire [15:0] therm,
    output reg [4:0] code, output reg invalid, corrected);
    reg [15:0] filtered;
    reg seen_zero;
    integer i;
    always @* begin
        filtered=therm;
        for (i=1;i<15;i=i+1)
            filtered[i]=(therm[i-1]&therm[i]) | (therm[i]&therm[i+1]) |
                        (therm[i-1]&therm[i+1]);
        code=0; invalid=0; seen_zero=0; corrected=(filtered!=therm);
        for (i=0;i<16;i=i+1) begin
            if (filtered[i]) begin code=code+1'b1; if (seen_zero) invalid=1; end
            else seen_zero=1;
        end
    end
endmodule
