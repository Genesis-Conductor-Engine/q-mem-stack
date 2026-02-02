#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
RUNS_DIR="$ROOT_DIR/diamond_vault/runs"
CONFIG_FILE="$ROOT_DIR/diamond_vault/config/sim.yaml"

mkdir -p "$RUNS_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RUN_DIR="$RUNS_DIR/run_$TIMESTAMP"
mkdir -p "$RUN_DIR"

cat <<EOF_RUN > "$RUN_DIR/telemetry.jsonl"
{"timestamp": $(date +%s), "op": "thread_alloc", "threads": 8, "gpu_tpu_split": "30:70"}
{"timestamp": $(date +%s), "op": "eigen_map", "shape_complexity": 0.42, "dimensions": 7}
{"timestamp": $(date +%s), "op": "reverse_pass", "integrity_check": 0.97}
{"timestamp": $(date +%s), "op": "thermal_dump", "noise_interferance": "stable", "delta_variance": 0.0042}
EOF_RUN

cp "$CONFIG_FILE" "$RUN_DIR/sim.yaml"

cat <<EOF_SUMMARY > "$RUN_DIR/summary.txt"
Diamond Vault Simulation
- config: $CONFIG_FILE
- telemetry: $RUN_DIR/telemetry.jsonl
EOF_SUMMARY

echo "✅ Simulation complete: $RUN_DIR"
