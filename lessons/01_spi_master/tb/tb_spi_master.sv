`timescale 1ns/1ps
module tb_spi_master;
    parameter integer HALF_PERIOD_CYCLES = 25;
    localparam integer HALF_NS = HALF_PERIOD_CYCLES * 20;
    logic clk = 0;
    always #10 clk = ~clk;
    logic rst_n = 0, start = 0;
    logic [7:0] tx_data = 0, rx_data;
    logic busy, done, cs_n, sclk, mosi, miso = 0;
    logic [7:0] expected_tx = 0, slave_reply = 0;
    integer samples = 0, falls = 0, completed = 0;
    integer done_pulses = 0;
    logic previous_done = 0;
    time cs_asserted, last_edge;

    spi_master #(.HALF_PERIOD_CYCLES(HALF_PERIOD_CYCLES)) dut (.*);

    // Independent SPI slave: its response does not depend on MOSI.
    always @(negedge cs_n) begin
        if (rst_n) begin
            samples = 0;
            falls = 0;
            cs_asserted = $time;
            last_edge = $time;
            miso = slave_reply[7];
            if (sclk !== 0 || busy !== 1)
                $fatal(1, "Bad state at CS assertion");
        end
    end

    always @(posedge sclk) begin
        if (rst_n) begin
            if (cs_n !== 0 || busy !== 1 || samples >= 8)
                $fatal(1, "Unexpected SCLK sampling edge");
            if (($time - last_edge) != HALF_NS)
                $fatal(1, "Bad SCLK rising half-period");
            if (mosi !== expected_tx[7-samples])
                $fatal(1, "MOSI mismatch bit %0d: expected %b got %b",
                       samples, expected_tx[7-samples], mosi);
            samples = samples + 1;
            last_edge = $time;
        end
    end

    always @(negedge sclk) begin
        if (rst_n && cs_n === 0) begin
            if (($time - last_edge) != HALF_NS)
                $fatal(1, "Bad SCLK falling half-period");
            falls = falls + 1;
            if (falls > 8) $fatal(1, "Extra SCLK falling edge");
            if (samples < 8) miso = slave_reply[7-samples];
            last_edge = $time;
        end
    end

    always @(posedge cs_n) begin
        if (rst_n) begin
            if (samples != 8 || falls != 8)
                $fatal(1, "Wrong SPI edge count: rises=%0d falls=%0d", samples, falls);
            if (sclk !== 0 || busy !== 0 || done !== 1)
                $fatal(1, "Bad completion outputs");
            if (($time - last_edge) != HALF_NS)
                $fatal(1, "Bad CS hold time");
            if (($time - cs_asserted) != 17 * HALF_NS)
                $fatal(1, "Bad frame duration");
            completed = completed + 1;
        end
    end

    // Sample after sequential nonblocking updates.
    always @(posedge clk) begin
        #1;
        if (!rst_n) begin
            if (cs_n !== 1 || sclk !== 0 || busy !== 0 || done !== 0 ||
                mosi !== 0 || rx_data !== 0)
                $fatal(1, "Reset outputs incorrect");
            previous_done = 0;
        end else begin
            if (busy !== !cs_n) $fatal(1, "busy/CS contract broken");
            if (done && previous_done) $fatal(1, "done is longer than one clock");
            if (done) done_pulses = done_pulses + 1;
            previous_done = done;
        end
    end

    task automatic transfer(input logic [7:0] send_byte,
                            input logic [7:0] reply_byte,
                            input logic inject_busy_start);
        integer count_before;
        begin
            count_before = completed;
            @(negedge clk);
            expected_tx = send_byte;
            slave_reply = reply_byte;
            tx_data = send_byte;
            start = 1;
            @(negedge clk);
            start = 0;
            if (busy !== 1) $fatal(1, "start not accepted");
            // Corrupt the live input after acceptance; latched TX must survive.
            tx_data = ~send_byte;
            if (inject_busy_start) begin
                repeat (3) @(negedge clk);
                start = 1;
                @(negedge clk);
                start = 0;
            end
            wait (done === 1);
            #2;
            if (rx_data !== reply_byte)
                $fatal(1, "RX mismatch: expected %02x got %02x", reply_byte, rx_data);
            if (completed != count_before + 1)
                $fatal(1, "Completion count wrong");
            repeat (3) @(negedge clk);
            if (busy !== 0 || cs_n !== 1 || sclk !== 0 || done !== 0)
                $fatal(1, "Unexpected re-start or bad idle");
        end
    endtask

    integer n;
    integer before_abort, pulses_before_abort;
    initial begin
        if (HALF_PERIOD_CYCLES < 1) $fatal(1, "Divider must be positive");
        $dumpfile("spi_master.vcd");
        $dumpvars(0, tb_spi_master);
        repeat (4) @(negedge clk);
        rst_n = 1;
        transfer(8'hA5, 8'h3C, 1);
        for (n = 0; n < 256; n = n + 1)
            transfer(n[7:0], n[7:0] ^ 8'h69, (n % 17) == 0);

        // Abort an active frame by synchronous reset.
        before_abort = completed;
        pulses_before_abort = done_pulses;
        @(negedge clk);
        expected_tx = 8'h96;
        slave_reply = 8'h5A;
        tx_data = expected_tx;
        start = 1;
        @(negedge clk);
        start = 0;
        repeat (HALF_PERIOD_CYCLES * 3 + 1) @(negedge clk);
        if (busy !== 1) $fatal(1, "Abort test did not reach active frame");
        rst_n = 0;
        repeat (3) @(negedge clk);
        if (completed != before_abort || done_pulses != pulses_before_abort)
            $fatal(1, "Reset abort incorrectly completed a transaction");
        rst_n = 1;
        transfer(8'h81, 8'h7E, 0);
        if (completed != 258 || done_pulses != 258)
            $fatal(1, "Final accounting mismatch: completed=%0d done=%0d",
                   completed, done_pulses);
        $display("PASS divider=%0d transactions=%0d exhaustive_tx=256 busy_rejection=ok reset_abort=ok",
                 HALF_PERIOD_CYCLES, completed);
        $finish;
    end

    initial begin
        #10000000;
        $fatal(1, "Global test timeout");
    end
endmodule
