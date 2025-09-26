# 🤖 Amp Demo: Step-by-Step Prompts & Expected Responses

## 🎯 Interactive Amp Session Guide

This document provides the **exact prompts** and **expected responses** for demonstrating Amp's end-to-end HPC optimization capabilities.

---

## 📂 **Setup: Starting Repository State**

**Presenter Action**: Clone and show starting point
```bash
git clone https://github.com/sjarmak/gamma-technologies-demo.git
cd gamma-technologies-demo
```

**Key Message**: *"Here's our starting point - a working but naive Fortran→Kokkos translation."*

---

## 🔍 **Amp Prompt #1: Initial Code Analysis**

### **Prompt to Amp**:
```
I have a naive Fortran→Kokkos translation of a MITgcm tridiagonal solver that works but has poor performance. 

Please analyze kokkos/mitgcm_demo/src/kernel.cpp and identify the key performance bottlenecks. Focus on:
1. Kernel launch patterns  
2. Memory access efficiency
3. Parallelization opportunities
4. GPU optimization potential

Give me specific, actionable optimization recommendations.
```

### **Expected Amp Response**:
Amp should identify:

1. **Major Issue: O(nk) Kernel Launch Overhead**
   - ~50 separate `parallel_for` calls in nested loops
   - Each launch has GPU kernel setup/teardown cost
   - Dominates performance on GPU architectures

2. **Memory Layout Inefficiency** 
   - Default Kokkos layout may not be optimal for coalescing
   - No explicit memory access pattern optimization
   - Missing GPU-specific memory traits

3. **Missed Team Parallelism Opportunities**
   - Sequential k-loops could be parallelized within teams
   - No use of team scratch memory for temporaries
   - Global memory traffic for intermediate arrays

4. **Specific Recommendations**:
   - Implement TeamPolicy single-kernel approach
   - Use LayoutLeft for coalesced access patterns  
   - Add RandomAccess traits for read-only data
   - Move temporaries to team scratch memory

### **Demo Talking Point**:
*"Notice Amp doesn't just say 'make it faster' - it identifies specific architectural issues and provides concrete optimization strategies."*

---

## 🧠 **Amp Prompt #2: Oracle Consultation**

### **Prompt to Amp**:
```
Based on your analysis, I want expert-level guidance on optimizing this tridiagonal solver. Please consult the Oracle to get detailed optimization recommendations with expected performance impact.

Focus on creating a production-ready GPU-optimized implementation that maintains perfect numerical accuracy.
```

### **Expected Amp Response**:
Amp will use the Oracle tool and receive guidance on:

1. **TeamPolicy Single-Kernel Architecture**
   ```cpp
   // Replace O(nk) launches with single kernel
   TeamPolicy<ExecSpace> policy(ni, Kokkos::AUTO);
   ```

2. **Memory Layout Optimization** 
   ```cpp
   using Layout = LayoutLeft;  // Explicit coalescing
   View<double**, Layout, MemSpace> arrays;
   ```

3. **GPU Memory Traits**
   ```cpp
   using ReadOnlyTraits = MemoryTraits<RandomAccess>;
   View<const double**, Layout, MemSpace, ReadOnlyTraits> coefficients;
   ```

4. **Performance Expectation**: 5-10x improvement expected from eliminating launch overhead alone

### **Demo Talking Point**:
*"The Oracle provides expert-level optimization guidance - this is like having a Kokkos performance specialist on demand."*

---

## ⚡ **Amp Prompt #3: Implementation**

### **Prompt to Amp**:
```
Excellent analysis! Now implement the Oracle's recommendations. 

Create an optimized version with:
1. Single TeamPolicy kernel eliminating O(nk) launches
2. LayoutLeft memory layout for GPU coalescing  
3. RandomAccess traits for read-only coefficient arrays
4. Team scratch memory for c_prime and y_prime temporaries
5. Performance comparison capability (naive vs optimized)

Put the optimized implementation in kokkos/mitgcm_demo_optimized/ and ensure it can demonstrate the speedup achieved.
```

### **Expected Amp Actions**:
1. **Create Directory Structure**
   ```
   kokkos/mitgcm_demo_optimized/src/kernel.cpp
   ```

2. **Implement TeamPolicy Approach**
   - Single kernel with team-based parallelization
   - Sequential k-loops within each team
   - Proper team scratch memory allocation

3. **Add Performance Comparison**
   - Both naive and optimized implementations in same binary
   - Timing comparison with warmup iterations
   - Speedup calculation and reporting

4. **Memory Optimization**  
   - Explicit LayoutLeft specification
   - RandomAccess traits for read-only data
   - Team scratch for temporaries

### **Demo Talking Point**:
*"Watch Amp implement complex Kokkos optimizations automatically. This level of optimization typically requires deep expertise and significant development time."*

---

## 🧪 **Amp Prompt #4: Performance Validation**

### **Prompt to Amp**:
```
Now I need to validate that the optimization works and maintains numerical accuracy. 

Create a comprehensive test that:
1. Builds both naive and optimized versions
2. Runs performance comparison  
3. Validates numerical accuracy is maintained
4. Shows the achieved speedup

Make it automated so I can demonstrate the results reliably.
```

### **Expected Amp Actions**:
1. **Create Test Script** (`test_demo.sh`)
   - Automated build verification
   - Performance benchmark execution
   - Numerical accuracy validation
   - Results summary

2. **Performance Verification**
   ```bash
   kokkos/mitgcm_demo_optimized/build/kernel 1024 10 both
   ```
   Expected: ~20-30x speedup

