#!/usr/bin/env bash
set -euo pipefail

echo "📦 Preparing Oracle-Optimized Fortran → Kokkos Demo for Google Colab"
echo "===================================================================="

# Create clean package directory
PACKAGE_DIR="colab_package"
rm -rf "$PACKAGE_DIR"
mkdir -p "$PACKAGE_DIR"

# Copy essential files (exclude build artifacts and outputs)
echo "📁 Copying workspace files..."

# Core directories
cp -r fortran/ "$PACKAGE_DIR/"
cp -r kokkos/ "$PACKAGE_DIR/"
cp -r tools/ "$PACKAGE_DIR/"
cp -r docs/ "$PACKAGE_DIR/"
cp -r .slurm/ "$PACKAGE_DIR/"

# Documentation
cp AGENTS.md "$PACKAGE_DIR/"
cp README.md "$PACKAGE_DIR/"
cp DELIVERABLES.md "$PACKAGE_DIR/"
cp progress.md "$PACKAGE_DIR/"
cp colab_gpu_demo.ipynb "$PACKAGE_DIR/"
cp colab_gpu_demo_optimized.ipynb "$PACKAGE_DIR/"

# Clean build artifacts from Kokkos directories  
echo "🧹 Cleaning build artifacts..."
find "$PACKAGE_DIR/kokkos" -name "build" -type d -exec rm -rf {} + 2>/dev/null || true
find "$PACKAGE_DIR/kokkos" -name "CMakeLists.txt" -delete 2>/dev/null || true

# Create outputs directory
mkdir -p "$PACKAGE_DIR/outputs"

# Create .gitignore for the package
cat > "$PACKAGE_DIR/.gitignore" << 'EOF'
build/
outputs/
*.o
*.mod
a.out
EOF

# Create package info
cat > "$PACKAGE_DIR/COLAB_README.md" << 'EOF'
# Oracle-Optimized Fortran → Kokkos GPU Demo Package

This package contains the complete workspace with AI Oracle-guided optimizations:

## ✅ Proven M4 Mac Results:
- **Perfect numerical fidelity** (max_abs_diff = 0.0)
- **23.7x CPU speedup** from Oracle optimizations
- Real MITgcm tridiagonal solver successfully translated
- Complete automation pipeline with validation

## 🧠 Oracle Optimizations Implemented:
- **Single TeamPolicy kernel** (eliminates O(nk) launch overhead)  
- **LayoutLeft memory layout** (coalesced GPU access patterns)
- **RandomAccess traits** (enables GPU texture cache)
- **Team scratch memory** (reduces global memory traffic)

## 🚀 Ready for GPU Acceleration:
1. Upload this package to Google Colab
2. Run **`colab_gpu_demo_optimized.ipynb`** (NEW optimized notebook)
3. Demonstrate T4 GPU acceleration with corrected bandwidth expectations
4. Show 5-10x additional GPU speedup over optimized CPU version

## 📊 Expected GPU Results:
- Perfect numerical fidelity maintained across M4 Mac → T4 GPU
- Professional NVIDIA profiling integration  
- Visual performance scaling analysis
- Memory bandwidth utilization demonstration

## 📁 Key Files:
- `colab_gpu_demo_optimized.ipynb` - Oracle-optimized demo notebook
- `kokkos/mitgcm_demo_optimized/` - 23.7x faster implementation
- `progress.md` - Complete development and optimization history

See `progress.md` for the full optimization journey guided by Oracle AI.
EOF

# Create tarball for easy upload
echo "📦 Creating tarball for Colab upload..."
tar -czf fortran_kokkos_demo.tar.gz -C "$PACKAGE_DIR" .

# Summary
PACKAGE_SIZE=$(du -h fortran_kokkos_demo.tar.gz | cut -f1)
FILE_COUNT=$(find "$PACKAGE_DIR" -type f | wc -l)

echo "✅ Package ready for Google Colab!"
echo "   File: fortran_kokkos_demo.tar.gz"
echo "   Size: $PACKAGE_SIZE"
echo "   Files: $FILE_COUNT"
echo ""
echo "🚀 Next steps for Oracle-optimized demo:"
echo "   1. Open Google Colab (colab.research.google.com)"
echo "   2. Upload **colab_gpu_demo_optimized.ipynb** (NEW optimized notebook)" 
echo "   3. Upload fortran_kokkos_demo.tar.gz when prompted"
echo "   4. Run cells to demonstrate Oracle-guided GPU acceleration!"
echo ""
echo "💡 Expected demo highlights:"
echo "   • 23.7x CPU speedup demonstrated → additional GPU acceleration"
echo "   • Perfect numerical validation maintained across platforms"
echo "   • T4 GPU bandwidth analysis (corrected ~320 GB/s expectations)"
echo "   • Professional NVIDIA profiling integration"
echo "   • Visual before/after performance comparisons"
echo "   • Oracle AI optimization techniques showcased"
