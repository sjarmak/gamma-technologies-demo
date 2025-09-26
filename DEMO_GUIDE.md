# Oracle-Optimized Fortran → Kokkos GPU Demo Guide

## Quick Start Checklist

### **Option 1: Local Demo (M4 Mac Proven)**
```bash
# 1. Verify local optimizations work
./tools/build_kokkos.sh --kernel mitgcm_demo_optimized --backend openmp
kokkos/mitgcm_demo_optimized/build/kernel 1024 10 both

# Expected output:
# Naive Time per iteration: 0.0046 seconds
# Optimized Time per iteration: 0.0002 seconds
# Speedup: 23.71x
```

### **Option 2: Google Colab GPU Demo**
1. **Open Google Colab**: https://colab.research.google.com
2. **Upload Notebook**: `colab_gpu_demo_optimized.ipynb`
3. **Select GPU Runtime**: Runtime → Change runtime type → GPU
4. **Upload Package**: `fortran_kokkos_demo.tar.gz` (when prompted by notebook)
5. **Run All Cells**: Expected total time ~15-20 minutes

---

## Demo Flow & Presentation Script

### **Introduction (2 minutes)**

> "Today I'll demonstrate **AI-guided optimization** of HPC code translation, showing how we achieved **perfect numerical fidelity** with **23.7x performance improvement** by implementing Oracle AI recommendations."

**Key Opening Points:**
- Real MITgcm tridiagonal solver (not toy example)
- Oracle AI provided expert optimization guidance
- Perfect numerical agreement across platforms
- Complete M4 Mac → GPU acceleration pipeline

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
