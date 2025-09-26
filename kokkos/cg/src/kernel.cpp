#include <Kokkos_Core.hpp>
#include <cmath>
#include <chrono>
#include <iostream>
#include <iomanip>

int main(int argc, char* argv[]) {
    if (argc < 3) {
        std::cerr << "Usage: " << argv[0] << " --n <n> --reps <reps>" << std::endl;
        return 1;
    }
    
    int n = 1024, reps = 2;
    
    // Parse command line arguments
    for (int i = 1; i < argc; i += 2) {
        if (std::string(argv[i]) == "--n") {
            n = std::atoi(argv[i+1]);
        } else if (std::string(argv[i]) == "--reps") {
            reps = std::atoi(argv[i+1]);
        }
    }
    
    Kokkos::initialize(argc, argv);
    {
        using ViewType = Kokkos::View<double**, Kokkos::LayoutLeft>;
        using VectorType = Kokkos::View<double*>;
        
        // Allocate arrays
        ViewType A("A", n, n);
        VectorType x("x", n);
        VectorType b("b", n);
        VectorType r("r", n);
        VectorType p("p", n);
        VectorType Ap("Ap", n);
        
        // Initialize - simple symmetric positive definite matrix
        Kokkos::parallel_for("init_matrix", Kokkos::RangePolicy<>(0, n),
                            KOKKOS_LAMBDA(const int i) {
            for (int j = 0; j < n; j++) {
                if (i == j) {
                    A(i, j) = 4.0;
                } else if (std::abs(i - j) == 1) {
                    A(i, j) = -1.0;
                } else {
                    A(i, j) = 0.0;
                }
            }
            b(i) = std::sin(3.14159 * static_cast<double>(i + 1) / static_cast<double>(n));
            x(i) = 0.0;
        });
        
        Kokkos::fence();
        auto start_time = std::chrono::high_resolution_clock::now();
        
        for (int rep = 0; rep < reps; rep++) {
            // Reset solution
            Kokkos::parallel_for("reset_x", n, KOKKOS_LAMBDA(const int i) {
                x(i) = 0.0;
            });
            
            // Simple CG iteration
            // r = b
            Kokkos::parallel_for("init_r", n, KOKKOS_LAMBDA(const int i) {
                r(i) = b(i);
            });
            
            // p = r
            Kokkos::parallel_for("init_p", n, KOKKOS_LAMBDA(const int i) {
                p(i) = r(i);
            });
            
            // rsold = dot_product(r, r)
            double rsold = 0.0;
            Kokkos::parallel_reduce("dot_r_r", n, KOKKOS_LAMBDA(const int i, double& sum) {
                sum += r(i) * r(i);
            }, rsold);
            
            int max_iter = (10 < n) ? 10 : n;  // Limited iterations for demo
            for (int iter = 0; iter < max_iter; iter++) {
                // Ap = A * p
                Kokkos::parallel_for("matvec", n, KOKKOS_LAMBDA(const int i) {
                    double sum = 0.0;
                    for (int j = 0; j < n; j++) {
                        sum += A(i, j) * p(j);
                    }
                    Ap(i) = sum;
                });
                
                // pAp = dot_product(p, Ap)
                double pAp = 0.0;
                Kokkos::parallel_reduce("dot_p_Ap", n, KOKKOS_LAMBDA(const int i, double& sum) {
                    sum += p(i) * Ap(i);
                }, pAp);
                
                if (pAp <= 1e-14) {
                    break;
                }
                
                double alpha = rsold / pAp;
                
                // x = x + alpha * p
                Kokkos::parallel_for("update_x", n, KOKKOS_LAMBDA(const int i) {
                    x(i) = x(i) + alpha * p(i);
                });
                
                // r = r - alpha * Ap
                Kokkos::parallel_for("update_r", n, KOKKOS_LAMBDA(const int i) {
                    r(i) = r(i) - alpha * Ap(i);
                });
                
                // rsnew = dot_product(r, r)
                double rsnew = 0.0;
                Kokkos::parallel_reduce("dot_r_r_new", n, KOKKOS_LAMBDA(const int i, double& sum) {
                    sum += r(i) * r(i);
                }, rsnew);
                
                if (std::sqrt(rsnew) < 1e-10) {
                    break;
                }
                
                double beta = rsnew / rsold;
                
                // p = r + beta * p
                Kokkos::parallel_for("update_p", n, KOKKOS_LAMBDA(const int i) {
                    p(i) = r(i) + beta * p(i);
                });
                
                rsold = rsnew;
            }
        }
        
        auto end_time = std::chrono::high_resolution_clock::now();
        double elapsed = std::chrono::duration<double>(end_time - start_time).count();
        
        // Output solution
        auto h_x = Kokkos::create_mirror_view(x);
        Kokkos::deep_copy(h_x, x);
        
        for (int i = 0; i < n; i++) {
            if (i < n - 1) {
                std::cout << std::fixed << std::setprecision(10) << h_x(i) << ",";
            } else {
                std::cout << std::fixed << std::setprecision(10) << h_x(i) << std::endl;
            }
        }
        
        std::cerr << "Time per iteration: " << std::fixed << std::setprecision(4) 
                  << elapsed / reps << " seconds" << std::endl;
    }
    Kokkos::finalize();
    
    return 0;
}
