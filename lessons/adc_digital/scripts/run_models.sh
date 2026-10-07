#!/usr/bin/env bash
set -euo pipefail
lesson_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
output="$lesson_dir/results/models"
mkdir -p "$output"
python3 "$lesson_dir/models/experiments.py" --output "$output" 2>&1 | tee "$output/models.log"
grep -q '^ADC_MODELS_COMPLETE lessons=20' "$output/models.log"
echo ADC_MODEL_VERIFICATION_COMPLETE
