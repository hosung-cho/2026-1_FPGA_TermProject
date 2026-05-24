#!/usr/bin/env bash
set -euo pipefail

export PATH=/home/inseong/.local/verilator-5.036/bin:$PATH

cd "$(dirname "$0")"
make -f Makefile.verilator run
