#include <Kokkos_Core.hpp>
#include <iostream>
#include <chrono>
#include <cmath>
#include <iomanip>

using namespace Kokkos;

// Optimized memory layout and traits for GPU performance
using Layout = LayoutLeft;  // Explicit layout for coalesced access
using MemSpace = DefaultExecutionSpace::memory_space;
using ExecSpace = DefaultExecutionSpace;

// Memory traits for read-only data (enables texture cache on GPU)
using ReadOnlyTraits = MemoryTraits<RandomAccess>;

// Profiling stubs for compatibility
inline void pushRegion(const char*) {}
inline void popRegion() {}

void solve_tridiagonal_kokkos_optimized(int ni, int nk, 
                                       View<const double**, Layout, MemSpace, ReadOnlyTraits> a,
                                       View<const double**, Layout, MemSpace, ReadOnlyTraits> b,
                                       View<const double**, Layout, MemSpace, ReadOnlyTraits> c,
                                       View<double**, Layout, MemSpace> y) {
  
  pushRegion("thomas_solver_optimized");
  
  // Single TeamPolicy kernel with scratch memory - eliminates O(nk) launch overhead
  TeamPolicy<ExecSpace> policy(ni, Kokkos::AUTO);
  
  // Allocate scratch memory for temporaries (c_prime, y_prime)
  policy.set_scratch_size(0, PerTeam(2 * nk * sizeof(double)));
  
  parallel_for("thomas_algorithm_single_kernel", policy,
    KOKKOS_LAMBDA(const TeamPolicy<ExecSpace>::member_type& team) {
      
      int i = team.league_rank();
      
      // Get scratch memory for this team
      double* c_prime = (double*)team.team_scratch(0).get_shmem(nk * sizeof(double));
      double* y_prime = (double*)team.team_scratch(0).get_shmem(nk * sizeof(double), nk * sizeof(double));
      
      // Forward sweep - first element
      if (b(i,0) != 0.0) {
        double recVar = 1.0 / b(i,0);
        c_prime[0] = c(i,0) * recVar;
        y_prime[0] = y(i,0) * recVar;
      } else {
        c_prime[0] = 0.0;
        y_prime[0] = 0.0;
      }
      
      // Forward sweep - sequential k-loop within team (no kernel launch overhead)
      for (int k = 1; k < nk; k++) {
        double tmpVar = b(i,k) - a(i,k) * c_prime[k-1];
        if (tmpVar != 0.0) {
          double recVar = 1.0 / tmpVar;
          c_prime[k] = c(i,k) * recVar;
          y_prime[k] = (y(i,k) - a(i,k) * y_prime[k-1]) * recVar;
        } else {
          c_prime[k] = 0.0;
          y_prime[k] = 0.0;
        }
      }
      
      // Backward sweep - last element
      y(i,nk-1) = y_prime[nk-1];
      
      // Backward sweep - sequential k-loop within team
      for (int k = nk-2; k >= 0; k--) {
        y(i,k) = y_prime[k] - c_prime[k] * y(i,k+1);
      }
    }
  );
  
  popRegion();
}

