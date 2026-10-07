`timescale 1ns/1ps
// AD08: depth8, signed18/F4 payload. Coordinated reset required.
// Read data/valid registered on an accepted pop. Not a physical CDC signoff.
module adc_async_fifo(input wire wclk, wrst_n, push,
    input wire [17:0] wdata, output wire full,
    output reg overflow,
    input wire rclk, rrst_n, pop,
    output reg [17:0] rdata, output reg rvalid, underflow,
    output wire empty);
    reg [17:0] mem[0:7];
    reg [3:0] wb, wg, rb, rg;
    (* async_reg="true" *) reg [3:0] rg1, rg2, wg1, wg2;
    wire [3:0] wb_next=wb+1'b1;
    wire [3:0] wg_next=(wb_next>>1)^wb_next;
    assign full = (wg=={~rg2[3:2],rg2[1:0]});
    assign empty = (rg==wg2);
    always @(posedge wclk) begin
        if(!wrst_n) begin wb<=0; wg<=0; rg1<=0; rg2<=0; overflow<=0; end
        else begin
            rg1<=rg; rg2<=rg1;
            if(push) begin
                if(full) overflow<=1;
                else begin mem[wb[2:0]]<=wdata; wb<=wb_next; wg<=wg_next; end
            end
        end
    end
    always @(posedge rclk) begin
        if(!rrst_n) begin rb<=0; rg<=0; wg1<=0; wg2<=0;
            rdata<=0; rvalid<=0; underflow<=0; end
        else begin
            wg1<=wg; wg2<=wg1; rvalid<=0;
            if(pop) begin
                if(empty) underflow<=1;
                else begin
                    rdata<=mem[rb[2:0]]; rvalid<=1;
                    rb<=rb+1'b1; rg<=((rb+1'b1)>>1)^(rb+1'b1);
                end
            end
        end
    end
endmodule
