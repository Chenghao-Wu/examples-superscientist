# 3C-SiC Thermal Conductivity — Workflow Plan

**Experiment Design:** docs/superscientist/specs/2026-05-23-SiC-thermal-conductivity-design.md
**Workflow ID:** sic-thermal-conductivity-2026-05-23
**Stages:** 4 total

## Stage Execution Order

1. Stage 1: Structure Generation — build 3C-SiC supercell, write LAMMPS data file
2. Stage 2: Equilibration (NVT) (depends on: stage-1) — 50 ps NVT at 300 K with Tersoff
3. Stage 3: NVE Production with Heat Flux Sampling (depends on: stage-2) — 200 ps NVE, collect HACF
4. Stage 4: HACF Analysis and κ Calculation (depends on: stage-3) — integrate HACF, quantum correction, report κ

## Per-Stage Details

### Stage 1: Structure Generation
- **Dependencies:** none
- **Inputs:** none (generated from scratch)
- **Commands:**
  1. `mkdir -p stage-1`
  2. Python script (run via `lmp-python wrapper`):
     ```python
     from ase.build import bulk
     from ase.io import write
     atoms = bulk('SiC', crystalstructure='zincblende', a=4.3596, cubic=True) * (5, 5, 5)
     # Write LAMMPS data file with atomic masses for Tersoff
     write('stage-1/data.3c-sic', atoms, format='lammps-data', masses=True, atom_style='atomic')
     print(f'Atoms: {len(atoms)}, Stoichiometry Si:C = {atoms.get_chemical_symbols().count("Si")}:{atoms.get_chemical_symbols().count("C")}')
     ```
- **Outputs:** `stage-1/data.3c-sic`, `stage-1/build.log`
- **Success criteria:** 1000 ± 8 atoms, 1:1 Si:C stoichiometry, min interatomic distance ≥ 1.5 Å
- **Estimated walltime:** < 1 sec
- **Backend:** local
- **Dispatch mode:** sync

### Stage 2: Equilibration (NVT)
- **Dependencies:** stage-1
- **Inputs:** `stage-1/data.3c-sic`
- **Commands:**
  1. `mkdir -p stage-2`
  2. Write `stage-2/input.equil` — LAMMPS input script:
     ```
     units       metal
     atom_style  atomic
     read_data   ../stage-1/data.3c-sic
     pair_style  tersoff
     pair_coeff  * * SiC.tersoff Si C
     velocity    all create 300 87287 dist gaussian
     timestep    0.0005
     fix         nvt all nvt temp 300 300 0.1
     thermo      5000
     thermo_style custom step temp ke pe etotal press
     dump        equil_dump all custom 5000 stage-2/dump.equil id type x y z
     run         100000
     write_restart stage-2/equil.restart
     ```
  3. Run: `cd stage-2 && docker run --rm -v "$PWD:$PWD" -w "$PWD" --user "$(id -u):$(id -g)" ghcr.io/Chenghao-Wu/examples-superscientist:latest mpirun -np 4 lmp -in input.equil`
- **Outputs:** `stage-2/log.equil`, `stage-2/equil.restart`, `stage-2/input.equil`
- **Success criteria:** T stable at 300 ± 5 K over final 10 ps, energy drift < 0.1% over final 10 ps
- **Estimated walltime:** ~1-2 min
- **Backend:** local
- **Dispatch mode:** sync

### Stage 3: NVE Production with Heat Flux Sampling
- **Dependencies:** stage-2
- **Inputs:** `stage-2/equil.restart`
- **Commands:**
  1. `mkdir -p stage-3`
  2. Write `stage-3/input.prod` — LAMMPS input script:
     ```
     units       metal
     atom_style  atomic
     read_restart ../stage-2/equil.restart
     pair_style  tersoff
     pair_coeff  * * SiC.tersoff Si C
     timestep    0.0005
     compute     myFlux all heat/flux ke/atom pe/atom stress/atom
     compute     myPress all pressure NULL virial
     fix         nve all nve
     fix         ave all ave/correlate 2 10 1000 c_myFlux[1] c_myFlux[2] c_myFlux[3] type auto file stage-3/J0Jt.dat
     thermo      10000
     thermo_style custom step temp ke pe etotal c_myFlux[*]
     run         400000
     write_restart stage-3/prod.restart
     ```
  3. Run: `cd stage-3 && docker run --rm -v "$PWD:$PWD" -w "$PWD" --user "$(id -u):$(id -g)" ghcr.io/Chenghao-Wu/examples-superscientist:latest mpirun -np 4 lmp -in input.prod`
