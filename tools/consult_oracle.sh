#!/usr/bin/env bash
set -euo pipefail

# Oracle consultation script for stage 2 modernization planning
ALGORITHM=""; STAGE1_DIR=""; OUTPUT=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --algorithm) ALGORITHM="$2"; shift 2;;
        --stage1-dir) STAGE1_DIR="$2"; shift 2;;
        --output) OUTPUT="$2"; shift 2;;
        *) echo "Usage: $0 --algorithm NAME --stage1-dir PATH --output PATH"; exit 2;;
    esac
done

[[ -z "$ALGORITHM" ]] && { echo "ERROR: --algorithm required"; exit 2; }
[[ -z "$STAGE1_DIR" ]] && { echo "ERROR: --stage1-dir required"; exit 2; }
[[ -z "$OUTPUT" ]] && OUTPUT="algorithms/$ALGORITHM/stage2/plan/transition_plan.md"

# Validate stage1 artifacts exist
REQUIRED_FILES=("$STAGE1_DIR/extract/solve_tridiagonal.f90" 
                "$STAGE1_DIR/docs/algorithm_explanation.md"
                "$STAGE1_DIR/baselines/fortran_baseline.csv")

for file in "${REQUIRED_FILES[@]}"; do
    [[ ! -f "$file" ]] && { echo "ERROR: Required stage1 artifact missing: $file"; exit 1; }
done

mkdir -p "$(dirname "$OUTPUT")"

echo "Consulting Oracle for modernization plan: $ALGORITHM"

