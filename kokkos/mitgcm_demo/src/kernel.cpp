#include <Kokkos_Core.hpp>
#include <iostream>
#include <chrono>
#include <cmath>
#include <iomanip>

using namespace Kokkos;

void solve_tridiagonal_kokkos(int ni, int nk, 
                             View<double**> a, View<double**> b, View<double**> c,
                             View<double**> y) {
  
  // Create temporary arrays for the Thomas algorithm
  View<double**> c_prime("c_prime", ni, nk);
  View<double**> y_prime("y_prime", ni, nk);
  
  // Forward sweep - Thomas algorithm
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
  
  // Sequential k-loop for forward sweep
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
  
  // Backward sweep
  parallel_for("backward_sweep_last", ni, KOKKOS_LAMBDA(int i) {
    y(i,nk-1) = y_prime(i,nk-1);
  });
  
  // Sequential k-loop for backward sweep
  for (int k = nk-2; k >= 0; k--) {
    parallel_for("backward_sweep", ni, KOKKOS_LAMBDA(int i) {
      y(i,k) = y_prime(i,k) - c_prime(i,k) * y(i,k+1);
    });
  }
}

int main(int argc, char* argv[]) {
  if (argc < 3) {
    std::cerr << "Usage: " << argv[0] << " <n> <reps>" << std::endl;
    return 1;
  }
  
  int n = std::atoi(argv[1]);
  int reps = std::atoi(argv[2]);
  
  // Initialize Kokkos
  initialize(argc, argv);
  {
    constexpr int Nr = 50;  // vertical levels (typical MITgcm)
    constexpr double pi = 3.141592653589793;
    
    // Allocate Views
    View<double**> a("a", n, Nr);
    View<double**> b("b", n, Nr);
    View<double**> c("c", n, Nr);
    View<double**> y("y", n, Nr);
    View<double**> y_result("y_result", n, Nr);
    
    // Initialize test matrices - tridiagonal system for heat diffusion
    parallel_for("init_matrices", MDRangePolicy<Rank<2>>({0,0}, {n,Nr}), 
                 KOKKOS_LAMBDA(int i, int k) {
      // Lower diagonal (except first row)
      if (k > 0) {
        a(i,k) = -0.5;
      } else {
        a(i,k) = 0.0;
      }
      
      // Main diagonal - always positive definite (use 1-based indexing like Fortran)
      b(i,k) = 2.0 + 0.1 * std::sin(pi * double(i+1)/double(n));
      
      // Upper diagonal (except last row)
      if (k < Nr-1) {
        c(i,k) = -0.5;
      } else {
        c(i,k) = 0.0;
      }
      
      // RHS - some test function (use 1-based indexing like Fortran)
      y(i,k) = std::sin(pi * double(i+1)/double(n)) * std::cos(pi * double(k+1)/double(Nr));
    });
    
    fence();  // Ensure initialization is complete before timing
    
    auto start = std::chrono::high_resolution_clock::now();
    
    for (int rep = 0; rep < reps; rep++) {
      // Copy y to y_result for each iteration
      deep_copy(y_result, y);
      
      // Call the tridiagonal solver
      solve_tridiagonal_kokkos(n, Nr, a, b, c, y_result);
    }
    
    fence();  // Ensure computation is complete before measuring time
    
    auto end = std::chrono::high_resolution_clock::now();
    auto duration = std::chrono::duration_cast<std::chrono::microseconds>(end - start);
    
    // Write output to CSV format
    auto h_y_result = create_mirror_view_and_copy(HostSpace{}, y_result);
    
    for (int i = 0; i < n; i++) {
      for (int k = 0; k < Nr; k++) {
        std::cout << std::fixed << std::setprecision(10) << h_y_result(i,k);
        if (k < Nr-1) std::cout << ",";
      }
      std::cout << std::endl;
    }
    
    // Write timing info to stderr
    double time_per_iter = double(duration.count()) / (1000000.0 * reps);
    std::cerr << "Time per iteration: " << std::fixed << std::setprecision(4) 
              << time_per_iter << " seconds" << std::endl;
  }
  finalize();
  
  return 0;
}
