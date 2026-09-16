using LinearAlgebra, Printf
A = [1 0.18 -0.13 -0.26 0.19 -0.25 -0.12; 0.18 1 0.22 -0.14 0.31 0.16 0.09;
     -0.13 0.22 1 0.06 -0.08 0.04 0.04; -0.26 -0.14 0.06 1 0.85 0.85 0.85;
     0.19 0.31 -0.08 0.85 1 0.85 0.85; -0.25 0.16 0.04 0.85 0.85 1 0.85;
     -0.12 0.09 0.04 0.85 0.85 0.85 1]
tol = 7 * eps(Float64)
let Y = copy(A)
dS = zeros(7, 7)
for it in 1:36
    R = Y - dS; F = eigen(Symmetric(R))
    X = F.vectors * Diagonal(max.(F.values, 0.0)) * F.vectors'; X = (X + X') / 2
    dS = X - R; Y = copy(X); for i in 1:7; Y[i, i] = 1.0; end
    rel = norm(Y - X) / norm(Y)
    it >= 31 && @printf("it %d  rel = %.3e  tol = %.3e  ratio = %.3f\n", it, rel, tol, rel / tol)
end
end
