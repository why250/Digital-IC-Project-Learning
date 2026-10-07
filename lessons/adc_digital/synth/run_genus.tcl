set script_dir [file dirname [file normalize [info script]]]
set lesson_dir [file dirname $script_dir]
foreach key {ADC_TOP ADC_RESULTS} {
    if {![info exists ::env($key)]} {error "$key must be set"}
}
set top $::env(ADC_TOP)
set output [file normalize $::env(ADC_RESULTS)]
set_db max_cpus_per_server 2
set_db library /opt/eda/cadence/DDI251/GENUS251/share/synth/tutorials/tech/tutorial.lib
foreach source [lsort [glob [file join $lesson_dir rtl *.sv]]] {read_hdl -sv $source}
elaborate $top
check_design -unresolved > [file join $output design_check.rpt]
if {$top == "adc_async_fifo"} {
    create_clock -name wclk -period 10 [get_ports wclk]
    create_clock -name rclk -period 14 [get_ports rclk]
    set_input_delay -clock wclk 1 [get_ports {push wdata* wrst_n}]
    set_input_delay -clock rclk 1 [get_ports {pop rrst_n}]
    set_output_delay -clock wclk 1 [get_ports {full overflow}]
    set_output_delay -clock rclk 1 [get_ports {empty rdata* rvalid underflow}]
    # First-stage synchronizer D only: isolate CDC, retain each destination
    # synchronizer stage1->stage2 setup/hold paths. Physical Gray skew separate.
    set_false_path -from [get_clocks wclk] -to [get_pins -hierarchical *wg1*/D]
    set_false_path -from [get_clocks rclk] -to [get_pins -hierarchical *rg1*/D]
    set_false_path -from [get_clocks wclk] -to [get_pins -hierarchical *rdata*/D]
} elseif {$top == "flash_encoder"} {
    create_clock -name vclk -period 10
    set_input_delay -clock vclk 1 [all_inputs]
    set_output_delay -clock vclk 1 [all_outputs]
} else {
    create_clock -name core -period 10 [get_ports clk]
    set_input_delay -clock core 1 [remove_from_collection [all_inputs] [get_ports clk]]
    set_output_delay -clock core 1 [all_outputs]
    set_clock_uncertainty 0.2 [get_clocks core]
}
set_load 0.02 [all_outputs]
set_input_transition 0.1 [all_inputs]
check_timing_intent > [file join $output timing_intent.rpt]
syn_generic
syn_map
syn_opt
check_design -all > [file join $output mapped_design_check.rpt]
check_timing_intent > [file join $output mapped_timing_intent.rpt]
report_area > [file join $output area.rpt]
report_gates > [file join $output gates.rpt]
report_timing -max_paths 10 > [file join $output timing.rpt]
# Installed Genus report_timing has no early/hold option. This is setup-only
# logical synthesis; hold/CTS/multi-corner remain a separate physical flow.
write_hdl > [file join $output mapped.v]
write_sdc > [file join $output mapped.sdc]
puts "ADC_SYNTHESIS_COMPLETE top=$top"
