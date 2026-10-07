`timescale 1ns/1ps
module tb_fixed;
    reg clk=0; always #5 clk=~clk;
    reg rst_n=0, flush=0, valid=0;
    reg signed [11:0] raw;
    reg signed [17:0] offset,gain;
    reg [65:0] meta;
    wire ov,sat; wire signed [17:0] data; wire [65:0] tag;
    adc_fixed_correct dut(.clk(clk),.rst_n(rst_n),.flush(flush),.in_valid(valid),
        .raw(raw),.offset(offset),.inverse_gain(gain),.meta(meta),
        .out_valid(ov),.sat(sat),.data(data),.out_meta(tag));
    integer exp_data[0:20000], exp_sat[0:20000], exp_cycle[0:20000];
    integer count=0, received=0, cycle=0, fd,rc,r,o,g,y,s,seed=1551;
    reg [31:0] random_value;
    always @(posedge clk) begin
        if(!rst_n) cycle=0;
        else begin
            cycle=cycle+1;
            #1;
            if(ov) begin
                if(data!==exp_data[received][17:0] || sat!==exp_sat[received][0] ||
                    tag!=received || cycle!=exp_cycle[received]+4)
                    $fatal(1,"fixed mismatch index=%0d got=%0d expected=%0d cycle=%0d",received,data,exp_data[received],cycle);
                received=received+1;
            end
        end
    end
    initial begin
        raw=0; offset=0; gain=0; meta=0;
        repeat(3) @(negedge clk); rst_n=1;
        fd=$fopen("fixed_vectors.txt","r"); if(!fd) $fatal(1,"fixed vectors missing");
        while(!$feof(fd)) begin
            rc=$fscanf(fd,"%d %d %d %d %d\n",r,o,g,y,s);
            if(rc==5) begin
                @(negedge clk);
                random_value=$random(seed);
                if(random_value%5==0) begin valid=0; @(negedge clk); end
                valid=1; raw=r; offset=o; gain=g; meta=count;
                exp_data[count]=y; exp_sat[count]=s; exp_cycle[count]=cycle+1; count=count+1;
            end else if(!$feof(fd)) $fatal(1,"fixed vectors parse");
        end
        $fclose(fd); @(negedge clk); valid=0; repeat(6) @(negedge clk);
        if(received!=count) $fatal(1,"fixed lost output");
        // Flush abandons in-flight data; no stale output after it.
        valid=1; repeat(2) @(negedge clk); valid=0; flush=1;
        @(negedge clk); flush=0; repeat(6) @(negedge clk);
        if(ov || received!=count) $fatal(1,"fixed flush leak");
        $display("PASS AD15 FIXED vectors=%0d latency=4 random-idle flush saturation negative-ties",count);
        $display("ADC_FIXED_COMPLETE"); $finish;
    end
    initial begin #10000000; $fatal(1,"fixed watchdog"); end
endmodule
