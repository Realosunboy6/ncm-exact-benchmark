#=
Local reimplementation of Huynh & Hwang (2025), "Accelerated Gradient Descent With
Quasi-Newton Preconditioning for Nearest Correlation Matrix Problems," Numerical
Linear Algebra with Applications, DOI 10.1002/nla.70045.

PURPOSE: verify this reimplementation against the paper's own published counts
(Table 3, q=2: P7 -> 31 EVDs, P8 -> 18 EVDs, P9 -> 5 EVDs) on their own instances
(cor1399, cor3120, bccd16) BEFORE it is ever run on the KKT-controlled family or
reported in a ranking-reversal comparison. Per Paper 2's own thesis, an unverified
reimplementation reported as losing is indefensible -- this file is gate 1, not the
Paper 2 experiment itself.

TRANSCRIBED FROM THE PAPER (pages captured as
work/pdf-review/algorithm1-09.png, algorithms34-12.png, setup-16.png):
  - Algorithm 1 (AGD): steepest-descent direction, monotone Armijo backtracking for
    alpha_k, then a BB-style rescaling beta_k = a_k/b_k (a_k = <g_k,g_k>,
    b_k = <g_k - g(y_k), g_k>) applied to alpha_k*d_k, beta_k=1 if b_k<=0.
    NOTE the sign convention: z_k = grad(x_k) - grad(y_k), the reverse of the usual
    BB secant sign; this file follows the paper exactly.
  - Algorithm 3 (QN-SDAJ): solves a diagonal secant system B_k d_k = -grad(x_k),
    updates x_k using the SAME beta-rescaled step rule as Algorithm 1 but with a
    NONMONOTONE linesearch for alpha_k, then updates B_{k+1} = Diag(b) elementwise
    by the secant ratio z^i/s^i, clamped to [eps_l, eps_u] or reset to 1.
  - Algorithm 4 (AGD-SDAJ): q inner QN-SDAJ iterations from x_k to get x_k^pre
    (falling back to x_k if theta did not decrease), then ONE Algorithm-1 iteration
    from x_k^pre to get x_{k+1}.
  - Parameters (Section 4.3, page captured as setup-16.png): Armijo c=1e-4, rho=0.5;
    Algorithm-3/4 parameters lambda1=lambda2=0.01, eps_l=1e-5, eps_u=1e8, q=2;
    x_0 = 0; stopping ||grad theta(x_k)||_2 <= 1e-7*n; k_max=200 or 3000s -> failure.

UNVERIFIED / ASSUMED (the paper's eq. (6), the nonmonotone-linesearch formula, and
the role of lambda1, lambda2, sit on a page not captured in this repository):
  - Nonmonotone linesearch is implemented here as the standard Grippo-Lampariello-
    Lucidi (1986) rule: theta(y_k) <= max_{0<=j<=min(k,M-1)} theta(x_{k-j})
    + c*alpha_k*grad(x_k)'*d_k, backtracking alpha by factor rho from an initial
    trial of 1. Memory M defaults to 10 (not given in the captured pages).
  - lambda1, lambda2 do not appear in Algorithms 1/3/4 as pseudocoded on the
    captured pages; they are not used below. If verification fails, this is the
    first place to look -- they may parameterize the missing eq. (6).
  - B_0 = I at the start of every outer AGD-SDAJ call's inner QN-SDAJ run (the
    paper states B_k is reset each outer iteration; the reset value is not shown
    on the captured pages, I is the natural default for a "positive definite B_0").

