# Validate all five solvers against published examples before the thesis run.
#  1. Higham (2002) 3x3 example: published nearest correlation matrix to 4 d.p.
#  2. Huynh & Hwang (2025) P7/P8/P9: published ||A - X||_F and AGD-SDAJ EVD counts
#     under their stopping rule ||grad theta||_2 <= 1e-7 n.
ENV["NCM_STANDALONE"] = "1"
include(joinpath(@__DIR__, "..", "bench_sbb_dual.jl"))
using LinearAlgebra, Printf
BLAS.set_num_threads(4)

function solve_all(G, tol; agd_cap=400, apm_maxit=300, sbb_maxit=3000)
    n = size(G, 1)
    return [
        ("SBB-Dual",      () -> sbb_dual(G; tol=tol, maxit=sbb_maxit)),
        ("Newton-SIN-BH", () -> newton_ncm_globalized(G; tol=tol, globalization=:armijo_bh)),
        ("AGD-SDAJ",      () -> agd_sdaj_ncm(G; tol=tol, max_evds=agd_cap, globalization=:armijo_naive)),
        ("AGD-SDAJ-BH",   () -> agd_sdaj_ncm(G; tol=tol, max_evds=agd_cap, globalization=:armijo_bh)),
        ("Dykstra-APM",   () -> dykstra_apm(G; tol=tol, maxit=apm_maxit)),
    ]
end

function report(name, G, tol; published_dist=nothing, published_X=nothing, published_evds=nothing)
    @printf("\n=== %s  (n=%d, tol=%.1e)\n", name, size(G, 1), tol)
    published_dist === nothing || @printf("    published ||A-X||_F = %s\n", published_dist)
    published_evds === nothing || @printf("    published AGD-SDAJ EVDs = %d\n", published_evds)
    @printf("    %-14s %6s %8s %14s %11s %10s  %s\n", "solver", "EVDs", "time(s)", "||A-X||_F", "lam_min", "diag err", "exit")
    Xs = Dict{String,Matrix{Float64}}()
    for (s, f) in solve_all(G, tol)
        t = @elapsed r = f()
        X = r.X
        Xs[s] = X
        lam = minimum(eigvals(Symmetric((X + X') / 2)))
        de = maximum(abs.(diag(X) .- 1))
        @printf("    %-14s %6d %8.1f %14.6f %11.2e %10.2e  %s\n", s, r.evds, t, norm(G - X), lam, de, r.exit)
        if published_X !== nothing
            @printf("        max |X - X_published| = %.1e (published to 4 d.p.)\n", maximum(abs.(X - published_X)))
        end
        flush(stdout)
    end
    Xn = Xs["Newton-SIN-BH"]
    for (s, X) in Xs
        s == "Newton-SIN-BH" && continue
        @printf("    ||X_%s - X_Newton||_F = %.2e\n", s, norm(X - Xn))
    end
    flush(stdout)
end

# 1. Higham (2002), IMA J. Numer. Anal. 22, Sec. 5 example
A3 = [1.0 1 0; 1 1 1; 0 1 1]
X3 = [1.0 0.7607 0.1573; 0.7607 1.0 0.7607; 0.1573 0.7607 1.0]
report("Higham 2002 3x3", A3, 1e-12; published_X=X3)

# 2. Huynh & Hwang (2025) P7, P8, P9 at their stopping rule 1e-7 n
suite = Dict(load_suite(get(ENV, "NCM_REAL_SUITE", joinpath(@__DIR__, "..", "real_suite"))))
for (nm, dist, evds) in (("cor1399", "21.03", 31), ("cor3120", "5.44", 18), ("bccd16", "29.06", 5))
    G = suite[nm]
    report(nm, G, 1e-7 * size(G, 1); published_dist=dist, published_evds=evds)
end
println("\nVALIDATION DONE")
