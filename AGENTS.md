# Superscientist Environment

## Setup

Run once to install micromamba and create the conda environment:

```bash
bash bootstrap.sh
```

## Running LAMMPS

All LAMMPS and Python commands go through the `superscientist` conda environment:

```bash
micromamba run -n superscientist lmp -in input.lmp
micromamba run -n superscientist python analysis.py
micromamba run -n superscientist bash
```

## Environment details

- **Env name:** `superscientist`
- **Runner:** `micromamba`
- **Bootstrap:** `bash bootstrap.sh`
- **Lockfiles:** `conda-linux-64.lock`, `conda-osx-arm64.lock`, `conda-osx-64.lock`

See `superscientist.json` for machine-readable configuration.
