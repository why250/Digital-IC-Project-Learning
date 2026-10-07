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
output="$lesson_dir/results/stream"
mkdir -p "$output"
bash "$lesson_dir/scripts/run_models.sh"
python3 "$lesson_dir/models/stream_reference.py" --generate "$output" --models "$lesson_dir/results/models/experiments.json"
"${compiler[@]}" -g2012 -Wall -s tb_stream -o "$output/stream.vvp" \
    "$lesson_dir"/rtl/*.sv "$lesson_dir/tb/tb_stream.sv" > "$output/compile.log" 2>&1
(cd "$output" && "$runner" stream.vvp) 2>&1 | tee "$output/sim.log"
grep -q '^ADC_STREAM_SIMULATION_COMPLETE samples=65540' "$output/sim.log"
python3 "$lesson_dir/models/stream_reference.py" --verify "$output" 2>&1 | tee "$output/verification.log"
grep -q '^ADC_STREAM_VERIFICATION_COMPLETE' "$output/verification.log"
