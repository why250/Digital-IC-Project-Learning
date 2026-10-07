`timescale 1ns/1ps
module tb_stream;
    reg clk=0; always #5 clk=~clk;
    reg rst_n=0, commit=0;
    reg [71:0] offsets=0,gains=0;
    reg [3:0] rv=0;
    reg [47:0] raw=0; reg [127:0] ids=0; reg [63:0] epochs=0;
    wire [3:0] req; wire [31:0] sample_id;
    wire ov,sat,fault; wire signed [17:0] data; wire [65:0] meta;
    ti_adc_backend dut(.clk(clk),.rst_n(rst_n),.epoch(16'd3),.sample_req(req),.sample_id(sample_id),
        .rsp_valid(rv),.rsp_raw(raw),.rsp_id(ids),.rsp_epoch(epochs),.cfg_commit(commit),
        .cfg_offsets(offsets),.cfg_gains(gains),.cfg_accepted(),.cfg_rejected(),.cfg_applied(),.applied_id(),
        .sink_ready(1'b1),.out_valid(ov),.out_sat(sat),.out_data(data),.out_meta(meta),
        .fault(fault),.fault_code(),.fault_id(),.fault_tick(),.snapshot(1'b0),.stats_snapshot());
    integer values[0:65539]; integer queued_id[0:3],due[0:3],delay[0:3];
    reg pending[0:3];
    integer fd,cf,of,rc,n,t,lane,received=0;
    initial begin
        fd=$fopen("raw.txt","r"); cf=$fopen("coefficients.txt","r"); of=$fopen("stream.txt","w");
        if(!fd || !cf || !of) $fatal(1,"stream files");
        rc=$fscanf(cf,"%h %h\n",offsets,gains); if(rc!=2) $fatal(1,"stream coefficients");
        for(n=0;n<65540;n=n+1) begin rc=$fscanf(fd,"%d\n",values[n]);
            if(rc!=1) $fatal(1,"stream raw %0d",n); end
        $fclose(fd); $fclose(cf);
        delay[0]=18; delay[1]=52; delay[2]=9; delay[3]=31;
        for(lane=0;lane<4;lane=lane+1) begin pending[lane]=0; queued_id[lane]=0; due[lane]=0; end
        repeat(3) @(negedge clk); rst_n=1;
        for(t=0;received<65540;t=t+1) begin
            rv=0; raw=0; ids=0; epochs=0; commit=(t==10);
            for(lane=0;lane<4;lane=lane+1) if(pending[lane] && due[lane]==t) begin
                rv[lane]=1; raw[lane*12+:12]=values[queued_id[lane]];
                ids[lane*32+:32]=queued_id[lane]; epochs[lane*16+:16]=16'd3;
            end
            @(posedge clk);
            for(lane=0;lane<4;lane=lane+1) if(rv[lane]) pending[lane]=0;
            if(req!=0 && sample_id<65540) begin
                lane=sample_id%4;
                if(pending[lane]) $fatal(1,"stream lane overlapping conversion");
                pending[lane]=1; queued_id[lane]=sample_id; due[lane]=t+delay[lane];
            end
            #1;
            if(fault) $fatal(1,"stream backend fault at tick=%0d",t);
            if(ov) begin
                $fwrite(of,"%0d %0d %0d %0d %0d\n",meta[33:2],data,sat,meta[49:34],meta[65:50]);
                received=received+1;
            end
            @(negedge clk);
        end
        $fclose(of); $display("ADC_STREAM_SIMULATION_COMPLETE samples=%0d cycles=%0d",received,t); $finish;
    end
    initial begin #20000000; $fatal(1,"stream watchdog"); end
endmodule
