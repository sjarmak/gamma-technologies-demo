# AGENTS.md

See @docs/amp-guidance.md
See @tools/*.sh

---
globs:
- 'fortran/**/*.f*'
- 'kokkos/**/src/*.cpp'
- 'algorithms/**/*.yml'
---

## 3-Stage Workflow Contracts

### Stage 1: Analysis & Extraction
- **Extract**: Use `tools/extract_fortran_routine.sh` to create standalone drivers
- **Explain**: Generate algorithm documentation with `tools/explain_mitgcm.py`  
- **Baseline**: Establish Fortran performance metrics with validated outputs

### Stage 2: Planning & Review
- **Plan**: Create detailed translation strategies using stage configuration
- **Review**: Oracle consultation provides optimization recommendations and risk assessment

### Stage 3: Implementation & Validation
- **Implement**: Generate Kokkos C++ with proper View declarations and parallel patterns
- **Validate**: Automated correctness checking against Stage 1 baselines
- **Package**: Create deployable Colab demonstrations

## Build & Run Contracts

- Kokkos C++ target lives at `kokkos/{name}/src/kernel.cpp`.
- Arrays must use `Kokkos::View`. Insert exactly one `Kokkos::fence()` before timing/printing.
- CLI: each program accepts `--n <int> --reps <int>`.
- Build: `tools/build_kokkos.sh --kernel {name} --backend {openmp|cuda|hip}`
- Run C++: `tools/run_kokkos.sh --kernel {name} --n {N} --reps {R} [--sbatch]`
- Run Fortran: `tools/run_fortran.sh --src {path} --n {N} --reps {R} --out outputs/{name}_fortran.csv`
- Compare: `python3 tools/compare_outputs.py --fortran outputs/{name}_fortran.csv --kokkos outputs/{name}_kokkos.csv --tol 1e-10`

## Stage Runner Orchestration

```bash
# Execute specific stages/targets
python3 tools/stage_runner.py --algorithm {name} --stage {stage1|stage2|stage3} --target {extract|explain|baseline|plan|review|implement|validate|package_colab}

# List available targets
python3 tools/stage_runner.py --algorithm {name} --list
```

## Algorithm Configuration

Each algorithm requires `algorithms/{name}/stage.yml` with:
- **Sources**: MITgcm repository and target files
- **Stages**: Complete dependency graph for all targets
- **Validation**: Tolerance, test sizes, and backend specifications
- **Metadata**: Complexity, memory patterns, and parallelization strategy

## MITgcm Extraction Notes

- When extracting a routine, avoid changing upstream package toggles
- For demos, inline minimal constants in the driver
- MITgcm packages are controlled via `PARAMS.h` and `input/data.pkg` (`use${Pkg}` flags)
- Target specific routines like `SOLVE_TRIDIAGONAL` in `model/src/`

## Subagents

- For batches, spawn one subagent per kernel/file
- Each subagent: translate → build (OpenMP) → small-N sanity → emit CSV
- Use `tools/spawn_subagents.sh` for parallel processing of multiple algorithms

## Oracle

- Stage 2 Oracle reviews provide expert optimization guidance
- Oracle critiques: memory layout, parallel patterns, performance risks
- Recommendations are concrete and implementable (no direct code edits)
- Use `tools/consult_oracle.sh` for structured consultation process
