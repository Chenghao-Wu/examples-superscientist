#!/bin/bash
set -e

# ── Infrastructure ──
command -v docker >/dev/null 2>&1 || { echo "FAIL: docker not found"; exit 1; }
command -v uvx >/dev/null 2>&1 || { echo "FAIL: uvx not found"; exit 1; }
command -v tmux >/dev/null 2>&1 || { echo "FAIL: tmux not found"; exit 1; }
uvx --from dpdispatcher dpdisp --help > /dev/null 2>&1 || { echo "FAIL: dpdispatcher not accessible via uvx"; exit 1; }

# ── LAMMPS wrapper ──
LMP="/home/zhenghaowu/.claude/plugins/cache/superscientist-marketplace/superscientist/0.1.0/bin/lmp"
LMP_PYTHON="/home/zhenghaowu/.claude/plugins/cache/superscientist-marketplace/superscientist/0.1.0/bin/lmp-python"
test -x "$LMP" || { echo "FAIL: lmp wrapper not found or not executable at $LMP"; exit 1; }
test -x "$LMP_PYTHON" || { echo "FAIL: lmp-python wrapper not found or not executable at $LMP_PYTHON"; exit 1; }
$LMP --help > /dev/null 2>&1 || { echo "FAIL: lmp Docker wrapper not functional (image pull failed?)"; exit 1; }

# ── Python environment (inside Docker) ──
$LMP_PYTHON -c "import ase; import numpy; import lammpsio; print('ASE', ase.__version__)" || { echo "FAIL: required Python libraries not available in Docker image (ase, numpy, lammpsio)"; exit 1; }

echo "Environment ready."
