#!/usr/bin/env bash
set -euo pipefail
lesson_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_dir="$(cd "$lesson_dir/../.." && pwd)"
local_tools="$project_dir/.tools/iverilog/root/usr"
if [[ -x "$local_tools/bin/iverilog" ]]; then
    compiler=("$local_tools/bin/iverilog" -B "$local_tools/lib64/ivl")
    runner="$local_tools/bin/vvp"
elif command -v iverilog >/dev/null && command -v vvp >/dev/null; then
    compiler=(iverilog); runner="$(command -v vvp)"
else echo 'No Icarus available' >&2; exit 2; fi
output="$lesson_dir/results/sim"
mkdir -p "$output"
python3 "$lesson_dir/models/experiments.py" --vectors --output "$output"
python3 "$lesson_dir/models/ti_reference.py" --generate "$output/stimuli"
for name in architectures fixed fifo ti; do
    "${compiler[@]}" -g2012 -Wall -s "tb_$name" -o "$output/$name.vvp" \
        "$lesson_dir"/rtl/*.sv "$lesson_dir/tb/tb_$name.sv" 2>&1 | tee "$output/compile_$name.log"
done
for name in architectures fixed fifo; do
    (cd "$output" && "$runner" "$name.vvp") 2>&1 | tee "$output/$name.log"
    grep -q "^ADC_${name^^}_COMPLETE" "$output/$name.log"
done
for stimulus in "$output"/stimuli/*.json; do
    case_name="$(basename "$stimulus" .json)"
    case_dir="$output/ti_$case_name"
    mkdir -p "$case_dir"
    extra=()
    [[ "$case_name" != normal ]] || extra+=(+VCD)
    [[ "$case_name" != wrap_guard ]] || extra+=(+WRAP_GUARD)
    [[ "$case_name" != version_guard ]] || extra+=(+VERSION_GUARD)
    (cd "$case_dir" && "$runner" "$output/ti.vvp" "+STIM=$output/stimuli/$case_name.txt" "${extra[@]}") \
        2>&1 | tee "$case_dir/sim.log"
    grep -q '^ADC_TI_TRACE_COMPLETE' "$case_dir/sim.log"
    python3 "$lesson_dir/models/ti_reference.py" --expected "$stimulus" --trace "$case_dir/trace.txt" \
        2>&1 | tee "$case_dir/verification.log"
    grep -q "^PASS TI case=$case_name " "$case_dir/verification.log"
done
echo ADC_SIMULATION_COMPLETE
