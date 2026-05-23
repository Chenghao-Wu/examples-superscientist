# 3C-SiC Thermal Conductivity via Green-Kubo MD — Experiment Design

**Objective:** Compute the thermal conductivity (κ) of 3C-SiC at 300 K using equilibrium molecular dynamics with the Green-Kubo formalism. Reproduce a known result in the published Tersoff range (200–350 W/m·K).

**System/Problem:** 3C-SiC (zincblende), 1000 atoms — 5×5×5 conventional cubic unit cells (8 atoms/cell: 4 C + 4 Si), isotropic κ.

**Method:** Green-Kubo equilibrium MD — integrate the heat flux autocorrelation function (HACF):
κ = (V / k_B T²) ∫₀^∞ ⟨J(0)J(t)⟩ dt. For cubic 3C-SiC, κ = κ_xx = κ_yy = κ_zz.

**Software:** LAMMPS (≥2024.08.29) with `pair_style tersoff`; Python 3.12 + numpy + matplotlib for analysis. All invoked via `micromamba run -n superscientist`.

## Method Validation

- **Green-Kubo:** Well-established for lattice thermal conductivity of crystalline semiconductors. Standard method implemented in LAMMPS (`compute heat/flux`, `fix ave/correlate`).
- **Tersoff for SiC:** Original parameterization by J. Tersoff, Phys. Rev. B 39, 5566 (1989). Widely used for SiC thermal transport. Literature reports κ_300K for 3C-SiC with Tersoff in ~200–350 W/m·K range.
- **Known limitations:**
  - Finite-size suppression: 1000 atoms cannot support phonons with λ > ~3 nm, systematically reducing κ by ~20–40% vs. bulk
  - Classical MD: no quantum heat capacity correction; error is moderate at 300 K
  - Tersoff tends to overestimate κ relative to experiment (misses some anharmonic channels)
  - HACF convergence: long-time tail is noisy; reported value depends on integration cutoff

## Computational Stages

### Stage 1: Structure Generation
- **Purpose:** Create the 3C-SiC atomic configuration
- **Inputs:** None (built from lattice parameter)
- **Parameters:** Lattice parameter a = 4.359 Å; 5×5×5 replication of the conventional cubic cell → 1000 atoms (500 C + 500 Si); LAMMPS `lattice diamond` for zincblende basis
- **Success criteria:** 1000 atoms total; correct zincblende structure verified by coordination count (each C has 4 Si neighbors and vice versa); no overlapping atoms
- **Expected walltime:** < 1 minute
- **Known pitfalls:** Wrong lattice constant shifts phonon frequencies (mitigated: NPT relaxation in Stage 2 finds Tersoff equilibrium). Wrong atom ordering obtained (mitigated: coordination check as success criterion).

### Stage 2: Equilibration
- **Purpose:** Bring system to 300 K and Tersoff equilibrium volume
- **Inputs:** Structure from Stage 1
- **Parameters:**
  - NPT: T = 300 K, P = 0 bar (isotropic), Tdamp = 100 fs, Pdamp = 1000 fs, 1 fs timestep, 100 ps
  - NVT: T = 300 K, Tdamp = 100 fs, 1 fs timestep, 50 ps
- **Success criteria:**
  - NPT phase: P ~0 ± 1 bar; density converged (< 0.1% change in last 20 ps)
  - NVT phase: T stable at 300 ± 5 K; energy drift < 0.1% over final 20 ps
- **Expected walltime:** ~10 minutes on 4 cores
- **Known pitfalls:** Insufficient NPT leaves residual stress → κ affected (mitigated: convergence checks on P, density, energy). Tdamp too small over-damps phonons (mitigated: 100 fs is standard for solids).

### Stage 3: Green-Kubo Production
- **Purpose:** Sample equilibrium heat flux for the HACF
- **Inputs:** Equilibrated structure + velocities from Stage 2
- **Parameters:**
  - NVE ensemble, 0.5 fs timestep, 500 ps total
  - Sample heat flux every 2 fs (`compute heat/flux`, `fix ave/correlate` with Nevery=2, Nrepeat=1)
  - Correlation length = 100 ps
