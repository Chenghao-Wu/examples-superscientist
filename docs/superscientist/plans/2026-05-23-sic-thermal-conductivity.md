# 3C-SiC Thermal Conductivity — Workflow Plan

**Experiment Design:** `docs/superscientist/specs/2026-05-23-sic-thermal-conductivity-design.md`
**Workflow ID:** `sic-thermal-conductivity-2026-05-23`
**Stages:** 5 total

## Stage Execution Order

1. **Stage 1: Structure Generation** — Create 1000-atom 3C-SiC zincblende structure
2. **Stage 2: Equilibration** (depends on: stage-1) — NPT + NVT relaxation to 300 K
3. **Stage 3: Green-Kubo Production** (depends on: stage-2) — NVE run sampling heat flux
4. **Stage 4: Thermal Conductivity Analysis** (depends on: stage-3) — Compute κ from HACF
5. **Stage 5: Validation** (depends on: stage-4) — Compare κ against reference range

## Per-Stage Details

### Stage 1: Structure Generation
- **Dependencies:** None
- **Inputs:** None (generated from lattice parameter)
- **Commands:** `micromamba run -n superscientist lmp -in workflow/scripts/stage-1_structure.lmp`
- **Outputs:** `stage-1/initial.data`
- **Success criteria:** 1000 atoms; correct zincblende coordination (C↔Si 4-fold); no overlapping atoms
- **Estimated walltime:** < 1 minute
- **Backend:** local
- **Dispatch mode:** sync (< 2 min)

### Stage 2: Equilibration
- **Dependencies:** stage-1
- **Inputs:** `stage-1/initial.data`
- **Commands:** `micromamba run -n superscientist lmp -in workflow/scripts/stage-2_equilibration.lmp`
- **Outputs:** `stage-2/equilibrated.data`, `stage-2/equilibrated.restart`
- **Success criteria:** NPT: P ~0 ± 1 bar, density converged (< 0.1% in last 20 ps). NVT: T 300 ± 5 K, energy drift < 0.1% over final 20 ps
- **Estimated walltime:** ~10 minutes
- **Backend:** local
- **Dispatch mode:** async (> 2 min, launched via tmux)

### Stage 3: Green-Kubo Production
- **Dependencies:** stage-2
- **Inputs:** `stage-2/equilibrated.data`, `stage-2/equilibrated.restart`
- **Commands:** `micromamba run -n superscientist lmp -in workflow/scripts/stage-3_production.lmp`
- **Outputs:** `stage-3/heat_flux.dat`, `stage-3/production.log`
- **Success criteria:** Energy drift < 0.01% over 500 ps; T 300 ± 15 K; HACF decays to < 10% of peak within 100 ps; no atom displaced > 0.1 Å from start
- **Estimated walltime:** ~1–2 hours
- **Backend:** local
- **Dispatch mode:** async (> 2 min, launched via tmux)

### Stage 4: Thermal Conductivity Analysis
- **Dependencies:** stage-3
- **Inputs:** `stage-3/heat_flux.dat`
- **Commands:** `micromamba run -n superscientist python workflow/scripts/stage-4_analysis.py`
- **Outputs:** `stage-4/kappa_report.txt`, `stage-4/hacf_plot.png`, `stage-4/running_integral_plot.png`
- **Success criteria:** HACF envelope < 10% of peak within correlation window; plateau slope < 5% of mean over final 50 ps; per-component κ within < 30%
- **Estimated walltime:** < 1 minute
- **Backend:** local
- **Dispatch mode:** sync (< 2 min)

### Stage 5: Validation
- **Dependencies:** stage-4
- **Inputs:** `stage-4/kappa_report.txt`
- **Commands:** `micromamba run -n superscientist python workflow/scripts/stage-5_validation.py`
- **Outputs:** `stage-5/validation_report.txt`
- **Success criteria:** κ within 200–350 W/m·K (published Tersoff MD range for 3C-SiC at 300 K)
- **Estimated walltime:** < 1 minute
- **Backend:** local
- **Dispatch mode:** sync (< 2 min)
