# Does anderson_apm_fast (the timing form) compute the same iterates as
# anderson_apm (the transcription validated against the published counts)?
#
# Both are run on the same instances under both tolerances used by the timing
# study. For each pair of runs this reports whether the EVD counts and exits
# agree, the largest relative difference between their per-step forward errors,
# and the difference between the returned matrices.
#
# Usage (from code/):
#   NCM_STANDALONE=1 NCM_REAL_SUITE=real_suite julia --project=. validation/check_anderson_fast.jl
ENV["NCM_STANDALONE"] = "1"
include(joinpath(@__DIR__, "..", "bench_sbb_dual.jl"))
using LinearAlgebra, Printf
BLAS.set_num_threads(1)

function pick(dir, names)
    s = Dict(load_suite(dir)); xs = load_xstars(dir)
    [(nm, s[nm], xs[nm]) for nm in names if haskey(s, nm)]
end

cases = vcat(
    pick("degen_instances_paired",
         ["degen-r$(r)-m$(m)-d$(d)-p0" for r in (5, 20, 50) for m in (1, 5, 20) for d in ("0", "1e-08")]),
    pick("degen_instances_n500_paired",
         ["degen-r5-m1-d0-p0", "degen-r20-m20-d1e-08-p0", "degen-r50-m5-d0-p0"]))
rocky = Dict(load_suite(get(ENV, "NCM_REAL_SUITE", "real_suite")))["Rocky_Mountain_Region_CORR"]
push!(cases, ("Rocky_Mountain_Region_CORR", rocky, anderson_apm(rocky; tol=1e-13, maxit=5000).X))

@printf("%-28s %-8s %6s %6s %-14s %12s %12s\n", "instance", "tol", "EVDs", "fast", "exit",
        "max rel err", "||X-Xf||")
worst = 0.0; mismatches = 0
for (nm, G, Xref) in cases
    n = size(G, 1)
    for (lab, τ) in (("native", 1e-7 * n), ("matched", 1e-11))
        t1 = Traj(Xref); t2 = Traj(Xref)
        a = anderson_apm(G; tol=τ, maxit=5000, traj=t1)
        b = anderson_apm_fast(G; tol=τ, maxit=5000, traj=t2)
        e1 = [r.err_raw_fro for r in t1.rows]; e2 = [r.err_raw_fro for r in t2.rows]
        k = min(length(e1), length(e2))
        rel = maximum(abs(e1[i] - e2[i]) / max(e1[i], 1e-300) for i in 1:k)
        dx = norm(a.X - b.X) / norm(a.X)
        same = a.evds == b.evds && a.exit == b.exit
        same || (global mismatches += 1)
        global worst = max(worst, dx)
        @printf("%-28s %-8s %6d %6d %-14s %12.1e %12.1e%s\n", nm, lab, a.evds, b.evds,
                a.exit, rel, dx, same ? "" : "   <- differ")
        flush(stdout)
    end
end
@printf("\n%d run pairs; EVD count or exit differs in %d; largest relative difference in the returned X %.1e\n",
        2 * length(cases), mismatches, worst)
println("FAST CHECK DONE")
