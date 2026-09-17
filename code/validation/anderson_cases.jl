# The published Anderson-acceleration counts of Higham & Strabic (2016) whose
# matrices are public: Table 1 (delta = 0), Table 7 (delta = 1e-8, 0.1) and
# Table 4 (fixed elements). Used by diagnose_anderson.jl.

const HS_TEC03 = [1 -0.55 -0.15 -0.10; -0.55 1 0.90 0.90; -0.15 0.90 1 0.90; -0.10 0.90 0.90 1.0]
const HS_BHWI01 = [1 -0.50 -0.30 -0.25 -0.70; -0.50 1 0.90 0.30 0.70; -0.30 0.90 1 0.25 0.20;
                   -0.25 0.30 0.25 1 0.75; -0.70 0.70 0.20 0.75 1.0]
const HS_FING97 = [1 0.18 -0.13 -0.26 0.19 -0.25 -0.12; 0.18 1 0.22 -0.14 0.31 0.16 0.09;
                   -0.13 0.22 1 0.06 -0.08 0.04 0.04; -0.26 -0.14 0.06 1 0.85 0.85 0.85;
                   0.19 0.31 -0.08 0.85 1 0.85 0.85; -0.25 0.16 0.04 0.85 0.85 1 0.85;
                   -0.12 0.09 0.04 0.85 0.85 0.85 1.0]
function hs_mmb13()
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
function hs_blockpattern(sizes)
    n = sum(sizes); P = falses(n, n); s = 0
    for b in sizes
        P[s+1:s+b, s+1:s+b] .= true; s += b
    end
    return P
end

function anderson_cases()
    suite = Dict(load_suite(get(ENV, "NCM_REAL_SUITE", joinpath(@__DIR__, "..", "real_suite"))))
    small = [("tec03", HS_TEC03), ("bhwi01", HS_BHWI01), ("mmb13", hs_mmb13()), ("fing97", HS_FING97)]
    pub = Dict(
        0.0  => [[15, 10, 9, 9, 9, 9], [17, 14, 12, 11, 10, 10], [305, 212, 117, 126, 40, 31], [15, 10, 10, 10, 9, 9]],
        1e-8 => [[15, 10, 9, 9, 9, 10], [17, 14, 12, 11, 10, 10], [280, 177, 114, 58, 39, 30], [15, 10, 10, 10, 9, 9]],
        0.1  => [[31, 19, 16, 13, 14, 13], [23, 15, 14, 12, 12, 12], [269, 216, 127, 59, 48, 41], [31, 24, 15, 15, 14, 14]])
    cases = NamedTuple[]
    for delta in (0.0, 1e-8, 0.1), (k, (nm, A)) in enumerate(small), m in 1:6
        ours = nearcorr_aa(A; mMax=m, delta=delta, itmax=100000).iter
        push!(cases, (name=nm, A=A, delta=delta, pattern=nothing, m=m, label="m=$m",
                      pub=pub[delta][k][m], ours=ours))
    end
    fixed = [("fing97fe", Matrix{Float64}(HS_FING97), hs_blockpattern([3, 1, 1, 1, 1]), [14, 11, 10, 9, 9]),
             ("Rockyfe", suite["Rocky_Mountain_Region_CORR"],
              hs_blockpattern([12, 5, 1, 14, 12, 1, 10, 4, 5, 9, 13, 8]), [15, 14, 12, 12, 12])]
    for (nm, A, P, p) in fixed, m in 1:5
        ours = nearcorr_aa(A; mMax=m, pattern=P, itmax=100000).iter
        push!(cases, (name=nm, A=A, delta=0.0, pattern=P, m=m, label="m=$m", pub=p[m], ours=ours))
    end
    return cases
end