void solve_tridiagonal_kokkos_naive(int ni, int nk, 
                                   View<double**, Layout, MemSpace> a, 
                                   View<double**, Layout, MemSpace> b, 
                                   View<double**, Layout, MemSpace> c,
                                   View<double**, Layout, MemSpace> y) {
  
  pushRegion("thomas_solver_naive");
  
  // Create temporary arrays for the Thomas algorithm
  View<double**, Layout, MemSpace> c_prime("c_prime", ni, nk);
  View<double**, Layout, MemSpace> y_prime("y_prime", ni, nk);
  
  // Forward sweep - first elements
  pushRegion("forward_sweep");
  parallel_for("forward_sweep_first", ni, KOKKOS_LAMBDA(int i) {
    if (b(i,0) != 0.0) {
      double recVar = 1.0 / b(i,0);
      c_prime(i,0) = c(i,0) * recVar;
      y_prime(i,0) = y(i,0) * recVar;
    } else {
      c_prime(i,0) = 0.0;
      y_prime(i,0) = 0.0;
    }
  });
  
  // Sequential k-loop for forward sweep - O(nk) kernel launches!
  for (int k = 1; k < nk; k++) {
    parallel_for("forward_sweep", ni, KOKKOS_LAMBDA(int i) {
      double tmpVar = b(i,k) - a(i,k) * c_prime(i,k-1);
      if (tmpVar != 0.0) {
        double recVar = 1.0 / tmpVar;
        c_prime(i,k) = c(i,k) * recVar;
        y_prime(i,k) = (y(i,k) - a(i,k) * y_prime(i,k-1)) * recVar;
      } else {
        c_prime(i,k) = 0.0;
        y_prime(i,k) = 0.0;
      }
    });
  }
  popRegion();
  
  // Backward sweep
  pushRegion("backward_sweep");
  parallel_for("backward_sweep_last", ni, KOKKOS_LAMBDA(int i) {
    y(i,nk-1) = y_prime(i,nk-1);
  });
  
  // Sequential k-loop for backward sweep - more kernel launches
  for (int k = nk-2; k >= 0; k--) {
    parallel_for("backward_sweep", ni, KOKKOS_LAMBDA(int i) {
      y(i,k) = y_prime(i,k) - c_prime(i,k) * y(i,k+1);
    });
  }
  popRegion();
  
  popRegion();
}

