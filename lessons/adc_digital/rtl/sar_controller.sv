`timescale 1ns/1ps
// AD02: synchronous teaching SAR; comparator response belongs to current trial.
module sar_controller #(
    parameter integer BITS=10, SETTLE=2, TIMEOUT=8
)(input wire clk, rst_n, start,
  input wire cmp_valid, cmp_ge,
  output reg busy, done, error,
  output reg [BITS-1:0] trial, result,
  output wire cmp_req);
    localparam IDLE=0, APPLY=1, DAC_WAIT=2, COMP_WAIT=3;
    reg [1:0] state;
    reg [BITS-1:0] kept;
    integer bit_index, wait_count;
    assign cmp_req = busy && state==COMP_WAIT;
    always @(posedge clk) begin
        if (!rst_n) begin
            state<=IDLE; busy<=0; done<=0; error<=0;
            trial<=0; result<=0; kept<=0; bit_index<=0; wait_count<=0;
        end else begin
            done<=0; error<=0;
            case (state)
                IDLE: if (start) begin
                    busy<=1; kept<=0; bit_index<=BITS-1; state<=APPLY;
                end
                APPLY: begin
                    trial<=kept | ({{(BITS-1){1'b0}},1'b1} << bit_index);
                    wait_count<=0; state<=DAC_WAIT;
                end
                DAC_WAIT: begin
                    if (wait_count==SETTLE-1) begin
                        wait_count<=0; state<=COMP_WAIT;
                    end else wait_count<=wait_count+1;
                end
                COMP_WAIT: begin
                    if (cmp_valid) begin
                        if (cmp_ge) kept<=trial;
                        if (bit_index==0) begin
                            result<=cmp_ge ? trial : kept;
                            busy<=0; done<=1; state<=IDLE;
                        end else begin bit_index<=bit_index-1; state<=APPLY; end
                    end else if (wait_count==TIMEOUT-1) begin
                        busy<=0; error<=1; state<=IDLE;
                    end else wait_count<=wait_count+1;
                end
                default: begin busy<=0; error<=1; state<=IDLE; end
            endcase
        end
    end
endmodule
