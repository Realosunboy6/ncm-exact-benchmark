# How much do the published tol = n*eps iteration counts depend on rounding?
# Each Higham & Strabic (2016) case is rerun with three LAPACK symmetric
# eigensolvers (syevr, syevd, syev), which differ only in rounding. A published
# count that one of them reproduces differs from our default only by rounding.
#
# Usage (from code/):
#   NCM_STANDALONE=1 NCM_REAL_SUITE=real_suite julia --project=. validation/eigensolver_sensitivity.jl
ENV["NCM_STANDALONE"] = "1"
include(joinpath(@__DIR__, "..", "bench_sbb_dual.jl"))
using LinearAlgebra, Printf
BLAS.set_num_threads(1)
include(joinpath(@__DIR__, "anderson_cases.jl"))

const SOLVERS = (:syevr, :syevd, :syev)

function count_with(solver, c)
    HS_EIG[] = solver
    try
        return nearcorr_aa(c.A; mMax=c.m, delta=c.delta, pattern=c.pattern, itmax=100000).iter
    catch
        return -1
    finally
        HS_EIG[] = :syevr
    end
end

cases = anderson_cases()
exact = 0; within = 0; mmb = 0; mmb_within = 0
@printf("%-8s %-7s %-5s %4s | %6s %6s %6s | %s\n", "matrix", "delta", "case", "pub", "syevr", "syevd", "syev", "")
for c in cases
    cs = [count_with(s, c) for s in SOLVERS]
    hit = c.pub in cs
    lo, hi = extrema(cs)
    tag = cs[1] == c.pub ? "default matches" :
          hit ? "matched by another eigensolver" :
          (lo <= c.pub <= hi ? "inside the eigensolver range" : "outside the range")
    if c.name == "mmb13"
        global mmb += 1; (hit || lo <= c.pub <= hi) && (global mmb_within += 1)
    else
        cs[1] == c.pub && (global exact += 1)
        (hit || lo <= c.pub <= hi) && (global within += 1)
    end
    @printf("%-8s %-7s %-5s %4d | %6d %6d %6d | %s\n", c.name, string(c.delta), c.label, c.pub,
            cs[1], cs[2], cs[3], tag)
    flush(stdout)
end
# Headline: exact matches per eigensolver. "Matched or bracketed" below is a
# weaker, secondary criterion and is reported only alongside it.
for sv in SOLVERS
    ex_o = count(c -> c.name != "mmb13" && count_with(sv, c) == c.pub, cases)
    ex_m = count(c -> c.name == "mmb13" && count_with(sv, c) == c.pub, cases)
    @printf("\nexact matches under %s: %d of %d excluding mmb13, %d of %d on mmb13",
            sv, ex_o, length(cases) - mmb, ex_m, mmb)
end
println()
nsmall = length(cases) - mmb
@printf("\nExcluding mmb13: default eigensolver matches %d of %d; published count matched or bracketed by the three eigensolvers in %d of %d.\n",
        exact, nsmall, within, nsmall)
@printf("mmb13: published count matched or bracketed in %d of %d.\n", mmb_within, mmb)
println("\nSENSITIVITY DONE")
