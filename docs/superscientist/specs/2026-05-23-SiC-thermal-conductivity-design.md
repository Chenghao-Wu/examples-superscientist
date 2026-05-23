# 3C-SiC Thermal Conductivity via Green-Kubo EMD — Experiment Design

**Objective:** Compute thermal conductivity κ of 3C-SiC at 300 K using equilibrium molecular dynamics
**System/Problem:** 3C-SiC (zinc blende, cubic, isotropic), ~1000 atoms, single temperature
**Method:** Green-Kubo equilibrium MD — integrate heat flux autocorrelation function (HACF) from an NVE trajectory
**Software:** LAMMPS (Tersoff potential) + Python (numpy, matplotlib) for HACF analysis. All via the project Docker image (`lmp` wrapper). MPI: 4 processors.

## Method Validation

Green-Kubo EMD is well-established for computing thermal conductivity from equilibrium fluctuations (Green 1954, Kubo 1957). Extensively applied to SiC: Li et al. J. Appl. Phys. 83 (1998), Termentzidis et al. J. Appl. Phys. 121 (2017).

Tersoff potential for Si-C: parameterized by Tersoff, Phys. Rev. B 39 (1989). Validated for thermal properties of 3C-SiC across multiple studies.

**Known limitations:**
- Classical statistics at 300 K underestimate phonon heat capacity (3C-SiC Debye ~1200 K) — quantum correction required
- ~1000-atom cell suppresses long-wavelength phonons — result will be a lower bound, ~40-60% of experimental κ (~360 W/m·K)
- HACF integration converges slowly — insufficient correlation time is the most common failure mode

## Computational Stages

### Stage 1: Structure Generation
- **Purpose:** Build 3C-SiC supercell
- **Inputs:** None (generated from scratch)
- **Parameters:** Zinc blende (F-43m, #216), lattice constant 4.3596 Å (Tersoff equilibrium), ~5×5×5 conventional cells → ~1000 atoms
- **Success criteria:** 1000 ± 8 atoms, 1:1 Si:C stoichiometry, min interatomic distance ≥ 1.5 Å
- **Expected walltime:** < 1 sec
- **Known pitfalls:** Wrong lattice constant shifts Tersoff energy minimum → NVE drift. Verify lattice constant against Tersoff published value. Off by ≥ 0.05 Å causes problematic hydrostatic stress.

### Stage 2: Equilibration (NVT)
- **Purpose:** Bring structure to 300 K equilibrium
- **Inputs:** Structure data file from Stage 1
- **Parameters:** timestep 0.5 fs, Nosé-Hoover NVT, T = 300 K, 50 ps (100,000 steps), Tdamp = 100 fs, initial velocities drawn from Maxwell-Boltzmann at 300 K, seed = 87287, 4 MPI procs
- **Success criteria:** T stable at 300 ± 5 K over final 10 ps, energy drift < 0.1% over final 10 ps
- **Expected walltime:** ~1-2 min
- **Known pitfalls:** Insufficient equilibration → residual stress bleeds into NVE → HACF corrupted. Gate: check T(t) and U(t) plots final 10 ps. Tdamp too large → temperature oscillation; too small → overdamped dynamics.

### Stage 3: NVE Production with Heat Flux Sampling
- **Purpose:** Collect equilibrium heat flux trajectory for Green-Kubo integration
- **Inputs:** Equilibrated positions + velocities from Stage 2
- **Parameters:** timestep 0.5 fs, NVE ensemble, 200 ps (400,000 steps), sample `compute heat/flux` every 2 fs, seed = 87287 (same as equilibration for velocity continuity), 4 MPI procs
- **Success criteria:** HACF decays to < 5% of peak within 20 ps, energy drift < 0.01% over production
- **Expected walltime:** ~5-10 min
- **Known pitfalls:** HACF doesn't decay → window too short, extend production. Energy drift in NVE → redo Stage 2. Finite-size suppression → result is a lower bound (accepted for exploratory stage).

### Stage 4: HACF Analysis and κ Calculation
- **Purpose:** Integrate HACF, apply quantum correction, report κ. Also verifies Stage 3 plateau convergence.
- **Inputs:** Heat flux time series (J0Jt.dat) from Stage 3
- **Parameters:** Correlation window ~20 ps (tuned from HACF decay inspection in Stage 3); quantum correction via Debye model heat capacity ratio: κ_quantum = κ_classical × (C_V^Debye / 3k_B), evaluated at 300 K with Θ_D = 1200 K for 3C-SiC (correction factor ~1.5)
- **Success criteria:** κ(t) running integral plateaus (slope < 0.01 W/m·K per ps over final 5 ps of correlation window), κ within 100–300 W/m·K (plausible range accounting for finite-size suppression to ~40-60% of experimental ~360 W/m·K)
- **Expected walltime:** seconds
- **Known pitfalls:** Integral drifts if run into noisy HACF tail — truncate at first zero-crossing or 1/e decay point of HACF. Insufficient plateau → loop back to Stage 3 for longer production or additional seeds. Missing/wrong quantum correction → systematically low κ (factor ~1.5 matters).

## Parameter Sensitivity

| Parameter | Chosen | Rationale | Effect if wrong |
|---|---|---|---|
| Lattice constant | 4.3596 Å | Tersoff equilibrium for 3C-SiC | ±0.05 Å → hydrostatic stress → NVE drift |
| Timestep | 0.5 fs | Conservative for light C atoms (12 amu) with stiff Si-C bonds | 1.0 fs → energy drift; 2.0 fs → likely unstable |
| Equilibration length | 50 ps | 2-3× typical phonon relaxation time at 300 K | Too short → residual stress in NVE. Diagnostics gate this |
| Production length | 200 ps | Typical for converged HACF in ~1000-atom SiC | Too short → no plateau. HACF decay inspection validates |
| Correlation window | ~20 ps | Should capture full decay at 300 K | Too short → truncation error; too long → noisy tail corrupts integral |
| Tdamp (NVT) | 100 fs | Standard ~20× timestep | Too weak → slow equilibration; too strong → overdamped |

Parameters are gated on success criteria (T stability, energy drift, HACF plateau) rather than swept — if criteria pass, parameters are sufficient.

## Expected Outputs

1. `data.3c-sic` — LAMMPS data file
2. `log.equil` — equilibration log (T(t), U(t) verification)
3. `log.prod` — production log (energy conservation)
4. `J0Jt.dat` — heat flux autocorrelation time series
5. Summary plot: HACF + running κ integral with final κ value
6. **κ(300 K) ≈ X W/m·K** (quantum-corrected)

## Resource Estimate

| Stage | Walltime (n=4 MPI) | Memory | Storage |
|---|---|---|---|
| Structure | < 1 sec | negligible | < 1 MB |
| Equilibration | ~1-2 min | ~200 MB | ~5 MB |
| Production | ~5-10 min | ~300 MB | ~50 MB |
| Analysis | seconds | ~100 MB | ~1 MB |
| **Total** | **~10-15 min** | < 500 MB | < 60 MB |

All stages: local machine via Docker image (`lmp` wrapper). No HPC required.
