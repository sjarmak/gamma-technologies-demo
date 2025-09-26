# Stage 1: Algorithm Explanation Prompt

## Mission
Extract and analyze a Fortran routine from MITgcm, providing comprehensive algorithm documentation and performance baselines.

## Context
- **Algorithm**: {ALGORITHM_NAME}
- **Target Routine**: {TARGET_ROUTINE}
- **Source Files**: {SOURCE_FILES}
- **Extract Directory**: {EXTRACT_DIR}

## Primary Objectives

### 1. Algorithm Analysis
Analyze the extracted Fortran routine and produce:
- Mathematical description of the algorithm
- Computational complexity analysis  
- Memory access patterns identification
- Dependency analysis for parallelization potential

### 2. Performance Baseline
Establish baseline performance metrics:
- Execute multiple problem sizes: [64, 256, 1024, 4096]  
- Run with 5 repetitions per size for statistical validity
- Generate CSV output: `algorithm,implementation,N,reps,time_ms,gflops`

### 3. Documentation Generation
Create comprehensive documentation including:
- **Algorithm explanation**: Mathematical foundations and implementation details
- **Performance analysis**: Baseline metrics and scaling characteristics
- **Optimization opportunities**: Identified parallelization and modernization targets

## Key Requirements

### Numerical Accuracy
- Use double precision throughout baseline measurements
- Document any numerical conditioning concerns
- Validate against analytical solutions where available

### Performance Methodology  
- Include warm-up iterations before timing measurements
- Use high-resolution timing (microsecond precision)
- Calculate GFLOPS based on algorithm-specific operation counts
- Report both time per iteration and throughput metrics

### Documentation Standards
- Use clear technical language suitable for HPC practitioners
- Include code snippets for critical algorithm sections
- Provide performance scaling graphs where beneficial
- Document assumptions and limitations

## Output Artifacts

### Required Files
1. `stage1/docs/algorithm_explanation.md` - Comprehensive algorithm analysis
2. `stage1/docs/performance_analysis.md` - Baseline performance characterization  
3. `stage1/baselines/fortran_baseline.csv` - Raw performance measurements
4. `stage1/extract/solve_tridiagonal.f90` - Extracted and validated Fortran routine

### Success Criteria
- [ ] Algorithm complexity and characteristics clearly documented
- [ ] Baseline performance measurements completed across all test sizes
- [ ] CSV output format matches specification exactly
- [ ] All performance metrics are numerically consistent
- [ ] Documentation provides sufficient detail for Stage 2 modernization planning

## Error Handling
- Validate that extracted routine compiles and executes correctly
- Check for numerical stability issues across problem sizes
- Report any missing dependencies or compilation warnings
- Document system-specific performance considerations

## Next Stage Interface
Stage 1 outputs directly feed into Stage 2 Oracle consultation:
- Algorithm documentation informs modernization strategy
- Performance baselines establish optimization targets
- Identified bottlenecks guide Kokkos pattern selection

Focus on thoroughness and accuracy - these baselines are critical for validating Stage 3 modernization success.
