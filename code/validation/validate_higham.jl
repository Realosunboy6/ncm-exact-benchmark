# Second validation round: the invalid correlation matrices of the Higham
# CORRINV collection (github.com/higham/matrices-correlation-invalid), with the
# published alternating-projections iteration counts of Higham & Strabic (2016),
# Numer. Algorithms 72:1021-1042, Table 1 (standard NCM) and Table 4 column "it".
#
# Check A (Dykstra-APM work): reimplement nearcorr_new.m line for line
#   (Y=A; R=Y-dS; X=P_psd(R); dS=X-R; Y=P_unitdiag(X); stop ||Y-X||_F/||Y||_F <= tol)
#   and compare its iteration count with the published one, for tol = n*eps
#   (code default) and tol = n*u, u = eps/2 (paper text). Then run OUR harness
#   dykstra_apm for exactly that many iterations and compare the iterates.
# Check B (all five solvers): same solution, valid correlation matrix.
ENV["NCM_STANDALONE"] = "1"
include(joinpath(@__DIR__, "..", "bench_sbb_dual.jl"))
using LinearAlgebra, Printf
BLAS.set_num_threads(1)

function treshape_unit(x)
    m = length(x); n = round(Int, (-1 + sqrt(1 + 8m)) / 2) + 1
    T = Matrix{Float64}(I, n, n); i = 1
    for j in 2:n
        T[1:j-1, j] = x[i:i+j-2]; i += j - 1
    end
    return T + triu(T, 1)'
end

high02 = [1.0 1 0; 1 1 1; 0 1 1]
tec03 = [1 -0.55 -0.15 -0.10; -0.55 1 0.90 0.90; -0.15 0.90 1 0.90; -0.10 0.90 0.90 1]
bhwi01 = [1 -0.50 -0.30 -0.25 -0.70; -0.50 1 0.90 0.30 0.70; -0.30 0.90 1 0.25 0.20;
          -0.25 0.30 0.25 1 0.75; -0.70 0.70 0.20 0.75 1]