EVD COUNTING CONVENTION (must match this project's own protocol, Paper 2 Sec. 3.2):
one eigendecomposition of (A + Diag(x)) per DISTINCT point x at which theta and/or
grad theta is evaluated. theta and grad theta are always evaluated together from
the same EVD (grad theta(x) = diag((A+Diag(x))_+) - e), so one point = one EVD
regardless of whether theta alone, grad alone, or both are requested. Every
linesearch trial, accepted or rejected, costs one EVD.
=#

using LinearAlgebra, Printf

# ---------------------------------------------------------------- I/O (MAT-free)
# Reuse the exact Anymatrix CORRINV convention from bench_sbb_dual.jl, but read
# a pre-exported binary (float64, row-major upper-triangle-free full matrix) so
# this file has no MAT/TimerOutputs dependency and can run standalone.
function load_bin_matrix(path::AbstractString, n::Int)
    A = Array{Float64}(undef, n, n)
    open(path, "r") do io
        read!(io, A)
    end
    return Symmetric((A + A') / 2)
end

# ------------------------------------------------------------------ EVD kernel
mutable struct EvdCounter
    n::Int
end

"theta, grad at x. One EVD. Increments counter."
function theta_grad(A::Symmetric{Float64,Matrix{Float64}}, x::Vector{Float64},
                    counter::Ref{Int})
    C = Symmetric(Matrix(A) + Diagonal(x))
    F = eigen(C)
    pos = F.values .> 0.0
    Vp = F.vectors[:, pos]
    wp = F.values[pos]
    Xp = Vp * Diagonal(wp) * Vp'
    Xp = (Xp + Xp') / 2
    th = 0.5 * dot(wp, wp) - sum(x)
    g = diag(Xp) .- 1.0
    counter[] += 1
    return th, g
end

# ------------------------------------------------------------- line searches
# Backtracking diagnostics. Huynh-Hwang report #NLS (nonmonotone backtracking
# steps) in Table 3; matching it is a stronger check than matching EVDs alone.
const BT = Dict{String,Int}("mls" => 0, "nls" => 0)
reset_bt!() = (BT["mls"] = 0; BT["nls"] = 0)
"Monotone Armijo backtracking (Algorithm 1, line 5). Returns alpha, y, thy, gy, evals."
function monotone_linesearch(A, xk, dk, thk, gk, counter::Ref{Int};
                             c=1e-4, rho=0.5, alpha0=1.0, max_bt=60)
    alpha = alpha0
    slope = dot(gk, dk)                # grad theta(xk)' * dk  (<= 0 for descent)
    for _ in 1:max_bt
        y = xk .+ alpha .* dk
        thy, gy = theta_grad(A, y, counter)
        if thy <= thk + c * alpha * slope
            return alpha, y, thy, gy
        end
        BT["mls"] += 1
        alpha *= rho
    end
    y = xk .+ alpha .* dk
    thy, gy = theta_grad(A, y, counter)
    return alpha, y, thy, gy
end

"""
Nonmonotone linesearch. Modes:

`:eq6`  The paper's equation (6), transcribed EXACTLY from the full text
        (article p.5, obtained 2026-09-08). Li-Fukushima [14] form:

          ||grad theta(x + alpha*d)||^2 <= (1 + eps_k)*||grad theta(x)||^2
                                           - lam1*||alpha*grad theta(x)||^2
                                           - lam2*||alpha*d||^2

        with eps_k = 1/(k+1)^2 (article eq. (7), summable), k the Algorithm-3
        inner iteration index, lam1 = lam2 = 0.01, alpha backtracked as rho^m
        from 1. NOTE: norms are SQUARED, lam1 multiplies the GRADIENT term and
        lam2 the DIRECTION term. The merit function is f = 0.5*||grad theta||^2;
        d need not be a descent direction for it, which is exactly why a
        nonmonotone rule is required here.

`:gll`  Grippo-Lampariello-Lucidi on theta (superseded; kept for the record of
        the pre-full-text verification attempt).

`:lf`   Li-Fukushima with UNSQUARED norms and eps_k = 0 (superseded; the
        pre-full-text guess, which bracketed the published counts from the
        strict side).
"""
function nonmonotone_linesearch(A, xk, dk, thk, gk, hist::Vector{Float64},
                                counter::Ref{Int}; c=1e-4, rho=0.5, alpha0=1.0,
                                max_bt=60, mode::Symbol=:eq6, lam1=0.01, lam2=0.01,
                                iter::Int=0)
    alpha = alpha0
    slope = dot(gk, dk)
    ref = maximum(hist)
    gnorm = norm(gk)
    dnorm = norm(dk)
    eps_k = 1.0 / (iter + 1)^2
    for _ in 1:max_bt
        y = xk .+ alpha .* dk
        thy, gy = theta_grad(A, y, counter)
        ok = if mode === :eq6
            norm(gy)^2 <= (1 + eps_k) * gnorm^2 -
                          lam1 * (alpha * gnorm)^2 - lam2 * (alpha * dnorm)^2
        elseif mode === :lf
            norm(gy) <= gnorm - lam1 * (alpha * dnorm)^2 - lam2 * (alpha * gnorm)^2
        else
            thy <= ref + c * alpha * slope
        end
        if ok
            return alpha, y, thy, gy
        end
        BT["nls"] += 1
        alpha *= rho
    end
    y = xk .+ alpha .* dk
    thy, gy = theta_grad(A, y, counter)
    return alpha, y, thy, gy
end

# --------------------------------------------------------------- Algorithm 1
"""
AGD. Returns (x*, iters, evds, converged::Bool). `counter` accumulates EVDs
across calls so nested use from Algorithm 4 shares one running total.
"""
function agd!(A, x0::Vector{Float64}, counter::Ref{Int}; c=1e-4, rho=0.5,
             eps=1e-7 * length(x0), kmax=200)
    x = copy(x0)
    th, g = theta_grad(A, x, counter)
    k = 0
    while k < kmax && norm(g) > eps
        d = -g
        alpha, y, thy, gy = monotone_linesearch(A, x, d, th, g, counter; c=c, rho=rho)
        z = g .- gy                      # paper's sign: grad(x_k) - grad(y_k)
        a = dot(g, g)
        b = dot(z, g)
        beta = b > 0 ? a / b : 1.0
        xnew = x .+ beta .* alpha .* d
        thnew, gnew = theta_grad(A, xnew, counter)
        x, th, g = xnew, thnew, gnew
        k += 1
    end
    return x, k, norm(g) <= eps
end

# --------------------------------------------------------------- Algorithm 3
"""
QN-SDAJ, run for at most `qmax` inner iterations (Algorithm 4 calls this with a
fixed small qmax rather than to convergence) or until ||grad|| <= eps.
Returns (x_pre, evds-this-call-tracked-via-counter, hist-updated).
"""
function qnsdaj!(A, x0::Vector{Float64}, counter::Ref{Int}, hist::Vector{Float64},
                 th0::Float64, g0::Vector{Float64};
                 eps_l=1e-5, eps_u=1e8, c=1e-4, rho=0.5, eps=1e-7 * length(x0),
                 qmax=2, M=10, ls_mode::Symbol=:eq6)
    n = length(x0)
    x = copy(x0)
    # theta/grad at x0 are supplied by the caller, which already evaluated them.
    # Recomputing here costs a redundant EVD at an already-visited point -- the
    # same defect class as Paper 2 Sec. 4 trap 1 (redundant Jacobian factorization).
    th, g = th0, copy(g0)
    b = ones(n)                          # B_0 = I
    k = 0
    while k < qmax && norm(g) > eps
        d = -g ./ b                      # B_k d = -g, B_k diagonal
        alpha, y, thy, gy = nonmonotone_linesearch(A, x, d, th, g, hist, counter;
                                                    c=c, rho=rho, mode=ls_mode,
                                                    iter=k)
        # Acceleration factor for a GENERAL direction (article Sec. 2.3): the
        # paper applies Andrei's factor to "more general descent directions
        # d(x_k^pre)". Algorithm 1's a_k = ||g||^2 is the SPECIALIZATION to
        # d = -grad theta and is NOT valid here, where d = -B^{-1} g. The general
        # form a = -g'd, b = (g_y - g)'d reduces exactly to Algorithm 1 when
        # d = -g, so it is consistent with both statements.
        a_ = -dot(g, d)
        b_ = dot(gy .- g, d)
        beta_pre = b_ > 0 ? a_ / b_ : 1.0
        s = beta_pre .* alpha .* d
        xnew = x .+ s
        if xnew == y
            thnew, gnew = thy, gy        # same point, no extra EVD
        else
            thnew, gnew = theta_grad(A, xnew, counter)
        end
        z = gnew .- g                    # secant pair for the diagonal update
        for i in 1:n
            if s[i] != 0.0
                ratio = z[i] / s[i]
                b[i] = (eps_l <= ratio <= eps_u) ? ratio : 1.0
            else
                b[i] = 1.0
            end
        end
        x, th, g = xnew, thnew, gnew
        push!(hist, th); length(hist) > M && popfirst!(hist)
        k += 1
    end
    return x, th, g
end

# --------------------------------------------------------------- Algorithm 4
"""
AGD-SDAJ. Returns (x*, outer_iters, total_evds, converged::Bool).
"""
function agd_sdaj(A::Symmetric{Float64,Matrix{Float64}}, x0::Vector{Float64};
                  c=1e-4, rho=0.5, eps_l=1e-5, eps_u=1e8, q=2, M=10,
                  eps=1e-7 * length(x0), kmax=200, ls_mode::Symbol=:eq6)
    counter = Ref(0)
    x = copy(x0)
    th, g = theta_grad(A, x, counter)
    k = 0
    while k < kmax && norm(g) > eps
        hist = [th]
        xpre, thpre, gpre = qnsdaj!(A, x, counter, hist, th, g; eps_l=eps_l,
                                    eps_u=eps_u, c=c, rho=rho, eps=eps, qmax=q, M=M,
                                    ls_mode=ls_mode)
        if thpre > th
            xpre, thpre, gpre = x, th, g   # fallback: reject the preconditioned step
        end
        # Early termination on the preconditioned point. Huynh-Hwang state this
        # explicitly in the Table 3 note: "the loop is also terminated whenever the
        # preconditioned point x_k^pre satisfies the stopping criteria (P7, P8, and
        # P9). In such cases, the number of EVDs is reduced by fewer than two units."
        # Without this the outer Algorithm-1 step is always paid, inflating EVDs.
        if norm(gpre) <= eps
            x, th, g = xpre, thpre, gpre
            k += 1
            break
        end
        # one Algorithm-1 iteration from xpre
        d = -gpre
        alpha, y, thy, gy = monotone_linesearch(A, xpre, d, thpre, gpre, counter;
                                                c=c, rho=rho)
        z = gpre .- gy
        a_ = dot(gpre, gpre)
        b_ = dot(z, gpre)
        beta = b_ > 0 ? a_ / b_ : 1.0
        xnew = xpre .+ beta .* alpha .* d
        thnew, gnew = theta_grad(A, xnew, counter)
        x, th, g = xnew, thnew, gnew
        k += 1
    end
    return x, k, counter[], norm(g) <= eps
end

# ------------------------------------------------------------------------ CLI
function main()
    if length(ARGS) < 2
        println("usage: julia agd_sdaj.jl <bin-matrix-path> <n> [q] [M]")
        return
    end
    path = ARGS[1]
    n = parse(Int, ARGS[2])
    q = length(ARGS) >= 3 ? parse(Int, ARGS[3]) : 2
    M = length(ARGS) >= 4 ? parse(Int, ARGS[4]) : 10
    ls_mode = length(ARGS) >= 5 ? Symbol(ARGS[5]) : :eq6

    A = load_bin_matrix(path, n)
    reset_bt!()
    x0 = zeros(n)
    t0 = time()
    x, iters, evds, converged = agd_sdaj(A, x0; q=q, M=M, eps=1e-7 * n, kmax=200, ls_mode=ls_mode)
    elapsed = time() - t0

    _, g = theta_grad(A, x, Ref(0))
    Xp = begin
        C = Symmetric(Matrix(A) + Diagonal(x))
        F = eigen(C)
        pos = F.values .> 0.0
        Vp = F.vectors[:, pos]; wp = F.values[pos]
        Xp = Vp * Diagonal(wp) * Vp'
        (Xp + Xp') / 2
    end
    resid_norm = norm(Matrix(A) - Xp)

    @printf("n=%d q=%d M=%d ls=%s  iters=%d  EVDs=%d  #NLS=%d  #MLS=%d  time=%.2fs  converged=%s  ||grad||=%.3e  ||A-X*||_F=%.4f\n",
            n, q, M, String(ls_mode), iters, evds, BT["nls"], BT["mls"], elapsed, converged,
            norm(g), resid_norm)
end

main()
