# Amp End-to-End HPC Optimization Demo

## Interactive demonstration of Amp's complete workflow for optimizing HPC code translation

### **What This Demo Shows**
- **Amp's complete optimization process** from naive code to 33x performance improvement
- **AI-guided analysis and implementation** of complex Kokkos optimizations
- **Oracle consultation** providing expert-level performance recommendations
- **Perfect numerical validation** maintained throughout optimization process
- **Professional deliverables** created automatically by Amp

### **Demo Outcome: 33x Speedup Achievement**
```bash
# Starting Point (Naive Implementation)
Baseline: 0.0046 seconds per iteration

# After Amp Optimization Process
Optimized: 0.0001 seconds per iteration
Improvement: 33.17x speedup

# Numerical Accuracy: max_abs_diff = 0.0 (Perfect fidelity)
```

## **Demo Formats Available**

### **Quick Demo (5 minutes)**
Show Amp's final optimization results:
```bash
git clone https://github.com/sjarmak/gamma-technologies-demo.git
cd gamma-technologies-demo
./test_demo.sh # Shows 33x speedup achieved
```

### **Interactive Amp Session (25 minutes)**
Follow along as Amp optimizes code step-by-step:
```bash
./setup_amp_demo.sh # Prepare starting point
# Then follow AMP_DEMO.md for live Amp interaction
```

### **Complete GPU Pipeline (30 minutes)**
Full CPU → GPU acceleration demonstration:
- Local optimization with Amp
- Google Colab GPU deployment
- Professional performance analysis

## **Demo Documentation**

### **For Presenters**
- **[`AMP_DEMO.md`](AMP_DEMO.md)** - Complete 25-minute interactive demo script
- **[`AMP_PROMPTS.md`](AMP_PROMPTS.md)** - Exact prompts and expected Amp responses
- **[`QUICK_START.md`](QUICK_START.md)** - 30-second to 20-minute demo options

### **For Technical Details**
- **[`DEMO_GUIDE.md`](DEMO_GUIDE.md)** - Technical deep-dive and troubleshooting
- **[`progress.md`](progress.md)** - Complete optimization development history

## **Demo Setup**

### **Prepare Interactive Demo**
```bash
# Set up starting point for live Amp demonstration
./setup_amp_demo.sh

# This creates the naive baseline and removes optimized versions
# so you can demonstrate Amp creating them live
```

### **Verify Demo Ready**
```bash
# Test that baseline works
kokkos/mitgcm_demo/build/kernel 1024 5 both

# Expected: Shows naive performance (~0.0046s per iteration)
# Ready to ask Amp to optimize this
```

## **Key Demo Talking Points**

### **Opening**
*"Today I'll show Amp's complete workflow for HPC optimization - taking naive code and achieving 33x performance improvement through AI-guided development."*

### **During Amp Analysis**
*"Watch Amp identify the exact performance bottleneck that an HPC expert would find after detailed profiling - O(nk) kernel launch overhead."*

### **During Oracle Consultation**
*"Amp's Oracle provides expert-level optimization guidance - concrete, implementable strategies rather than vague suggestions."*

### **During Implementation**
*"These TeamPolicy optimizations require deep Kokkos expertise. Amp implements them automatically while maintaining perfect numerical accuracy."*

### **Results Reveal**
*"33x performance improvement with exact numerical fidelity maintained. This is production-ready optimization achieved in minutes, not weeks."*

## **Interactive Prompts for Live Demo**

### **Amp Prompt 1: Analysis**
```
Analyze the MITgcm tridiagonal solver in kokkos/mitgcm_demo/src/kernel.cpp.
Identify performance bottlenecks and recommend specific Kokkos optimizations.
```

### **Amp Prompt 2: Oracle Consultation**
```
Consult the Oracle to create a concrete optimization plan for this solver.
I want specific code changes for dramatic GPU performance improvement.
```

### **Amp Prompt 3: Implementation**
```
Implement the Oracle recommendations: TeamPolicy kernel, LayoutLeft layout,
RandomAccess traits, and team scratch memory. Create optimized version
with performance comparison capability.
```

### **Expected Outcome**
Amp creates optimized implementation achieving 33x speedup with perfect accuracy.

## **Repository Structure**

### **Starting Point (Naive Implementation)**
- `fortran/mitgcm_demo.f90` - Original MITgcm algorithm
- `kokkos/mitgcm_demo/` - Naive Fortran→Kokkos translation
- **Performance**: ~0.0046s per iteration (baseline)

### **Amp-Generated Optimizations**
- `kokkos/mitgcm_demo_optimized/` - Created by Amp during demo
- **Techniques**: TeamPolicy, LayoutLeft, RandomAccess, scratch memory
- **Performance**: ~0.0001s per iteration (33x improvement)

### **Validation & Automation**
- `test_demo.sh` - Automated verification suite
- `tools/` - Complete build/test/compare pipeline
- `colab_gpu_demo_optimized.ipynb` - GPU acceleration notebook

## **Success Metrics for Demo**

### **Technical Achievement**
- **33x speedup** through AI-guided optimization
- **Perfect numerical accuracy** maintained throughout process
- **Real-world algorithm** (MITgcm) successfully optimized
- **Production-ready code** with complete validation

### **Process Demonstration**
- **AI analysis** identifying specific performance bottlenecks
- **Expert consultation** providing concrete optimization strategies
- **Automated implementation** of complex parallel programming patterns
- **Professional validation** ensuring deployment readiness

### **Business Value**
- **Expert-level results** achieved in minutes vs weeks
- **Reproducible process** applicable to other HPC applications
- **Platform portability** from laptop CPU to datacenter GPU
- **Complete deliverables** ready for production deployment

## **Why This Demo Matters**

### **For HPC Community**
Demonstrates that AI can achieve expert-level optimization results while maintaining the numerical accuracy critical for scientific computing.

### **For Software Development**
Shows how AI agents can handle complex performance engineering tasks that typically require specialized expertise and extensive development time.

### **For AI Capabilities**
Illustrates advanced AI reasoning applied to real-world technical problems with measurable, reproducible results.

## **Demo Outcomes**

**Immediate Impact**: Audience sees Amp transform weeks of expert work into minutes of AI-guided development.

**Technical Validation**: 33x performance improvement with perfect numerical accuracy proves production-ready results.

**Process Innovation**: Complete workflow from analysis to deployment demonstrates AI-augmented software engineering at its best.

---

**Ready to see Amp optimize your HPC applications?** Start with `./setup_amp_demo.sh` and follow the interactive demo guide!