function mmb13()
    A = [0.010712 0.000654 0.002391 0.010059 -0.008321 0.001738
         0.000654 0.000004 0.002917 0.000650 0.002263 0.002913
         0.002391 0.002917 0.013225 -0.000525 0.010834 0.010309
         0.010059 0.000650 -0.000525 0.009409 -0.010584 -0.001175
        -0.008321 0.002263 0.010834 -0.010584 0.019155 0.008571
         0.001738 0.002913 0.010309 -0.001175 0.008571 0.007396]
    d = sqrt.(diag(A)); A = A ./ (d * d')
    for i in 1:6; A[i, i] = 1.0; end
    return A
end
fing97 = [1 0.18 -0.13 -0.26 0.19 -0.25 -0.12; 0.18 1 0.22 -0.14 0.31 0.16 0.09;
          -0.13 0.22 1 0.06 -0.08 0.04 0.04; -0.26 -0.14 0.06 1 0.85 0.85 0.85;
          0.19 0.31 -0.08 0.85 1 0.85 0.85; -0.25 0.16 0.04 0.85 0.85 1 0.85;
          -0.12 0.09 0.04 0.85 0.85 0.85 1]
beyu11 = [
1 0.2387 0.6161 0.6167 0.6621 0.5173 0.6758 0.7071 0.7983 0.5769 0.4705 0.7881
0.2387 1 0.3506 0.3537 0.2959 0.4637 0.1931 0.1202 0.2316 0.1708 0.4047 0.1161
0.6161 0.3506 1 0.8579 0.6603 0.4093 0.3826 0.5164 0.6079 0.5574 0.4512 0.5128
0.6167 0.3537 0.8579 1 0.7477 0.1803 0.4705 0.6167 0.6218 0.4705 0.3582 0.2966
0.6621 0.2959 0.6603 0.7477 1 0.3537 0.7364 0.5670 0.6613 0.5140 0.5140 0.4610
0.5173 0.4637 0.4093 0.1803 0.3537 1 0.3582 0.1803 0.0605 0.4705 0.3582 0.6161
0.6758 0.1931 0.3826 0.4705 0.7364 0.3582 1 0.4705 0.6424 0.6090 0.4911 0.4962
0.7071 0.1202 0.5164 0.6167 0.5670 0.1803 0.4705 1 0.7149 0.4705 0.3582 0.5164
0.7983 0.2316 0.6079 0.6218 0.6613 0.0605 0.6424 0.7149 1 0.4371 0.4371 0.6079
0.5769 0.1708 0.5574 0.4705 0.5140 0.4705 0.6090 0.4705 0.4371 1 0.3745 0.4512
0.4705 0.4047 0.4512 0.3582 0.5140 0.3582 0.4911 0.3582 0.4371 0.3745 1 0.4512
0.7881 0.1161 0.5128 0.2966 0.4610 0.6161 0.4962 0.5164 0.6079 0.4512 0.4512 1]
tyda99r1 = treshape_unit([0.1, -1, 0.4, 0.8, -0.1, -0.2, 0.7, 0.4, -0.3, 0.8, -0.1, 0.4, 0.8, -0.3,
                          0, 0.3, 0.2, 0.9, -0.3, -0.5, -0.4, 0.3, 0.6, 0.8, 0.1, 1, -0.2, 0.6])
tyda99r2 = treshape_unit([0.1, 1, 0.4, 0.8, 0.1, 0.2, 0.7, 0.4, 0.3, 0.8, 0.1, 0.4, 0.8, 0.3, 0,
                          0.3, 0.2, 0.9, 0.3, 0.5, 0.4, 0.3, 0.6, 0.8, 0.1, 1, 0.2, 0.6])
tyda99r3 = treshape_unit([-0.5, -0.5, 0.5, 0.5, -0.5, -0.5, -0.5, 0.5, 0.5, -0.5, 0.5, 0.5, -0.5, 0.5,
                          0.5, 0.5, 0.5, -0.5, 0.5, -0.5, 0.5, -0.5, 0.5, 0.5, -0.5, 0.5, 0.5, -0.5])
rocky = Dict(load_suite(get(ENV, "NCM_REAL_SUITE", joinpath(@__DIR__, "..", "real_suite"))))["Rocky_Mountain_Region_CORR"]

# nearcorr_new.m, pattern = [], delta = 0
function nearcorr_new(A; tol, itmax=100000)
    Y = copy(A); dS = zeros(size(A)); iter = 0; X = Y; rel = Inf
    while rel > tol
        R = Y - dS
        F = eigen(Symmetric(R))
        X = F.vectors * Diagonal(max.(F.values, 0.0)) * F.vectors'
        X = (X + X') / 2
        dS = X - R
        Y = copy(X); for i in 1:size(A, 1); Y[i, i] = 1.0; end
        rel = norm(Y - X) / norm(Y)
        iter += 1
        iter > itmax && error("itmax")
    end
    return Y, X, iter
end

tests = [("high02", high02, nothing), ("tec03", tec03, 39), ("bhwi01", bhwi01, 27),
         ("mmb13", mmb13(), 801), ("fing97", fing97, 33), ("beyu11", beyu11, nothing),
         ("tyda99r1", tyda99r1, nothing), ("tyda99r2", tyda99r2, nothing),
         ("tyda99r3", tyda99r3, nothing), ("usgs13 (Rocky)", rocky, 18)]

println("Check A: Higham-Strabic (2016) published alternating-projections iterations")
@printf("  %-15s %4s %9s %11s %11s %16s\n", "matrix", "n", "published", "it tol=n*eps", "it tol=n*u", "our Dykstra vs ref")
for (nm, A, pub) in tests
    @assert A == A' "$nm not symmetric"
    n = size(A, 1)
    Y1, X1, it1 = nearcorr_new(A; tol=n * eps(Float64))
    Y2, X2, it2 = nearcorr_new(A; tol=n * eps(Float64) / 2)
    # our harness Dykstra, exactly it1 iterations (tol=0 so it cannot stop early)
    r = dykstra_apm(A; tol=0.0, maxit=it1)
    # dykstra_apm returns the PSD half-iterate, so compare it with Higham's X,
    # not with his unit-diagonal Y (whose distance to X is the stopping quantity).
    d = norm(r.X - X1) / norm(X1)
    @printf("  %-15s %4d %9s %11d %11d %16.1e\n", nm, n, pub === nothing ? "-" : string(pub), it1, it2, d)
end

println("\nCheck B: all five solvers, absolute tol 1e-10 on ||grad theta||_2")
@printf("  %-15s %-14s %6s %14s %10s %10s %11s  %s\n", "matrix", "solver", "EVDs", "||A-X||_F", "lam_min", "diag err", "vs Newton", "exit")
for (nm, A, _) in tests
    tol = 1e-10
    runs = [("Newton-SIN-BH", () -> newton_ncm_globalized(A; tol=tol, globalization=:armijo_bh)),
            ("SBB-Dual",      () -> sbb_dual(A; tol=tol, maxit=200000)),
            ("AGD-SDAJ",      () -> agd_sdaj_ncm(A; tol=tol, maxit=100000, max_evds=200000, globalization=:armijo_naive)),
            ("AGD-SDAJ-BH",   () -> agd_sdaj_ncm(A; tol=tol, maxit=100000, max_evds=200000, globalization=:armijo_bh)),
            ("Dykstra-APM",   () -> dykstra_apm(A; tol=tol, maxit=200000))]
    Xn = nothing
    for (s, f) in runs
        r = f(); X = r.X
        Xn === nothing && (Xn = X)
        @printf("  %-15s %-14s %6d %14.8f %10.1e %10.1e %11.1e  %s\n", nm, s, r.evds, norm(A - X),
                minimum(eigvals(Symmetric((X + X') / 2))), maximum(abs.(diag(X) .- 1)), norm(X - Xn), r.exit)
    end
    flush(stdout)
end
println("\nHIGHAM VALIDATION DONE")
