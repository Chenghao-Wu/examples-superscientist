#!/bin/bash
set -euo pipefail

# ── Platform detection ──
OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Linux)
    case "$ARCH" in
      x86_64)  PLATFORM="linux-64" ;;
      *)       echo "ERROR: unsupported architecture: $ARCH on Linux"; exit 1 ;;
    esac
    MICROMAMBA_BIN="micromamba-linux-64"
    ;;
  Darwin)
    case "$ARCH" in
      arm64)   PLATFORM="osx-arm64"; MICROMAMBA_BIN="micromamba-osx-arm64" ;;
      x86_64)  PLATFORM="osx-64";    MICROMAMBA_BIN="micromamba-osx-64" ;;
      *)       echo "ERROR: unsupported architecture: $ARCH on macOS"; exit 1 ;;
    esac
    ;;
  MINGW*|MSYS*|CYGWIN*)
    echo "Windows detected. LAMMPS is not available via conda-forge on Windows."
    echo ""
    echo "Two options:"
    echo "  1. WSL (recommended): Install WSL, clone this repo inside it, and re-run bootstrap.sh"
    echo "  2. Native: Download the LAMMPS Windows installer from https://packages.lammps.org/windows.html"
    echo "     then create a conda env with the Python packages:"
    echo "       micromamba create -n superscientist python=3.12 dpdispatcher ase lammpsio freud numpy matplotlib-base"
    exit 0
    ;;
  *)
    echo "ERROR: unsupported OS: $OS"
    echo "Supported: Linux (x86_64), macOS (arm64, x86_64), Windows (WSL or native LAMMPS)"
    exit 1
    ;;
esac

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCKFILE="$SCRIPT_DIR/conda-${PLATFORM}.lock"

if [ ! -f "$LOCKFILE" ]; then
  echo "ERROR: lockfile not found: $LOCKFILE"
  exit 1
fi

# ── Bootstrap micromamba if not on PATH ──
MICROMAMBA_URL="https://github.com/mamba-org/micromamba-releases/releases/latest/download/${MICROMAMBA_BIN}"
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$LOCAL_BIN"

if ! command -v micromamba >/dev/null 2>&1; then
  if [ -x "$LOCAL_BIN/micromamba" ]; then
    echo "micromamba found in $LOCAL_BIN but not on PATH"
    echo "Add $LOCAL_BIN to your PATH and re-run:"
    echo "  export PATH=\"$LOCAL_BIN:\$PATH\""
    exit 1
  fi

  echo "Downloading micromamba for ${PLATFORM}..."
  if command -v curl >/dev/null 2>&1; then
    curl -fSL --progress-bar -o "$LOCAL_BIN/micromamba" "$MICROMAMBA_URL"
  elif command -v wget >/dev/null 2>&1; then
    wget -q --show-progress -O "$LOCAL_BIN/micromamba" "$MICROMAMBA_URL"
  else
    echo "ERROR: neither curl nor wget found. Install one and re-run."
    exit 1
  fi

  chmod +x "$LOCAL_BIN/micromamba"

  if [ -x "$LOCAL_BIN/micromamba" ]; then
    echo "micromamba installed to $LOCAL_BIN/micromamba"
    echo "Add $LOCAL_BIN to your PATH and re-run:"
    echo "  export PATH=\"$LOCAL_BIN:\$PATH\""
    exit 1
  else
    echo "ERROR: failed to download micromamba from:"
    echo "  $MICROMAMBA_URL"
    exit 1
  fi
fi

# ── Create or update the superscientist environment ──
if micromamba env list 2>/dev/null | grep -q "^[[:space:]]*superscientist[[:space:]]"; then
  echo "Environment 'superscientist' already exists. Updating..."
  micromamba install -y -n superscientist --file "$LOCKFILE"
else
  echo "Creating environment 'superscientist'..."
  micromamba create -y -n superscientist --file "$LOCKFILE"
fi

# ── Verify ──
echo ""
echo "Verifying environment..."
micromamba run -n superscientist lmp -h > /dev/null 2>&1 || {
  echo "ERROR: lmp not functional in superscientist environment"
  exit 1
}
echo "  lmp: OK"

micromamba run -n superscientist python -c "import ase, numpy, lammpsio, freud; print('  python (ase, numpy, lammpsio, freud): OK')" || {
  echo "ERROR: required Python libraries not available"
  exit 1
}

echo ""
echo "Environment 'superscientist' is ready."
echo ""
echo "Usage:"
echo "  micromamba run -n superscientist lmp -in smoke-test.lmp"
echo "  micromamba run -n superscientist python"
