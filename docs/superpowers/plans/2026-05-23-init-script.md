# init.sh — Experiment Scaffold Script Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add `init.sh` at repo root that scaffolds `experiments/<name>/` with `superscientist.json` and `AGENTS.md`.

**Architecture:** Single bash script at repo root. Takes one positional argument (experiment name), creates the directory, copies the two env descriptor files from root. `set -euo pipefail` handles missing source files. No external dependencies.

**Tech Stack:** Bash, matching `bootstrap.sh` conventions.

---

### Task 1: Create `init.sh`

**Files:**
- Create: `init.sh`

- [ ] **Step 1: Write `init.sh`**

```bash
#!/bin/bash
set -euo pipefail

# ── Argument validation ──
if [ $# -eq 0 ]; then
  echo "Usage: bash init.sh <experiment-name>" >&2
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
```

- [ ] **Step 2: Make `init.sh` executable**

```bash
chmod +x init.sh
```

- [ ] **Step 3: Test the golden path**

```bash
bash init.sh demo-experiment
```

Expected output: `Experiment scaffold created at experiments/demo-experiment/`

- [ ] **Step 4: Verify the scaffolded files**

```bash
ls experiments/demo-experiment/
diff superscientist.json experiments/demo-experiment/superscientist.json
diff AGENTS.md experiments/demo-experiment/AGENTS.md
```

Expected: both files exist, diffs show no difference.

- [ ] **Step 5: Test error — no argument**

```bash
bash init.sh
```

Expected: `Usage: bash init.sh <experiment-name>` on stderr, exit code 1.

- [ ] **Step 6: Test error — directory exists**

```bash
bash init.sh demo-experiment
```

Expected: `ERROR: experiments/demo-experiment/ already exists` on stderr, exit code 1.

- [ ] **Step 7: Clean up test directory**

```bash
rm -rf experiments/demo-experiment
```

- [ ] **Step 8: Commit**

```bash
git add init.sh
git commit -m "feat: add init.sh for experiment directory scaffolding

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>"
```
