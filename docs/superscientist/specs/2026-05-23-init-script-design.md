# init.sh — Experiment Scaffold Script

**Purpose:** A single `init.sh <name>` script that scaffolds a new experiment directory under `experiments/<name>/` with the two files superscientist needs to operate: `superscientist.json` and `AGENTS.md`.

## Behavior

```
bash init.sh sic-thermal-conductivity
```

1. Validate that `<name>` is provided; print usage and exit 1 if not
2. Create `experiments/<name>/` (parents included)
3. Copy repo root's `superscientist.json` and `AGENTS.md` into `experiments/<name>/`
4. Print confirmation: `Experiment scaffold created at experiments/<name>/`

## Error handling

- **No name argument:** print `Usage: bash init.sh <experiment-name>` to stderr, exit 1
- **Directory already exists:** print `ERROR: experiments/<name>/ already exists` to stderr, exit 1 — no force/overwrite flag
- **Missing source files:** `set -euo pipefail` handles this; cp will fail the script if root files are absent

## What it does NOT do

- Does NOT create stage subdirectories — those come from workflow-planning
- Does NOT create `workflow-state.json` — that's checkpoint-management's job
- Does NOT create any input files, templates, or scripts — those are experiment-specific and come from experiment-design + executing-workflows

## Rationale

The two files (`superscientist.json` and `AGENTS.md`) are the superscientist "environment descriptor" files that tell superscientist skills how to invoke LAMMPS and Python. Copying them from root into `experiments/<name>/` means each experiment directory is self-contained and can be discovered by superscientist tooling. The rest of the experiment structure is built out incrementally by the workflow skills.

## Style

- Bash script matching `bootstrap.sh` conventions: `set -euo pipefail`, same comment style
- Non-interactive (like `bootstrap.sh`)
