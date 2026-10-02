# Teaching assumptions, NOT external SPI interface signoff.
# tutorial.lib time unit: ns; capacitive load unit: pF.
create_clock -name sys_clk -period 20.0 [get_ports clk]
set_clock_uncertainty 0.2 [get_clocks sys_clk]
set_clock_transition 0.1 [get_clocks sys_clk]

# clk-domain command interface; synchronous active-low reset.
set_input_delay -clock sys_clk -max 2.0 [get_ports {start tx_data[*] rst_n}]
set_input_delay -clock sys_clk -min 0.2 [get_ports {start tx_data[*] rst_n}]

# Conservative teaching budgets relative to sys_clk.
# Actual MISO timing needs SCLK-relative slave/board timing in a later lesson.
set_input_delay -clock sys_clk -max 5.0 [get_ports miso]
set_input_delay -clock sys_clk -min 0.2 [get_ports miso]
set_input_transition 0.1 [get_ports {start tx_data[*] rst_n miso}]

set_output_delay -clock sys_clk -max 5.0 [get_ports {rx_data[*] busy done cs_n sclk mosi}]
set_output_delay -clock sys_clk -min 0.2 [get_ports {rx_data[*] busy done cs_n sclk mosi}]
set_load 0.05 [get_ports {rx_data[*] busy done cs_n sclk mosi}]
# No false paths or multicycle exceptions in lesson 01.
