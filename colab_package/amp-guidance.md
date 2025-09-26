# Amp Guidance - Fortran → Kokkos Demo

## Numeric Correctness Policy

- Target tolerance: `max_abs_diff <= 1e-10` for double precision comparisons
- Use `tools/compare_outputs.py` for automated validation
- Each translation must pass correctness before optimization

## Timing & Profiling

- One change per iteration - measure impact of each modification
- Use `Kokkos::fence()` before timing measurements for GPU correctness
- Profile with NCU (NVIDIA) or rocprof (AMD) when available
- Report timing per iteration for consistent metrics

## Development Flow

1. **Extract**: Minimal MITgcm routine with standalone driver
2. **Translate**: Preserve semantics, use `Kokkos::View` for arrays
3. **Validate**: Build, run, compare with tolerance check
4. **Review**: Oracle feedback on performance and correctness risks
5. **Optimize**: One targeted change based on profiling data

## Core Amp Concepts

- **Subagents**: Parallel processing for independent kernel translations
- **Oracle**: Expert review and planning guidance (non-editing)
- **CLI**: Consistent `--n --reps` interface across all programs
- **Tools**: Automated build/run/compare workflow with proper error handling
