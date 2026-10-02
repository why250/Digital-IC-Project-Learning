#!/usr/bin/env bash
set -euo pipefail
lesson_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
project_dir="$(cd "$lesson_dir/../.." && pwd)"
local_tools="$project_dir/.tools/iverilog/root/usr"
if [[ -x "$local_tools/bin/iverilog" ]]; then
    compiler=("$local_tools/bin/iverilog" -B "$local_tools/lib64/ivl")
    runner="$local_tools/bin/vvp"
elif command -v iverilog >/dev/null && command -v vvp >/dev/null; then
    compiler=(iverilog)
    runner="$(command -v vvp)"
else
    echo "No Icarus: run bash tools/bootstrap_iverilog.sh" >&2
    exit 2
fi
if (( $# > 0 )); then dividers=("$@"); else dividers=(1 3 25); fi
for divider in "${dividers[@]}"; do
    [[ "$divider" =~ ^[1-9][0-9]*$ ]] || { echo "Invalid divider" >&2; exit 2; }
    output="$lesson_dir/results/sim/div$divider"
    mkdir -p "$output"
    "${compiler[@]}" -g2012 -Wall -s tb_spi_master \
        -P "tb_spi_master.HALF_PERIOD_CYCLES=$divider" \
        -o "$output/test.vvp" "$lesson_dir/rtl/spi_master.sv" \
        "$lesson_dir/tb/tb_spi_master.sv" 2>&1 | tee "$output/compile.log"
    (cd "$output" && "$runner" test.vvp) 2>&1 | tee "$output/sim.log"
    grep -q "^PASS divider=$divider transactions=258 " "$output/sim.log"
    python3 "$project_dir/tools/vcd_to_svg.py" "$output/spi_master.vcd" \
        --output "$output/spi_first_frame.svg"
done
echo "SPI_SIMULATION_COMPLETE"
