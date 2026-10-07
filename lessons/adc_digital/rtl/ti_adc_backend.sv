`timescale 1ns/1ps
// AD06/07/15/17: four-lane teaching backend, core100MHz, sample every25 cycles.
// Sample and response ports describe events accepted at the next rising edge.
module ti_adc_backend(input wire clk, rst_n,
    input wire [15:0] epoch,
    output wire [3:0] sample_req,
    output wire [31:0] sample_id,
    input wire [3:0] rsp_valid,
    input wire [47:0] rsp_raw,
    input wire [127:0] rsp_id,
    input wire [63:0] rsp_epoch,
    input wire cfg_commit,
    input wire [71:0] cfg_offsets, cfg_gains,
    output reg cfg_accepted, cfg_rejected, cfg_applied,
    output reg [31:0] applied_id,
    input wire sink_ready,
    output wire out_valid, out_sat,
    output wire signed [17:0] out_data,
    output wire [65:0] out_meta,
    output reg fault,
    output reg [3:0] fault_code,
    output reg [31:0] fault_id,
    output reg [63:0] fault_tick,
    input wire snapshot,
    output reg [191:0] stats_snapshot);
    reg [63:0] tick;
    reg [4:0] phase;
    reg [31:0] next_id, release_id;
    reg [15:0] version;
    reg pending;
    reg signed [17:0] active_o[0:3], active_g[0:3], pend_o[0:3], pend_g[0:3];
    reg occupied[0:7], received[0:7];
    reg [31:0] tags[0:7];
    // A slot lives <=80 cycles, is reused after200, and faults before256.
    // Full tags/epoch retain identity; only local age is modulo256.
    reg [7:0] times[0:7];
    reg signed [11:0] raw_slots[0:7];
    reg signed [17:0] off_slots[0:7], gain_slots[0:7];
    reg [15:0] versions[0:7];
    reg [63:0] requests, responses, delivered;
    wire [2:0] alloc_slot=next_id[2:0], release_slot=release_id[2:0];
    wire sample_event=(phase==0) && !fault && rst_n;
    wire [7:0] release_age=tick[7:0]-times[release_slot];
    wire due=occupied[release_slot] && (release_age==8'd80);
    reg bad;
    reg [3:0] bad_code;
    reg [31:0] bad_id;
    reg cfg_ok;
    reg signed [17:0] check_o, check_g;
    integer i;
    reg [2:0] s, response_count;
    reg [7:0] age;
    wire corr_valid, corr_sat;
    wire signed [17:0] corr_data;
    wire [65:0] corr_meta;
    always @* begin
        bad=0; bad_code=0; bad_id=next_id; response_count=0;
        cfg_ok=1; check_o=0; check_g=0; s=0; age=0;
        for(i=0;i<4;i=i+1) begin
            check_o=$signed(cfg_offsets[i*18+:18]); check_g=$signed(cfg_gains[i*18+:18]);
            if(check_o< -18'sd2048 || check_o>18'sd2048 ||
                check_g<18'sd52429 || check_g>18'sd81920) cfg_ok=0;
            // Slot j belongs to lane j%4: each lane can target only two slots.
            s={rsp_id[i*32+2],i[1:0]};
            age=tick[7:0]-times[s];
            if(rsp_valid[i]) begin
                response_count=response_count+1;
                if(!occupied[s] || tags[s]!=rsp_id[i*32+:32] ||
                    rsp_id[i*32+:2]!=i || rsp_epoch[i*16+:16]!=epoch) begin
                    bad=1; bad_code=1; bad_id=rsp_id[i*32+:32];
                end else if(received[s]) begin bad=1; bad_code=2; bad_id=tags[s]; end
                else if(age<8'd1 || age>8'd60) begin
                    bad=1; bad_code=3; bad_id=tags[s];
                end
            end
        end
        if(due && !received[release_slot]) begin bad=1; bad_code=4; bad_id=release_id; end
        if(sample_event && occupied[alloc_slot]) begin bad=1; bad_code=5; bad_id=next_id; end
        if(corr_valid && !sink_ready) begin bad=1; bad_code=6; bad_id=corr_meta[33:2]; end
        if(sample_event && (next_id==32'hfffffffc ||
            (next_id[1:0]==0 && pending && version==16'hffff))) begin
            bad=1; bad_code=7; bad_id=next_id;
        end
    end
    assign sample_req = sample_event && !bad ? (4'b0001<<next_id[1:0]) : 4'b0000;
    assign sample_id=next_id;
    // fault is registered. Gating with live response validation would glitch
    // after an accepted response changes its slot from empty to received.
    assign out_valid=corr_valid && !fault;
    assign out_data=corr_data; assign out_sat=corr_sat; assign out_meta=corr_meta;
    adc_fixed_correct correction(.clk(clk),.rst_n(rst_n),.flush(fault||bad),
        .in_valid(due && !fault && !bad),.raw(raw_slots[release_slot]),
        .offset(off_slots[release_slot]),.inverse_gain(gain_slots[release_slot]),
        .meta({epoch,versions[release_slot],tags[release_slot],tags[release_slot][1:0]}),
        .out_valid(corr_valid),.sat(corr_sat),.data(corr_data),.out_meta(corr_meta));
    integer j;
    always @(posedge clk) begin
        if(!rst_n) begin
            tick<=0; phase<=0; next_id<=0; release_id<=0; version<=0; pending<=0;
            fault<=0; fault_code<=0; fault_id<=0; fault_tick<=0;
            cfg_accepted<=0; cfg_rejected<=0; cfg_applied<=0; applied_id<=0;
            requests<=0; responses<=0; delivered<=0; stats_snapshot<=0;
            for(j=0;j<4;j=j+1) begin active_o[j]<=0; active_g[j]<=18'sd65536;
                pend_o[j]<=0; pend_g[j]<=18'sd65536; end
            for(j=0;j<8;j=j+1) begin occupied[j]<=0; received[j]<=0; tags[j]<=0;
                times[j]<=0; raw_slots[j]<=0; off_slots[j]<=0; gain_slots[j]<=0; versions[j]<=0; end
        end else begin
            cfg_accepted<=0; cfg_rejected<=0; cfg_applied<=0;
            if(snapshot) stats_snapshot<={requests,responses,delivered};
            if(!fault) begin
                if(bad) begin
                    fault<=1; fault_code<=bad_code; fault_id<=bad_id; fault_tick<=tick;
                    cfg_rejected<=cfg_commit;
                    for(j=0;j<8;j=j+1) begin occupied[j]<=0; received[j]<=0; end
                end else begin
                    tick<=tick+1'b1;
                    phase<=phase==24 ? 0 : phase+1'b1;
                    if(cfg_commit) begin
                        if(pending || !cfg_ok) cfg_rejected<=1;
                        else begin pending<=1; cfg_accepted<=1;
                            for(j=0;j<4;j=j+1) begin pend_o[j]<=cfg_offsets[j*18+:18];
                                pend_g[j]<=cfg_gains[j*18+:18]; end
                        end
                    end
                    if(sample_event) begin
                        requests<=requests+1'b1; next_id<=next_id+1'b1;
                        occupied[alloc_slot]<=1; received[alloc_slot]<=0;
                        tags[alloc_slot]<=next_id; times[alloc_slot]<=tick[7:0];
                        if(next_id[1:0]==0 && pending) begin
                            pending<=0; version<=version+1'b1; cfg_applied<=1; applied_id<=next_id;
                            for(j=0;j<4;j=j+1) begin active_o[j]<=pend_o[j]; active_g[j]<=pend_g[j]; end
                            off_slots[alloc_slot]<=pend_o[next_id[1:0]];
                            gain_slots[alloc_slot]<=pend_g[next_id[1:0]];
                            versions[alloc_slot]<=version+1'b1;
                        end else begin off_slots[alloc_slot]<=active_o[next_id[1:0]];
                            gain_slots[alloc_slot]<=active_g[next_id[1:0]];
                            versions[alloc_slot]<=version; end
                    end
                    responses<=responses+response_count;
                    // Constant lane per slot avoids inferring four arbitrary
                    // writers. Wrong-lane/tag responses already enter HALT.
                    for(j=0;j<8;j=j+1) if(rsp_valid[j%4] && rsp_id[(j%4)*32+:3]==j) begin
                        received[j]<=1;
                        raw_slots[j]<=rsp_raw[(j%4)*12+:12];
                    end
                    if(due) begin occupied[release_slot]<=0; received[release_slot]<=0;
                        release_id<=release_id+1'b1; end
                    if(out_valid) delivered<=delivered+1'b1;
                end
            end else if(cfg_commit) cfg_rejected<=1;
        end
    end
endmodule
