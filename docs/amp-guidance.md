# Amp Guidance - Fortran → Kokkos Demo

## 3-Stage Educational & Consultative Workflow

The modernization process follows a structured 3-stage approach emphasizing explanation-first learning, plan-first modernization, and rigorous implementation:

### **Stage 1: Extract & Explain (No Optimization)**
- **Extract**: Extract minimal MITgcm routines without migration/optimization
- **Explain**: Have Amp explain what the algorithm does and how it integrates with larger MITgcm codebase at ~/MITgcp
- **Baseline**: Establish Fortran performance baselines for validation

### **Stage 2: Oracle-Guided Planning**  
- **Plan**: Ask Amp to consult Oracle for modernization recommendations (parallelization, multi-core/HPC, developer productivity)
- **Review**: Oracle reviews and refines the transition plan
- **Output**: Complete transition_plan.md with implementation strategy

### **Stage 3: Implementation & Validation**
- **Review**: Oracle reviews transition_plan.md and makes recommended revisions
- **Implement**: Use subagents to parallelize implementation tasks
- **Validate**: Test coverage with precision validation and runtime measurement
- **Package**: Create Google Colab notebook for GPU testing

## Stage Orchestration

Use `stage_runner.py` for systematic execution:

```bash
# Stage 1: Analysis & extraction
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target extract
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target explain  
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target baseline

# Stage 2: Planning & review
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage2 --target plan
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage2 --target review

# Stage 3: Implementation & validation
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target implement
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target validate
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target package_colab
```

## Numeric Correctness Policy

- Target tolerance: `max_abs_diff <= 1e-10` for double precision comparisons
- Use `tools/compare_outputs.py` for automated validation
- Each translation must pass correctness before optimization
- Validation occurs in Stage 3 against Stage 1 baselines

## Timing & Profiling

- One change per iteration - measure impact of each modification
- Use `Kokkos::fence()` before timing measurements for GPU correctness
- Profile with NCU (NVIDIA) or rocprof (AMD) when available
- Report timing per iteration for consistent metrics
- Performance baselines established in Stage 1

## Core Amp Concepts

- **Stage Runner**: Orchestrates the complete 3-stage workflow
- **Oracle**: Expert review and planning guidance (Stage 2)
- **Subagents**: Parallel processing for independent kernel translations
- **CLI**: Consistent `--n --reps` interface across all programs
- **Dependencies**: Each stage builds on artifacts from previous stages
- **Validation**: Automated correctness and performance verification
