# Run using scripts/run_synth.sh; all outputs use an explicit results directory.
set script_dir [file dirname [file normalize [info script]]]
set lesson_dir [file dirname $script_dir]
if {![info exists ::env(SPI_RESULTS)]} { error "SPI_RESULTS must be set by runner" }
set output_dir [file normalize $::env(SPI_RESULTS)]
file mkdir $output_dir

set lib /opt/eda/cadence/DDI251/GENUS251/share/synth/tutorials/tech/tutorial.lib
if {[info exists ::env(SPI_LIB)]} { set lib [file normalize $::env(SPI_LIB)] }
if {![file readable $lib]} { error "Library is not readable: $lib" }

set_db max_cpus_per_server 2
set_db library $lib
read_hdl -sv [file join $lesson_dir rtl spi_master.sv]
elaborate spi_master
check_design -unresolved > [file join $output_dir design_check.rpt]
read_sdc [file join $lesson_dir constraints spi_master.sdc]
check_timing_intent > [file join $output_dir timing_intent.rpt]

syn_generic
syn_map
syn_opt

check_design -all > [file join $output_dir mapped_design_check.rpt]
check_timing_intent > [file join $output_dir mapped_timing_intent.rpt]

report_area > [file join $output_dir area.rpt]
report_gates > [file join $output_dir gates.rpt]
report_timing -max_paths 10 > [file join $output_dir timing.rpt]
write_hdl > [file join $output_dir mapped.v]
write_sdc > [file join $output_dir mapped.sdc]
puts "SPI_SYNTHESIS_COMPLETE"
