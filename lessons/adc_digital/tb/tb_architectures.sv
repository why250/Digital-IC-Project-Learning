`timescale 1ns/1ps
module tb_architectures;
    reg clk=0; always #5 clk=~clk;
    reg rst_n=0, start=0, cmp_valid=0;
    integer target=0;
    wire cmp_ge=(target>=trial);
    wire busy, done, error, cmp_req;
    wire [9:0] trial, result;
    sar_controller sar(.clk(clk),.rst_n(rst_n),.start(start),.cmp_valid(cmp_valid),
        .cmp_ge(cmp_ge),.busy(busy),.done(done),.error(error),.trial(trial),.result(result),.cmp_req(cmp_req));
    reg [15:0] therm;
    wire [4:0] code;
    wire invalid, corrected;
    flash_encoder flash(.therm(therm),.code(code),.invalid(invalid),.corrected(corrected));
    reg dv=0; reg [3:0] q=0;
    wire [7:0] select; wire ov, de;
    dwa_encoder dwa(.clk(clk),.rst_n(rst_n),.valid(dv),.q(q),.select(select),.out_valid(ov),.error(de));
    reg [3:0] pv=0; reg [7:0] pd=0; reg [127:0] ids=0; reg signed [7:0] residue=0;
    wire pov, pf; wire [31:0] pid; wire signed [11:0] pvalue;
    pipeline_align pa(.clk(clk),.rst_n(rst_n),.valid(pv),.decisions(pd),.ids(ids),.residue(residue),
        .out_valid(pov),.fault(pf),.out_id(pid),.value(pvalue));
    integer i,j,k,fd,rc,w,c,iv,co,watch,ptr,expected,mask;
    integer usage[0:7];
    function integer decision(input integer n, input integer stage);
        decision=((n*7+stage*5)%3)-1;
    endfunction
    function integer residue_value(input integer n);
        residue_value=(n%33)-16;
    endfunction
    function integer reconstructed(input integer n);
        reconstructed=128*decision(n,0)+64*decision(n,1)+32*decision(n,2)+
                      16*decision(n,3)+residue_value(n);
    endfunction
    task reset_all;
        begin
            @(negedge clk); rst_n=0; start=0; cmp_valid=0; dv=0; pv=0;
            repeat(3) @(negedge clk); rst_n=1;
        end
    endtask
    initial begin
        therm=0; reset_all();
        for(i=0;i<1024;i=i+1) begin
            target=i; @(negedge clk); start=1;
            @(negedge clk); start=0; watch=0;
            while(!done) begin
                // Comparator has a delayed response; busy start pulses must be ignored.
                cmp_valid=cmp_req && (watch%3==0); start=(watch==7);
                @(posedge clk); #1; watch=watch+1;
                if(error || watch>200) $fatal(1,"SAR timeout target=%0d",target);
                @(negedge clk);
            end
            if(result!==target[9:0]) $fatal(1,"SAR code %0d != %0d",result,target);
            cmp_valid=0; start=0; @(posedge clk); #1;
            if(done) $fatal(1,"SAR done not one cycle");
        end
        @(negedge clk); start=1; @(negedge clk); start=0; cmp_valid=0;
        watch=0;
        while(!error) begin @(posedge clk); #1; watch=watch+1;
            if(watch>40 || done) $fatal(1,"SAR missing comparator response"); end
        reset_all(); @(negedge clk); start=1; @(negedge clk); start=0;
        repeat(4) @(negedge clk); rst_n=0; @(posedge clk); #1;
        if(busy || done) $fatal(1,"SAR reset abort"); reset_all();
        $display("PASS AD02 SAR exhaustive=1024 timeout reset busy-start done");
        fd=$fopen("flash_vectors.txt","r"); if(!fd) $fatal(1,"flash vector file missing");
        for(i=0;i<65536;i=i+1) begin
            rc=$fscanf(fd,"%d %d %d %d\n",w,c,iv,co); if(rc!=4) $fatal(1,"flash vector parse");
            therm=w; #1;
            if(code!==c[4:0] || invalid!==iv[0] || corrected!==co[0]) $fatal(1,"flash mismatch %0d",w);
        end
        $fclose(fd); $display("PASS AD03 FLASH vectors=65536");
        reset_all(); ptr=0; for(j=0;j<8;j=j+1) usage[j]=0;
        for(i=0;i<128;i=i+1) begin
            @(negedge clk); dv=1; q=(i<8) ? 3 : i%9;
            mask=0; for(j=0;j<q;j=j+1) mask=mask | (1<<((ptr+j)%8));
            @(posedge clk); #1;
            if(!ov || de || select!==mask[7:0]) $fatal(1,"DWA selection %0d",i);
            if(i<8) for(j=0;j<8;j=j+1) usage[j]=usage[j]+select[j];
            ptr=(ptr+q)%8;
        end
        for(j=0;j<8;j=j+1) if(usage[j]!=3) $fatal(1,"DWA usage");
        @(negedge clk); q=9; @(posedge clk); #1;
        if(!de || ov) $fatal(1,"DWA invalid q");
        @(negedge clk); q=3; mask=0;
        for(j=0;j<3;j=j+1) mask=mask | (1<<((ptr+j)%8));
        @(posedge clk); #1;
        if(!ov || de || select!==mask[7:0]) $fatal(1,"DWA illegal q changed pointer");
        @(negedge clk); dv=0; @(posedge clk); #1; if(ov || de) $fatal(1,"DWA idle");
        $display("PASS AD05 DWA variable q idle illegal reset");
        reset_all();
        for(i=0;i<104;i=i+1) begin
            @(negedge clk); pv=0; pd=0; ids=0; residue=0;
            for(j=0;j<4;j=j+1) begin
                k=i-j;
                if(k>=0 && k<100) begin
                    pv[j]=1; pd[j*2+:2]=decision(k,j); ids[j*32+:32]=k;
                    if(j==3) residue=residue_value(k);
                end
            end
            @(posedge clk); #1;
            if(i>=3 && i<103) begin
                expected=reconstructed(i-3);
                if(!pov || pf || pid!=i-3 || pvalue!==expected[11:0])
                    $fatal(1,"pipeline alignment i=%0d id=%0d value=%0d expected=%0d",i,pid,pvalue,expected);
            end else if(pov) $fatal(1,"pipeline startup/end valid");
        end
        reset_all();
        for(i=0;i<8;i=i+1) begin
            @(negedge clk); pv=4'b1111; pd=0;
            for(j=0;j<4;j=j+1) ids[j*32+:32]=i-j;
            if(i==5) ids[127:96]=999;
            @(posedge clk); #1;
            if(i>=5 && (!pf || pov)) $fatal(1,"pipeline tag fault/HALT");
        end
        reset_all();
        for(i=0;i<8;i=i+1) begin
            @(negedge clk); pv=4'b1111; pd=0;
            for(j=0;j<4;j=j+1) ids[j*32+:32]=i-j;
            if(i==5) pd[7:6]=2'b10;
            @(posedge clk); #1;
            if(i>=5 && (!pf || pov)) $fatal(1,"pipeline illegal trit/HALT");
        end
        $display("PASS AD04 PIPELINE aligned=100 mismatched-tag illegal-trit HALT");
        $display("ADC_ARCHITECTURES_COMPLETE"); $finish;
    end
    initial begin #10000000; $fatal(1,"architectures watchdog"); end
endmodule
