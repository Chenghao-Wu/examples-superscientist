# AGENTS.md — Experiment Initialization Guidance

**Purpose:** Add a "Starting an experiment" section to `AGENTS.md` documenting `init-experiment.sh`.

## Addition

Insert between "Running LAMMPS" and "Environment details":

```markdown
## Starting an experiment

Scaffold a new experiment directory:

\`\`\`bash
bash init-experiment.sh sic-thermal-conductivity
\`\`\`

This creates `experiments/sic-thermal-conductivity/` with copies of `superscientist.json` and `AGENTS.md` — everything superscientist needs to discover the environment. From there, use the superscientist skills (experiment-design → workflow-planning → executing-workflows) to build out the experiment.
```

## Rationale

- Matches existing AGENTS.md style: concise sections, code blocks, direct commands
- Shows a concrete example name rather than `<placeholder>` syntax
- Points to the next step (superscientist workflow skills) so a reader knows what to do after scaffolding
