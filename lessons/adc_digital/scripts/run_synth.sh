#!/usr/bin/env bash
set -euo pipefail
lesson_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
genus_bin="${GENUS_BIN:-/opt/eda/cadence/DDI251/GENUS251/bin/genus}"
[[ -x "$genus_bin" ]] || { echo 'Genus unavailable' >&2; exit 2; }
if [[ "${1:-}" == --verify ]]; then
    shift
    for top in sar_controller flash_encoder pipeline_align dwa_encoder adc_fixed_correct adc_async_fifo ti_adc_backend; do
        report_dir="$lesson_dir/results/synth/$top"
        grep -q "^ADC_SYNTHESIS_COMPLETE top=$top" "$report_dir/console.log"
        grep -q 'Normal exit' "$report_dir/console.log"
        python3 "$lesson_dir/models/check_synth.py" "$report_dir" "$top"
    done
    echo 'ADC_SYNTHESIS_VERIFIED_OUTPUTS tops=7 mode=existing-reports'
    exit 0
fi
if (( $# )); then tops=("$@"); else
    tops=(sar_controller flash_encoder pipeline_align dwa_encoder adc_fixed_correct adc_async_fifo ti_adc_backend)
fi
for top in "${tops[@]}"; do
    case "$top" in sar_controller|flash_encoder|pipeline_align|dwa_encoder|adc_fixed_correct|adc_async_fifo|ti_adc_backend) ;;
        *) echo "Unsupported synthesis top: $top" >&2; exit 2;; esac
    export ADC_TOP="$top" ADC_RESULTS="$lesson_dir/results/synth/$top"
    mkdir -p "$ADC_RESULTS"
    echo "Synthesis starting: $top"
    if ! (cd "$ADC_RESULTS" && "$genus_bin" -no_gui -batch -abort_on_error -disable_user_startup \
        -log "$ADC_RESULTS/genus" -files "$lesson_dir/synth/run_genus.tcl" \
        > "$ADC_RESULTS/console.log" 2>&1); then
        tail -60 "$ADC_RESULTS/console.log" >&2; exit 1
    fi
    grep -q "^ADC_SYNTHESIS_COMPLETE top=$top" "$ADC_RESULTS/console.log"
    grep -q 'Normal exit' "$ADC_RESULTS/console.log"
    python3 "$lesson_dir/models/check_synth.py" "$ADC_RESULTS" "$top"
done
echo "ADC_SYNTHESIS_VERIFIED_OUTPUTS tops=${#tops[@]}"
