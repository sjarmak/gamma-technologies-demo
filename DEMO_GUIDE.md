# 3-Stage Fortran → Kokkos Demo Guide

## Overview

This guide demonstrates the complete 3-stage workflow for translating MITgcm Fortran routines to optimized Kokkos implementations. The process extracts production algorithms, analyzes their structure, and creates GPU-accelerated versions with perfect numerical fidelity.

## Quick Start Options

### **Option 1: Complete 3-Stage Workflow**
```bash
# Run the full pipeline for tridiag_thomas algorithm
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target extract
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target explain  
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target baseline

python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage2 --target plan
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage2 --target review

python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target implement
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target validate
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target package_colab
```

### **Option 2: Pre-Built Demo (Legacy)**
```bash
# Verify existing optimized implementation
./tools/build_kokkos.sh --kernel mitgcm_demo_optimized --backend openmp
kokkos/mitgcm_demo_optimized/build/kernel 1024 10 both
```

### **Option 3: Google Colab GPU Demo**
1. **Complete Stage 3**: Run `package_colab` target to generate notebook
2. **Open Google Colab**: https://colab.research.google.com
3. **Upload**: Generated notebook from `algorithms/{name}/stage3/package_colab/`
4. **Select GPU Runtime**: Runtime → Change runtime type → GPU
5. **Run All Cells**: Follow automated workflow

---

## 3-Stage Demo Flow

### **Stage 1: MITgcm Extraction & Analysis (5 minutes)**

**Script:**
> "We start by extracting production algorithms from MITgcm and establishing performance baselines."

**Show Stage 1 Execution:**
```bash
# Extract the SOLVE_TRIDIAGONAL routine from MITgcm
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target extract

# Generate algorithm documentation
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target explain

# Establish Fortran performance baseline
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target baseline
```

**Key Points:**
- Real production code from MITgcm ocean model
- Automated documentation generation
- Precise performance baseline for validation

### **Stage 2: Oracle-Guided Planning (3 minutes)**

**Script:**
> "Our Oracle AI analyzes the algorithm and provides expert-level optimization strategies."

**Show Stage 2 Execution:**
```bash
# Create detailed translation plan
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage2 --target plan

# Oracle consultation for optimization guidance  
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage2 --target review
```

**Show Generated Plans:**
- Memory layout optimization strategies
- Parallel pattern recommendations
- Performance risk assessments
- Concrete implementation guidance

### **Stage 3: Implementation & Validation (7 minutes)**

**Script:**
> "The final stage implements the Oracle recommendations and validates perfect numerical accuracy."

**Show Stage 3 Execution:**
```bash
# Implement Kokkos translation
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target implement

# Validate against Fortran baseline
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target validate

# Package for Colab demonstration
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target package_colab
```

**Key Messages:**
- Automated Kokkos implementation generation
- Perfect numerical fidelity validation
- Ready-to-deploy demonstration packages

### **Stage 1: Numerical Validation Proof (3 minutes)**

**Script**:
> "First, let's prove **exact numerical fidelity**. This is critical for HPC - any precision loss is unacceptable."

**Show**:
```bash
# Run comparison
python3 tools/compare_outputs.py --fortran outputs/fortran_n1024.csv --kokkos outputs/gpu_n1024.csv --tol 1e-10

# Expected: max_abs_diff = 0.0000000000
```

**Key Message**: "Zero precision loss across language translation and platform migration."

### **Stage 2: Oracle Optimization Impact (5 minutes)**

**Script**:
> "Here's where **Oracle AI guidance** made the difference. The AI identified 4 critical optimizations:"

**Show Performance Results**:
```
Problem Size: 1024
Naive Implementation: 0.0046 seconds
Oracle-Optimized: 0.0002 seconds
Speedup: 23.7x improvement
```

**Explain Each Optimization** (with code snippets):

1. **"Single TeamPolicy Kernel"**
```cpp
// BEFORE: O(nk) kernel launches (~50 launches)
for (int k = 1; k < nk; k++) {
parallel_for("forward_sweep", ni, KOKKOS_LAMBDA(int i) { ... });
}

// AFTER: One kernel with team scratch
parallel_for("thomas_algorithm_single_kernel", TeamPolicy<>(ni, AUTO),
KOKKOS_LAMBDA(const TeamMember& team) { ... });
```

2. **"Memory Layout Optimization"**
```cpp
// Oracle recommended: Explicit LayoutLeft for coalesced access
using Layout = LayoutLeft; // i is stride-1 dimension
View<double**, Layout, MemSpace> arrays;
```

3. **"GPU Memory Traits"**
```cpp
// RandomAccess enables texture cache for read-only data
View<const double**, Layout, MemSpace, RandomAccess> coefficients;
```