- **Success criteria:** Energy drift < 0.01% over full run; T remains 300 ± 15 K (NVE fluctuation); HACF decays to near-zero within the 100 ps correlation window; no atom displaced > 0.1 Å from its starting position over the full 500 ps run (solid phase maintained)
- **Expected walltime:** ~1–2 hours on 4 cores
- **Known pitfalls:** Timestep too large → energy drift in NVE (mitigated: 0.5 fs is conservative for light C atoms). Trajectory too short → HACF tail under-sampled (mitigated: 500 ps is adequate for 1000-atom SiC at 300 K). HACF sampling too coarse → miss fast initial decay (mitigated: 2 fs interval resolves phonons up to ~250 THz).

### Stage 4: Thermal Conductivity Analysis
- **Purpose:** Compute κ from the HACF
- **Inputs:** Heat flux time series from Stage 3
- **Parameters:**
  - Trapezoidal integration of HACF → running integral κ(τ)
  - Plateau identified where HACF has decayed to < 10% of peak
  - Average over x, y, z components
  - Error estimated from component spread and plateau region variation
- **Success criteria:** HACF envelope decays to < 10% of zero-time peak within the 100 ps correlation window; running integral plateau slope < 5% of plateau mean over the final 50 ps of the correlation window; per-component κ agree within < 30% (isotropy check)
- **Expected walltime:** < 1 minute
- **Known pitfalls:** Noisy HACF tail → integral diverges (mitigated: cutoff when envelope < 10% of zero-time value). No clear plateau → no forced number (mitigated: report as inconclusive, increase trajectory length).

### Stage 5: Validation
- **Purpose:** Compare computed κ against reference values
- **Inputs:** κ from Stage 4
- **Success criteria:** κ falls within 200–350 W/m·K (published Tersoff range for 3C-SiC at 300 K). Finite-size depression of ~20–40% expected.
- **Known pitfalls:** Comparing against experimental ~360 W/m·K without accounting for finite-size + classical-statistics errors (mitigated: reference range is Tersoff-specific, not experimental).

## Parameter Sensitivity

| Parameter | Value | Rationale | If wrong |
|-----------|-------|-----------|----------|
| Lattice constant (initial) | 4.359 Å | Experimental value; NPT relaxes to Tersoff equilibrium | Only affects NPT convergence speed if off |
| System size | 1000 atoms (5×5×5) | Smallest practical size; ~1–2 hour runtime | Finite-size suppression of κ by ~20–40% — designed in as known limitation |
| Timestep (production) | 0.5 fs | Conservative for SiC (C atoms are light); ~56 points per fastest phonon period | Too large → energy drift in NVE, corrupt flux. 0.5 fs is safe |
| Production length | 500 ps | HACF for SiC decays within ~50–100 ps at 300 K | Too short → noisy HACF, no plateau. Plateau analysis reveals this |
| Correlation length | 100 ps | Longer than HACF decay, shorter than total run (5 independent blocks) | Too short → truncate HACF, underestimate κ. Too long → fewer blocks, noisier |
| HACF sampling interval | 2 fs | Resolves fast initial decay (phonon modes up to ~35 THz) | Too coarse → miss fast decay, underestimate κ |
| NPT duration | 100 ps | Sufficient for 1000-atom solid to relax cell dimensions | Too short → unconverged density. Density check catches this |
| Tdamp | 100 fs | Standard for solids; balances T control vs. minimal phonon damping | Too small → thermostat artifact damps phonons. Too large → poor T control |

No parameter sensitivity sweep is planned for this first-pass calculation. The finite-size uncertainty is the dominant error source and is documented rather than swept.

## Expected Outputs

1. κ value (mean ± 1σ across x/y/z components), annotated as finite-size-affected lower bound
2. HACF plot — decay vs. correlation time
3. Running integral plot — κ(τ) with plateau and extracted value
4. Equilibration diagnostics — T, P, energy, density traces
5. Energy conservation plot from NVE production

## Resource Estimate

| Stage | Cores | Walltime | Storage |
|-------|-------|----------|---------|
| 1. Structure generation | 1 | < 1 min | negligible |
| 2. Equilibration | 4 | ~10 min | ~10 MB |
| 3. GK production | 4 | ~1–2 hours | ~100 MB |
| 4. Analysis | 1 | < 1 min | ~1 MB |
| 5. Validation | — | < 1 min | — |
| **Total** | | **~1.5–2.5 hours** | **~120 MB** |

All stages run locally. No HPC required. The only stage exceeding 1 hour is Stage 3 (GK production).
