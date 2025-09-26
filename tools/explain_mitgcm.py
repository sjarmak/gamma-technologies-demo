#!/usr/bin/env python3
"""Explain MITgcm algorithm implementation and performance characteristics."""

import argparse
import os
import sys
from pathlib import Path
import re
from typing import Dict, List, Tuple

class MITgcmExplainer:
    def __init__(self, context_dir: str):
        self.context_dir = Path(context_dir)
        self.algorithm_info = {}
        
    def analyze_fortran_code(self, routine: str) -> Dict:
        """Analyze Fortran code structure and algorithm."""
        # Look for extracted Fortran files
        fortran_files = list(self.context_dir.glob("*.f90")) + list(self.context_dir.glob("*.F"))
        
        if not fortran_files:
            return {'error': 'No Fortran files found in context directory'}
        
        main_file = fortran_files[0]  # Use first file found
        
        with open(main_file, 'r') as f:
            content = f.read()
        
        analysis = {
            'routine_name': routine,
            'source_file': str(main_file),
            'algorithm_type': self._identify_algorithm(content),
            'complexity': self._analyze_complexity(content),
            'memory_pattern': self._analyze_memory_access(content),
            'parallelization': self._analyze_parallelization(content),
            'key_operations': self._extract_key_operations(content),
            'data_structures': self._identify_data_structures(content),
            'performance_characteristics': self._analyze_performance(content)
        }
        
        return analysis
    
    def _identify_algorithm(self, content: str) -> str:
        """Identify the algorithmic approach used."""
        content_upper = content.upper()
        
        if 'THOMAS' in content_upper or ('FORWARD' in content_upper and 'BACK' in content_upper):
            return 'Thomas Algorithm (Tridiagonal Solver)'
        elif 'GAUSSIAN' in content_upper or 'ELIMINATION' in content_upper:
            return 'Gaussian Elimination'
        elif 'CONJUGATE' in content_upper and 'GRADIENT' in content_upper:
            return 'Conjugate Gradient'
        elif 'JACOBI' in content_upper or 'GAUSS' in content_upper:
            return 'Iterative Solver'
        elif 'TRIDIAG' in content_upper:
            return 'Tridiagonal System Solver'
        else:
            return 'Linear System Solver'
    
    def _analyze_complexity(self, content: str) -> str:
        """Analyze algorithmic complexity."""
        content_upper = content.upper()
        
        # Count nested loops
        do_loops = content_upper.count('DO ')
        nested_level = 0
        max_nesting = 0
        
        for line in content.split('\n'):
            line_upper = line.upper().strip()
            if line_upper.startswith('DO '):
                nested_level += 1
                max_nesting = max(max_nesting, nested_level)
            elif 'ENDDO' in line_upper or 'END DO' in line_upper or 'CONTINUE' in line_upper:
                nested_level = max(0, nested_level - 1)
        
        if 'THOMAS' in content_upper or ('FORWARD' in content_upper and 'BACK' in content_upper):
            return 'O(N) - Thomas algorithm linear complexity'
        elif max_nesting >= 3:
            return 'O(N³) - Triple nested loops'
        elif max_nesting == 2:
            return 'O(N²) - Double nested loops'
        elif max_nesting == 1:
            return 'O(N) - Single loop'
        else:
            return 'O(1) - Constant time'
    
    def _analyze_memory_access(self, content: str) -> str:
        """Analyze memory access patterns."""
        content_upper = content.upper()
        
        # Look for array access patterns
        if re.search(r'[A-Z]\([I-1][,\)]', content_upper):
            return 'Sequential/Stride-1 Access'
        elif re.search(r'[A-Z]\([I]\+[1-9]', content_upper):
            return 'Strided Access Pattern'
        elif 'TRANSPOSE' in content_upper:
            return 'Matrix Transpose Pattern'
        else:
            return 'Regular Array Access'
    
    def _analyze_parallelization(self, content: str) -> str:
        """Analyze parallelization potential."""
        content_upper = content.upper()
        
        if 'THOMAS' in content_upper:
            return 'Embarrassingly parallel across multiple tridiagonal systems'
        elif 'REDUCTION' in content_upper:
            return 'Parallel reduction operations'
        elif re.search(r'DO.*I\s*=.*N', content_upper) and not re.search(r'[A-Z]\([I-1]', content_upper):
            return 'Parallel loop - no dependencies'
        elif re.search(r'[A-Z]\([I-1].*[A-Z]\([I]\)', content_upper):
            return 'Sequential dependency - limited parallelization'
        else:
            return 'Data dependency analysis required'
    
    def _extract_key_operations(self, content: str) -> List[str]:
        """Extract key computational operations."""
        operations = []
        content_upper = content.upper()
        
        if 'FACTOR' in content_upper:
            operations.append('Pivot calculation and factorization')
        if '/' in content and 'FACTOR' not in content_upper:
            operations.append('Division operations')
        if '*' in content:
            operations.append('Multiplication operations')
        if '+' in content or '-' in content:
            operations.append('Addition/subtraction operations')
        if 'SQRT' in content_upper:
            operations.append('Square root computations')
        if 'ELIMINATION' in content_upper:
            operations.append('Forward elimination')
        if 'SUBSTITUTION' in content_upper or 'BACK' in content_upper:
            operations.append('Back substitution')
        
        return operations if operations else ['Basic arithmetic operations']
    
    def _identify_data_structures(self, content: str) -> List[str]:
        """Identify key data structures."""
        structures = []
        
        # Find array declarations
        array_pattern = r'(REAL\*8|DOUBLE\s+PRECISION|INTEGER|REAL)\s+::\s*(\w+)\([^)]+\)'
        arrays = re.findall(array_pattern, content.upper())
        
        if arrays:
            structures.extend([f"Array: {arr[1]}" for arr in arrays])
        
        # Look for specific patterns
        content_upper = content.upper()
        if re.search(r'[A-Z]\([^,)]+,[^,)]+,[^,)]+\)', content_upper):
            structures.append("3D arrays (NX,NY,NZ)")
        elif re.search(r'[A-Z]\([^,)]+,[^,)]+\)', content_upper):
            structures.append("2D arrays/matrices")
        elif re.search(r'[A-Z]\([^,)]+\)', content_upper):
            structures.append("1D arrays/vectors")
            
        return structures if structures else ['Scalar variables']
    
    def _analyze_performance(self, content: str) -> Dict[str, str]:
        """Analyze performance characteristics."""
        perf = {}
        content_upper = content.upper()
        
        # Memory bandwidth analysis
        if 'THOMAS' in content_upper:
            perf['memory_bandwidth'] = 'Moderate - linear memory access per system'
            perf['arithmetic_intensity'] = 'Low - O(N) operations on O(N) data'
            perf['cache_efficiency'] = 'Good - sequential memory access pattern'
        else:
            perf['memory_bandwidth'] = 'Analysis required'
            perf['arithmetic_intensity'] = 'Analysis required'
            perf['cache_efficiency'] = 'Analysis required'
        
        # Scalability analysis
        if 'PARALLEL' in content_upper or ('THOMAS' in content_upper):
            perf['parallel_scalability'] = 'Good - independent systems can run in parallel'
        else:
            perf['parallel_scalability'] = 'Depends on data dependencies'
        
        # GPU suitability
        if 'THOMAS' in content_upper:
            perf['gpu_suitability'] = 'Excellent - embarrassingly parallel with regular access'
        elif re.search(r'DO.*I\s*=.*N', content_upper):
            perf['gpu_suitability'] = 'Good - regular parallel loops'
        else:
            perf['gpu_suitability'] = 'Analysis required'
            
        return perf
    
    def generate_explanation(self, routine: str, output_dir: Path) -> None:
        """Generate comprehensive algorithm explanation."""
        analysis = self.analyze_fortran_code(routine)
        
        if 'error' in analysis:
            print(f"Error: {analysis['error']}")
            return
        
        # Algorithm explanation document
        explanation = f"""# Algorithm Explanation: {analysis['routine_name']}

## Overview
**Algorithm Type**: {analysis['algorithm_type']}
**Computational Complexity**: {analysis['complexity']}
**Memory Access Pattern**: {analysis['memory_pattern']}
**Parallelization Strategy**: {analysis['parallelization']}

## Source Analysis
**Source File**: `{analysis['source_file']}`

## Key Computational Operations
{chr(10).join(f'- {op}' for op in analysis['key_operations'])}

## Data Structures
{chr(10).join(f'- {struct}' for struct in analysis['data_structures'])}

## Algorithm Description

### Thomas Algorithm for Tridiagonal Systems
The Thomas algorithm is a specialized form of Gaussian elimination for solving tridiagonal linear systems of the form:

```
b₁x₁ + c₁x₂                    = d₁
a₂x₁ + b₂x₂ + c₂x₃             = d₂
       a₃x₂ + b₃x₃ + c₃x₄      = d₃
              ...
                aₙ₋₁xₙ₋₁ + bₙxₙ = dₙ
```

### Forward Elimination
1. Eliminate the lower diagonal by updating the main diagonal and RHS:
   ```
   bᵢ' = bᵢ - (aᵢ/bᵢ₋₁') * cᵢ₋₁
   dᵢ' = dᵢ - (aᵢ/bᵢ₋₁') * dᵢ₋₁
   ```

### Back Substitution
2. Solve for unknowns from last to first:
   ```
   xₙ = dₙ'/bₙ'
   xᵢ = (dᵢ' - cᵢ*xᵢ₊₁)/bᵢ'
   ```

## Parallelization Strategy
- **Inter-system parallelism**: Multiple independent tridiagonal systems can be solved simultaneously
- **Intra-system constraints**: Each individual system must be solved sequentially due to data dependencies
- **Kokkos implementation**: Use `parallel_for` over the second dimension (system index)

## Memory Layout Considerations
- **Fortran**: Column-major storage (first index varies fastest)
- **C++/Kokkos**: Row-major default, consider `LayoutLeft` for Fortran compatibility
- **Access pattern**: Sequential within each tridiagonal system

## Numerical Stability
- Thomas algorithm is numerically stable for diagonally dominant matrices
- No pivoting required for well-conditioned tridiagonal systems
- Condition number affects accuracy of solution
"""
        
        output_dir.mkdir(parents=True, exist_ok=True)
        with open(output_dir / "algorithm_explanation.md", 'w') as f:
            f.write(explanation)
        
        # Performance analysis document
        performance = f"""# Performance Analysis: {analysis['routine_name']}

## Computational Characteristics
- **Time Complexity**: {analysis['complexity']}
- **Space Complexity**: O(N) for each tridiagonal system
- **Memory Access**: {analysis['memory_pattern']}

## Performance Metrics
{chr(10).join(f'- **{k.replace("_", " ").title()}**: {v}' for k, v in analysis['performance_characteristics'].items())}

## Optimization Opportunities

### Memory Optimization
1. **Data Layout**: Use appropriate Kokkos layout for target architecture
2. **Memory Coalescing**: Ensure GPU threads access contiguous memory
3. **Cache Utilization**: Sequential access pattern is cache-friendly

### Parallelization Strategy
1. **Thread-level**: Parallelize over independent tridiagonal systems
2. **Vector-level**: Use SIMD instructions for arithmetic operations  
3. **GPU Optimization**: Launch one thread per tridiagonal system

### Backend-Specific Optimizations

#### OpenMP
- Use `parallel_for` with static scheduling
- Consider NUMA-aware memory allocation
- Vectorization with appropriate compiler flags

#### CUDA
- Launch configuration: blocks = (num_systems + threads_per_block - 1) / threads_per_block
- Shared memory usage for temporary arrays if beneficial
- Coalesced memory access across warp

#### HIP/ROCm
- Similar to CUDA with AMD-specific optimizations
- Consider wavefront size (64 threads) for optimal occupancy

## Benchmarking Strategy
1. **Problem Sizes**: Test with various N (64, 256, 1024, 4096)
2. **System Counts**: Vary number of independent systems
3. **Precision**: Compare single vs double precision performance
4. **Memory Patterns**: Test different data layouts

## Expected Performance
- **Sequential**: 8N FLOPS per system, memory-bound operation
- **Parallel Efficiency**: Near-linear scaling with number of systems
- **GPU Speedup**: 10-100x over CPU depending on problem size
"""
        
        with open(output_dir / "performance_analysis.md", 'w') as f:
            f.write(performance)
        
        print(f"Algorithm explanation generated in {output_dir}")

def main():
    parser = argparse.ArgumentParser(description="Generate MITgcm algorithm explanation")
    parser.add_argument("--routine", required=True, help="Routine name to analyze")
    parser.add_argument("--context", required=True, help="Context directory with Fortran source")
    parser.add_argument("--output", required=True, help="Output directory for documentation")
    
    args = parser.parse_args()
    
    if not os.path.exists(args.context):
        print(f"Error: Context directory {args.context} does not exist")
        return 1
    
    explainer = MITgcmExplainer(args.context)
    explainer.generate_explanation(args.routine, Path(args.output))
    
    return 0

if __name__ == "__main__":
    sys.exit(main())
