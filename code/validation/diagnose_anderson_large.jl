# Table 3 of Higham & Strabic (2016): itAA = 124 (cor1399) and 174 (cor3120),
# m = 2. Our transcription gives fewer. This separates the candidate causes:
#   floor      the stopping quantity rel_k near tol = n*eps over the last steps
#   solver     the count under each LAPACK eigensolver
#   droptol    Walker's AndAcc.m, which the paper names as its implementation,
#              drops history columns when cond(R) > 1e10 by default
#   drift      our QR-updating iterates against a from-scratch least-squares
#              solve, before the floor
#
# Usage (from code/):
#   NCM_STANDALONE=1 NCM_REAL_SUITE=real_suite julia --project=. validation/diagnose_anderson_large.jl [cor1399|cor3120]
ENV["NCM_STANDALONE"] = "1"
include(joinpath(@__DIR__, "..", "bench_sbb_dual.jl"))
using LinearAlgebra, Printf
BLAS.set_num_threads(4)

nm = isempty(ARGS) ? "cor1399" : ARGS[1]
pub = Dict("cor1399" => 124, "cor3120" => 174)[nm]
suite = Dict(load_suite(get(ENV, "NCM_REAL_SUITE", joinpath(@__DIR__, "..", "real_suite"))))
A = suite[nm]; n = size(A, 1); τ = n * eps()
@printf("%s (n=%d), published itAA = %d, tol = n*eps = %.2e\n", nm, n, pub, τ)

function traced(A; solver=:syevr, droptol=0.0, steps)
    HS_EIG[] = solver
    rels = Float64[]; Xs = Matrix{Float64}[]
    stop = (X, Y) -> begin
        push!(rels, norm(Y - X) / norm(Y))
        length(Xs) < 40 && push!(Xs, X)          # early iterates for the drift check
        length(rels) >= steps
    end
    t = @elapsed r = nearcorr_aa(A; mMax=2, itmax=steps, droptol=droptol, stop=stop)
    HS_EIG[] = :syevr
    return rels, Xs, r, t
end

firstbelow(r, t) = (k = findfirst(<(t), r); k === nothing ? -1 : k)
steps = pub + 25

for (label, solver, droptol) in [("syevr, droptol 0", :syevr, 0.0),
                                 ("syevd, droptol 0", :syevd, 0.0),
                                 ("syevr, droptol 1e10", :syevr, 1e10)]
    rels, _, r, t = traced(A; solver=solver, droptol=droptol, steps=steps)
    @printf("\n  %-20s count at n*eps %4d   at 1e-8 %4d   at 1e-10 %4d   at 1e-12 %4d  (%s%.0fs)\n",
            label, firstbelow(rels, τ), firstbelow(rels, 1e-8), firstbelow(rels, 1e-10),
            firstbelow(rels, 1e-12), r.breakdown ? "breakdown, " : "", t)
    lo = max(1, firstbelow(rels, 1e-11) - 2)
    print("    rel/(n*eps) from step $lo:")
    for k in lo:length(rels)
        (k - lo) % 10 == 0 && print("\n     ")
        @printf(" %d:%.2f", k, rels[k] / τ)
    end
    println()
    flush(stdout)
end

# Drift of our updating QR against a from-scratch least-squares solve.
function direct_first(A, steps)
    n = size(A, 1); N = n * n; to = TimerOutput()
    Yin = copy(A); Sin = zeros(n, n)
    Fs = Vector{Vector{Float64}}(); Gs = Vector{Vector{Float64}}(); Xs = Matrix{Float64}[]
    for it in 1:steps
        Xo, Yo, So = hs_ap_step(A, Yin, Sin, nothing, 0.0, to)
        push!(Xs, Xo)
        x = vcat(vec(Yin), vec(Sin)); g = vcat(vec(Yo), vec(So)); f = g - x
        push!(Fs, f); push!(Gs, g)
        length(Fs) > 3 && (popfirst!(Fs); popfirst!(Gs))
        k = length(Fs) - 1
        if k == 0
            x = g
        else
            DF = hcat([Fs[i+1] - Fs[i] for i in 1:k]...)
            DGm = hcat([Gs[i+1] - Gs[i] for i in 1:k]...)
            x = g - DGm * (qr(DF) \ f)
        end
        Yin = reshape(x[1:N], n, n); Sin = reshape(x[N+1:2N], n, n)
    end
    return Xs
end
K = n < 2000 ? 40 : 8
_, Xo, _, _ = traced(A; steps=K)
Xd = direct_first(A, K)
@printf("\n  drift over the first %d steps: max ||X_k(ours) - X_k(direct)||_F / ||X_k||_F = %.1e\n",
        K, maximum(norm(Xo[k] - Xd[k]) / norm(Xo[k]) for k in 1:K))
println("\nLARGE DIAGNOSIS DONE")
