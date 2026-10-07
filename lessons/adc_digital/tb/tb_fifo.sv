`timescale 1ns/1ps
module tb_fifo;
    reg wclk=0,rclk=0; always #5 wclk=~wclk; always #7 rclk=~rclk;
    reg wrst_n=0,rrst_n=0,push=0,pop=0;
    reg [17:0] wdata=0;
    wire full,empty,overflow,underflow,rvalid;
    wire [17:0] rdata;
    adc_async_fifo dut(.wclk(wclk),.wrst_n(wrst_n),.push(push),.wdata(wdata),.full(full),
        .overflow(overflow),.rclk(rclk),.rrst_n(rrst_n),.pop(pop),.rdata(rdata),
        .rvalid(rvalid),.underflow(underflow),.empty(empty));
    integer sent=0,received=0,mode=0,ws=882,rs=883;
    reg [31:0] rw,rr;
    always @(negedge wclk) begin
        rw=$random(ws); wdata=sent;
        push=wrst_n && (mode==1 || (mode==3 && rw%4!=0));
    end
    always @(negedge rclk) begin
        rr=$random(rs); pop=rrst_n && (mode==2 || (mode==3 && rr%3!=0));
    end
    always @(posedge wclk) if(wrst_n && push && !full) sent=sent+1;
    always @(posedge rclk) begin
        #1;
        if(rrst_n && rvalid) begin
            if(rdata!==received[17:0]) $fatal(1,"FIFO order %0d != %0d",rdata,received);
            received=received+1;
        end
    end
    initial begin
        #40; wrst_n=1; rrst_n=1; mode=1;
        #250; if(!full || !overflow || sent!=8) $fatal(1,"FIFO full/overflow/depth");
        mode=2; #350;
        if(!empty || !underflow || received!=8) $fatal(1,"FIFO empty/underflow");
        mode=3; #25000; mode=2; #500;
        if(received!=sent || !empty) $fatal(1,"FIFO drain sent=%0d received=%0d",sent,received);
        mode=0; #40; wrst_n=0; rrst_n=0; #50; sent=0; received=0;
        wrst_n=1; rrst_n=1; mode=3; #5000; mode=2; #500;
        if(sent!=received || !empty) $fatal(1,"FIFO reset recovery");
        $display("PASS AD08 FIFO clocks=10ns/14ns overflow underflow wrap reset received=%0d",received);
        $display("ADC_FIFO_COMPLETE"); $finish;
    end
    initial begin #1000000; $fatal(1,"FIFO watchdog"); end
endmodule