3. **Numerical Accuracy Check**
   - Compare Fortran reference vs optimized Kokkos
   - Verify `max_abs_diff = 0.0` maintained
   - Automated pass/fail validation

### **Expected Results Display**:
```
✅ Build successful  
✅ 33.17x speedup achieved
✅ Perfect numerical agreement verified
✅ Demo ready for presentation
```

### **Demo Talking Point**:
*"Not only does Amp optimize - it validates. Production-ready code with performance improvement AND numerical accuracy guaranteed."*

---

## 📊 **Amp Prompt #5: Professional Demo Package**

### **Prompt to Amp**:
```
Create a professional demo package for showcasing this optimization, including:

1. A Google Colab notebook demonstrating GPU acceleration
2. Performance visualization and analysis charts
3. Complete documentation of the optimization process  
4. Easy-to-use demo scripts for live presentation

This should showcase the complete M4 Mac → GPU acceleration pipeline with professional-quality results.
```

### **Expected Amp Deliverables**:

1. **Colab Notebook** (`colab_gpu_demo_optimized.ipynb`)
   - GPU environment setup and detection
   - Performance scaling analysis across problem sizes
   - Memory bandwidth utilization studies
   - Visual comparison charts

2. **Demo Documentation**
   - Step-by-step presentation guide
   - Key talking points and technical explanations
   - Backup procedures for technical issues

3. **Upload Package** (`fortran_kokkos_demo.tar.gz`)
   - Complete workspace for Colab deployment
   - All optimized kernels included
   - Professional documentation suite

### **Demo Talking Point**:
*"Amp doesn't just optimize code - it creates complete professional deliverables ready for presentation and deployment."*

---

## 🎬 **Live Demo Performance**

### **Show the Results**:
```bash
# Before optimization (baseline)
kokkos/mitgcm_demo/build/kernel 1024 10 both
# Expected: ~0.0046 seconds per iteration

# After Amp optimization  
kokkos/mitgcm_demo_optimized/build/kernel 1024 10 both
# Expected: ~0.0001 seconds per iteration
# Speedup: 33.17x improvement ⚡
```

### **Numerical Validation**:
```bash
# Verify perfect accuracy maintained
python3 tools/compare_outputs.py --fortran outputs/fortran_ref.csv --kokkos outputs/optimized.csv --tol 1e-10
# Expected: max_abs_diff = 0.0000000000 ✅
```

---

## 🎯 **Demo Success Metrics**

### **Performance Achievement**:
- ✅ **33x speedup** from Oracle-guided optimizations
- ✅ **Perfect numerical fidelity** maintained (`max_abs_diff = 0.0`)
- ✅ **Real-world algorithm** (MITgcm production code) optimized
- ✅ **GPU-ready architecture** with coalesced memory patterns

### **Process Demonstration**:
- ✅ **AI-guided analysis** identifying specific bottlenecks
- ✅ **Expert consultation** providing concrete optimization strategies  
- ✅ **Automated implementation** of complex Kokkos patterns
- ✅ **Professional validation** ensuring production readiness

### **Business Value**:
- ✅ **Expert-level results** achieved in minutes vs weeks
- ✅ **Reproducible process** with complete automation
- ✅ **Platform portability** from CPU to GPU architectures
- ✅ **Professional deliverables** ready for deployment

---

## 🎤 **Key Demo Soundbites**

### **Opening**:
*"Watch Amp transform weeks of expert HPC optimization work into a 30-minute AI-guided process."*

### **During Analysis**:
*"Amp identified the exact performance bottleneck - O(nk) kernel launches - that an expert would find after detailed profiling."*

### **During Implementation**:
*"These TeamPolicy optimizations require deep Kokkos expertise. Amp implemented them automatically with perfect accuracy."*

### **Results Reveal**:
*"33x performance improvement while maintaining exact numerical fidelity. This is production-ready optimization."*

### **Closing**:
*"From problem to optimized solution: Amp delivered expert-level HPC performance engineering in minutes, not weeks."*

---

## 🔄 **Interactive Q&A Prompts**

### **If Asked About Technical Details**:
```
"Amp, explain exactly why the TeamPolicy approach eliminated the performance bottleneck."
```

### **If Asked About Accuracy**:  
```
"Amp, show me how you verified that numerical accuracy was maintained during optimization."
```

### **If Asked About GPU Scaling**:
```
"Amp, what additional performance gains do we expect when this runs on Tesla T4 GPU versus M4 Mac?"
```

### **If Asked About Other Algorithms**:
```
"Amp, what other HPC algorithms could benefit from similar optimization approaches?"
```

---

## ✅ **Demo Validation Checklist**

**Before Demo**:
- [ ] All prompts tested with Amp
- [ ] 33x speedup reproduces consistently  
- [ ] Numerical validation passes
- [ ] Colab notebook functional
- [ ] Backup plan prepared

**During Demo**:
- [ ] Show clear before/after comparison
- [ ] Explain each optimization step  
- [ ] Demonstrate live Amp interaction
- [ ] Validate numerical accuracy
- [ ] Show final performance results

**Demo Success Indicators**:
- [ ] Audience understands Amp's analysis capability
- [ ] Performance improvement clearly demonstrated  
- [ ] Numerical fidelity validation convincing
- [ ] Professional quality of results evident
- [ ] Questions about Amp's capabilities generated

This demo showcases **Amp as the expert HPC optimization assistant** - analyzing, optimizing, and validating complex scientific code with expert-level results in minutes rather than weeks.
