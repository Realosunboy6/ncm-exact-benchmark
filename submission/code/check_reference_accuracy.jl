# How accurate is the computed reference on cor3120 (and bccd16)?
#
# Reference A: the paper's recipe, semismooth Newton (Borsdorf-Higham line
#   search) from y = 0, capped at 30 EVDs.
# Reference B: an independent route, SBB-Dual driven to its floor, then the
#   same Newton polish from that point.
# The per-iteration gradient norm of each Newton run is logged, so the rounding
# floor is visible, and the two primal matrices are compared. Their distance
# bounds how finely forward error can be resolved on these matrices.
#
# Usage (from code/): julia --project=. check_reference_accuracy.jl <suite dir> [matrix_names...]
ENV["NCM_STANDALONE"] = "1"
include(joinpath(@__DIR__, "bench_sbb_dual.jl"))
using LinearAlgebra, Printf
BLAS.set_num_threads(4)

suite_dir = length(ARGS) >= 1 ? ARGS[1] : "real_suite"
matrix_names = length(ARGS) >= 2 ? ARGS[2:end] : ["cor3120", "bccd16"]
suite = Dict(load_suite(suite_dir))

function newton_logged(G, label; y0=nothing)
    lg = Any[]
    t = @elapsed r = newton_ncm_globalized(G; tol=1e-14, y0=y0, globalization=:armijo_bh,
                                          max_evds=30, log=lg)
    @printf("  %s: %d EVDs, %.0fs, exit=%s\n", label, r.evds, t, r.exit)
    for e in lg
        @printf("    outer %2d  evds %2d  ||grad|| %.3e -> %.3e  %s\n",
                e.outer, e.evds, e.grad2_current, e.grad2, e.decision)
    end
    flush(stdout)
    return r
end

for nm in matrix_names
    G = suite[nm]; n = size(G, 1)
    @printf("\n=== %s (n=%d), n*eps = %.2e\n", nm, n, n * eps(Float64))
    rA = newton_logged(G, "reference A (Newton from 0)")
    ts = @elapsed w = sbb_dual(G; tol=1e-11, maxit=60000, rescale=false)
    @printf("  SBB-Dual to floor: %d EVDs, %.0fs, exit=%s\n", w.evds, ts, w.exit)
    rB = newton_logged(G, "reference B (Newton from SBB-Dual)"; y0=w.y)
    _, gA, _ = theta_grad(G, rA.y, TimerOutput())
    _, gB, _ = theta_grad(G, rB.y, TimerOutput())
    @printf("  ||grad A|| = %.3e   ||grad B|| = %.3e\n", norm(gA), norm(gB))
    @printf("  ||X_A - X_B||_F = %.3e   ||y_A - y_B||_2 = %.3e\n",
            norm(rA.X - rB.X), norm(rA.y - rB.y))
    @printf("  ||G - X_A||_F = %.10f   ||G - X_B||_F = %.10f\n", norm(G - rA.X), norm(G - rB.X))
    flush(stdout)
end
println("\nREFERENCE CHECK DONE")
