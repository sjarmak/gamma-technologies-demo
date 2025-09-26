# Stage 3: Implementation Review & Validation Prompt

## Mission
Execute Oracle-guided modernization implementation, perform comprehensive validation, and prepare production-ready Kokkos implementations with full correctness and performance verification.

## Context
- **Algorithm**: {ALGORITHM_NAME}
- **Transition Plan**: {STAGE2_TRANSITION_PLAN}
- **Implementation Target**: Production-ready Kokkos C++ translation
- **Validation Requirements**: Numerical correctness and performance verification

## Implementation Phase

### 1. Core Algorithm Translation
**Objective**: Direct translation following Oracle recommendations

**Implementation Requirements**:
- Convert Fortran loops to appropriate Kokkos::parallel_for patterns
- Implement Kokkos::View declarations per memory layout specifications
- Maintain identical numerical algorithm semantics
- Add Kokkos::fence() before all timing measurements
- Follow transition plan execution policy recommendations

**Code Quality Standards**:
- Modern C++17 compatible implementation
- Clear variable naming consistent with Fortran counterparts
- Comprehensive error handling for edge cases
- No compiler warnings or static analysis issues

### 2. Memory Layout Optimization
**Objective**: Implement Oracle-specified memory optimization strategies

**Optimization Requirements**:
- Deploy optimal Kokkos::View layouts for target backends
- Minimize memory allocations in performance-critical paths
- Ensure GPU memory coalescing patterns
- Implement efficient data transfer strategies

**Validation Checkpoints**:
- Memory access pattern analysis with profiling tools
- Bandwidth utilization measurements
- Cache efficiency verification on CPU backends

### 3. Performance Infrastructure
**Objective**: Comprehensive timing and profiling integration

**Timing Requirements**:
- High-resolution kernel execution timing
- CSV output format matching Fortran baseline: `algorithm,implementation,N,reps,time_ms,gflops`
- GFLOPS calculation based on algorithm-specific operation counts  
- Warm-up iterations before performance measurements

**Profiling Integration**:
- NCU profiling hooks for GPU analysis (when available)
- rocprof integration for AMD GPU profiling
- CPU performance counter integration

### 4. Numerical Validation Framework
**Objective**: Rigorous correctness verification against Fortran baseline

**Validation Requirements**:
- Direct numerical comparison with tolerance checking (≤ 1e-10)
- Boundary condition verification across all test cases
- Multiple problem size validation: [64, 256, 1024, 4096]
- Edge case handling verification

**Correctness Methodology**:
```cpp
// Example validation structure
bool validate_results(const array_1d_t& kokkos_result, 
                     const std::vector<double>& fortran_result, 
                     double tolerance = 1e-10) {
    double max_abs_diff = 0.0;
    // ... implementation details
    return max_abs_diff <= tolerance;
}
```

## Comprehensive Validation Pipeline

### 1. Build System Validation
**Requirements**:
- Clean compilation across all target backends (OpenMP, CUDA, HIP)
- CMake configuration following project standards
- Warning-free builds with strict compiler flags

**Validation Commands**:
```bash
tools/build_kokkos.sh --kernel {ALGORITHM} --backend openmp
tools/build_kokkos.sh --kernel {ALGORITHM} --backend cuda  # if available
```

### 2. Correctness Validation
**Test Matrix**:
- All problem sizes against Fortran baseline
- Multiple random seed test cases  
- Boundary condition stress tests
- Ill-conditioned matrix handling (where applicable)

**Acceptance Criteria**:
- max_abs_diff ≤ 1e-10 for all test cases
- Consistent results across multiple runs
- Graceful handling of edge cases

### 3. Performance Validation  
**Benchmarking Requirements**:
- Performance comparison against Fortran baseline
- Backend-specific optimization verification
- Scaling analysis across problem sizes
- Memory bandwidth utilization analysis

**Performance Targets**:
- Within ±5% of Fortran baseline performance
- Expected GPU acceleration where theoretically possible
- Memory bandwidth utilization ≥80% of peak (for memory-bound algorithms)

### 4. Production Readiness Assessment
**Code Quality Checklist**:
- [ ] Comprehensive error handling and validation
- [ ] Clear documentation and comments where needed
- [ ] Consistent coding style and patterns
- [ ] Memory leak verification with tools like valgrind
- [ ] Thread safety analysis (for multi-threaded usage)

## Deliverable Generation

### 1. Implementation Artifacts
**Required Files**:
- `stage3/implement/kernel.cpp` - Complete Kokkos implementation
- `stage3/implement/translation_notes.md` - Implementation decisions and rationale
- `stage3/implement/build_instructions.md` - Compilation and dependency guidance

### 2. Validation Reports
**Required Documentation**:
- `stage3/validate/correctness_report.md` - Comprehensive numerical validation results
- `stage3/validate/performance_comparison.csv` - Detailed performance comparison data
- `stage3/validate/profiling_analysis.md` - Performance bottleneck analysis

### 3. Production Package
**Colab Demo Preparation**:
- Interactive Jupyter notebook with live demonstration
- Side-by-side performance comparison
- Educational content explaining modernization benefits
- Ready-to-execute code examples

## Oracle Review Integration

### Pre-Implementation Oracle Consultation
**Review Areas**:
- Implementation strategy validation
- Performance optimization priorities
- Risk assessment and mitigation strategies

### Post-Implementation Oracle Validation
**Review Areas**:
- Code quality and best practices adherence
- Performance optimization effectiveness
- Numerical correctness validation completeness

## Success Criteria

### Functional Requirements
- [ ] Complete algorithm functionality preserved from Fortran
- [ ] Numerical results identical within specified tolerance
- [ ] All test cases pass validation pipeline
- [ ] Clean compilation across target backends

### Performance Requirements  
- [ ] Performance competitive with Fortran baseline
- [ ] Efficient resource utilization demonstrated
- [ ] Scaling characteristics match theoretical expectations
- [ ] Profiling data confirms optimization effectiveness

### Production Requirements
- [ ] Code quality meets enterprise standards
- [ ] Documentation sufficient for maintenance and extension
- [ ] Colab demo package ready for deployment
- [ ] Comprehensive validation reports completed

**Stage 3 Completion Goal**: Deliver production-ready, Oracle-validated Kokkos implementation with comprehensive correctness verification, competitive performance, and complete educational demonstration materials.
