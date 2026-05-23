# examples-superscientist

Reproducible LAMMPS Docker environment for [superscientist](https://github.com/Chenghao-Wu/superscientist) demonstrations.

## Quickstart (consumer)

```bash
docker pull ghcr.io/Chenghao-Wu/examples-superscientist:latest
mkdir lj-demo && cd lj-demo
curl -O https://raw.githubusercontent.com/Chenghao-Wu/examples-superscientist/main/smoke-test.lmp
docker run --rm -v "$PWD:/work" -w /work \
  --user "$(id -u):$(id -g)" \
  ghcr.io/Chenghao-Wu/examples-superscientist:latest \
  lmp -in smoke-test.lmp
```

You should see `Total wall time: 0:00:00` near the end of `log.lammps`.

For interactive use:

```bash
docker run --rm -it -v "$PWD:/work" -w /work \
  --user "$(id -u):$(id -g)" \
  ghcr.io/Chenghao-Wu/examples-superscientist:latest \
  bash
```

## What's inside

| Tool | Purpose |
|---|---|
| `lmp` | LAMMPS molecular dynamics engine (CPU + MPI, conda-forge build) |
| `python` | Python 3.12 with `dpdispatcher`, `ase`, `lammpsio`, `freud`, `numpy`, `matplotlib-base` |

Base image: `mambaorg/micromamba:2.0-ubuntu24.04`. Architecture: `linux/amd64` (Apple Silicon Macs use Docker Desktop's Rosetta 2 emulation — conda-forge has no `linux-aarch64` LAMMPS build).

## Use with superscientist

The [superscientist](https://github.com/Chenghao-Wu/superscientist) repo ships host wrappers (`bin/lmp`, `bin/lmp-python`, `bin/lmp-shell`) that hide the `docker run` invocation. Add `superscientist/bin/` to your `PATH` and superscientist's `compute-backend` skill will call `lmp` transparently.

To pin a specific image version, set:

```bash
export EXAMPLES_SUPERSCIENTIST_IMAGE="ghcr.io/Chenghao-Wu/examples-superscientist:v0.1.0"
```

## Reproducing a demo bit-for-bit

Always cite a versioned tag (e.g., `v0.1.0`) in shared demos, not `:latest`. The `:latest` tag floats with `main`.

## Rebuilding the image yourself

```bash
git clone https://github.com/Chenghao-Wu/examples-superscientist
cd examples-superscientist
docker buildx build --platform linux/amd64 --load -t examples-superscientist:dev .
```

## Updating dependencies

1. Edit `environment.yml` (e.g., bump `lammps` version floor).
2. Regenerate the lockfile:
   ```bash
   uvx --from conda-lock conda-lock \
     --file environment.yml \
     --platform linux-64 \
     --kind explicit \
     --filename-template 'conda-{platform}.lock'
   ```
3. Commit `environment.yml` + the regenerated `conda-linux-64.lock` together. CI's drift check enforces consistency.

## Image tags

| Tag | Source | Use |
|---|---|---|
| `latest` | every push to `main` | Casual / development use |
| `vX.Y.Z` | git tags `vX.Y.Z` | **Cite in shared demos** |
| `sha-<short>` | every CI build on `main` | Bisecting / debugging |

## License

MIT — see [LICENSE](LICENSE).
