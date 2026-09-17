# Why do some published Anderson counts differ? A transcription error would
# make our iterates differ from an independent implementation well before
# rounding matters, and would change counts at loose tolerances too. Rounding
# noise at the stopping tolerance n*eps would not.
#
# For every Table 1 / Table 7 / Table 4 case this reports
#   drift   max_k ||X_k(ours) - X_k(direct)||_F / ||X_k||_F over the steps with
#           rel_k > 1e-10 (before the iteration reaches the rounding floor)
#   c8,c10  iteration counts at tol = 1e-8 and 1e-10, ours / direct
#   floor   rel_k / (n*eps) at the published count k and at k-1, k+1: values
#           near 1 mean the published tolerance sits on the rounding floor
#
# Usage (from code/):
#   NCM_STANDALONE=1 NCM_REAL_SUITE=real_suite julia --project=. validation/diagnose_anderson.jl
ENV["NCM_STANDALONE"] = "1"
include(joinpath(@__DIR__, "..", "bench_sbb_dual.jl"))
using LinearAlgebra, Printf
BLAS.set_num_threads(1)

include(joinpath(@__DIR__, "anderson_cases.jl"))

"Run nearcorr_aa to a fixed number of steps, recording Xout and rel at each."
function trace_ours(A; m, delta, pattern, steps)
    Xs = Matrix{Float64}[]; rels = Float64[]
    stop = (X, Y) -> begin
        push!(Xs, X); push!(rels, norm(Y - X) / norm(Y))
        length(rels) >= steps
    end
    nearcorr_aa(A; mMax=m, delta=delta, pattern=pattern, itmax=steps, stop=stop)
    return Xs, rels
end

"Independent Anderson acceleration (from-scratch least squares), same record."
function trace_direct(A; m, delta, pattern, steps)
    n = size(A, 1); N = n * n; to = TimerOutput()
    Yin = copy(A); Sin = zeros(n, n)
    Fs = Vector{Vector{Float64}}(); Gs = Vector{Vector{Float64}}()
    Xs = Matrix{Float64}[]; rels = Float64[]
    for it in 1:steps
        Xo, Yo, So = hs_ap_step(A, Yin, Sin, pattern, delta, to)
        push!(Xs, Xo); push!(rels, norm(Yo - Xo) / norm(Yo))
        x = vcat(vec(Yin), vec(Sin)); g = vcat(vec(Yo), vec(So)); f = g - x
        push!(Fs, f); push!(Gs, g)
        length(Fs) > m + 1 && (popfirst!(Fs); popfirst!(Gs))
        k = length(Fs) - 1
        if k == 0
            x = g
        else
            DF = hcat([Fs[i+1] - Fs[i] for i in 1:k]...)
            DGm = hcat([Gs[i+1] - Gs[i] for i in 1:k]...)
            F = qr(DF)
            any(iszero, diag(F.R)) && break      # rounding-floor breakdown
            x = g - DGm * (F \ f)
        end
        Yin = reshape(x[1:N], n, n); Sin = reshape(x[N+1:2N], n, n)
    end
    return Xs, rels
end

firstbelow(rels, t) = (k = findfirst(<(t), rels); k === nothing ? -1 : k)

@printf("%-8s %-7s %-6s %4s %4s | %9s | %9s %9s | %s\n", "matrix", "delta", "case", "pub", "ours",
        "drift", "c8 o/d", "c10 o/d", "rel/(n*eps) at pub-1, pub, pub+1")
for c in anderson_cases()
    n = size(c.A, 1)
    steps = max(c.pub, c.ours) + 40
    Xo, ro = trace_ours(c.A; m=c.m, delta=c.delta, pattern=c.pattern, steps=steps)
    Xd, rd = trace_direct(c.A; m=c.m, delta=c.delta, pattern=c.pattern, steps=steps)
    K = min(something(findfirst(<(1e-10), ro), steps), length(Xo), length(Xd))
    drift = maximum(norm(Xo[k] - Xd[k]) / norm(Xo[k]) for k in 1:K)
    τ = n * eps()
    fl(k) = 1 <= k <= length(ro) ? @sprintf("%5.2f", ro[k] / τ) : "  -  "
    @printf("%-8s %-7s %-6s %4d %4d | %9.1e | %4d/%-4d %4d/%-4d | %s %s %s%s\n",
            c.name, string(c.delta), c.label, c.pub, c.ours, drift,
            firstbelow(ro, 1e-8), firstbelow(rd, 1e-8), firstbelow(ro, 1e-10), firstbelow(rd, 1e-10),
            fl(c.pub - 1), fl(c.pub), fl(c.pub + 1), c.pub == c.ours ? "" : "   <- differs")
    flush(stdout)
end
println("\nDIAGNOSIS DONE")
