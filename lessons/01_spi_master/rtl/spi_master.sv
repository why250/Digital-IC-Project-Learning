`timescale 1ns/1ps
// SPI master: Mode 0, 8-bit, MSB first. All storage uses clk.
// rst_n is synchronous active-low. start is a one-cycle clk-domain pulse.
module spi_master #(
    parameter integer HALF_PERIOD_CYCLES = 25
) (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       start,
    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       busy,
    output logic       done,
    output logic       cs_n,
    output logic       sclk,
    output logic       mosi,
    input  logic       miso
);
    localparam integer DIV_BITS =
        (HALF_PERIOD_CYCLES > 1) ? $clog2(HALF_PERIOD_CYCLES) : 1;
    localparam logic [DIV_BITS-1:0] DIV_LAST = HALF_PERIOD_CYCLES - 1;
    typedef enum logic [1:0] {IDLE, TRANSFER, FINISH} state_t;
    state_t state;
    logic [DIV_BITS-1:0] div_count;
    logic [2:0] bit_count;
    logic [7:0] tx_shift, rx_shift;

    // HALF_PERIOD_CYCLES must be a positive integer (checked by the runner).
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state     <= IDLE;
            div_count <= '0;
            bit_count <= '0;
            tx_shift  <= '0;
            rx_shift  <= '0;
            rx_data   <= '0;
            busy      <= 1'b0;
            done      <= 1'b0;
            cs_n      <= 1'b1;
            sclk      <= 1'b0;
            mosi      <= 1'b0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE: begin
                    if (start) begin
                        tx_shift  <= tx_data;
                        rx_shift  <= '0;
                        bit_count <= '0;
                        div_count <= '0;
                        mosi      <= tx_data[7]; // First bit before first rising edge.
                        cs_n      <= 1'b0;
                        sclk      <= 1'b0;
                        busy      <= 1'b1;
                        state     <= TRANSFER;
                    end
                end
                TRANSFER: begin
                    if (div_count == DIV_LAST) begin
                        div_count <= '0;
                        if (!sclk) begin
                            sclk     <= 1'b1;
                            rx_shift <= {rx_shift[6:0], miso};
                            if (bit_count == 3'd7)
                                rx_data <= {rx_shift[6:0], miso};
                        end else begin
                            sclk <= 1'b0;
                            if (bit_count == 3'd7) begin
                                state <= FINISH;
                            end else begin
                                bit_count <= bit_count + 1'b1;
                                tx_shift  <= {tx_shift[6:0], 1'b0};
                                mosi      <= tx_shift[6]; // Old register value.
                            end
                        end
                    end else begin
                        div_count <= div_count + 1'b1;
                    end
                end
                FINISH: begin
                    // Hold CS for one full half-period after final falling edge.
                    if (div_count == DIV_LAST) begin
                        div_count <= '0;
                        cs_n      <= 1'b1;
                        busy      <= 1'b0;
                        done      <= 1'b1;
                        mosi      <= 1'b0;
                        state     <= IDLE;
                    end else begin
                        div_count <= div_count + 1'b1;
                    end
                end
                default: begin
                    state <= IDLE;
                    cs_n  <= 1'b1;
                    sclk  <= 1'b0;
                    busy  <= 1'b0;
                    mosi  <= 1'b0;
                end
            endcase
        end
    end
endmodule
