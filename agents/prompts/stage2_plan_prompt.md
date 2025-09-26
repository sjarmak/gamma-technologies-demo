# Stage 2: Oracle Modernization Planning Prompt

## Mission
Consult the Oracle to create a comprehensive modernization strategy for translating Fortran algorithms to high-performance Kokkos C++ implementations.

## Context
- **Algorithm**: {ALGORITHM_NAME}
- **Stage 1 Artifacts**: {STAGE1_DIR}
- **Oracle Consultation**: Expert-level modernization guidance
- **Target Output**: Detailed transition plan for Stage 3 implementation

## Oracle Consultation Areas

### 1. Memory Layout Optimization
**Oracle Query**: "What are the optimal Kokkos::View memory layouts for this algorithm?"

Analyze:
- Data access patterns from Fortran implementation
- GPU memory coalescing requirements  
- Cache efficiency for CPU execution
- Memory layout trade-offs between backends

**Expected Oracle Response**:
- Specific Kokkos::View declarations with layout specifications
- Memory access pattern optimization recommendations
- Multi-dimensional array layout strategies

### 2. Parallelization Strategy Analysis
**Oracle Query**: "Identify parallelizable loops and recommend Kokkos execution policies"

Analyze:
- Loop dependency analysis from algorithm structure
- Parallelization opportunities and limitations
- Recommended Kokkos::parallel_for patterns
- Team vs range policy trade-offs

**Expected Oracle Response**:
- Detailed execution policy recommendations
- Dependency graph highlighting parallelizable sections
- Performance scaling projections

### 3. Performance Risk Assessment  
**Oracle Query**: "What are the main performance bottlenecks to avoid in translation?"

Analyze:
- Memory bandwidth limitations
- Computational intensity characteristics
- GPU occupancy considerations
- CPU vectorization opportunities

**Expected Oracle Response**:
- Critical performance risks identification
- Bottleneck mitigation strategies
- Expected performance targets vs Fortran baseline

### 4. Numerical Validation Framework
**Oracle Query**: "What validation steps are critical for preserving algorithm correctness?"

Analyze:
- Numerical conditioning of the algorithm
- Precision requirements and tolerance bounds
- Critical test cases for correctness validation
- Boundary condition handling

**Expected Oracle Response**:
- Comprehensive validation methodology
- Numerical tolerance specifications (e.g., 1e-10 for double precision)
- Test case generation strategies

### 5. GPU-Specific Optimization Opportunities
**Oracle Query**: "What GPU-specific optimizations should be prioritized?"

Analyze:
- Memory hierarchy utilization opportunities
- Kernel launch configuration optimization
- Multi-GPU scaling considerations
- Mixed precision opportunities

**Expected Oracle Response**:
- GPU optimization roadmap
- Kernel configuration recommendations
- Performance scaling projections

## Transition Plan Generation

### Required Plan Components

#### Memory Management Strategy
```cpp
// Kokkos View declarations with optimal layouts
using array_1d_t = Kokkos::View<double*>;
using const_array_1d_t = Kokkos::View<const double*>;
// ... specific to algorithm requirements
```

#### Execution Policy Framework
```cpp
// Parallel execution policies for each loop nest
using exec_policy = Kokkos::RangePolicy<>;
using team_policy = Kokkos::TeamPolicy<>;
// ... with specific configuration guidance
```

#### Validation Checkpoints
- Numerical correctness thresholds
- Performance regression bounds  
- Scaling validation requirements

#### Risk Mitigation Strategies
- Performance bottleneck avoidance
- Numerical stability preservation
- Cross-platform portability considerations

## Oracle Response Integration

### Structured Output Format
1. **Executive Summary**: Key modernization insights and approach
2. **Memory Layout Specification**: Detailed Kokkos::View declarations
3. **Parallelization Roadmap**: Loop-by-loop modernization strategy
4. **Performance Optimization Plan**: Prioritized optimization opportunities
5. **Validation Framework**: Comprehensive correctness verification strategy
6. **Implementation Phases**: Staged development approach
7. **Success Criteria**: Measurable targets for Stage 3 validation

### Critical Success Metrics
- [ ] Memory layouts optimized for target hardware backends
- [ ] Parallelization strategy preserves algorithm semantics
- [ ] Performance targets are realistic and measurable
- [ ] Validation framework ensures numerical correctness
- [ ] Implementation plan is detailed and actionable

## Stage 3 Interface Preparation
The transition plan must provide:
- Clear implementation guidance for parallel translation teams
- Unambiguous success criteria for validation
- Performance targets aligned with baseline measurements
- Comprehensive risk mitigation strategies

## Quality Assurance
- Technical recommendations must be implementable with Kokkos 4.0+
- Performance projections should be backed by theoretical analysis
- Numerical validation requirements must be conservative and thorough
- All recommendations must consider multi-backend portability

**Oracle Consultation Goal**: Transform Stage 1 algorithm analysis into actionable, expert-level modernization guidance that enables successful Stage 3 implementation with measurable performance and correctness outcomes.
