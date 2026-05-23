# examples-superscientist

Reproducible LAMMPS conda environment for [superscientist](https://github.com/Chenghao-Wu/superscientist) demonstrations.

## Quickstart

```bash
git clone https://github.com/Chenghao-Wu/examples-superscientist
cd examples-superscientist
bash bootstrap.sh
```

Once the environment is ready:

```bash
micromamba run -n superscientist lmp -in smoke-test.lmp
```

You should see `Total wall time: 0:00:00` near the end of `log.lammps`.

## What's inside

| Tool | Purpose |
|---|---|
| `lmp` | LAMMPS molecular dynamics engine (CPU + MPI, conda-forge build) |
| `python` | Python 3.12 with `dpdispatcher`, `ase`, `lammpsio`, `freud`, `numpy`, `matplotlib-base` |

## Supported platforms

| Platform | Status |
|---|---|
| linux-64 (x86_64) | Validated in CI |
| osx-arm64 (Apple Silicon) | Validated in CI |
| osx-64 (Intel Mac) | Validated in CI |
| Windows | Use [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) and follow the Linux quickstart, or install the [native LAMMPS Windows package](https://packages.lammps.org/windows.html) and create the conda env manually |

## Use with superscientist

The [superscientist](https://github.com/Chenghao-Wu/superscientist) Claude Code skill calls `micromamba run -n superscientist lmp` directly when the `superscientist` conda environment is present.

## Environment descriptor

This repo serves as the canonical source of truth for the LAMMPS environment. Two files document how to bootstrap and invoke the environment:

| File | Audience | Purpose |
|---|---|---|
| `superscientist.json` | Machines (JSON) | Command argv arrays for `lmp`, `python`, `shell` |
| `AGENTS.md` | Humans & AI agents | Setup instructions and usage examples |

Tools and Claude Code skills can read `superscientist.json` to discover how to invoke LAMMPS without hardcoding `docker run` or `micromamba run`.

## Updating dependencies

1. Edit `environment.yml` (e.g., bump `lammps` version floor).
2. Regenerate all lockfiles:
   ```bash
   for plat in linux-64 osx-arm64 osx-64; do
     uvx --from conda-lock conda-lock \
       --file environment.yml \
       --platform $plat \
       --kind explicit \
       --filename-template 'conda-{platform}.lock'
   done
   ```
3. Commit `environment.yml` + all regenerated lockfiles together. CI's drift check enforces consistency.

## License

MIT — see [LICENSE](LICENSE).
