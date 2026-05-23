#!/bin/bash
set -e

# ── Infrastructure ──
command -v uvx >/dev/null 2>&1 || { echo "FAIL: uvx not found"; exit 1; }
uvx --from dpdispatcher dpdisp --help > /dev/null 2>&1 || { echo "FAIL: dpdispatcher not accessible via uvx"; exit 1; }

# ── Project-specific ──
command -v micromamba >/dev/null 2>&1 || { echo "FAIL: micromamba not found"; exit 1; }

# Verify LAMMPS is available
micromamba run -n superscientist lmp -h > /dev/null 2>&1 || { echo "FAIL: LAMMPS (lmp) not found in superscientist environment"; exit 1; }

# Verify Python and required libraries are available
PYTHON_CMD="micromamba run -n superscientist python"
$PYTHON_CMD --version > /dev/null 2>&1 || { echo "FAIL: python not found in superscientist environment"; exit 1; }
$PYTHON_CMD -c "import numpy" || { echo "FAIL: numpy not available"; exit 1; }
$PYTHON_CMD -c "import matplotlib" || { echo "FAIL: matplotlib not available"; exit 1; }
$PYTHON_CMD -c "import freud" || { echo "FAIL: freud not available"; exit 1; }
$PYTHON_CMD -c "import lammpsio" || { echo "FAIL: lammpsio not available"; exit 1; }

echo "Environment ready."
