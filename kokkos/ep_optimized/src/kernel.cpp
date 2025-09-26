#include <Kokkos_Core.hpp>
#include <iostream>
#include <cmath>
#include <chrono>
#include <iomanip>

using namespace Kokkos;

// Optimized memory layout and traits
using Layout = LayoutLeft;
using MemSpace = DefaultExecutionSpace::memory_space;
using ExecSpace = DefaultExecutionSpace;
using ReadOnlyTraits = MemoryTraits<RandomAccess>;

// Profiling stubs for compatibility
inline void pushRegion(const char*) {}
inline void popRegion() {}

int main(int argc, char* argv[]) {
  if (argc < 4) {
    std::cerr << "Usage: kernel <n> <reps> <impl>" << std::endl;
    std::cerr << "  impl: naive|optimized|both" << std::endl;
    return 1;
  }

  int n = std::atoi(argv[1]);
  int reps = std::atoi(argv[2]);
  std::string impl = argv[3];

  initialize(argc, argv);
  {
    // Allocate arrays with optimized layout
    View<double*, Layout, MemSpace> x("x", n);
    View<double*, Layout, MemSpace> y_naive("y_naive", n);
    View<double*, Layout, MemSpace> y_optimized("y_optimized", n);

    // Initialize arrays
    pushRegion("initialization");
    parallel_for("init", n, KOKKOS_LAMBDA(const int i) {
      x(i) = std::sin(3.14159 * static_cast<double>(i + 1) / static_cast<double>(n));
    });
    popRegion();

    fence(); // Ensure initialization is complete

    // Warmup
    for (int warmup = 0; warmup < 3; warmup++) {
      parallel_for("warmup", n, KOKKOS_LAMBDA(const int i) {
        y_naive(i) = x(i) * x(i) + 2.0 * x(i) + 1.0;
      });
    }
    fence();

    // Benchmark naive implementation
    if (impl == "naive" || impl == "both") {
      pushRegion("ep_naive");
      auto start_naive = std::chrono::high_resolution_clock::now();
      
      for (int rep = 0; rep < reps; rep++) {
        parallel_for("ep_computation_naive", n, KOKKOS_LAMBDA(const int i) {
          y_naive(i) = x(i) * x(i) + 2.0 * x(i) + 1.0;
        });
      }
      
      fence();
      auto end_naive = std::chrono::high_resolution_clock::now();
      popRegion();
      
      auto duration_naive = std::chrono::duration_cast<std::chrono::microseconds>(end_naive - start_naive);
      double time_per_iter_naive = double(duration_naive.count()) / (1000000.0 * reps);
      
      std::cerr << "Naive Time per iteration: " << std::fixed << std::setprecision(6) 
                << time_per_iter_naive << " seconds" << std::endl;
    }

    // Benchmark optimized implementation with memory traits
    if (impl == "optimized" || impl == "both") {
      // Create const view with RandomAccess traits for read-only data
      auto x_const = View<const double*, Layout, MemSpace, ReadOnlyTraits>(x);
      
      pushRegion("ep_optimized");
      auto start_optimized = std::chrono::high_resolution_clock::now();
      
      for (int rep = 0; rep < reps; rep++) {
        // Optimized kernel with memory traits and better vectorization hints
        parallel_for("ep_computation_optimized", 
          RangePolicy<ExecSpace>(0, n).set_chunk_size(1024),
          KOKKOS_LAMBDA(const int i) {
            const double xi = x_const(i);  // Single load, const-qualified
            y_optimized(i) = xi * xi + 2.0 * xi + 1.0;  // Optimized computation
          }
        );
      }
      
      fence();
      auto end_optimized = std::chrono::high_resolution_clock::now();
      popRegion();
      
      auto duration_optimized = std::chrono::duration_cast<std::chrono::microseconds>(end_optimized - start_optimized);
      double time_per_iter_optimized = double(duration_optimized.count()) / (1000000.0 * reps);
      
      std::cerr << "Optimized Time per iteration: " << std::fixed << std::setprecision(6) 
                << time_per_iter_optimized << " seconds" << std::endl;
      
      if (impl == "both") {
        // Calculate speedup
        auto start_naive = std::chrono::high_resolution_clock::now();
        for (int rep = 0; rep < reps; rep++) {
          parallel_for("ep_computation_naive", n, KOKKOS_LAMBDA(const int i) {
            y_naive(i) = x(i) * x(i) + 2.0 * x(i) + 1.0;
          });
        }
        fence();
        auto end_naive = std::chrono::high_resolution_clock::now();
        auto duration_naive = std::chrono::duration_cast<std::chrono::microseconds>(end_naive - start_naive);
        double time_per_iter_naive = double(duration_naive.count()) / (1000000.0 * reps);
        
        double speedup = time_per_iter_naive / time_per_iter_optimized;
        std::cerr << "Speedup: " << std::fixed << std::setprecision(2) << speedup << "x" << std::endl;
      }
    }

    // Output results (use appropriate result based on implementation)
    View<double*, Layout, MemSpace> result_view;
    if (impl == "optimized") {
      result_view = y_optimized;
    } else {
      result_view = y_naive;
    }

    auto h_result = create_mirror_view_and_copy(HostSpace{}, result_view);

    // Write results in CSV format
    for (int i = 0; i < n; i++) {
      std::cout << std::fixed << std::setprecision(10) << h_result(i);
      if (i < n-1) std::cout << ",";
    }
    std::cout << std::endl;

    // Performance analysis output handled above
  }
  finalize();

  return 0;
}
