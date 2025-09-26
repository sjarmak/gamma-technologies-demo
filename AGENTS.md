# AGENTS.md

See @docs/amp-guidance.md
See @tools/*.sh

---
globs:
  - 'fortran/**/*.f*'
  - 'kokkos/**/src/*.cpp'
---

## Contracts

- Kokkos C++ target lives at `kokkos/{name}/src/kernel.cpp`.
- Arrays must use `Kokkos::View`. Insert exactly one `Kokkos::fence()` before timing/printing.
- CLI: each program accepts `--n <int> --reps <int>`.
- Build: `tools/build_kokkos.sh --kernel {name} --backend {openmp|cuda|hip}`
- Run C++: `tools/run_kokkos.sh --kernel {name} --n {N} --reps {R} [--sbatch]`
- Run Fortran: `tools/run_fortran.sh --src {path} --n {N} --reps {R} --out outputs/{name}_fortran.csv`
- Compare: `python3 tools/compare_outputs.py --fortran outputs/{name}_fortran.csv --kokkos outputs/{name}_kokkos.csv --tol 1e-10`

## MITgcm notes

- When extracting a routine, avoid changing upstream package toggles; for demos, inline minimal constants in the driver. MITgcm packages are controlled via `PARAMS.h` and `input/data.pkg` (`use${Pkg}` flags).

## Subagents

- For batches, spawn one subagent per kernel/file. Each subagent: translate → build (OpenMP) → small-N sanity → emit CSV.

## Oracle

- Before wide edits, run an **Oracle** review: critique diffs, fence placement, memory layout, portability flags; propose fixes (no edits).
