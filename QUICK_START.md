# Quick Start - 3-Stage Fortran → Kokkos Demo

This guide shows how to run the complete 3-stage modernization workflow from MITgcm algorithm extraction through GPU-accelerated Colab testing.

## Prerequisites

1. **MITgcm Repository**: Clone MITgcm to ~/MITgcp
   ```bash
   cd ~
   git clone https://github.com/MITgcm/MITgcm.git MITgcp
   ```

2. **Environment Setup**:
   ```bash
   export MITGCM_ROOT=~/MITgcp
   ```

3. **Dependencies**: gfortran, cmake, Kokkos (for Stage 3)

## Stage 1: Extract & Explain (No Optimization)

Extract the MITgcm tridiagonal solver and have Amp explain what it does:

```bash
# Extract algorithm from MITgcm
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target extract

# Generate algorithm explanation  
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target explain

# Establish Fortran baseline
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target baseline
```

**Outputs:**
- `algorithms/tridiag_thomas/stage1/extract/solve_tridiagonal.f90` - Extracted Fortran code
- `algorithms/tridiag_thomas/stage1/docs/algorithm_explanation.md` - Algorithm explanation  
- `algorithms/tridiag_thomas/stage1/baselines/fortran_baseline.csv` - Performance baseline

## Stage 2: Oracle-Guided Planning

Consult the Oracle for modernization recommendations:

```bash
# Generate modernization plan
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage2 --target plan

# Oracle review and refinement
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage2 --target review
```

**Outputs:**
- `algorithms/tridiag_thomas/stage2/plan/transition_plan.md` - Detailed modernization strategy

## Stage 3: Implementation & Validation

Oracle reviews plan and coordinates implementation:

```bash
# Implement Kokkos version using subagents
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target implement

# Validate numerical correctness and performance
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target validate

# Package for Google Colab GPU testing
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target package_colab
```

**Outputs:**
- `algorithms/tridiag_thomas/stage3/implement/kernel.cpp` - Kokkos implementation
- `algorithms/tridiag_thomas/stage3/validate/correctness_report.md` - Validation results
- `colab_package/tridiag_thomas/` - Ready-to-upload Colab package

## Run Complete Pipeline

Execute all stages sequentially:

```bash
# Stage 1: Extract and explain
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target extract
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target explain  
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target baseline

# Stage 2: Plan and review
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage2 --target plan
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage2 --target review

# Stage 3: Implement, validate, package
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target implement
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target validate
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target package_colab
```

## Test the Results

After Stage 3, test the implementations:

```bash
# Build and run Fortran baseline
tools/run_fortran.sh --src algorithms/tridiag_thomas/stage1/extract/solve_tridiagonal.f90 --n 1024 --reps 5 --out outputs/fortran_test.csv

# Build and run Kokkos implementation  
tools/build_kokkos.sh --kernel tridiag_thomas --backend openmp
tools/run_kokkos.sh --kernel tridiag_thomas --n 1024 --reps 5

# Compare numerical accuracy
python3 tools/compare_outputs.py --fortran outputs/fortran_test.csv --kokkos outputs/tridiag_thomas_kokkos.csv --tol 1e-10
```

## GPU Testing with Colab

Upload the generated package to Google Colab:

1. Compress the package: `tar -czf tridiag_thomas_demo.tar.gz colab_package/tridiag_thomas/`
2. Upload to Google Colab 
3. Open `tridiag_thomas_demo.ipynb`
4. Run all cells to see Fortran vs Kokkos GPU performance comparison

## Key Features

- **Educational Focus**: Stage 1 emphasizes algorithm understanding before optimization
- **Oracle Guidance**: Stage 2 provides expert modernization recommendations  
- **Rigorous Validation**: Stage 3 ensures numerical correctness within 1e-10 tolerance
- **GPU Ready**: Automated Colab package generation for GPU acceleration testing
- **Parallel Implementation**: Subagents handle independent translation tasks concurrently

## Next Steps

- Add new algorithms by creating `algorithms/{name}/stage.yml` configurations
- Customize validation tolerances and test sizes per algorithm
- Extend to additional Kokkos backends (CUDA, HIP, SYCL)
