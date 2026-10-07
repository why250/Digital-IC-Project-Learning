`timescale 1ns/1ps
// AD05: eight unit elements, q=0..8; state changes only on valid requests.
module dwa_encoder(input wire clk, rst_n, valid,
    input wire [3:0] q, output reg [7:0] select,
    output reg out_valid, error);
    reg [2:0] pointer;
    integer j;
    always @(posedge clk) begin
        if (!rst_n) begin pointer<=0; select<=0; out_valid<=0; error<=0; end
        else begin
            out_valid<=0; error<=0;
            if (valid) begin
                if (q>8) error<=1;
                else begin
                    select<=0;
                    for (j=0;j<8;j=j+1)
                        if (j<q) select[(pointer+j)%8]<=1;
                    pointer<=pointer+q; out_valid<=1;
                end
            end
        end
    end
endmodule
