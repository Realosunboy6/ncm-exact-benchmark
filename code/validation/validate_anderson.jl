# Validation of anderson_apm.jl against Higham & Strabic (2016),
# Numer. Algorithms 72:1021-1042, and their released code nearcorr_aa.m.
#
# Published iteration counts checked here (the matrices are public):
#   Table 1  four small matrices, delta = 0,           it and itAA, m = 1..6
#   Table 7  the same matrices, delta = 1e-8 and 0.1,  it and itAA, m = 1..6
#   Table 4  fixed elements: fing97 (leading 3x3 block) and the Rocky Mountain
#            matrix (its twelve diagonal blocks), it, it_fe, itAA_fe, m = 1..5
#   Table 3  cor1399 and cor3120, m = 2 (large; run with --large)
# The n = 90 matrix of Table 4 and the RiskMetrics matrices are not public.
#
# Each count is computed at tol = n*eps (the code's default) and n*eps/2
# (the paper's text, n*u). An independent Anderson implementation that stores
# the difference matrix and solves each least-squares problem from scratch is
# run alongside, to check the QR-updating arithmetic separately from the
# published counts.
#
# Usage (from code/):
#   NCM_STANDALONE=1 NCM_REAL_SUITE=real_suite julia --project=. validation/validate_anderson.jl [--large]
ENV["NCM_STANDALONE"] = "1"
include(joinpath(@__DIR__, "..", "bench_sbb_dual.jl"))
using LinearAlgebra, Printf
BLAS.set_num_threads(1)

const LARGE = "--large" in ARGS

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
small = [("tec03", 4, Matrix{Float64}(tec03)), ("bhwi01", 5, Matrix{Float64}(bhwi01)),
         ("mmb13", 6, mmb13()), ("fing97", 7, Matrix{Float64}(fing97))]

suite = Dict(load_suite(get(ENV, "NCM_REAL_SUITE", joinpath(@__DIR__, "..", "real_suite"))))
rocky = suite["Rocky_Mountain_Region_CORR"]

"Independent Anderson acceleration (Algorithm 2 with a from-scratch least-squares solve)."
function aa_direct(A; mMax, delta=0.0, pattern=nothing, tol=size(A, 1) * eps(), itmax=100000)
    n = size(A, 1); N = n * n; to = TimerOutput()
    Yin = copy(A); Sin = zeros(n, n)
    Fs = Vector{Vector{Float64}}(); Gs = Vector{Vector{Float64}}()
    for it in 1:itmax
        Xo, Yo, So = hs_ap_step(A, Yin, Sin, pattern, delta, to)
        x = vcat(vec(Yin), vec(Sin)); g = vcat(vec(Yo), vec(So)); f = g - x
        norm(Yo - Xo) / norm(Yo) < tol && return it
        push!(Fs, f); push!(Gs, g)
        if length(Fs) > mMax + 1
            popfirst!(Fs); popfirst!(Gs)
        end
        k = length(Fs) - 1
        if k == 0
            x = g
        else
            DF = hcat([Fs[i+1] - Fs[i] for i in 1:k]...)
            DGm = hcat([Gs[i+1] - Gs[i] for i in 1:k]...)
            γ = qr(DF) \ f
            x = g - DGm * γ
        end
        Yin = reshape(x[1:N], n, n); Sin = reshape(x[N+1:2N], n, n)
    end
    return -1
end

function blockpattern(sizes)
    n = sum(sizes); P = falses(n, n); s = 0
    for b in sizes
        P[s+1:s+b, s+1:s+b] .= true; s += b
    end
    return P
end

nmatch = Ref(0); ntotal = Ref(0); ndirect = Ref(0)
function report(label, pub, a, b, d)
    ntotal[] += 1
    ok = a == pub
    ok && (nmatch[] += 1)
    d == a && (ndirect[] += 1)
    @printf("    %-10s published %4d   tol=n*eps %4d %s   tol=n*u %4d   direct-LS %4d\n",
            label, pub, a, ok ? "match" : "DIFF ", b, d)
end

