# Table 3, cor3120: itAA published 174 (m = 2). Count under the syevd eigensolver,
# which reproduced the published cor1399 count exactly (diagnose_anderson_cor1399.log).
ENV["NCM_STANDALONE"] = "1"
include(joinpath(@__DIR__, "..", "bench_sbb_dual.jl"))
using LinearAlgebra, Printf
BLAS.set_num_threads(4)
A = Dict(load_suite(get(ENV, "NCM_REAL_SUITE", "real_suite")))["cor3120"]
for s in (:syevd,)
    HS_EIG[] = s
    t = @elapsed r = nearcorr_aa(A; mMax=2, itmax=100000)
    @printf("cor3120 (n=%d) %s: itAA = %d (published 174)  %.0fs\n", size(A, 1), s, r.iter, t)
end
