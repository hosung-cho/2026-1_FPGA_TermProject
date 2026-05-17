#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Vivado Tcl Batch mode simulation starts..."
vivado -mode batch -source run_sim.tcl -notrace

echo
echo "========================================="
echo "[Cleanup] Remove unnecessary Vivado temp files"
echo "========================================="

rm -rf .Xil
rm -f vivado*.jou vivado*.log

echo "[Cleanup] done"
