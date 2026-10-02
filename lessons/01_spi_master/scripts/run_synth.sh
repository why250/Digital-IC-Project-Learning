#!/usr/bin/env bash
set -euo pipefail
lesson_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export SPI_RESULTS="$lesson_dir/results/synth"
mkdir -p "$SPI_RESULTS"
genus_bin="${GENUS_BIN:-/opt/eda/cadence/DDI251/GENUS251/bin/genus}"
[[ -x "$genus_bin" ]] || { echo "Genus not found: $genus_bin" >&2; exit 2; }
cd "$SPI_RESULTS"
echo "Running Genus; complete log: $SPI_RESULTS/console.log"
if ! "$genus_bin" -no_gui -batch -abort_on_error -disable_user_startup \
    -log "$SPI_RESULTS/genus" -files "$lesson_dir/synth/run_genus.tcl" \
    > "$SPI_RESULTS/console.log" 2>&1; then
    tail -80 "$SPI_RESULTS/console.log" >&2
    exit 1
fi
grep -q "^SPI_SYNTHESIS_COMPLETE" "$SPI_RESULTS/console.log"
test -s "$SPI_RESULTS/mapped.v"
test -s "$SPI_RESULTS/timing.rpt"
echo "SPI_SYNTHESIS_VERIFIED_OUTPUTS"
