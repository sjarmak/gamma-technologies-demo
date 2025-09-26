#!/usr/bin/env bash
set -euo pipefail
KERNEL=""; BACKEND="openmp"
while [[ $# -gt 0 ]]; do case "$1" in
  --kernel) KERNEL="$2"; shift 2;;
  --backend) BACKEND="$2"; shift 2;;
  *) echo "unknown $1"; exit 2;;
esac; done
[[ -z "$KERNEL" ]] && { echo "need --kernel"; exit 2; }

mkdir -p "kokkos/$KERNEL/src" "kokkos/$KERNEL/build" && cd "kokkos/$KERNEL"
# Minimal CMake; assumes Kokkos available via module or find_package
cat > CMakeLists.txt <<'EOF'
cmake_minimum_required(VERSION 3.20)
project(kokkos_port LANGUAGES CXX)

# Handle OpenMP on macOS
if(APPLE)
  set(OpenMP_CXX_FLAGS "-Xclang -fopenmp -I/opt/homebrew/Cellar/libomp/21.1.2/include")
  set(OpenMP_CXX_LIB_NAMES "omp")
  set(OpenMP_omp_LIBRARY "/opt/homebrew/Cellar/libomp/21.1.2/lib/libomp.dylib")
endif()

find_package(Kokkos REQUIRED)
add_executable(kernel src/kernel.cpp)
target_link_libraries(kernel Kokkos::kokkos)
EOF

cmake -S . -B build \
  -DKokkos_ENABLE_OPENMP=$([[ "$BACKEND" == "openmp" ]] && echo ON || echo OFF) \
  -DKokkos_ENABLE_CUDA=$([[ "$BACKEND" == "cuda" ]] && echo ON || echo OFF) \
  -DKokkos_ENABLE_HIP=$([[ "$BACKEND" == "hip" ]] && echo ON || echo OFF) \
  -DKokkos_ENABLE_SERIAL=$([[ "$BACKEND" == "serial" ]] && echo ON || echo OFF) \
  -DCMAKE_BUILD_TYPE=Release
cmake --build build -j
