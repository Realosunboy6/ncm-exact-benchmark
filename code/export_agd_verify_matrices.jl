#=
Export P7 (cor1399), P8 (cor3120), P9 (bccd16) to plain float64 binaries so
agd_sdaj.jl can run without a MAT dependency. Reproduces the exact
treshape(x,1)-then-symmetrize convention audited in run_p7_p8_sbb.py /
bench_sbb_dual.jl::load_higham_matrix -- same matrices already used for the
SBB-Dual vs Newton P7/P8 benchmark, so no new provenance question is introduced.
=#
using MAT, LinearAlgebra

SRC = joinpath(@__DIR__, "..", "..", "..", "..", "..",
               "benchmarks-and-missingness", "work", "p7-p8-sbb", "source-matrices")
OUT = joinpath(@__DIR__, "agd_verify_matrices")
mkpath(OUT)

function load_higham_matrix(path::AbstractString)
    vars = matread(path)
    if !haskey(vars, "x")
        haskey(vars, "A") || error("$path has neither variable x nor A")
        A = Float64.(vars["A"])
        size(A, 1) == size(A, 2) || error("$path: A is not square")
        return (A + A') / 2
    end
    x = vec(Float64.(vars["x"]))
    m = length(x)
    n = Int(round((1.0 + sqrt(1.0 + 8.0 * m)) / 2.0))
    n * (n - 1) ÷ 2 == m || error("x has invalid unit-triangular length $m")
    A = Matrix{Float64}(I, n, n)
    offset = 0
    for col in 2:n
        k = col - 1
        A[1:k, col] = x[offset+1:offset+k]
        offset += k
    end
    offset == m || error("not all packed entries consumed")
    A .+= triu(A, 1)'
    return A
end

for (name, file) in [("P7_cor1399", "cor1399.mat"), ("P8_cor3120", "cor3120.mat"),
                      ("P9_bccd16", "bccd16.mat")]
    path = joinpath(SRC, file)
    isfile(path) || (println("MISSING: $path"); continue)
    A = load_higham_matrix(path)
    n = size(A, 1)
    open(joinpath(OUT, "$name.bin"), "w") do io
        write(io, A)
    end
    println("$name: n=$n  diag range [$(minimum(diag(A))), $(maximum(diag(A)))]  written")
end