int main(int argc, char* argv[]) {
  if (argc < 4) {
    std::cerr << "Usage: " << argv[0] << " <n> <reps> <impl>" << std::endl;
    std::cerr << "  impl: naive|optimized|both" << std::endl;
    return 1;
  }
  
  int n = std::atoi(argv[1]);
  int reps = std::atoi(argv[2]);
  std::string impl = argv[3];
  
  // Initialize Kokkos
  initialize(argc, argv);
  {
    constexpr int Nr = 50;  // vertical levels (typical MITgcm)
    constexpr double pi = 3.141592653589793;
    
    // Allocate Views with optimized layout
    View<double**, Layout, MemSpace> a("a", n, Nr);
    View<double**, Layout, MemSpace> b("b", n, Nr);
    View<double**, Layout, MemSpace> c("c", n, Nr);
    View<double**, Layout, MemSpace> y("y", n, Nr);
    View<double**, Layout, MemSpace> y_naive("y_naive", n, Nr);
    View<double**, Layout, MemSpace> y_optimized("y_optimized", n, Nr);
    
    // Initialize test matrices - tridiagonal system for heat diffusion
    pushRegion("initialization");
    parallel_for("init_matrices", MDRangePolicy<Rank<2>>({0,0}, {n,Nr}), 
                 KOKKOS_LAMBDA(int i, int k) {
      // Lower diagonal (except first row)
      if (k > 0) {
        a(i,k) = -0.5;
      } else {
        a(i,k) = 0.0;
      }
      
      // Main diagonal - always positive definite
      b(i,k) = 2.0 + 0.1 * std::sin(pi * double(i+1)/double(n));
      
      // Upper diagonal (except last row)
      if (k < Nr-1) {
        c(i,k) = -0.5;
      } else {
        c(i,k) = 0.0;
      }
      
      // RHS - some test function
      y(i,k) = std::sin(pi * double(i+1)/double(n)) * std::cos(pi * double(k+1)/double(Nr));
    });
    popRegion();
    
    fence();  // Ensure initialization is complete before timing
    
    // Warmup iterations
    for (int warmup = 0; warmup < 3; warmup++) {
      deep_copy(y_naive, y);
      if (impl == "naive" || impl == "both") {
        solve_tridiagonal_kokkos_naive(n, Nr, a, b, c, y_naive);
      }
      if (impl == "optimized" || impl == "both") {
        deep_copy(y_optimized, y);
        // Create const views with ReadOnly traits for optimized version
        auto a_const = View<const double**, Layout, MemSpace, ReadOnlyTraits>(a);
        auto b_const = View<const double**, Layout, MemSpace, ReadOnlyTraits>(b);
        auto c_const = View<const double**, Layout, MemSpace, ReadOnlyTraits>(c);
        solve_tridiagonal_kokkos_optimized(n, Nr, a_const, b_const, c_const, y_optimized);
      }
    }
    fence();
    
    // Benchmark naive implementation
    if (impl == "naive" || impl == "both") {
      auto start_naive = std::chrono::high_resolution_clock::now();
      
      for (int rep = 0; rep < reps; rep++) {
        deep_copy(y_naive, y);
        solve_tridiagonal_kokkos_naive(n, Nr, a, b, c, y_naive);
      }
      
      fence();
      auto end_naive = std::chrono::high_resolution_clock::now();
      auto duration_naive = std::chrono::duration_cast<std::chrono::microseconds>(end_naive - start_naive);
      double time_per_iter_naive = double(duration_naive.count()) / (1000000.0 * reps);
      
      std::cerr << "Naive Time per iteration: " << std::fixed << std::setprecision(4) 
                << time_per_iter_naive << " seconds" << std::endl;
    }
    
    // Benchmark optimized implementation
    if (impl == "optimized" || impl == "both") {
      // Create const views with ReadOnly traits
      auto a_const = View<const double**, Layout, MemSpace, ReadOnlyTraits>(a);
      auto b_const = View<const double**, Layout, MemSpace, ReadOnlyTraits>(b);
      auto c_const = View<const double**, Layout, MemSpace, ReadOnlyTraits>(c);
      
      auto start_optimized = std::chrono::high_resolution_clock::now();
      
      for (int rep = 0; rep < reps; rep++) {
        deep_copy(y_optimized, y);
        solve_tridiagonal_kokkos_optimized(n, Nr, a_const, b_const, c_const, y_optimized);
      }
      
      fence();
      auto end_optimized = std::chrono::high_resolution_clock::now();
      auto duration_optimized = std::chrono::duration_cast<std::chrono::microseconds>(end_optimized - start_optimized);
      double time_per_iter_optimized = double(duration_optimized.count()) / (1000000.0 * reps);
      
      std::cerr << "Optimized Time per iteration: " << std::fixed << std::setprecision(4) 
                << time_per_iter_optimized << " seconds" << std::endl;
      
      if (impl == "both") {
        // Calculate speedup
        auto start_naive = std::chrono::high_resolution_clock::now();
        for (int rep = 0; rep < reps; rep++) {
          deep_copy(y_naive, y);
          solve_tridiagonal_kokkos_naive(n, Nr, a, b, c, y_naive);
        }
        fence();
        auto end_naive = std::chrono::high_resolution_clock::now();
        auto duration_naive = std::chrono::duration_cast<std::chrono::microseconds>(end_naive - start_naive);
        double time_per_iter_naive = double(duration_naive.count()) / (1000000.0 * reps);
        
        double speedup = time_per_iter_naive / time_per_iter_optimized;
        std::cerr << "Speedup: " << std::fixed << std::setprecision(2) << speedup << "x" << std::endl;
      }
    }
    
    // Write output to CSV format (use appropriate result based on implementation)
    View<double**, Layout, MemSpace> result_view;
    if (impl == "optimized") {
      result_view = y_optimized;
    } else {
      result_view = y_naive;
    }
    
    auto h_y_result = create_mirror_view_and_copy(HostSpace{}, result_view);
    
    for (int i = 0; i < n; i++) {
      for (int k = 0; k < Nr; k++) {
        std::cout << std::fixed << std::setprecision(10) << h_y_result(i,k);
        if (k < Nr-1) std::cout << ",";
      }
      std::cout << std::endl;
    }
  }
  finalize();
  
  return 0;
}
