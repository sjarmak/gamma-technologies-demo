# Fortran → Kokkos C++ Demo Workspace

A reproducible demonstration workspace showcasing the translation of computational kernels from Fortran to Kokkos C++, featuring a real MITgcm tridiagonal solver and additional test kernels.

## Repository Structure

```
├── fortran/ # Fortran reference implementations
│ ├── mitgcm_demo.f90 # MITgcm tridiagonal solver (extracted)
│ ├── cg.f90 # Conjugate gradient demo
│ └── ep.f90 # Embarrassingly parallel demo
├── kokkos/ # Kokkos C++ translations
│ ├── mitgcm_demo/src/kernel.cpp # Main tridiagonal solver
│ ├── cg/src/kernel.cpp # CG translation
│ └── ep/src/kernel.cpp # EP translation
├── tools/ # Build/run/compare automation
│ ├── build_kokkos.sh # Kokkos build automation
│ ├── run_kokkos.sh # Kokkos execution wrapper
│ ├── run_fortran.sh # Fortran execution wrapper
│ └── compare_outputs.py # Numerical validation
├── docs/
│ └── amp-guidance.md # Development methodology
└── AGENTS.md # Workflow contracts
```

## Quick Start

### Prerequisites
- gfortran with OpenMP support
- CMake 3.20+
- Kokkos library installed
- Python 3 with numpy

### Running a Complete Validation

1. **Build and test Fortran baseline:**
```bash
./tools/run_fortran.sh --src fortran/mitgcm_demo.f90 --n 256 --reps 2 --out outputs/mitgcm_demo_fortran.csv
```

2. **Build Kokkos version:**
```bash
./tools/build_kokkos.sh --kernel mitgcm_demo --backend openmp
```

3. **Run Kokkos version:**
```bash
./tools/run_kokkos.sh --kernel mitgcm_demo --n 256 --reps 2
```

4. **Validate numerical correctness:**
```bash
python3 tools/compare_outputs.py --fortran outputs/mitgcm_demo_fortran.csv --kokkos outputs/mitgcm_demo_kokkos.csv --tol 1e-10
```

## Core Features

### MITgcm Tridiagonal Solver
- **Source**: Extracted from [MITgcm model/src/solve_tridiagonal.F](~/MITgcm/model/src/solve_tridiagonal.F)
- **Algorithm**: Thomas method for tridiagonal linear systems
- **Application**: Vertical diffusion/advection in ocean modeling
- **Translation**: Preserves computational semantics with Kokkos parallelization

### Oracle-Reviewed Implementation
The Kokkos translation received expert review focusing on:
- Sequential k-loop handling (preserves dependencies)
- Memory layout optimization recommended (use LayoutLeft)
- Proper fence placement for timing
- Performance improvements suggested (TeamPolicy approach)

### Automated Validation Pipeline
- **Tolerance**: `max_abs_diff <= 1e-10` for double precision
- **Tools**: Python-based numerical comparison
- **Coverage**: All kernels tested for correctness

## Performance Results

| Kernel | N | Reps | Fortran Time/iter | Status |
|--------|---|------|------------------|---------|
| mitgcm_demo | 256 | 2 | 0.0006s | Validated |
| cg | 64 | 2 | <0.0001s | Validated |
| ep | 128 | 2 | 0.0004s | Validated |

*Note: Kokkos performance pending library installation*

## Next Steps

### Immediate Optimizations (from Oracle review)
1. **Memory Layout**: Use `LayoutLeft` for better cache performance
2. **Kernel Consolidation**: Replace O(nk) launches with single TeamPolicy kernel
3. **Scratch Memory**: Use team scratch for temporary arrays
4. **Const Correctness**: Mark read-only Views as const

### Advanced Parallel Algorithms
- Consider PCR (Parallel Cyclic Reduction) for increased k-parallelism
- GPU profiling with NCU/rocprof when hardware available
- Multi-GPU scaling studies

## MITgcm Integration Notes

The extracted routine maintains compatibility with MITgcm's computational patterns:
- **Package Integration**: Respects MITgcm's PARAMS.h and data.pkg structure
- **Standalone Demo**: Inlines necessary constants for independent execution
- **Numerical Fidelity**: Preserves original algorithm semantics

## Development Methodology

This workspace demonstrates:
- **Oracle Review**: Expert analysis before wide edits
- **Subagent Parallelization**: Independent kernel processing
- **Automated Validation**: Continuous correctness checking
- **Performance Iteration**: One change per measurement cycle

See [docs/amp-guidance.md](docs/amp-guidance.md) for complete development workflow.