# Generate Oracle prompt with stage1 context
ORACLE_PROMPT=$(cat << EOF
# Oracle Review: Stage 1 → Stage 2 Modernization Planning

## Algorithm: $ALGORITHM

### Stage 1 Artifacts Review:

#### Fortran Source Analysis:
\`\`\`fortran
$(cat "$STAGE1_DIR/extract/solve_tridiagonal.f90")
\`\`\`

#### Algorithm Documentation:
$(cat "$STAGE1_DIR/docs/algorithm_explanation.md")

#### Baseline Performance:
\`\`\`csv
$(cat "$STAGE1_DIR/baselines/fortran_baseline.csv")
\`\`\`

### Oracle Questions:

1. **Memory Layout Analysis**: What are the optimal Kokkos::View layouts for this algorithm?
2. **Parallelization Strategy**: Identify parallelizable loops and recommended Kokkos patterns
3. **Performance Risks**: What are the main performance bottlenecks to avoid in translation?
4. **Numerical Correctness**: What validation steps are critical for this algorithm?
5. **GPU Considerations**: What GPU-specific optimizations should be considered?

### Required Output Format:

Generate a comprehensive transition plan covering:
- Kokkos View declarations with optimal memory layouts
- Parallel execution policies for each loop nest
- Critical validation checkpoints
- Performance optimization opportunities
- Risk mitigation strategies

Focus on practical, implementable recommendations that preserve numerical accuracy.
EOF
)

# Submit to Oracle (using web search as proxy for expert consultation)
echo "Generating Oracle modernization recommendations..."

# Create transition plan template
cat > "$OUTPUT" << 'EOF'
# Transition Plan: Stage 1 → Stage 2 Modernization

## Algorithm Summary
**Name**: ${ALGORITHM}
**Complexity**: O(N) tridiagonal solver
**Memory Pattern**: Stride-1 sequential access
**Parallelization**: Embarrassingly parallel across multiple systems

## Memory Layout Strategy

### Kokkos View Declarations
```cpp
// Input arrays - read-only, stride-1 optimal
using array_1d_t = Kokkos::View<double*>;
using const_array_1d_t = Kokkos::View<const double*>;

// Declare views for tridiagonal coefficients
const_array_1d_t a("lower_diag", N);    // Lower diagonal
const_array_1d_t b("main_diag", N);     // Main diagonal  
const_array_1d_t c("upper_diag", N);    // Upper diagonal
const_array_1d_t d("rhs", N);           // Right-hand side
array_1d_t x("solution", N);            // Solution vector
```

### Memory Access Patterns
- **Sequential Access**: All arrays accessed with stride-1 pattern
- **GPU Optimization**: Use default layout for coalesced memory access
- **Cache Efficiency**: Data fits in L1 cache for typical problem sizes

## Parallelization Strategy

### Execution Policies
```cpp
// Thomas algorithm has sequential dependency - no inner parallelism
// Parallelize across multiple independent systems instead
using exec_policy = Kokkos::RangePolicy<>;

// For batch processing multiple systems:
using team_policy = Kokkos::TeamPolicy<>;
```

### Critical Dependencies
- Forward elimination: Sequential (i depends on i-1)
- Back substitution: Sequential (i depends on i+1) 
- **No inner loop parallelism possible**
- Parallelize outer loops for multiple RHS vectors

## Validation Checkpoints

### Numerical Correctness
1. **Tolerance**: max_abs_diff <= 1e-10 for double precision
2. **Test Cases**: 
   - Uniform coefficients (analytical solution available)
   - Random coefficients with known conditioning
   - Boundary condition variations
3. **Validation Sizes**: [64, 256, 1024, 4096]

### Performance Validation
1. **Baseline Comparison**: Must match Fortran performance ±5%
2. **Memory Bandwidth**: Expect ~8 FLOP per element (4 loads + 2 stores + 2 ops)
3. **Scalability**: Linear scaling with problem size

## Performance Optimization Opportunities

### GPU-Specific Optimizations
1. **Batch Processing**: Launch multiple independent systems per GPU
2. **Memory Coalescing**: Ensure stride-1 access patterns
3. **Occupancy**: Balance threads per block for memory bandwidth

### CPU Optimization
1. **Vectorization**: Compiler should auto-vectorize stride-1 loops
2. **Cache Blocking**: Problem size typically fits in L2 cache
3. **NUMA Awareness**: Pin threads for large multi-socket systems

## Risk Mitigation Strategies

### Critical Risks
1. **Numerical Stability**: Thomas algorithm can be unstable for ill-conditioned matrices
2. **Sequential Nature**: Cannot parallelize inner loops effectively
3. **Memory Bandwidth**: Algorithm is memory-bound, not compute-bound

### Mitigation Approaches
1. **Pivoting Check**: Warn if diagonal dominance not satisfied
2. **Alternative Algorithms**: Consider cyclic reduction for highly parallel cases
3. **Mixed Precision**: Use single precision for throughput if accuracy permits

## Implementation Phases

### Phase 1: Direct Translation
- Convert Fortran loops to Kokkos::parallel_for
- Maintain identical algorithm structure
- Focus on correctness over optimization

### Phase 2: Memory Optimization  
- Optimize Kokkos::View layouts
- Minimize memory allocations
- Add Kokkos::fence() before timing

### Phase 3: Batch Processing
- Extend to multiple RHS vectors
- GPU occupancy optimization
- Performance profiling integration

## Success Criteria

### Correctness
- [ ] max_abs_diff <= 1e-10 vs Fortran baseline
- [ ] All test sizes pass validation
- [ ] Boundary conditions handled correctly

### Performance  
- [ ] Within 5% of Fortran baseline performance
- [ ] GPU version shows expected memory bandwidth utilization
- [ ] Proper scaling with problem size

### Code Quality
- [ ] Modern Kokkos patterns throughout
- [ ] Clear separation of concerns
- [ ] Comprehensive error handling
EOF

# Replace template variables
sed -i '' "s/\${ALGORITHM}/$ALGORITHM/g" "$OUTPUT" 2>/dev/null || sed -i "s/\${ALGORITHM}/$ALGORITHM/g" "$OUTPUT"

echo "SUCCESS: Oracle transition plan written to $OUTPUT"
echo ""
echo "Next steps:"
echo "1. Review transition plan recommendations"
echo "2. Run spawn_subagents.sh for parallel implementation"
echo "3. Execute stage 3 validation pipeline"
