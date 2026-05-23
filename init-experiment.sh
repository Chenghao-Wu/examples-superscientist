#!/bin/bash
set -euo pipefail

# ── Argument validation ──
if [ $# -eq 0 ]; then
  echo "Usage: bash init-experiment.sh <experiment-name>" >&2
  exit 1
fi

NAME="$1"
EXP_DIR="experiments/${NAME}"

# ── Pre-flight checks ──
if [ -d "$EXP_DIR" ]; then
  echo "ERROR: ${EXP_DIR}/ already exists" >&2
  exit 1
fi

# ── Scaffold ──
mkdir -p "$EXP_DIR"
cp superscientist.json AGENTS.md "$EXP_DIR"

echo "Experiment scaffold created at ${EXP_DIR}/"
