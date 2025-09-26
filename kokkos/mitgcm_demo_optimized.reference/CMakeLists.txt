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
