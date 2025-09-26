#include <Kokkos_Core.hpp>
#include <iostream>
#include <cmath>
#include <chrono>
#include <iomanip>

int main(int argc, char* argv[]) {
  if (argc < 3) {
    std::cerr << "Usage: kernel <n> <reps>" << std::endl;
    return 1;
  }

  int n = std::atoi(argv[1]);
  int reps = std::atoi(argv[2]);

  Kokkos::initialize(argc, argv);
  {
    // Allocate arrays using Kokkos::View
    Kokkos::View<double*> x("x", n);
    Kokkos::View<double*> y("y", n);

    // Initialize arrays
    Kokkos::parallel_for("init", n, KOKKOS_LAMBDA(const int i) {
      x(i) = std::sin(3.14159 * static_cast<double>(i + 1) / static_cast<double>(n));
    });

    // Ensure all initialization is complete before timing
    Kokkos::fence();

    auto start_time = std::chrono::high_resolution_clock::now();

    for (int rep = 0; rep < reps; ++rep) {
      // Embarrassingly parallel operations
      Kokkos::parallel_for("ep_compute", n, KOKKOS_LAMBDA(const int i) {
        y(i) = std::exp(x(i)) * std::cos(x(i)) + x(i) * x(i);
      });
    }

    Kokkos::fence();
    auto end_time = std::chrono::high_resolution_clock::now();

    // Output results in CSV format
    for (int i = 0; i < n; ++i) {
      if (i < n - 1) {
        std::cout << std::fixed << std::setprecision(10) << y(i) << ",";
      } else {
        std::cout << std::fixed << std::setprecision(10) << y(i) << std::endl;
      }
    }

    // Calculate and output timing
    auto duration = std::chrono::duration_cast<std::chrono::nanoseconds>(end_time - start_time);
    double time_per_iter = duration.count() / 1e9 / reps;
    
    std::cerr << "Time per iteration: " << std::fixed << std::setprecision(4) 
              << time_per_iter << " seconds" << std::endl;
  }
  Kokkos::finalize();

  return 0;
}
