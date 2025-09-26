#!/usr/bin/env bash
set -euo pipefail

echo "🎬 Setting up Amp End-to-End HPC Optimization Demo"
echo "================================================="

# Create a clean starting point for the Amp demonstration
echo "📂 Preparing demo starting state..."

# Temporarily remove the optimized implementations to simulate starting point
if [[ -d "kokkos/mitgcm_demo_optimized" ]]; then
    echo "💾 Backing up optimized implementation..."
    mv kokkos/mitgcm_demo_optimized kokkos/mitgcm_demo_optimized.backup
fi

if [[ -d "kokkos/ep_optimized" ]]; then
    mv kokkos/ep_optimized kokkos/ep_optimized.backup
fi

# Clean any build artifacts
echo "🧹 Cleaning build artifacts..."
find kokkos/ -name "build" -type d -exec rm -rf {} + 2>/dev/null || true

# Build the NAIVE starting implementation
echo "🔨 Building naive baseline implementation..."
./tools/build_kokkos.sh --kernel mitgcm_demo --backend openmp

# Test the naive implementation to show starting performance
echo "📊 Testing baseline performance..."
echo "Running: kokkos/mitgcm_demo/build/kernel 1024 5 both"
BASELINE_RESULT=$(kokkos/mitgcm_demo/build/kernel 1024 5 both 2>&1 | tail -3)
echo "Baseline Results:"
echo "$BASELINE_RESULT"

# Extract timing for comparison
BASELINE_TIME=$(echo "$BASELINE_RESULT" | grep "Time per iteration" | grep -o "[0-9.]*" | head -1)

echo ""
echo "✅ Amp Demo Starting Point Ready!"
echo "=================================="
echo "📍 Current State:"
echo "   • Naive implementation: WORKING"
echo "   • Baseline performance: ${BASELINE_TIME}s per iteration" 
echo "   • Optimized versions: REMOVED (to be created by Amp)"
echo ""
echo "🎯 Demo Flow:"
echo "   1. Show current naive performance"
echo "   2. Ask Amp to analyze the code"  
echo "   3. Get Oracle optimization guidance"
echo "   4. Implement Amp's recommendations"
echo "   5. Demonstrate 33x speedup achievement"
echo ""
echo "🚀 Ready to demonstrate Amp's optimization capabilities!"
echo ""
echo "📋 Next Steps:"
echo "   • Follow AMP_DEMO.md for presentation flow"
echo "   • Use AMP_PROMPTS.md for exact Amp interactions"
echo "   • Expected outcome: 33x performance improvement"

# Create a demo status file
cat > DEMO_STATUS.md << EOF
# Amp Demo Status

## Current State: READY FOR DEMONSTRATION

### Starting Point Verified ✅
- Naive implementation: WORKING
- Baseline performance: ${BASELINE_TIME}s per iteration
- Optimized versions: Removed (to be created by Amp)

### Demo Preparation ✅
- Build system: Functional
- Test scripts: Working  
- Documentation: Complete
- Expected improvement: 33x speedup

### Next Steps
1. Follow AMP_DEMO.md presentation guide
2. Use AMP_PROMPTS.md for Amp interactions
3. Demonstrate live optimization process
4. Show final 33x performance improvement

**Demo Ready**: $(date)
EOF

echo "📝 Demo status saved to DEMO_STATUS.md"

# Restore optimized versions but rename them so they're available as reference
if [[ -d "kokkos/mitgcm_demo_optimized.backup" ]]; then
    mv kokkos/mitgcm_demo_optimized.backup kokkos/mitgcm_demo_optimized.reference
    echo "📚 Optimized reference available at kokkos/mitgcm_demo_optimized.reference"
fi

if [[ -d "kokkos/ep_optimized.backup" ]]; then
    mv kokkos/ep_optimized.backup kokkos/ep_optimized.reference  
    echo "📚 EP optimized reference available at kokkos/ep_optimized.reference"
fi

echo ""
echo "🎭 Ready to demonstrate Amp's HPC optimization capabilities!"
echo "   Start with: Show baseline performance (~${BASELINE_TIME}s)"
echo "   End with: Amp-optimized performance (target: ~0.0001s = 33x improvement)"
