# 3-Stage Fortran → Kokkos Translation Demo

## Complete workflow for modernizing MITgcm HPC algorithms with AI guidance

### **What This Demo Shows**
- **3-Stage translation pipeline** from MITgcm Fortran to optimized Kokkos implementations
- **Oracle-guided optimization** providing expert-level performance recommendations
- **Automated extraction** of production algorithms from MITgcm codebase
- **Perfect numerical validation** maintained throughout translation process
- **Professional deliverables** including Colab demonstrations

### **3-Stage Workflow Overview**
```bash
# Stage 1: Analysis & Extraction
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target extract
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target explain
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target baseline

# Stage 2: Planning & Review  
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage2 --target plan
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage2 --target review

# Stage 3: Implementation & Validation
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target implement
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target validate
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target package_colab
```

## **Demo Options Available**

### **Quick Demo (5 minutes)**
Experience the complete 3-stage workflow:
```bash
git clone https://github.com/sjarmak/gamma-technologies-demo.git
cd gamma-technologies-demo

# Run complete pipeline for tridiag_thomas algorithm
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target baseline
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage2 --target review
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target validate
```

### **Interactive Development (25 minutes)**
Follow the complete 3-stage process with detailed explanations:
```bash
# See QUICK_START.md for step-by-step workflow
# See DEMO_GUIDE.md for presentation scripts
```

### **Legacy GPU Demo (30 minutes)**
Pre-built optimization demonstration:
- Existing optimized implementations
- Google Colab GPU deployment
- Performance comparison analysis

## **Demo Documentation**

### **For Quick Start**
- **[`QUICK_START.md`](QUICK_START.md)** - 30-second to 15-minute workflow options
- **[`DEMO_GUIDE.md`](DEMO_GUIDE.md)** - Complete 3-stage presentation script

### **For Development**
- **[`AGENTS.md`](AGENTS.md)** - Stage contracts and build/run commands
- **[`docs/amp-guidance.md`](docs/amp-guidance.md)** - 3-stage workflow technical details

### **Legacy Documentation**
- **[`AMP_DEMO.md`](AMP_DEMO.md)** - Interactive Amp optimization session
- **[`progress.md`](progress.md)** - Historical optimization development

## **Getting Started**

### **Prerequisites**
```bash
# Required tools for 3-stage workflow
- Python 3.6+
- gfortran (Fortran compiler)
- cmake (for Kokkos builds)
- git (for MITgcm extraction)
```

### **Verify Installation**
```bash
# Test stage runner with list of targets
python3 tools/stage_runner.py --algorithm tridiag_thomas --list

# Expected output: Available stage1/stage2/stage3 targets listed
```

### **Run Complete Workflow**
```bash
# Execute all stages for tridiag_thomas algorithm (5-10 minutes total)
for stage in stage1 stage2 stage3; do
    for target in $(python3 tools/stage_runner.py --algorithm tridiag_thomas --list | grep "$stage:" -A 10 | grep "    -" | cut -d'-' -f2 | xargs); do
        python3 tools/stage_runner.py --algorithm tridiag_thomas --stage $stage --target $target
    done
done
```

## **Key Demo Talking Points**

### **Opening**
*"Today I'll demonstrate the complete 3-stage pipeline for translating production MITgcm algorithms to GPU-accelerated Kokkos implementations with perfect numerical fidelity."*

### **Stage 1 Highlight**
*"We start by extracting real production algorithms from MITgcm and establishing precise baselines - this is critical for validation."*

### **Stage 2 Highlight**
*"Our Oracle AI analyzes the algorithm structure and provides expert-level optimization strategies - memory layouts, parallel patterns, performance risks."*

### **Stage 3 Highlight**
*"The final implementation automatically applies Oracle recommendations while maintaining exact numerical accuracy against the original Fortran."*

### **Results Emphasis**
*"Complete workflow from extraction to validation in minutes, with professional deliverables ready for production deployment."*

## **Interactive 3-Stage Demo Commands**

### **Stage 1 Commands**
```bash
# Extract algorithm from MITgcm
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target extract

# Generate documentation
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target explain

# Create performance baseline
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage1 --target baseline
```

### **Stage 2 Commands**
```bash
# Create translation plan
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage2 --target plan

# Oracle consultation
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage2 --target review
```

### **Stage 3 Commands**
```bash
# Implement Kokkos translation
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target implement

# Validate numerical correctness
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target validate

# Package for deployment
python3 tools/stage_runner.py --algorithm tridiag_thomas --stage stage3 --target package_colab
```

### **Expected Outcomes**
- Fortran routine extracted from MITgcm with documentation
- Oracle-guided translation plan with optimization strategies  
- Kokkos implementation validated against Fortran baseline
- Professional Colab demonstration package ready for deployment

## **Repository Structure**

### **3-Stage Workflow**
- `tools/stage_runner.py` - Main orchestration tool for all stages
- `algorithms/tridiag_thomas/stage.yml` - Algorithm configuration and dependencies
- `algorithms/tridiag_thomas/stage1/` - Extraction, documentation, and baselines
- `algorithms/tridiag_thomas/stage2/` - Translation plans and Oracle reviews
- `algorithms/tridiag_thomas/stage3/` - Implementation, validation, and packaging

### **Supporting Tools**
- `tools/extract_fortran_routine.sh` - MITgcm routine extraction
- `tools/explain_mitgcm.py` - Algorithm documentation generator
- `tools/build_kokkos.sh` - Kokkos build automation
- `tools/run_fortran.sh` / `tools/run_kokkos.sh` - Execution wrappers
- `tools/compare_outputs.py` - Numerical validation

### **Legacy Demonstrations**
- `kokkos/mitgcm_demo/` - Pre-built naive implementation
- `kokkos/mitgcm_demo_optimized/` - Pre-built optimized version
- `colab_gpu_demo_optimized.ipynb` - Legacy GPU demonstration

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
