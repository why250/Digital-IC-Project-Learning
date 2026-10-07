`timescale 1ns/1ps
// AD04: stage k presents sample n-k. Residue is signed8/F4 at stage3.
// Output r0 is signed12/F8. Illegal trits or mismatched aligned tags fault.
module pipeline_align(input wire clk, rst_n,
    input wire [3:0] valid,
    input wire [7:0] decisions,
    input wire [127:0] ids,
    input wire signed [7:0] residue,
    output reg out_valid, fault,
    output reg [31:0] out_id,
    output reg signed [11:0] value);
    reg signed [1:0] d0[0:2], d1[0:1], d2;
    reg [31:0] id0[0:2], id1[0:1], id2;
    reg v0[0:2], v1[0:1], v2;
    integer i;
    wire signed [11:0] w0={{10{d0[2][1]}},d0[2]};
    wire signed [11:0] w1={{10{d1[1][1]}},d1[1]};
    wire signed [11:0] w2={{10{d2[1]}},d2};
    wire signed [11:0] w3={{10{decisions[7]}},decisions[7:6]};
    wire signed [11:0] wr={{4{residue[7]}},residue};
    always @(posedge clk) begin
        if (!rst_n) begin
            out_valid<=0; fault<=0; out_id<=0; value<=0; d2<=0; id2<=0; v2<=0;
            for(i=0;i<3;i=i+1) begin d0[i]<=0; id0[i]<=0; v0[i]<=0; end
            for(i=0;i<2;i=i+1) begin d1[i]<=0; id1[i]<=0; v1[i]<=0; end
        end else begin
            d0[0]<=decisions[1:0]; id0[0]<=ids[31:0]; v0[0]<=valid[0];
            d1[0]<=decisions[3:2]; id1[0]<=ids[63:32]; v1[0]<=valid[1];
            d2<=decisions[5:4]; id2<=ids[95:64]; v2<=valid[2];
            for(i=1;i<3;i=i+1) begin d0[i]<=d0[i-1]; id0[i]<=id0[i-1]; v0[i]<=v0[i-1]; end
            d1[1]<=d1[0]; id1[1]<=id1[0]; v1[1]<=v1[0];
            out_valid<=0;
            if (v0[2] && v1[1] && v2 && valid[3]) begin
                if (id0[2]!=id1[1] || id0[2]!=id2 || id0[2]!=ids[127:96] ||
                    d0[2]==-2 || d1[1]==-2 || d2==-2 || decisions[7:6]==2'b10)
                    fault<=1;
                else if (!fault) begin
                    out_valid<=1; out_id<=id0[2];
                    value<=(w0<<<7)+(w1<<<6)+(w2<<<5)+(w3<<<4)+wr;
                end
            end
        end
    end
endmodule