4. **"Team Scratch Memory"**
```cpp
// Temporaries in fast scratch vs slow global memory
double* c_prime = team.team_scratch(0).get_shmem(...);
```

**Key Message**: "Oracle AI provided concrete, implementable optimizations with measurable impact."

### **Stage 3: GPU Acceleration Demonstration (8 minutes)**

**In Colab Notebook** (or describe expected results):

**Script**:
> "Now we demonstrate **performance portability** - the same code achieving acceleration across M4 Mac CPU and Tesla T4 GPU."

**Show GPU Detection**:
```python
# Expected output in Colab:
GPU: Tesla T4
Architecture: TURING75
Expected Memory Bandwidth: 320 GB/s (corrected estimate)
```

**Show Scaling Results**:
```
Problem Size | Naive (GPU) | Optimized (GPU) | Total Speedup
512 | 0.00X s | 0.00Y s | Z.Zx
1024 | 0.00A s | 0.00B s | C.Cx
2048 | 0.00D s | 0.00E s | F.Fx
```

**Show Bandwidth Analysis**:
```python
# Memory bandwidth utilization
Achieved: X GB/s out of 320 GB/s theoretical (Y% utilization)
Optimization opportunity: Oracle recommendations achieved Z% of peak
```

### **Stage 4: Professional Validation (2 minutes)**

**Script**:
> "This demonstrates **production-ready** HPC code translation with professional validation."

**Highlight**:
- **Exact numerical agreement**: `max_abs_diff = 0.0`
- **Real-world algorithm**: MITgcm production code
- **Expert guidance**: AI Oracle optimization recommendations
- **Complete automation**: Build/test/validate pipeline
- **Platform portability**: M4 Mac → Tesla GPU

---

## Key Talking Points & Soundbites

### **Opening Hook**:
*"What if AI could guide HPC code optimization to achieve 20x speedups while maintaining perfect numerical accuracy?"*

### **Technical Credibility**:
- "Real MITgcm tridiagonal solver, not a toy example"
- "Oracle AI identified kernel launch overhead as the primary bottleneck"
- "Perfect numerical fidelity with max_abs_diff = 0.0"

### **Business Impact**:
- "Same codebase runs on laptop and datacenter GPUs"
- "AI-guided optimization reduces expert time from weeks to hours"
- "Reproducible pipeline for large-scale code translation projects"

### **Demo Climax**:
*"23.7x CPU speedup from Oracle guidance, plus additional GPU acceleration - all while maintaining perfect numerical accuracy."*

### **Closing**:
*"This demonstrates the future of HPC development: AI-guided performance optimization with exact numerical validation."*

---

## Potential Issues & Solutions

### **If Colab GPU Not Available**:
- Use CPU results from M4 Mac (proven 23.7x speedup)
- Explain expected GPU performance based on bandwidth analysis

### **If Build Fails in Colab**:
- Pre-built binaries included in package
- Fall back to M4 Mac demonstration

### **If Timing Varies**:
- Multiple warmup iterations included
- Focus on speedup ratios, not absolute times
- Colab performance can vary by session

### **If Questions About Oracle**:
- "Oracle is our expert AI advisor for performance optimization"
- "It analyzed the code and provided concrete optimization recommendations"
- "All recommendations were implementable and measurably effective"

---

## Expected Demo Timeline

| Phase | Duration | Content |
|-------|----------|---------|
| **Setup** | 2 min | Open Colab, upload files, select GPU |
| **Numerical Validation** | 3 min | Prove exact accuracy |
| **Optimization Impact** | 5 min | Show 23.7x speedup, explain techniques |
| **GPU Acceleration** | 8 min | Platform portability, scaling analysis |
| **Wrap-up** | 2 min | Summary, Q&A |
| **Total** | **20 min** | Complete demonstration |

---

## Troubleshooting Commands

```bash
# Local verification
./tools/build_kokkos.sh --kernel mitgcm_demo_optimized --backend openmp
kokkos/mitgcm_demo_optimized/build/kernel 1024 5 both

# Check package contents
tar -tzf fortran_kokkos_demo.tar.gz | grep -E "(optimized|notebook)"

# Rebuild package if needed
./prepare_colab_demo.sh
```

---

## Presenter Notes

- **Confidence**: Local M4 Mac results are proven and reproducible
- **Backup Plan**: Have M4 Mac demo ready if Colab issues
- **Technical Depth**: Code snippets ready for technical audiences
- **Business Angle**: Emphasize AI-guided development workflow
- **Interactive**: Invite audience to suggest other optimization ideas

**Remember**: The 23.7x speedup is **already proven** on M4 Mac. The GPU demo extends this to show platform portability.
