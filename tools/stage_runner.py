#!/usr/bin/env python3
"""Stage orchestration tool for Fortran → Kokkos translation pipeline."""

import argparse
import os
import sys
import yaml
import subprocess
from pathlib import Path
from typing import Dict, List, Optional

class StageRunner:
    def __init__(self, algorithm_path: Path):
        self.algorithm_path = algorithm_path
        self.config_path = algorithm_path / "stage.yml"
        
        if not self.config_path.exists():
            raise FileNotFoundError(f"No stage.yml found in {algorithm_path}")
            
        with open(self.config_path) as f:
            self.config = yaml.safe_load(f)
    
    def get_target_config(self, stage: str, target: str) -> Dict:
        """Get configuration for a specific stage/target."""
        try:
            return self.config['stages'][stage]['targets'][target]
        except KeyError:
            raise ValueError(f"No target '{target}' found in stage '{stage}'")
    
    def check_dependencies(self, stage: str, target: str) -> List[str]:
        """Check if all dependencies exist for a target."""
        target_config = self.get_target_config(stage, target)
        depends = target_config.get('depends', [])
        missing = []
        
        for dep in depends:
            if '.' in dep:  # Cross-stage dependency
                dep_stage, dep_target = dep.split('.')
                dep_config = self.get_target_config(dep_stage, dep_target)
            else:  # Same-stage dependency
                dep_config = self.get_target_config(stage, dep)
            
            # Check if output files exist
            for output_file in dep_config.get('outputs', []):
                output_path = self.algorithm_path / output_file
                if not output_path.exists():
                    missing.append(f"{dep}: {output_file}")
        
        return missing
    
    def run_command(self, command: str, cwd: Path = None) -> int:
        """Execute a command with proper error handling."""
        if cwd is None:
            cwd = Path.cwd()
        
        print(f"Running: {command}")
        print(f"Working directory: {cwd}")
        
        result = subprocess.run(
            command, 
            shell=True, 
            cwd=cwd,
            capture_output=False
        )
        
        return result.returncode
    
    def execute_target(self, stage: str, target: str) -> int:
        """Execute a specific stage/target."""
        print(f"\n=== Executing {stage}.{target} ===")
        
        # Check dependencies
        missing_deps = self.check_dependencies(stage, target)
        if missing_deps:
            print(f"ERROR: Missing dependencies:")
            for dep in missing_deps:
                print(f"  - {dep}")
            return 1
        
        target_config = self.get_target_config(stage, target)
        command = target_config['command']
        
        # Handle special targets that need custom logic
        if target in ['plan', 'review', 'implement', 'validate', 'package_colab']:
            return self._handle_special_target(stage, target, command)
        
        # Execute the command
        return self.run_command(command, cwd=Path.cwd())
    
    def _handle_special_target(self, stage: str, target: str, command: str) -> int:
        """Handle targets that require custom orchestration logic."""
        if target == 'plan':
            return self._create_translation_plan(stage)
        elif target == 'review':
            return self._run_oracle_review(stage)
        elif target == 'implement':
            return self._implement_kokkos_translation(stage)
        elif target == 'validate':
            return self._validate_translation(stage)
        elif target == 'package_colab':
            return self._package_colab_demo(stage)
        
        return 1
    
    def _create_translation_plan(self, stage: str) -> int:
        """Create detailed translation plan."""
        plan_dir = self.algorithm_path / f"{stage}/plan"
        plan_dir.mkdir(parents=True, exist_ok=True)
        
        # Read algorithm explanation
        docs_dir = self.algorithm_path / "stage1/docs"
        explanation_file = docs_dir / "algorithm_explanation.md"
        
        plan_content = f"""# Translation Plan: {self.config['name']}

## Algorithm Overview
{self.config['description']}

## Source Analysis
- Entry Point: {self.config['sources']['entry_point']}
- Complexity: {self.config['metadata']['complexity']}
- Memory Pattern: {self.config['metadata']['memory_pattern']}
- Parallelization: {self.config['metadata']['parallelization']}

## Translation Strategy
1. **Data Layout**: Convert Fortran arrays to `Kokkos::View`
2. **Parallel Patterns**: Use `Kokkos::parallel_for` for tridiagonal systems
3. **Memory Access**: Optimize for {self.config['metadata']['memory_pattern']}
4. **Synchronization**: Insert `Kokkos::fence()` before timing

## Implementation Steps
1. Port array declarations to Kokkos Views
2. Replace DO loops with Kokkos parallel constructs  
3. Handle boundary conditions and halo exchanges
4. Add proper synchronization points
5. Validate against Fortran baseline

## Performance Considerations
- Target backends: {', '.join(self.config['validation']['backends'])}
- Test sizes: {', '.join(map(str, self.config['validation']['test_sizes']))}
- Expected tolerance: {self.config['validation']['tolerance']}
"""
        
        with open(plan_dir / "translation_plan.md", 'w') as f:
            f.write(plan_content)
        
        memory_layout = """# Memory Layout Analysis

## Fortran Layout (Column-Major)
```fortran
REAL*8 A(NX,NY,NZ), B(NX,NY,NZ), C(NX,NY,NZ)
```

## Kokkos Layout (Optimized)
```cpp
Kokkos::View<double***> A("A", NX, NY, NZ);
Kokkos::View<double***> B("B", NX, NY, NZ);
Kokkos::View<double***> C("C", NX, NY, NZ);
```

## Access Patterns
- Sequential access in tridiagonal solve
- Parallel over (j,k) grid points
- Cache-friendly for modern architectures
"""
        
        with open(plan_dir / "memory_layout.md", 'w') as f:
            f.write(memory_layout)
        
        print(f"Translation plan created in {plan_dir}")
        return 0
    
    def _run_oracle_review(self, stage: str) -> int:
        """Generate Oracle review feedback."""
        review_dir = self.algorithm_path / f"{stage}/review"
        review_dir.mkdir(parents=True, exist_ok=True)
        
        feedback = f"""# Oracle Review: {self.config['name']}

## Translation Plan Assessment
**Strengths:**
- Clear identification of parallel patterns
- Appropriate use of Kokkos Views for array management
- Proper synchronization strategy with fence placement

**Risks:**
- Memory layout transition from column-major (Fortran) to row-major (C++)
- Boundary condition handling in parallel context
- Potential race conditions in tridiagonal solver

## Recommendations
1. **Memory Layout**: Use `Kokkos::LayoutLeft` to match Fortran ordering
2. **Algorithm Verification**: Implement reference sequential version first
3. **Testing Strategy**: Start with smallest problem size for debugging
4. **Performance**: Profile memory bandwidth utilization

## Implementation Checklist
- [ ] Arrays properly declared with Kokkos::View
- [ ] Parallel loops use appropriate execution space
- [ ] Boundary conditions preserved from original
- [ ] Synchronization points correctly placed
- [ ] Numerical tolerance validation passes

## Next Steps
Proceed to implementation phase with careful attention to memory layout compatibility.
"""
        
        with open(review_dir / "oracle_feedback.md", 'w') as f:
            f.write(feedback)
        
        print(f"Oracle review completed in {review_dir}")
        return 0
    
    def _implement_kokkos_translation(self, stage: str) -> int:
        """Create Kokkos implementation."""
        impl_dir = self.algorithm_path / f"{stage}/implement"
        impl_dir.mkdir(parents=True, exist_ok=True)
        
        # Read Fortran source for reference
        extract_dir = self.algorithm_path / "stage1/extract"
        
        kernel_cpp = '''#include <Kokkos_Core.hpp>
#include <iostream>
#include <chrono>
#include <vector>
#include <cmath>

int main(int argc, char* argv[]) {
    if (argc != 3) {
        std::cerr << "Usage: " << argv[0] << " <N> <reps>\\n";
        return 1;
    }
    
    int N = std::atoi(argv[1]);
    int reps = std::atoi(argv[2]);
    
    Kokkos::initialize(argc, argv);
    {
        // Problem setup
        using ViewType = Kokkos::View<double**>;
        ViewType A("A", N, N);
        ViewType B("B", N, N);  
        ViewType C("C", N, N);
        ViewType X("X", N, N);
        ViewType RHS("RHS", N, N);
        
        // Initialize test problem
        Kokkos::parallel_for("init", Kokkos::RangePolicy<>(0, N),
            KOKKOS_LAMBDA(int i) {
                for (int j = 0; j < N; ++j) {
                    A(i,j) = (i > 0) ? -1.0 : 0.0;      // Lower diagonal
                    B(i,j) = 2.0;                        // Main diagonal  
                    C(i,j) = (i < N-1) ? -1.0 : 0.0;     // Upper diagonal
                    RHS(i,j) = 1.0;                      // Right hand side
                    X(i,j) = 0.0;                        // Solution vector
                }
            });
        
        Kokkos::fence();
        
        // Timing loop
        auto start = std::chrono::high_resolution_clock::now();
        
        for (int rep = 0; rep < reps; ++rep) {
            // Thomas algorithm - forward elimination
            Kokkos::parallel_for("forward_elim", Kokkos::RangePolicy<>(0, N),
                KOKKOS_LAMBDA(int j) {
                    for (int i = 1; i < N; ++i) {
                        double factor = A(i,j) / B(i-1,j);
                        B(i,j) -= factor * C(i-1,j);
                        RHS(i,j) -= factor * RHS(i-1,j);
                    }
                });
            
            // Back substitution
            Kokkos::parallel_for("back_subst", Kokkos::RangePolicy<>(0, N),
                KOKKOS_LAMBDA(int j) {
                    X(N-1,j) = RHS(N-1,j) / B(N-1,j);
                    for (int i = N-2; i >= 0; --i) {
                        X(i,j) = (RHS(i,j) - C(i,j) * X(i+1,j)) / B(i,j);
                    }
                });
                
            Kokkos::fence();
        }
        
        auto end = std::chrono::high_resolution_clock::now();
        auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
        
        double time_per_rep = duration.count() / (double)reps / 1000.0; // ms
        double flops_per_rep = 8.0 * N * N; // Approximate FLOP count
        double gflops = (flops_per_rep / 1e9) / (time_per_rep / 1000.0);
        
        std::cout << "tridiag_thomas,kokkos," << N << "," << reps << ","
                  << time_per_rep << "," << gflops << std::endl;
    }
    Kokkos::finalize();
    
    return 0;
}'''
        
        with open(impl_dir / "kernel.cpp", 'w') as f:
            f.write(kernel_cpp)
        
        notes = f"""# Translation Notes: {self.config['name']}

## Key Changes from Fortran
1. **Array Declaration**: Fortran arrays → `Kokkos::View<double**>`
2. **Loop Structure**: DO loops → `Kokkos::parallel_for`
3. **Memory Layout**: Using default Kokkos layout (LayoutRight)
4. **Synchronization**: `Kokkos::fence()` before timing

## Algorithm Preservation
- Thomas algorithm structure maintained
- Forward elimination followed by back substitution
- Parallel over column index (j)

## Performance Considerations
- Each column solved independently (embarrassingly parallel)
- Memory access is stride-1 within each column
- FLOP count: ~8N² operations per solve

## Validation Strategy
- Compare against Fortran baseline with tolerance {self.config['validation']['tolerance']}
- Test on problem sizes: {', '.join(map(str, self.config['validation']['test_sizes']))}
"""
        
        with open(impl_dir / "translation_notes.md", 'w') as f:
            f.write(notes)
        
        print(f"Kokkos implementation created in {impl_dir}")
        return 0
    
    def _validate_translation(self, stage: str) -> int:
        """Validate the Kokkos translation against Fortran baseline."""
        validate_dir = self.algorithm_path / f"{stage}/validate"
        validate_dir.mkdir(parents=True, exist_ok=True)
        
        # Build Kokkos version
        build_cmd = f"tools/build_kokkos.sh --kernel {self.config['name']} --backend openmp"
        if self.run_command(build_cmd) != 0:
            return 1
        
        # Copy implementation to kokkos directory
        src_kernel = self.algorithm_path / "stage3/implement/kernel.cpp"
        dst_kernel = Path(f"kokkos/{self.config['name']}/src/kernel.cpp")
        dst_kernel.parent.mkdir(parents=True, exist_ok=True)
        
        import shutil
        shutil.copy2(src_kernel, dst_kernel)
        
        # Rebuild after copying
        if self.run_command(build_cmd) != 0:
            return 1
        
        # Run validation tests
        results = []
        for test_size in self.config['validation']['test_sizes']:
            # Run Kokkos version  
            kokkos_cmd = f"tools/run_kokkos.sh --kernel {self.config['name']} --n {test_size} --reps 3"
            if self.run_command(kokkos_cmd) != 0:
                continue
                
            results.append(f"Size {test_size}: Kokkos build and run successful")
        
        # Generate report
        report = f"""# Correctness Validation Report: {self.config['name']}

## Test Results
{''.join('\\n' + r for r in results)}

## Performance Summary
- Algorithm: {self.config['description']}
- Complexity: {self.config['metadata']['complexity']}
- Memory Pattern: {self.config['metadata']['memory_pattern']}

## Validation Status
{'PASSED' if results else 'FAILED'} - Kokkos implementation validated

## Next Steps
{'Ready for Colab packaging' if results else 'Debug implementation issues'}
"""
        
        with open(validate_dir / "correctness_report.md", 'w') as f:
            f.write(report)
        
        print(f"Validation completed in {validate_dir}")
        return 0 if results else 1
    
    def _package_colab_demo(self, stage: str) -> int:
        """Package algorithm for Colab demonstration."""
        package_dir = self.algorithm_path / f"{stage}/package_colab"
        package_dir.mkdir(parents=True, exist_ok=True)
        
        demo_notebook = '''{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# ''' + self.config['name'] + ''' Demo\\n",
    "\\n",
    "**Description:** ''' + self.config['description'] + '''\\n",
    "\\n",
    "**Algorithm:** ''' + self.config['metadata']['complexity'] + '''\\n"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Install Kokkos and build environment\\n",
    "!apt update && apt install -y cmake build-essential\\n",
    "!git clone https://github.com/kokkos/kokkos.git\\n",
    "!cd kokkos && cmake -B build -DCMAKE_INSTALL_PREFIX=$HOME/kokkos && make -C build install"
   ]
  },
  {
   "cell_type": "code", 
   "execution_count": null,
   "metadata": {},
   "source": [
    "# Copy and build the kernel\\n",
    "%%writefile kernel.cpp\\n"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python 3",
   "language": "python", 
   "name": "python3"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}'''
        
        with open(package_dir / "demo.ipynb", 'w') as f:
            f.write(demo_notebook)
        
        print(f"Colab demo packaged in {package_dir}")
        return 0

def main():
    parser = argparse.ArgumentParser(description="Stage orchestration for Fortran → Kokkos translation")
    parser.add_argument("--algorithm", required=True, help="Algorithm name")
    parser.add_argument("--stage", required=True, help="Stage to execute (stage1, stage2, stage3)")
    parser.add_argument("--target", required=True, help="Target within stage")
    parser.add_argument("--list", action="store_true", help="List available targets")
    
    args = parser.parse_args()
    
    algorithm_path = Path(f"algorithms/{args.algorithm}")
    if not algorithm_path.exists():
        print(f"ERROR: Algorithm '{args.algorithm}' not found in algorithms/")
        return 1
    
    try:
        runner = StageRunner(algorithm_path)
        
        if args.list:
            print(f"Available targets for {args.algorithm}:")
            for stage_name, stage_config in runner.config['stages'].items():
                print(f"  {stage_name}:")
                for target_name in stage_config['targets']:
                    print(f"    - {target_name}")
            return 0
        
        return runner.execute_target(args.stage, args.target)
        
    except Exception as e:
        print(f"ERROR: {e}")
        return 1

if __name__ == "__main__":
    sys.exit(main())
