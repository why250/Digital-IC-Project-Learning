`timescale 1ns/1ps
// AD15: signed12/F0 raw, signed18/F4 offset, signed18/F16 inverse gain.
// Accepted at edge t, output after edge t+4. No backpressure. flush wins.
module adc_fixed_correct(input wire clk, rst_n, flush, in_valid,
    input wire signed [11:0] raw,
    input wire signed [17:0] offset, inverse_gain,
    input wire [65:0] meta,
    output reg out_valid, sat,
    output reg signed [17:0] data,
    output reg [65:0] out_meta);
    reg [3:0] v;
    reg [65:0] tag[0:3];
    reg signed [18:0] difference;
    reg signed [17:0] gain_q;
    reg signed [36:0] product;
    reg signed [37:0] rounded;
    reg signed [17:0] clipped;
    reg clipped_sat;
    wire signed [18:0] extended={{7{raw[11]}},raw};
    wire signed [18:0] off_extended={offset[17],offset};
    wire signed [37:0] floor_q={{17{product[36]}},product[36:16]};
    wire round_up=(product[15:0]>16'h8000) ||
                  ((product[15:0]==16'h8000) && product[16]);
    integer i;
    always @(posedge clk) begin
        if (!rst_n || flush) begin
            v<=0; out_valid<=0; sat<=0; data<=0; out_meta<=0;
            difference<=0; gain_q<=0; product<=0; rounded<=0; clipped<=0; clipped_sat<=0;
            for(i=0;i<4;i=i+1) tag[i]<=0;
        end else begin
            v<={v[2:0],in_valid}; tag[0]<=meta;
            for(i=1;i<4;i=i+1) tag[i]<=tag[i-1];
            difference<=(extended<<<4)-off_extended; gain_q<=inverse_gain;
            product<=difference*gain_q;
            rounded<=floor_q+(round_up ? 38'sd1 : 38'sd0);
            if(rounded>38'sd131071) begin clipped<=18'sd131071; clipped_sat<=1; end
            else if(rounded< -38'sd131072) begin clipped<=-18'sd131072; clipped_sat<=1; end
            else begin clipped<=rounded[17:0]; clipped_sat<=0; end
            out_valid<=v[3]; data<=clipped; sat<=clipped_sat; out_meta<=tag[3];
        end
    end
endmodule