- **Outputs:** `stage-3/log.prod`, `stage-3/J0Jt.dat`, `stage-3/prod.restart`, `stage-3/input.prod`
- **Success criteria:** HACF decays to < 5% of peak within 20 ps, energy drift < 0.01% over production
- **Estimated walltime:** ~5-10 min
- **Backend:** local
- **Dispatch mode:** async (tmux)

### Stage 4: HACF Analysis and κ Calculation
- **Dependencies:** stage-3
- **Inputs:** `stage-3/J0Jt.dat`
- **Commands:**
  1. `mkdir -p stage-4`
  2. Python analysis script (run via `lmp-python` wrapper):
     ```python
     import numpy as np
     import matplotlib.pyplot as plt

     # Read J0Jt.dat from LAMMPS ave/correlate output
     data = np.loadtxt('stage-3/J0Jt.dat', skiprows=4)
     time_col = data[:, 0]  # fs
     jx = data[:, 1]
     jy = data[:, 2]
     jz = data[:, 3]

     # Average HACF over 3 directions (cubic = isotropic)
     hacf = (jx + jy + jz) / 3.0
     dt_fs = time_col[1] - time_col[0]
     dt_s = dt_fs * 1e-15

     # Truncate at first zero-crossing or 1/e decay
     peak = hacf[0]
     zero_cross = np.where(np.diff(np.signbit(hacf)))[0]
     trunc = zero_cross[0] + 1 if len(zero_cross) > 0 else np.where(hacf < peak / np.e)[0][0]
     print(f"Truncating correlation at index {trunc} ({time_col[trunc]:.0f} fs)")

     # Running integral (Green-Kubo formula)
     # κ = (V / (3 k_B T^2)) * ∫ <J(0)·J(t)> dt
     V = None  # m^3 — extract from log.prod or data file
     kB = 1.380649e-23  # J/K
     T = 300  # K
     # For now, compute raw integral; volume scaling applied after reading log
     integral = np.cumsum(hacf[:trunc]) * dt_s
     kappa_classical = integral  # placeholder — need V and prefactor

     # Quantum correction: Debye model heat capacity ratio
     # C_V^Debye / 3k_B at T=300K, Theta_D=1200K
     theta_D = 1200
     x = np.linspace(1e-6, theta_D/T, 10000)
     # Debye C_V integrand: (x^4 e^x) / (e^x - 1)^2
     C_V_Debye = 9 * kB * np.trapz(x**4 * np.exp(x) / (np.exp(x) - 1)**2, x) / (theta_D/T)**3 * T**3
     correction = C_V_Debye / (3 * kB)
     print(f"Quantum correction factor: {correction:.3f}")

     kappa_quantum = kappa_classical * correction

     # Check plateau convergence
     window_ps = 20
     window_idx = int(window_ps * 1000 / dt_fs)
     final_segment = kappa_quantum[-window_idx:]
     slope = np.polyfit(np.arange(len(final_segment)), final_segment, 1)[0]
     print(f"Plateau slope: {slope:.6f} W/m·K per ps")

     fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4))
     ax1.plot(time_col[:trunc], hacf[:trunc] / peak)
     ax1.set_xlabel('Time (fs)'); ax1.set_ylabel('HACF (normalized)')
     ax1.set_title('Heat Flux Autocorrelation')
     ax2.plot(time_col[:trunc], kappa_quantum)
     ax2.set_xlabel('Time (fs)'); ax2.set_ylabel('κ (W/m·K)')
     ax2.set_title(f'κ(300 K) = {kappa_quantum[-1]:.1f} W/m·K')
     plt.tight_layout()
     plt.savefig('stage-4/kappa_plot.png', dpi=150)

     with open('stage-4/kappa_result.txt', 'w') as f:
         f.write(f'κ_classical = {kappa_classical[-1]:.2f} W/m·K\n')
         f.write(f'κ_quantum  = {kappa_quantum[-1]:.2f} W/m·K\n')
         f.write(f'Quantum correction factor: {correction:.4f}\n')
         f.write(f'Plateau slope: {slope:.6f} W/m·K per ps\n')
     ```
- **Outputs:** `stage-4/kappa_plot.png`, `stage-4/kappa_result.txt`
- **Success criteria:** κ(t) plateau slope < 0.01 W/m·K per ps over final 5 ps of window, κ within 100–300 W/m·K
- **Estimated walltime:** seconds
- **Backend:** local
- **Dispatch mode:** sync
