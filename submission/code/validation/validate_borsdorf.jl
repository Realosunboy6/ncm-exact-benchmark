# Newton-SIN-BH against Borsdorf (2007) MSc thesis, Example 5 (the only
# deterministic matrices in his tests): cor1399 and cor3120.
#   Table 6.5, tol = 1e-7 n : cor1399 ||G-X||_F = 21.033907, 5 its; cor3120 5.44375, 4 its
#   Table 6.6, tol = n eps  : cor1399 21.033911, 7 its;              cor3120 5.443751, 6 its
ENV["NCM_STANDALONE"] = "1"
include(joinpath(@__DIR__, "..", "bench_sbb_dual.jl"))
using LinearAlgebra, Printf
BLAS.set_num_threads(2)
suite = Dict(load_suite(get(ENV, "NCM_REAL_SUITE", joinpath(@__DIR__, "..", "real_suite"))))
pub = Dict(("cor1399", "1e-7n") => ("21.033907", 5), ("cor1399", "n eps") => ("21.033911", 7),
           ("cor3120", "1e-7n") => ("5.44375", 4),   ("cor3120", "n eps") => ("5.443751", 6))
@printf("%-8s %-6s %12s %5s | %12s %5s %5s %10s %9s  %s\n", "matrix", "tol", "pub ||G-X||", "its",
        "our ||G-X||", "its", "EVDs", "||grad||", "time(s)", "exit")
for nm in ("cor1399", "cor3120")
    G = suite[nm]; n = size(G, 1)
    for (lab, tol) in (("1e-7n", 1e-7 * n), ("n eps", n * eps(Float64)))
        t = @elapsed r = newton_ncm_globalized(G; tol=tol, globalization=:armijo_bh, max_evds=40)
        _, g, _ = theta_grad(G, r.y, TimerOutput())
        p = pub[(nm, lab)]
        @printf("%-8s %-6s %12s %5d | %12.6f %5d %5d %10.2e %9.1f  %s\n", nm, lab, p[1], p[2],
                norm(G - r.X), r.updates, r.evds, norm(g), t, r.exit)
        flush(stdout)
    end
end
println("BORSDORF VALIDATION DONE")
