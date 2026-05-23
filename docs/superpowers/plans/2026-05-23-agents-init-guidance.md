# AGENTS.md — Experiment Initialization Guidance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a "Starting an experiment" section to `AGENTS.md` documenting `init-experiment.sh`.

**Architecture:** Single-file edit. Insert a new markdown section between "Running LAMMPS" and "Environment details" in `AGENTS.md`. No new files, no logic changes.

**Tech Stack:** Markdown.

---

### Task 1: Add "Starting an experiment" section to AGENTS.md

**Files:**
- Modify: `AGENTS.md`

- [ ] **Step 1: Insert the new section after the "Running LAMMPS" block**

Open `AGENTS.md`. The file currently has three sections:

1. `## Setup`
2. `## Running LAMMPS` (ends with the `micromamba run -n superscientist bash` code block)
3. `## Environment details`

Insert the new section between sections 2 and 3. The addition:

```markdown
## Starting an experiment

Scaffold a new experiment directory:

```bash
bash init-experiment.sh sic-thermal-conductivity
```

This creates `experiments/sic-thermal-conductivity/` with copies of `superscientist.json` and `AGENTS.md` — everything superscientist needs to discover the environment. From there, use the superscientist skills (experiment-design → workflow-planning → executing-workflows) to build out the experiment.
```

The resulting file:

```markdown
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

## Starting an experiment

Scaffold a new experiment directory:

```bash
bash init-experiment.sh sic-thermal-conductivity
```

This creates `experiments/sic-thermal-conductivity/` with copies of `superscientist.json` and `AGENTS.md` — everything superscientist needs to discover the environment. From there, use the superscientist skills (experiment-design → workflow-planning → executing-workflows) to build out the experiment.

## Environment details

- **Env name:** `superscientist`
- **Runner:** `micromamba`
- **Bootstrap:** `bash bootstrap.sh`
- **Lockfiles:** `conda-linux-64.lock`, `conda-osx-arm64.lock`, `conda-osx-64.lock`

See `superscientist.json` for machine-readable configuration.
```

- [ ] **Step 2: Verify the file renders correctly**

```bash
# Check the section headers are in the right order
grep '^## ' AGENTS.md
```

Expected output:
```
## Setup
## Running LAMMPS
## Starting an experiment
## Environment details
```

- [ ] **Step 3: Commit**

```bash
git add AGENTS.md
git commit -m "docs: add experiment initialization guidance to AGENTS.md

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```