function table_small(title, delta, pub_it, pub_aa, ms)
    println("\n", title)
    for (k, (nm, n, A)) in enumerate(small)
        _, it1 = hs_nearcorr_new(A; delta=delta, itmax=100000)
        _, it2 = hs_nearcorr_new(A; delta=delta, tol=n * eps() / 2, itmax=100000)
        @printf("  %s (n=%d)\n", nm, n)
        report("it", pub_it[k], it1, it2, it1)
        Xap, _ = hs_nearcorr_new(A; delta=delta, itmax=100000)
        for (j, m) in enumerate(ms)
            r1 = nearcorr_aa(A; mMax=m, delta=delta, itmax=100000)
            r2 = nearcorr_aa(A; mMax=m, delta=delta, tol=n * eps() / 2, itmax=100000)
            d = aa_direct(A; mMax=m, delta=delta)
            report("itAA m=$m", pub_aa[k][j], r1.iter, r2.iter, d)
            j == 2 && @printf("    ||A-X_AA||_F - ||A-X_AP||_F = %.1e\n", norm(A - r1.X) - norm(A - Xap))
        end
    end
end

println("Higham & Strabic (2016) validation of anderson_apm.jl")

table_small("Table 1: delta = 0", 0.0, [39, 27, 801, 33],
            [[15, 10, 9, 9, 9, 9], [17, 14, 12, 11, 10, 10],
             [305, 212, 117, 126, 40, 31], [15, 10, 10, 10, 9, 9]], 1:6)
table_small("Table 7: delta = 1e-8", 1e-8, [39, 27, 802, 33],
            [[15, 10, 9, 9, 9, 10], [17, 14, 12, 11, 10, 10],
             [280, 177, 114, 58, 39, 30], [15, 10, 10, 10, 9, 9]], 1:6)
table_small("Table 7: delta = 0.1", 0.1, [66, 34, 895, 54],
            [[31, 19, 16, 13, 14, 13], [23, 15, 14, 12, 12, 12],
             [269, 216, 127, 59, 48, 41], [31, 24, 15, 15, 14, 14]], 1:6)

println("\nTable 4: fixed elements, delta = 0")
for (nm, A, P, pub_it, pub_fe, pub_aa) in
        [("fing97", Matrix{Float64}(fing97), blockpattern([3, 1, 1, 1, 1]), 33, 34, [14, 11, 10, 9, 9]),
         ("Rocky", rocky, blockpattern([12, 5, 1, 14, 12, 1, 10, 4, 5, 9, 13, 8]), 18, 40, [15, 14, 12, 12, 12])]
    n = size(A, 1)
    @printf("  %s (n=%d)\n", nm, n)
    _, it1 = hs_nearcorr_new(A; itmax=100000)
    _, it2 = hs_nearcorr_new(A; tol=n * eps() / 2, itmax=100000)
    report("it", pub_it, it1, it2, it1)
    _, f1 = hs_nearcorr_new(A; pattern=P, itmax=100000)
    _, f2 = hs_nearcorr_new(A; pattern=P, tol=n * eps() / 2, itmax=100000)
    report("it_fe", pub_fe, f1, f2, f1)
    for m in 1:5
        r1 = nearcorr_aa(A; pattern=P, mMax=m, itmax=100000)
        r2 = nearcorr_aa(A; pattern=P, mMax=m, tol=n * eps() / 2, itmax=100000)
        d = aa_direct(A; mMax=m, pattern=P)
        report("itAA_fe m=$m", pub_aa[m], r1.iter, r2.iter, d)
    end
end

@printf("\nSMALL SUMMARY: %d of %d published counts matched at tol = n*eps; direct-LS agreed on %d of %d\n",
        nmatch[], ntotal[], ndirect[], ntotal[])

# The benchmark wrapper and the published function share their arithmetic.
let A = mmb13()
    r = nearcorr_aa(A; mMax=2, itmax=100000)
    b = anderson_apm(A; tol=0.0, maxit=r.iter, m=2)
    @printf("\nanderson_apm wrapper vs nearcorr_aa on mmb13, %d steps: ||Xout diff||_F = %.1e\n",
            r.iter, norm(b.X - r.Xout))
end

if LARGE
    BLAS.set_num_threads(4)
    println("\nTable 3: m = 2, large matrices")
    for (nm, pub_it, pub_aa) in [("cor1399", 476, 124), ("cor3120", 559, 174)]
        A = suite[nm]; n = size(A, 1)
        t = @elapsed r = nearcorr_aa(A; mMax=2, itmax=100000)
        @printf("  %s (n=%d)  itAA published %d, ours %d %s  (%.0fs)\n", nm, n, pub_aa, r.iter,
                r.iter == pub_aa ? "match" : "DIFF", t)
        flush(stdout)
        t = @elapsed (_, it1) = hs_nearcorr_new(A; itmax=100000)
        @printf("  %s (n=%d)  it   published %d, ours %d %s  (%.0fs)\n", nm, n, pub_it, it1,
                it1 == pub_it ? "match" : "DIFF", t)
        flush(stdout)
    end
end
println("\nANDERSON VALIDATION DONE")
