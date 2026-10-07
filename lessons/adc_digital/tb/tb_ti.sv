`timescale 1ns/1ps
module tb_ti;
    reg clk=0; always #5 clk=~clk;
    reg rst_n=0;
    reg [15:0] epoch=0;
    wire [3:0] req; wire [31:0] sample_id;
    reg [3:0] rv=0; reg [47:0] raw=0; reg [127:0] ids=0; reg [63:0] epochs=0;
    reg commit=0,ready=1,snapshot=0; reg [71:0] offsets=0,gains=0;
    wire acc,rej,applied,ov,sat,fault;
    wire [31:0] applied_id,fault_id;
    wire [3:0] fault_code; wire [63:0] fault_tick;
    wire signed [17:0] data; wire [65:0] meta; wire [191:0] stats;
    ti_adc_backend dut(.clk(clk),.rst_n(rst_n),.epoch(epoch),.sample_req(req),.sample_id(sample_id),
        .rsp_valid(rv),.rsp_raw(raw),.rsp_id(ids),.rsp_epoch(epochs),
        .cfg_commit(commit),.cfg_offsets(offsets),.cfg_gains(gains),
        .cfg_accepted(acc),.cfg_rejected(rej),.cfg_applied(applied),.applied_id(applied_id),
        .sink_ready(ready),.out_valid(ov),.out_sat(sat),.out_data(data),.out_meta(meta),
        .fault(fault),.fault_code(fault_code),.fault_id(fault_id),.fault_tick(fault_tick),
        .snapshot(snapshot),.stats_snapshot(stats));
    integer fd,logfd,rc,line=0,rst_value,commit_value,ready_value,snapshot_value;
    reg [3:0] accepted_req; reg [31:0] accepted_id;
    reg [1023:0] stimulus;
    initial begin
        if(!$value$plusargs("STIM=%s",stimulus)) $fatal(1,"STIM missing");
        fd=$fopen(stimulus,"r"); logfd=$fopen("trace.txt","w");
        if(!fd || !logfd) $fatal(1,"TI file open");
        repeat(3) @(negedge clk);
        while(!$feof(fd)) begin
            rc=$fscanf(fd,"%d %h %d %h %h %h %h %h %h %d %d\n",
                rst_value,epoch,commit_value,offsets,gains,rv,raw,ids,epochs,ready_value,snapshot_value);
            if(rc==11) begin
                rst_n=rst_value; commit=commit_value; ready=ready_value; snapshot=snapshot_value;
                // Accelerate otherwise long counters; test-only, never synthesis.
                if($test$plusargs("WRAP_GUARD") && line==25) dut.next_id=32'hfffffffc;
                if($test$plusargs("VERSION_GUARD") && line==100) dut.version=16'hffff;
                @(posedge clk); accepted_req=req; accepted_id=sample_id; #1;
                $fwrite(logfd,"%0d %h %0d %0d %0d %0d %h %0d %0d %0d %0d %0d %0d %0d %0d %h\n",
                    line,accepted_req,accepted_id,ov,data,sat,meta,acc,rej,applied,applied_id,
                    fault,fault_code,fault_id,fault_tick,stats);
                line=line+1; @(negedge clk);
            end else if(!$feof(fd)) $fatal(1,"TI stimulus parse line=%0d rc=%0d",line,rc);
        end
        $fclose(fd); $fclose(logfd); $display("ADC_TI_TRACE_COMPLETE cycles=%0d",line); $finish;
    end
    initial if($test$plusargs("VCD")) begin $dumpfile("ti_adc.vcd"); $dumpvars(0,tb_ti); end
    initial begin #10000000; $fatal(1,"TI watchdog"); end
endmodule
