#=
Julia solve-level timing harness for SBB-Dual and comparators.

Implements the protocol in outputs/julia-timing-methodology.md verbatim:
  1. construct/load the instance OUTSIDE the timed region
  2. one DISCARDED warmup solve (removes JIT from the measurement)
  3. GC.gc()
  4. one measured solve, @elapsed around the complete solver call
  5. TimerOutputs for the internal breakdown (EVD vs BB vs certificate)
  6. report BOTH `updates` and `total_evds` (= updates + 1)
BLAS is pinned to one thread. BenchmarkTools is deliberately NOT used for the
headline table.

SOLVER UNDER TEST -- SBB-Dual, as specified:
  * dual clamped Barzilai-Borwein, BB1
  * exactly one dense symmetric EVD per iteration
  * clamp t in [eps, 2-eps]
  * Borsdorf-Higham diagonal-rescaling epilogue applied on exit
  * exit on ||grad theta||_2 <= 1e-7 * n   (DIMENSION-SCALED, not absolute)

COMPARATORS, run locally on the same instances -- no imported timings:
  * semismooth Newton (SIN-class): CG on the generalized Newton system with the
    Qi-Sun Eq. (40) selection (Omega_bb = 0) plus Armijo backtracking
  * Dykstra / alternating projections (APM), two-set

REFERENCE X*: semismooth Newton driven to ||grad theta||_2 <= 1e-13 (absolute),
with a BB warm start when the Newton globalization stalls. Reported separately
so ||X - X*||_F is auditable.

The ceiling-clamp fraction is reported as `ceiling_clamp_pct` and labelled a
LOW-CURVATURE INDICATOR. It is not a rank-deficiency diagnostic; see the H4
discussion in paper/main.tex.

Usage:
  julia --project=. bench_sbb_dual.jl --suite <dir> [--matrices <dir>] [--out <csv>]

  --suite     directory holding manifest.tsv + G_<idx>.bin, as written by
              experiments/export_suite.py (numpy PCG64 generators are not
              reproducible in Julia, so the suite is exported once and loaded)
  --matrices  directory of Anymatrix CORRINV *.mat files (cor1399.mat, ...)
=#

using LinearAlgebra, Printf, Dates, Statistics

# The controlled globalization grid uses only exported binary matrices and does
# not report wall-clock component timings. Its sandbox-safe standalone mode
# therefore avoids loading MAT and TimerOutputs while preserving every numerical
# operation in the solver. Normal benchmark runs retain the original packages.
const NCM_STANDALONE = get(ENV, "NCM_STANDALONE", "0") == "1"
if NCM_STANDALONE
    struct TimerOutput end
    macro timeit(timer, label, expression)
        return esc(expression)
    end
    matread(path) = error("MAT loading is unavailable in NCM_STANDALONE mode: $path")
else
    using TimerOutputs
    using MAT
end

BLAS.set_num_threads(1)

const EPS_CLAMP = 0.01
const REF_TOL = 1e-13

# ---------------------------------------------------------------- instances

"Reproduce Higham's treshape(x,1) then A = A + triu(A,1)', as audited in
run_p7_p8_sbb.py::load_higham_matrix."
function load_higham_matrix(path::AbstractString)
    vars = matread(path)
    # Two storage conventions in the CORRINV group: a packed unit-triangular
    # vector `x` (cor1399, cor3120) or the full matrix `A` (bccd16,
    # Rocky_Mountain_Region_CORR).
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

"Read the manifest + binary dump produced by experiments/export_suite.py."
function load_suite(dir::AbstractString)
    manifest = joinpath(dir, "manifest.tsv")
    isfile(manifest) || error("missing $manifest -- run export_suite.py first")
    out = Tuple{String,Matrix{Float64}}[]
    for line in eachline(manifest)
        isempty(strip(line)) && continue
        f = split(line, '\t')
        idx = parse(Int, f[1]); name = String(f[2]); n = parse(Int, f[3])
        G = Array{Float64}(undef, n, n)
        open(joinpath(dir, "G_$(idx).bin"), "r") do io
            read!(io, G)
        end
        push!(out, (name, (G + G') / 2))
    end
    return out
end

# Exact solutions X*, when the instance family provides them (see
# gen_degeneracy_family.py). Where present these replace the computed
# machine-precision reference entirely: the KKT construction makes X* exact, so
# forward error is measured against truth rather than against another solve.
function load_xstars(dir::AbstractString)
    out = Dict{String,Matrix{Float64}}()
    manifest = joinpath(dir, "manifest.tsv")
    isfile(manifest) || return out
    for line in eachline(manifest)
        isempty(strip(line)) && continue
        f = split(line, '\t')
        idx = parse(Int, f[1]); name = String(f[2]); n = parse(Int, f[3])
        path = joinpath(dir, "Xstar_$(idx).bin")
        isfile(path) || continue
        X = Array{Float64}(undef, n, n)
        open(path, "r") do io
            read!(io, X)
        end
        out[name] = (X + X') / 2
    end
    return out
end

"Read exact dual solutions written by materialize_exact_ystars.py."
function load_ystars(dir::AbstractString)
    out = Dict{String,Vector{Float64}}()
    manifest = joinpath(dir, "manifest.tsv")
    isfile(manifest) || return out
    for line in eachline(manifest)
        isempty(strip(line)) && continue
        f = split(line, '\t')
        idx = parse(Int, f[1]); name = String(f[2]); n = parse(Int, f[3])
        path = joinpath(dir, "ystar_$(idx).bin")
        isfile(path) || continue
        y = Vector{Float64}(undef, n)
        open(path, "r") do io
            read!(io, y)
        end
        out[name] = y
    end
    return out
end

# ------------------------------------------------------------------ kernels

"theta, grad, X at dual point y. One dense symmetric EVD."
# Returns the spectral factorization as well, so a caller already holding the
# EVD at y (e.g. Newton building its Jacobian) need not recompute it.
function theta_grad_full(G::Matrix{Float64}, y::Vector{Float64}, to::TimerOutput;
                         traj=nothing)
    C = Symmetric(G + Diagonal(y))
    local λ, V
    @timeit to "spectral_projection/eigen" begin
        F = eigen(C)
        λ = F.values
        V = F.vectors
    end
    @timeit to "spectral_projection/reconstruct" begin
        pos = λ .> 0.0
        Vp = V[:, pos]
        wp = λ[pos]
        X = Vp * Diagonal(wp) * Vp'
        X = (X + X') / 2
        θ = 0.5 * dot(wp, wp) - sum(y)
    end
    local g
    @timeit to "certificate/residual" begin
        g = diag(X) .- 1.0
    end
    snap!(traj, X, g)
    return θ, g, X, λ, V
end

function theta_grad(G::Matrix{Float64}, y::Vector{Float64}, to::TimerOutput;
                    traj=nothing)
    θ, g, X, _, _ = theta_grad_full(G, y, to; traj=traj)
    return θ, g, X
end

"Borsdorf-Higham diagonal-rescaling epilogue: Xhat = D^-1/2 X D^-1/2."
function bh_rescale(X::Matrix{Float64})
    d = diag(X)
    any(d .<= 0) && return copy(X), false
    s = 1.0 ./ sqrt.(d)
    Xh = (s * s') .* X
    Xh = (Xh + Xh') / 2
    for i in axes(Xh, 1)
        Xh[i, i] = 1.0
    end
    return Xh, true
end

# --------------------------------------------------- work/accuracy trajectory
#
# Records (cumulative EVDs, error) after EVERY eigendecomposition. Cost in this
# problem has a natural atom -- one EVD -- so that is the clock. Recording is
# O(n^2) on top of an O(n^3) step, and trajectory runs are a SEPARATE untimed
# pass, so the headline timings in julia_timing_results.csv are uncontaminated.
#
# Both the raw and the BH-rescaled iterate are recorded: the epilogue is O(n^2)
# and consumes no EVD, so it is free in the cost metric but changes the accuracy
# metric, and on nearly-feasible inputs it can make the error worse.

mutable struct Traj
    Xref::Matrix{Float64}
    evds::Int
    rows::Vector{NamedTuple}
end
Traj(Xref) = Traj(Xref, 0, NamedTuple[])

# One EVD that produced a new iterate.
function snap!(t, X, g; accepted::Bool=true, event::String="iterate",
               outer::Int=0, trial::Int=0)
    t === nothing && return nothing
    t.evds += 1
    Xh, ok = bh_rescale(X)
    push!(t.rows, (evds=t.evds,
                   err_raw_fro=norm(X .- t.Xref),
                   err_bh_fro=ok ? norm(Xh .- t.Xref) : NaN,
                   grad_2=norm(g), grad_inf=maximum(abs.(g)),
                   accepted=accepted, event=event,
                   outer_iteration=outer, trial=trial))
    return nothing
end

# One EVD that cost work but produced no new iterate (Newton's Jacobian
# factorization at the current y): cost rises, accuracy is flat.
snap_flat!(t, X, g; kwargs...) = snap!(t, X, g; kwargs...)

"Record a newly selected iterate that reuses an earlier EVD at current cost."
function snap_zero_cost!(t, X, g; accepted::Bool=true,
                         event::String="selection", outer::Int=0,
                         trial::Int=0)
    t === nothing && return nothing
    Xh, ok = bh_rescale(X)
    push!(t.rows, (evds=t.evds,
                   err_raw_fro=norm(X .- t.Xref),
                   err_bh_fro=ok ? norm(Xh .- t.Xref) : NaN,
                   grad_2=norm(g), grad_inf=maximum(abs.(g)),
                   accepted=accepted, event=event,
                   outer_iteration=outer, trial=trial))
    return nothing
end

# ------------------------------------------------------------- SBB-Dual

function sbb_dual(G::Matrix{Float64}; eps::Float64=EPS_CLAMP,
                  tol::Union{Nothing,Float64}=nothing, maxit::Int=5000,
                  rescale::Bool=true, to::TimerOutput=TimerOutput(),
                  traj=nothing)
    n = size(G, 1)
    τ = tol === nothing ? 1e-7 * n : tol      # dimension-scaled exit rule
    t_lo, t_hi = eps, 2.0 - eps
    y = zeros(n)
    θ, g, X = theta_grad(G, y, to; traj=traj)
    gn = norm(g)
    yprev = gprev = nothing
    updates = 0; evds = 1
    clamp_hi = 0; clamp_lo = 0; fallback = 0
    exitreason = "max_iter"

    for k in 1:maxit
        if gn <= τ
            # k == 1 means the INPUT already met the tolerance: no update was
            # ever taken. Under the dimension-scaled rule this happens on
            # nearly-feasible inputs and must not be read as a fast solve.
            exitreason = k == 1 ? "already_feasible_at_y0" : "diag_feasible"
            break
        end
        local t
        @timeit to "bb_step" begin
            if yprev === nothing
                t = 1.0; fallback += 1
            else
                s = y .- yprev
                w = g .- gprev
                num = dot(s, s); den = dot(s, w)
                if den > 0 && isfinite(den) && isfinite(num)
                    traw = num / den
                    traw > t_hi && (clamp_hi += 1)
                    traw < t_lo && (clamp_lo += 1)
                    t = min(max(traw, t_lo), t_hi)
                else
                    t = 1.0; fallback += 1
                end
            end
            yprev = copy(y); gprev = copy(g)
            y = y .- t .* g
        end
        θ, g, X = theta_grad(G, y, to; traj=traj)
        gn = norm(g); updates += 1; evds += 1
    end

    diag_pre = maximum(abs.(diag(X) .- 1.0))
    rescaled = false
    if rescale
        @timeit to "bh_rescale_epilogue" begin
            X, rescaled = bh_rescale(X)
        end
    end
    computed = max(updates - fallback, 1)
    return (X=X, y=y, updates=updates, evds=evds, exit=exitreason,
            cert=g, cert2=norm(g), certinf=maximum(abs.(g)),
            clamp_pct=100.0 * clamp_hi / computed, clamp_lo=clamp_lo,
            fallback=fallback, diag_pre=diag_pre, rescaled=rescaled, tol=τ)
end

# ------------------------------------- semismooth Newton (SIN-class)

"""V h for the Qi-Sun Eq. (40) block form with selectable Omega_bb.

Naively this is diag(P (W .* (P' Diag(h) P)) P'), which materialises an n x n
weight matrix and does two full n x n matmuls per call -- O(n^3) with a large
constant, and prohibitive inside CG. Because Omega has a zero (non-alpha,
non-alpha) block, only the alpha columns contribute:

    V h = diag(Pa Maa Pa') + 2 diag(Pa Mao Po')
    Maa = Pa' Diag(h) Pa,   Mao = T .* (Pa' Diag(h) Po),   T = la ./ (la - lo')

which costs O(n r (r+s)) with r = |alpha| and never forms an n x n temporary.
Verified against the naive form by --selftest.
"""
function V_apply(P::Matrix{Float64}, λ::Vector{Float64}, thr::Float64,
                 h::Vector{Float64}; omega_beta::Float64=0.0)
    n = length(λ)
    a = λ .> thr
    b = abs.(λ) .<= thr
    o = .!a
    out = zeros(n)
    if any(a)
        Pa = P[:, a]
        la = λ[a]
        hPa = h .* Pa
        Maa = Pa' * hPa
        out .+= vec(sum((Pa * Maa) .* Pa, dims=2))
        if any(o)
            Po = P[:, o]
            lo = λ[o]
            Mao = Pa' * (h .* Po)
            Mao .*= la ./ (la .- lo')
            out .+= 2 .* vec(sum((Pa * Mao) .* Po, dims=2))
        end
    end
    if omega_beta != 0.0 && any(b)
        Pb = P[:, b]
        Mbb = Pb' * (h .* Pb)
        out .+= omega_beta .* vec(sum((Pb * Mbb) .* Pb, dims=2))
    end
    return out
end

"Naive reference implementation, used only by --selftest."
function V_apply_naive(P::Matrix{Float64}, λ::Vector{Float64}, thr::Float64,
                       h::Vector{Float64}; omega_beta::Float64=0.0)
    n = length(λ)
    a = λ .> thr
    b = abs.(λ) .<= thr
    W = zeros(n, n)
    la = λ[a]; o = .!a; lo = λ[o]
    W[a, a] .= 1.0
    if any(a) && any(o)
        T = la ./ (la .- lo')
        W[a, o] = T
        W[o, a] = T'
    end
    W[b, b] .= omega_beta
    inner = P' * (h .* P)
    return diag(P * (W .* inner) * P')
end

# `cached=true` reuses the factorization already computed at the current y.
# `cached=false` reproduces the original behaviour, which recomputed an
# identical EVD to build the Jacobian -- one redundant EVD per outer iteration.
# Both are kept so the comparison cannot be dismissed as an implementation
# artifact.
function newton_ncm(G::Matrix{Float64}; tol::Float64, maxit::Int=100,
                    max_evds::Int=typemax(Int),
                    y0::Union{Nothing,Vector{Float64}}=nothing,
                    to::TimerOutput=TimerOutput(), traj=nothing,
                    cached::Bool=false, omega_beta::Float64=0.0, log=nothing)
    n = size(G, 1)
    y = y0 === nothing ? zeros(n) : copy(y0)
    θ, g, X, λc, Pc = theta_grad_full(G, y, to; traj=traj)
    evds = 1; its = 0; backtracks = 0
    cg_iters_total = 0; negative_curvature_count = 0
    exitreason = "max_iter"
    for it in 1:maxit
        if evds >= max_evds
            exitreason = "evd_budget"; break
        end
        gn = norm(g)
        if gn <= tol
            exitreason = "converged"; break
        end
        local λ, P
        if cached
            λ = λc; P = Pc                      # no extra EVD
        else
            local F
            @timeit to "spectral_projection/eigen" begin
                F = eigen(Symmetric(G + Diagonal(y)))
            end
            evds += 1
            snap_flat!(traj, X, g; accepted=false, event="jacobian",
                       outer=it, trial=0)        # cost only; no new iterate
            λ = F.values; P = F.vectors
        end
        thr = 100 * eps(Float64) * max(1.0, maximum(abs.(λ)))
        mv(h) = V_apply(P, λ, thr, h; omega_beta=omega_beta) .+ 1e-12 .* h
        # inexact Newton forcing term: superlinear without over-solving CG
        η = min(0.1, max(gn, 1e-12))
        local d
        cg_iters = 0; neg_curv = false
        @timeit to "newton_cg" begin
            d = zeros(n); r = -copy(g); p = copy(r); rs = dot(r, r)
            for _ in 1:min(200, 2n)
                cg_iters += 1
                Ap = mv(p); pAp = dot(p, Ap)
                if pAp <= 0
                    neg_curv = true; break
                end
                α = rs / pAp
                d .+= α .* p; r .-= α .* Ap
                rsn = dot(r, r)
                sqrt(rsn) <= η * gn && break
                p = r .+ (rsn / rs) .* p; rs = rsn
            end
        end
        cg_iters_total += cg_iters
        neg_curv && (negative_curvature_count += 1)
        (!all(isfinite, d) || dot(g, d) >= 0) && (d = -g)
        step = 1.0; ok = false; trial = 0
        budget_exhausted = false
        θt = θ; gt = g; Xt = X; λt = λc; Pt = Pc
        for _ in 1:50
            if evds >= max_evds
                budget_exhausted = true
                exitreason = "evd_budget"
                break
            end
            trial += 1
            # Record this EVD only after Armijo decides whether the trial is an
            # accepted Newton iterate. Rejected trials count as spectral work
            # but never receive matched-accuracy credit.
            θt, gt, Xt, λt, Pt = theta_grad_full(G, y .+ step .* d, to; traj=nothing)
            evds += 1
            if θt <= θ + 1e-4 * step * dot(g, d)
                snap!(traj, Xt, gt; accepted=true, event="armijo_trial",
                      outer=it, trial=trial)
                ok = true; break
            end
            snap!(traj, Xt, gt; accepted=false, event="armijo_trial",
                  outer=it, trial=trial)
            backtracks += 1
            step /= 2
        end
        budget_exhausted && break
        if !ok
            exitreason = "linesearch_failed"      # 50 consecutive backtracks
            break
        end
        y = y .+ step .* d
        θ, g, X = θt, gt, Xt
        λc, Pc = λt, Pt                            # refresh the cached EVD
        its = it
        if log !== nothing
            push!(log, (outer=it, trials=trial, step=step, theta=θ,
                        grad2=norm(g), cg_iters=cg_iters, neg_curv=neg_curv,
                        backtracks=backtracks, evds=evds))
        end
    end
    return (X=X, y=y, updates=its, evds=evds, exit=exitreason,
            cert=g, cert2=norm(g), certinf=maximum(abs.(g)),
            backtracks=backtracks, cg_iters_total=cg_iters_total,
            negative_curvature_count=negative_curvature_count)
end

"""Cached semismooth Newton with switchable finite-precision globalization.

`globalization` is one of:
  * `:armijo_naive`: Qi--Sun Armijo condition (2.12), retained as control.
  * `:armijo_bh`: Borsdorf--Higham Section 3.3 / Algorithm 4.1 Step 6,
    using their near-equality test and gradient-ratio conditions (3.1), (4.4).
  * `:gradient_test`: accept any trial that strictly reduces the gradient norm;
    otherwise apply the same Armijo test as the control.

The existing `newton_ncm` is deliberately retained unchanged for provenance.
"""
function newton_ncm_globalized(
        G::Matrix{Float64}; tol::Float64, maxit::Int=100,
        max_evds::Int=typemax(Int),
        y0::Union{Nothing,Vector{Float64}}=nothing,
        to::TimerOutput=TimerOutput(), traj=nothing,
        omega_beta::Float64=0.0,
        globalization::Symbol=:armijo_naive,
        bh_mu::Float64=0.9, bh_gamma::Float64=100.0,
        ystar::Union{Nothing,Vector{Float64}}=nothing,
        log=nothing, trial_log=nothing)
    globalization in (:armijo_naive, :armijo_bh, :gradient_test) ||
        error("unknown Newton globalization: $globalization")
    0.0 < bh_mu < 1.0 || error("bh_mu must lie in (0,1)")
    bh_gamma > 0.0 || error("bh_gamma must be positive")

    n = size(G, 1)
    y = y0 === nothing ? zeros(n) : copy(y0)
    theta_val, g, X, lambda_cache, P_cache =
        theta_grad_full(G, y, to; traj=traj)
    evds = 1
    its = 0
    backtracks = 0
    cg_iters_total = 0
    negative_curvature_count = 0
    exitreason = "max_iter"
    armijo_c1 = 1e-4
    unit_roundoff = eps(Float64) / 2.0  # Borsdorf--Higham use u=2^-53.

    for it in 1:maxit
        if evds >= max_evds
            exitreason = "evd_budget"
            break
        end
        gn = norm(g)
        if gn <= tol
            exitreason = "converged"
            break
        end

        lambda_now = lambda_cache
        P = P_cache
        thr = 100 * eps(Float64) * max(1.0, maximum(abs.(lambda_now)))
        mv(h) = V_apply(P, lambda_now, thr, h;
                        omega_beta=omega_beta) .+ 1e-12 .* h
        forcing = min(0.1, max(gn, 1e-12))

        local d
        cg_iters = 0
        neg_curv = false
        @timeit to "newton_cg" begin
            d = zeros(n)
            r = -copy(g)
            p = copy(r)
            rs = dot(r, r)
            for _ in 1:min(200, 2n)
                cg_iters += 1
                Ap = mv(p)
                pAp = dot(p, Ap)
                if pAp <= 0
                    neg_curv = true
                    break
                end
                alpha_cg = rs / pAp
                d .+= alpha_cg .* p
                r .-= alpha_cg .* Ap
                rsn = dot(r, r)
                sqrt(rsn) <= forcing * gn && break
                p = r .+ (rsn / rs) .* p
                rs = rsn
            end
        end
        cg_iters_total += cg_iters
        neg_curv && (negative_curvature_count += 1)

        raw_gtd = dot(g, d)
        fallback_used = !all(isfinite, d) || raw_gtd >= 0
        fallback_used && (d = -g)
        used_gtd = dot(g, d)
        yk = copy(y)
        newton_d = copy(d)
        yerr = ystar === nothing ? NaN : norm(ystar .- yk)
        d_to_yerr = ystar === nothing ? NaN :
            (yerr == 0.0 ? (norm(d) == 0.0 ? 0.0 : Inf) : norm(d) / yerr)

        # Borsdorf--Higham: Armijo (2.12), then the finite-precision branch
        # from Section 3.3 / Algorithm 4.1 Step 6. Their numerical tests use
        # mu=0.9, rho=0.5, sigma=1e-4; comment (d) sets gamma=100.
        step = 1.0
        ok = false
        budget_exhausted = false
        decision = "none"
        selected = 0
        evals = NamedTuple[]

        for _ in 1:50
            if evds >= max_evds
                budget_exhausted = true
                exitreason = "evd_budget"
                break
            end
            trial_number = length(evals) + 1
            theta_trial, g_trial, X_trial, lambda_trial, P_trial =
                theta_grad_full(G, yk .+ step .* newton_d, to; traj=nothing)
            evds += 1
            armijo_pass = theta_trial <=
                theta_val + armijo_c1 * step * used_gtd
            gradient_improves = norm(g_trial) < gn
            near_equal = abs(theta_trial - theta_val) <
                bh_gamma * unit_roundoff *
                (1.0 + abs(theta_trial) + abs(theta_val))
            push!(evals, (
                trial=trial_number, step=step, direction="newton",
                theta_trial=theta_trial, g_trial=g_trial, X_trial=X_trial,
                lambda_trial=lambda_trial, P_trial=P_trial,
                armijo_pass=armijo_pass,
                gradient_improves=gradient_improves,
                near_equal=near_equal, d_used=copy(newton_d),
                gtd_used=used_gtd))

            if globalization == :gradient_test && gradient_improves
                selected = length(evals)
                decision = "gradient_test"
                ok = true
                break
            elseif armijo_pass
                selected = length(evals)
                decision = "armijo_2.12"
                ok = true
                break
            elseif globalization == :armijo_bh && near_equal
                full_index = findfirst(e ->
                    e.direction == "newton" && e.step == 1.0, evals)
                full = evals[full_index]
                if norm(full.g_trial) / gn <= 1.0 - bh_mu
                    selected = full_index
                    decision = "bh_gradient_ratio_3.1_4.4"
                    ok = true
                    break
                end

                # Algorithm 4.1 Step 6: unit steepest-descent fallback.
                if fallback_used
                    selected = full_index
                else
                    if evds >= max_evds
                        budget_exhausted = true
                        exitreason = "evd_budget"
                        break
                    end
                    steepest_d = -g
                    steepest_gtd = -dot(g, g)
                    trial_number = length(evals) + 1
                    theta_sd, g_sd, X_sd, lambda_sd, P_sd =
                        theta_grad_full(G, yk .+ steepest_d, to; traj=nothing)
                    evds += 1
                    push!(evals, (
                        trial=trial_number, step=1.0,
                        direction="steepest", theta_trial=theta_sd,
                        g_trial=g_sd, X_trial=X_sd,
                        lambda_trial=lambda_sd, P_trial=P_sd,
                        armijo_pass=theta_sd <=
                            theta_val + armijo_c1 * steepest_gtd,
                        gradient_improves=norm(g_sd) < gn,
                        near_equal=abs(theta_sd - theta_val) <
                            bh_gamma * unit_roundoff *
                            (1.0 + abs(theta_sd) + abs(theta_val)),
                        d_used=copy(steepest_d), gtd_used=steepest_gtd))
                    selected = length(evals)
                end
                decision = "bh_unit_steepest_descent"
                ok = true
                break
            end
            step /= 2.0
        end

        # Delay trajectory writes until the accepted trial is known. If BH
        # selects a cached full step after later EVDs, a zero-cost selection row
        # records its accuracy at the correct cumulative work count.
        for (j, e) in enumerate(evals)
            accepted_at_evd = ok && j == selected && selected == length(evals)
            snap!(traj, e.X_trial, e.g_trial; accepted=accepted_at_evd,
                  event="$(globalization)_trial", outer=it, trial=e.trial)
            if !(ok && j == selected)
                backtracks += 1
            end
            if trial_log !== nothing
                push!(trial_log, (
                    outer=it, trial=e.trial,
                    globalization=String(globalization),
                    accepted=ok && j == selected,
                    decision=(ok && j == selected) ? decision : "rejected",
                    direction=e.direction, step=e.step,
                    theta_current=theta_val, theta_trial=e.theta_trial,
                    theta_delta=e.theta_trial - theta_val,
                    armijo_pass=e.armijo_pass,
                    gradient_improves=e.gradient_improves,
                    near_equal=e.near_equal, grad_current=gn,
                    grad_trial=norm(e.g_trial), raw_gtd=raw_gtd,
                    used_gtd=e.gtd_used, fallback_used=fallback_used,
                    cg_iters=cg_iters, neg_curv=neg_curv,
                    d_norm=norm(e.d_used), y_error_norm=yerr,
                    d_to_yerror=(ystar === nothing ? NaN :
                        (yerr == 0.0 ?
                         (norm(e.d_used) == 0.0 ? 0.0 : Inf) :
                         norm(e.d_used) / yerr)),
                    selection_evd=evds, yk=copy(yk), d=copy(e.d_used)))
            end
        end
        if ok && selected != length(evals)
            chosen = evals[selected]
            snap_zero_cost!(traj, chosen.X_trial, chosen.g_trial;
                            accepted=true, event="$(globalization)_selection",
                            outer=it, trial=chosen.trial)
        end

        if log !== nothing
            if ok
                chosen = evals[selected]
                chosen_ratio = ystar === nothing ? NaN :
                    (yerr == 0.0 ?
                     (norm(chosen.d_used) == 0.0 ? 0.0 : Inf) :
                     norm(chosen.d_used) / yerr)
                push!(log, (
                    outer=it, trials=length(evals), step=chosen.step,
                    theta=chosen.theta_trial, theta_current=theta_val,
                    grad2=norm(chosen.g_trial), grad2_current=gn,
                    raw_gtd=raw_gtd, used_gtd=chosen.gtd_used,
                    fallback_used=fallback_used,
                    d_norm=norm(chosen.d_used), y_error_norm=yerr,
                    d_to_yerror=chosen_ratio,
                    globalization=String(globalization), decision=decision,
                    accepted=true, cg_iters=cg_iters, neg_curv=neg_curv,
                    backtracks=backtracks, evds=evds,
                    yk=copy(yk), d=copy(chosen.d_used)))
            else
                push!(log, (
                    outer=it, trials=length(evals), step=NaN,
                    theta=theta_val, theta_current=theta_val,
                    grad2=gn, grad2_current=gn, raw_gtd=raw_gtd,
                    used_gtd=used_gtd, fallback_used=fallback_used,
                    d_norm=norm(newton_d), y_error_norm=yerr,
                    d_to_yerror=d_to_yerr,
                    globalization=String(globalization),
                    decision=budget_exhausted ? "evd_budget" :
                        "linesearch_failed", accepted=false,
                    cg_iters=cg_iters, neg_curv=neg_curv,
                    backtracks=backtracks, evds=evds,
                    yk=copy(yk), d=copy(newton_d)))
            end
        end

        budget_exhausted && break
        if !ok
            exitreason = "linesearch_failed"
            break
        end

        chosen = evals[selected]
        y = yk .+ chosen.step .* chosen.d_used
        theta_val = chosen.theta_trial
        g = chosen.g_trial
        X = chosen.X_trial
        lambda_cache = chosen.lambda_trial
        P_cache = chosen.P_trial
        its = it
    end

    return (X=X, y=y, updates=its, evds=evds, exit=exitreason,
            cert=g, cert2=norm(g), certinf=maximum(abs.(g)),
            backtracks=backtracks, cg_iters_total=cg_iters_total,
            negative_curvature_count=negative_curvature_count,
            globalization=String(globalization))
end

"""Reference solution X*, to machine precision.

Cheap phase first: clamped BB to 1e-11 costs one EVD per step, whereas each
Newton step costs a CG solve whose inner product is far more expensive on the
near-degenerate instances. Newton then supplies the quadratic endgame from the
warm start. The reference is NOT part of any timed measurement, so BLAS threads
are unpinned here and restored to 1 before the solvers run.
"""
# --------------------------------------------- AGD-SDAJ (Huynh--Hwang 2025)
#
# Algorithms 1/3/4 of Huynh & Hwang (2025), Numer. Linear Algebra Appl. 32(6),
# DOI 10.1002/nla.70045, transcribed from the full text.
#
# VERIFIED against the authors' own published counts on their own instances
# BEFORE use here (outputs/agd-sdaj-verification-status.md):
#   P9 bccd16  1 outer / 5 EVDs / 0 NLS   -- exact
#   P8 cor3120 3 outer / 18 EVDs / 1 NLS  -- exact
#   P7 cor1399 4 outer, ||A-X*||_F exact; 32 EVDs / 7 NLS vs published 31 / 8,
#              one differing backtracking decision (MATLAB/Julia eigensolver).
#
# Two transcription traps, both of which change the work counts while still
# converging to the correct solution -- i.e. invisible unless counts are checked
# against the source:
#   1. eq. (6) is a Li--Fukushima RESIDUAL rule on ||grad theta||^2 carrying a
#      (1 + eps_k) slack with eps_k = 1/(k+1)^2, NOT an Armijo condition on
#      theta. The merit function is 0.5||grad theta||^2 and d need not be a
#      descent direction for it.
#   2. the acceleration factor beta^pre inside Algorithm 3 must use the
#      GENERAL-direction form of Sec. 2.3 (a = -g'd, b = (g_y - g)'d).
#      Algorithm 1's a_k = ||g||^2 is the specialization to d = -grad theta and
#      is invalid where d = -B^{-1} g; using it costs 50% more outer iterations
#      (P7: 6 instead of 4).
#
# Trajectory accounting matches every other solver here: one EVD per distinct
# point evaluated, rejected linesearch trials recorded with accepted=false so
# they cost work but receive no accuracy credit.

function agd_sdaj_ncm(G::Matrix{Float64}; tol::Union{Nothing,Float64}=nothing,
                      maxit::Int=200, q::Int=2, lam1::Float64=0.01,
                      lam2::Float64=0.01, eps_l::Float64=1e-5,
                      eps_u::Float64=1e8, c::Float64=1e-4, rho::Float64=0.5,
                      max_bt::Int=60, max_evds::Int=typemax(Int),
                      globalization::Symbol=:armijo_naive,
                      bh_mu::Float64=0.9, bh_gamma::Float64=100.0,
                      to::TimerOutput=TimerOutput(), traj=nothing)
    globalization in (:armijo_naive, :armijo_bh) ||
        error("unknown AGD-SDAJ globalization: $globalization")
    n = size(G, 1)
    tau = tol === nothing ? 1e-7 * n : tol
    unit_roundoff = eps(Float64) / 2.0
    evds = Ref(0); nls_bt = Ref(0); mls_bt = Ref(0)

    function evaluate(yv)
        th, gv, Xv = theta_grad(G, yv, to; traj=nothing)
        evds[] += 1
        return th, gv, Xv
    end

    # Algorithm 1 line 5: monotone Armijo on theta.
    function mls(yk, dk, thk, gk, outer)
        alpha = 1.0
        slope = dot(gk, dk)
        local yt, tht, gt, Xt
        for j in 1:max_bt
            yt = yk .+ alpha .* dk
            tht, gt, Xt = evaluate(yt)
            ok = tht <= thk + c * alpha * slope
            # Algorithm 1 line 5 is the naive objective-value Armijo test, so it
            # inherits the finite-precision defect of Sec. 4 trap 2: once the
            # predicted decrease c*alpha*||grad theta||^2 falls below one ULP of
            # theta, no step can ever pass and the method stalls. Huynh--Hwang
            # never meet this because their dimension-scaled rule 1e-7*n stops
            # far above the floor; at a tight common tolerance it stalls on
            # 18/270 KKT instances. The correction applies Borsdorf--Higham's
            # near-equality test and decides on the GRADIENT when the objective
            # difference is unresolvable. This is our adaptation of BH's rule to
            # AGD-SDAJ, not something the authors specify.
            if !ok && globalization == :armijo_bh
                near_equal = abs(tht - thk) <
                    bh_gamma * unit_roundoff * (1.0 + abs(tht) + abs(thk))
                if near_equal && norm(gt) < norm(gk)
                    ok = true
                end
            end
            snap!(traj, Xt, gt; accepted=ok,
                  event=(ok ? "mls_accept" : "mls_trial"), outer=outer, trial=j)
            ok && return (alpha, yt, tht, gt, Xt)
            mls_bt[] += 1
            alpha *= rho
        end
        return (alpha, yt, tht, gt, Xt)
    end

    # Algorithm 3 line 4: nonmonotone linesearch, eq. (6).
    function nls(yk, dk, gk, inner, outer)
        alpha = 1.0
        gnorm2 = dot(gk, gk)
        dnorm2 = dot(dk, dk)
        eps_k = 1.0 / (inner + 1)^2
        local yt, tht, gt, Xt
        for j in 1:max_bt
            yt = yk .+ alpha .* dk
            tht, gt, Xt = evaluate(yt)
            ok = dot(gt, gt) <= (1 + eps_k) * gnorm2 -
                                lam1 * alpha^2 * gnorm2 - lam2 * alpha^2 * dnorm2
            snap!(traj, Xt, gt; accepted=ok,
                  event=(ok ? "nls_accept" : "nls_trial"), outer=outer, trial=j)
            ok && return (alpha, yt, tht, gt, Xt)
            nls_bt[] += 1
            alpha *= rho
        end
        return (alpha, yt, tht, gt, Xt)
    end

    # Sec. 2.3 acceleration factor for a general direction; reduces to
    # Algorithm 1's form when d = -g.
    function accel(gk, gy, dk)
        a = -dot(gk, dk)
        b = dot(gy .- gk, dk)
        return (b > 0 && isfinite(a) && isfinite(b)) ? a / b : 1.0
    end

    y = zeros(n)
    theta_val, g, X = evaluate(y)
    snap!(traj, X, g; accepted=true, event="iterate", outer=0)
    gn = norm(g)
    exitreason = "max_iter"
    k = 0

    while k < maxit
        if gn <= tau
            exitreason = k == 0 ? "already_feasible_at_y0" : "diag_feasible"
            break
        end
        if evds[] >= max_evds
            exitreason = "evd_budget"
            break
        end

        # --- Algorithm 4 step 3: q inner QN-SDAJ iterations from y ---------
        ypre = copy(y); thpre = theta_val; gpre = copy(g); Xpre = X
        b = ones(n)                                   # B_0 = I, reset each outer
        for i in 0:(q - 1)
            norm(gpre) <= tau && break
            d = -gpre ./ b
            alpha, yt, tht, gt, Xt = nls(ypre, d, gpre, i, k + 1)
            beta_pre = accel(gpre, gt, d)
            s = beta_pre .* alpha .* d
            ynew = ypre .+ s
            local thn, gnw, Xn
            if beta_pre == 1.0
                thn, gnw, Xn = tht, gt, Xt        # same point, no extra EVD
            else
                thn, gnw, Xn = evaluate(ynew)
                snap!(traj, Xn, gnw; accepted=true, event="qn_iterate",
                      outer=k + 1, trial=i + 1)
            end
            z = gnw .- gpre
            @inbounds for idx in 1:n
                if s[idx] != 0.0
                    r = z[idx] / s[idx]
                    b[idx] = (eps_l <= r <= eps_u) ? r : 1.0
                else
                    b[idx] = 1.0
                end
            end
            ypre, thpre, gpre, Xpre = ynew, thn, gnw, Xn
        end

        # --- step 4: monotonicity safeguard --------------------------------
        if thpre > theta_val
            ypre, thpre, gpre, Xpre = y, theta_val, g, X
        end

        # Early termination at the preconditioned point (Table 3 note).
        if norm(gpre) <= tau
            y, theta_val, g, X = ypre, thpre, gpre, Xpre
            gn = norm(g); k += 1
            exitreason = "diag_feasible_at_xpre"
            break
        end

        # --- step 7: one Algorithm-1 iteration from ypre --------------------
        d = -gpre
        alpha, yt, tht, gt, Xt = mls(ypre, d, thpre, gpre, k + 1)
        beta = accel(gpre, gt, d)
        ynew = ypre .+ beta .* alpha .* d
        if beta == 1.0
            theta_val, g, X = tht, gt, Xt
        else
            theta_val, g, X = evaluate(ynew)
            snap!(traj, X, g; accepted=true, event="iterate", outer=k + 1)
        end
        y = ynew
        gn = norm(g)
        k += 1
    end

    diag_pre = maximum(abs.(diag(X) .- 1.0))
    return (X=X, y=y, updates=k, evds=evds[], exit=exitreason,
            cert=g, cert2=norm(g), certinf=maximum(abs.(g)),
            nls_backtracks=nls_bt[], mls_backtracks=mls_bt[],
            backtracks=nls_bt[] + mls_bt[], diag_pre=diag_pre, tol=tau)
end

function reference_solution(G::Matrix{Float64}; sbb_maxit::Int=60000,
                            ref_max_evds::Int=30)
    # The reference must be the most reliable solver available, not the fastest
    # to write. Earlier this routine ran SBB-Dual to 1e-11 and then the
    # NAIVE-Armijo Newton -- the very variant Sec. 4 shows stalls in finite
    # precision. On bccd16 (n=3250) that combination failed to finish in four
    # hours. The BH-globalized Newton converges in 4-7 EVDs on every instance in
    # this project, so it is tried first, cold; the SBB warm start is kept only
    # as a fallback.
    nthreads_timed = BLAS.get_num_threads()
    BLAS.set_num_threads(Sys.CPU_THREADS)
    try
        to = TimerOutput()
        # REF_TOL is an ABSOLUTE gradient tolerance and is not attainable at
        # large n: on cor1399 the old reference spent 1770 EVDs to reach
        # 4.59e-13, of which a quadratically convergent method needed under ten.
        # The rest was the solve grinding against its own rounding floor. We
        # therefore cap the reference work and report whatever accuracy it
        # achieves, which is what the paper quotes.
        r = newton_ncm_globalized(G; tol=REF_TOL, globalization=:armijo_bh,
                                  to=to, max_evds=ref_max_evds)
        if r.cert2 > 1e-11 && sbb_maxit > 0
            w = sbb_dual(G; tol=1e-11, maxit=sbb_maxit, rescale=false, to=to)
            rw = newton_ncm_globalized(G; tol=REF_TOL, y0=w.y,
                                       globalization=:armijo_bh, to=to,
                                       max_evds=ref_max_evds)
            rw.cert2 < r.cert2 && (r = rw)
            w.cert2 < r.cert2 && (r = (X=w.X, y=w.y, updates=w.updates,
                                       evds=w.evds, exit=w.exit, cert=w.cert,
                                       cert2=w.cert2, certinf=w.certinf))
        end
        return r
    finally
        BLAS.set_num_threads(nthreads_timed)
    end
end

# ------------------------------------------------- Dykstra / APM comparator

function dykstra_apm(G::Matrix{Float64}; tol::Union{Nothing,Float64}=nothing,
                     maxit::Int=5000, to::TimerOutput=TimerOutput(),
                     traj=nothing)
    n = size(G, 1)
    τ = tol === nothing ? 1e-7 * n : tol
    X = copy(G); Pc = zeros(n, n); Q = zeros(n, n)
    Xpsd = copy(X); evds = 0; its = 0
    exitreason = "max_iter"
    for k in 1:maxit
        local Y
        @timeit to "spectral_projection/eigen" begin
            F = eigen(Symmetric((X + Pc + (X + Pc)') / 2))
            Y = F.vectors * Diagonal(max.(F.values, 0.0)) * F.vectors'
        end
        evds += 1
        Xpsd = (Y + Y') / 2
        snap!(traj, Xpsd, diag(Xpsd) .- 1.0)
        if norm(diag(Xpsd) .- 1.0) <= τ
            its = k; exitreason = "diag_feasible"; break
        end
        @timeit to "dykstra_update" begin
            Pc = X + Pc - Y
            Z = Y + Q
            for i in 1:n
                Z[i, i] = 1.0
            end
            Q = Y + Q - Z
            X = Z
        end
        its = k
    end
    g = diag(Xpsd) .- 1.0
    return (X=Xpsd, updates=its, evds=evds, exit=exitreason,
            cert=g, cert2=norm(g), certinf=maximum(abs.(g)))
end

# ---------------------------------------------------------------- metrics

section_seconds(to, key) = haskey(to.inner_timers, key) ?
    TimerOutputs.time(to.inner_timers[key]) / 1e9 : 0.0

function evd_seconds(to)
    s = 0.0
    for k in ("spectral_projection/eigen", "spectral_projection/reconstruct")
        s += section_seconds(to, k)
    end
    return s
end

# -------------------------------------------------------------------- main

function parse_args(argv)
    d = Dict{String,String}()
    i = 1
    while i <= length(argv)
        a = argv[i]
        if startswith(a, "--") && occursin('=', a)
            key, value = split(a[3:end], '='; limit=2)
            d[key] = value; i += 1
        elseif startswith(a, "--") && i < length(argv)
            d[a[3:end]] = argv[i+1]; i += 2
        else
            i += 1
        end
    end
    return d
end

function selftest()
    println("V_apply block form vs naive:")
    for n in (40, 120)
        A = randn(n, n); A = (A + A') / 2
        for i in 1:n; A[i, i] = 1.0; end
        F = eigen(Symmetric(A)); λ = F.values; P = F.vectors
        thr = 100 * eps(Float64) * max(1.0, maximum(abs.(λ)))
        h = randn(n)
        for omega_beta in (0.0, 0.5, 1.0)
            v1 = V_apply(P, λ, thr, h; omega_beta=omega_beta)
            v2 = V_apply_naive(P, λ, thr, h; omega_beta=omega_beta)
            denom = max(norm(v2), eps(Float64))
            @printf("  n=%3d  omega_beta=%.1f  rel diff = %.3e   (|alpha|=%d, |beta|=%d)\n",
                    n, omega_beta, norm(v1 - v2) / denom,
                    count(λ .> thr), count(abs.(λ) .<= thr))
        end
    end
    # Random symmetric matrices almost surely have no exact zero eigenvalues,
    # so force a nonempty beta block for the selection under investigation.
    n = 60
    P = Matrix(qr(randn(n, n)).Q)
    λ = vcat(collect(range(0.2, 2.0; length=20)), zeros(20),
             -collect(range(0.2, 2.0; length=20)))
    thr = 100 * eps(Float64) * maximum(abs.(λ))
    h = randn(n)
    @assert count(abs.(λ) .<= thr) == 20
    for omega_beta in (0.0, 0.5, 1.0)
        v1 = V_apply(P, λ, thr, h; omega_beta=omega_beta)
        v2 = V_apply_naive(P, λ, thr, h; omega_beta=omega_beta)
        rel = norm(v1 - v2) / max(norm(v2), eps(Float64))
        @printf("  forced beta=20  omega_beta=%.1f  rel diff = %.3e\n",
                omega_beta, rel)
        @assert rel <= 5e-13
    end
end

# Trajectory runs deliberately use a MUCH tighter stop than the headline runs,
# so that every method's curve spans a common error range and any epsilon can be
# read off afterwards. No epsilon is chosen in advance.
function run_trajectories(instances, outpath;
                          sbb_tol=1e-10, newton_tol=1e-11, apm_tol=1e-10,
                          apm_maxit=600, xstars=Dict{String,Matrix{Float64}}())
    open(outpath, "w") do io
        println(io, "instance,n,solver,evds,err_raw_fro,err_bh_fro,grad_2,grad_inf,accepted,event,outer_iteration,trial,solver_exit,backtracks,cg_iters_total,negative_curvature_count")
        for (name, G) in instances
            n = size(G, 1)
            @printf("\n=== %s (n=%d)\n", name, n); flush(stdout)
            local Xref
            if haskey(xstars, name)
                Xref = xstars[name]
                @printf("    reference: EXACT X* from construction\n")
            else
                ref = reference_solution(G)
                Xref = ref.X
                @printf("    reference ||grad||_2 = %.2e\n", ref.cert2)
            end
            flush(stdout)
            # Both Newton variants: the original (one redundant Jacobian EVD per
            # outer step) and the cached-factorization fix. Reporting both is
            # what stops the comparison being dismissed as an implementation
            # artifact.
            runs = (("SBB-Dual",          (t) -> sbb_dual(G; tol=sbb_tol, maxit=20000, traj=t)),
                    ("Newton-SIN",        (t) -> newton_ncm(G; tol=newton_tol, traj=t, cached=false)),
                    ("Newton-SIN-cached", (t) -> newton_ncm(G; tol=newton_tol, traj=t, cached=true)),
                    ("Dykstra-APM",       (t) -> dykstra_apm(G; tol=apm_tol, maxit=apm_maxit, traj=t)))
            for (sname, f) in runs
                t = Traj(Xref)
                res = f(t)
                for r in t.rows
                    @printf(io, "%s,%d,%s,%d,%.17g,%.17g,%.17g,%.17g,%s,%s,%d,%d,%s,%d,%d,%d\n",
                            name, n, sname, r.evds, r.err_raw_fro,
                            r.err_bh_fro, r.grad_2, r.grad_inf,
                            string(r.accepted), r.event, r.outer_iteration,
                            r.trial, res.exit,
                            hasproperty(res, :backtracks) ? res.backtracks : 0,
                            hasproperty(res, :cg_iters_total) ? res.cg_iters_total : 0,
                            hasproperty(res, :negative_curvature_count) ? res.negative_curvature_count : 0)
                end
                accepted_rows = filter(r -> r.accepted, t.rows)
                last = isempty(accepted_rows) ? nothing : accepted_rows[end]
                @printf("    %-12s %5d EVDs, final err_raw=%.3e err_bh=%.3e\n",
                        sname, res.evds,
                        last === nothing ? NaN : last.err_raw_fro,
                        last === nothing ? NaN : last.err_bh_fro); flush(stdout)
            end
        end
    end
    println("\nwrote ", outpath)
end

"""
Paper 2 Sec. 5 ranking study: four VERIFIED solvers on the KKT-controlled family,
recorded as work-accuracy trajectories so that rankings can be recomputed after
the fact under different stopping-rule and accounting conventions rather than
being fixed by whichever rule each solver ships with.

Solvers:
  SBB-Dual            clamped BB1 on the dual, one EVD per update
  Newton-SIN-BH       semismooth Newton, cached Jacobian factorization,
                      Borsdorf--Higham modified line search (the CORRECTED
                      comparator; the naive-Armijo variant stalls on 56/270)
  AGD-SDAJ            Huynh--Hwang 2025, verified against published counts
  Dykstra-APM         alternating projections

Every row is one EVD. Rejected line-search trials carry accepted=false: they cost
work and receive no accuracy credit. Forward error is measured against the EXACT
X* from the KKT construction, not against another solve.
"""
function run_ranking_study(instances, outpath;
                           sbb_tol=1e-11, newton_tol=1e-11, apm_tol=1e-11,
                           agd_tol=1e-11, apm_maxit=2000, sbb_maxit=20000,
                           max_evds=4000, ref_sbb_maxit=60000,
                           solvers::Union{Nothing,Vector{String}}=nothing,
                           xstars=Dict{String,Matrix{Float64}}())
    open(outpath, "w") do io
        println(io, "instance,n,solver,evds,err_raw_fro,err_bh_fro,grad_2,grad_inf,accepted,event,outer_iteration,trial,solver_exit,backtracks,cg_iters_total,negative_curvature_count,lambda_min_X,diag_err_inf")
        ninst = length(instances)
        for (idx, (name, G)) in enumerate(instances)
            n = size(G, 1)
            @printf("[%d/%d] %s (n=%d)\n", idx, ninst, name, n); flush(stdout)
            local Xref
            if haskey(xstars, name)
                Xref = xstars[name]
            else
                tref = @elapsed (ref = reference_solution(G; sbb_maxit=ref_sbb_maxit))
                Xref = ref.X
                @printf("    reference (computed, NOT exact): ||grad||_2=%.3e ||grad||_inf=%.3e exit=%s evds=%d  %.1fs\n",
                        ref.cert2, ref.certinf, ref.exit, ref.evds, tref)
                flush(stdout)
            end
            runs = (("SBB-Dual",      (t) -> sbb_dual(G; tol=sbb_tol, maxit=sbb_maxit, traj=t)),
                    ("Newton-SIN-BH", (t) -> newton_ncm_globalized(G; tol=newton_tol, traj=t,
                                                globalization=:armijo_bh, max_evds=max_evds)),
                    ("AGD-SDAJ",      (t) -> agd_sdaj_ncm(G; tol=agd_tol, traj=t, max_evds=max_evds,
                                                globalization=:armijo_naive)),
                    ("AGD-SDAJ-BH",   (t) -> agd_sdaj_ncm(G; tol=agd_tol, traj=t, max_evds=max_evds,
                                                globalization=:armijo_bh)),
                    ("Dykstra-APM",   (t) -> dykstra_apm(G; tol=apm_tol, maxit=apm_maxit, traj=t)))
            # --solvers runs a subset. At large n running all five variants to a
            # work cap can take a day per instance, so the choice is the user's.
            if solvers !== nothing
                known = [r[1] for r in runs]
                bad = setdiff(solvers, known)
                isempty(bad) || error("unknown solver(s) $(bad); choose from $(known)")
                runs = Tuple(r for r in runs if r[1] in solvers)
            end
            for (sname, f) in runs
                t = Traj(Xref)
                res = f(t)
                # Feasibility of the RETURNED iterate, reported at the exit point
                # so a reader can see what each solver actually hands back.
                Xout = res.X
                lam_min = minimum(eigvals(Symmetric((Xout + Xout') / 2)))
                diag_err = maximum(abs.(diag(Xout) .- 1.0))
                for r in t.rows
                    @printf(io, "%s,%d,%s,%d,%.17g,%.17g,%.17g,%.17g,%s,%s,%d,%d,%s,%d,%d,%d,%.17g,%.17g\n",
                            name, n, sname, r.evds, r.err_raw_fro,
                            r.err_bh_fro, r.grad_2, r.grad_inf,
                            string(r.accepted), r.event, r.outer_iteration,
                            r.trial, res.exit,
                            hasproperty(res, :backtracks) ? res.backtracks : 0,
                            hasproperty(res, :cg_iters_total) ? res.cg_iters_total : 0,
                            hasproperty(res, :negative_curvature_count) ? res.negative_curvature_count : 0,
                            lam_min, diag_err)
                end
                acc = filter(r -> r.accepted, t.rows)
                @printf("    %-14s %5d EVDs  err=%.3e  exit=%s\n", sname, res.evds,
                        isempty(acc) ? NaN : acc[end].err_raw_fro, res.exit)
                flush(stdout)
            end
        end
    end
    println("\nwrote ", outpath)
end

"Field access with a default, so one CSV row schema serves every solver."
getprop(nt, sym::Symbol, default) = hasproperty(nt, sym) ? getproperty(nt, sym) : default

function main()
    args = parse_args(ARGS)
    tol_mode = get(args, "tol-mode", "native")
    tol_mode in ("native", "matched") ||
        error("--tol-mode must be native or matched")
    matched_tol = parse(Float64, get(args, "matched-tol", "1e-11"))
    timing_evd_budget = parse(Int, get(args, "evd-budget", "4000"))
    dykstra_maxit = parse(Int, get(args, "dykstra-maxit", "2000"))
    if haskey(args, "selftest") || "--selftest" in ARGS
        selftest(); return
    end
    outcsv = get(args, "out", joinpath(@__DIR__, "julia_timing_results.csv"))

    instances = Tuple{String,Matrix{Float64}}[]
    if haskey(args, "suite")
        append!(instances, load_suite(args["suite"]))
    end
    if haskey(args, "matrices")
        for p in sort(filter(f -> endswith(f, ".mat"),
                             readdir(args["matrices"], join=true)))
            nm = splitext(basename(p))[1]
            try
                push!(instances, (nm, load_higham_matrix(p)))
            catch e
                @warn "skipping $nm" exception = e
            end
        end
    end
    isempty(instances) && error("no instances: pass --suite and/or --matrices")

    if haskey(args, "only")
        want = Set(strip.(split(args["only"], ",")))
        instances = [(nm, G) for (nm, G) in instances if nm in want]
        isempty(instances) && error("--only matched no instances")
    end

    if haskey(args, "trajectory")
        xs = haskey(args, "suite") ? load_xstars(args["suite"]) :
             Dict{String,Matrix{Float64}}()
        isempty(xs) || @printf("using %d exact X* from the instance family\n", length(xs))
        run_trajectories(instances, args["trajectory"]; xstars=xs)
    elseif haskey(args, "ranking")
        xs = haskey(args, "suite") ? load_xstars(args["suite"]) : Dict{String,Matrix{Float64}}()
        # Optional knobs (Paper 2 gaps run, 2026-09). Defaults reproduce the
        # original n=100 study exactly. --blas-threads only changes wall-clock
        # of this UNTIMED trajectory pass, never the EVD counts it records.
        rtol = parse(Float64, get(args, "ranking-tol", "1e-11"))
        haskey(args, "blas-threads") && BLAS.set_num_threads(parse(Int, args["blas-threads"]))
        run_ranking_study(instances, args["ranking"]; xstars=xs,
                          sbb_tol=rtol, newton_tol=rtol, apm_tol=rtol, agd_tol=rtol,
                          sbb_maxit=parse(Int, get(args, "sbb-maxit", "20000")),
                          apm_maxit=parse(Int, get(args, "apm-maxit", "2000")),
                          max_evds=parse(Int, get(args, "max-evds", "4000")),
                          ref_sbb_maxit=parse(Int, get(args, "ref-sbb-maxit", "60000")),
                          solvers=haskey(args, "solvers") ?
                                  String.(strip.(split(args["solvers"], ","))) : nothing)
        return
    end

    gitsha = try
        strip(read(`git -C $(dirname(dirname(@__DIR__))) rev-parse --short HEAD`, String))
    catch
        "unknown"
    end
    cpu = try Sys.cpu_info()[1].model catch; "unknown" end

    cols = ["instance","n","solver","tol_rule","tol_value","updates","total_evds",
            "elapsed_seconds","evd_seconds","evd_percent","bb_seconds",
            "certificate_seconds","rescale_seconds","newton_cg_seconds",
            "dykstra_update_seconds","other_seconds",
            "dist_G_X_fro","err_vs_ref_fro","lambda_min_X","diag_error_pre",
            "diag_error_post","certificate_2","certificate_inf",
            "ceiling_clamp_pct","exit",
            "cg_iters_total","jacobian_vector_products","linesearch_trials",
            "nls_backtracks","mls_backtracks","negative_curvature_count",
            "accepted_outer_iterations",
            "ref_cert_2","julia_version",
            "blas_vendor","blas_threads","julia_threads","cpu","os","git_commit"]

    open(outcsv, "w") do io
        println(io, join(cols, ","))
        for (name, G) in instances
            n = size(G, 1)
            @printf("\n=== %s (n=%d)\n", name, n)
            flush(stdout)

            ref = reference_solution(G; sbb_maxit=parse(Int, get(args, "ref-sbb-maxit", "60000")))
            Xref = ref.X
            @printf("    reference ||grad||_2 = %.2e (%s)\n", ref.cert2, ref.exit)
            flush(stdout)

            # tol_mode: "native" reproduces each method's shipped rule
            # (1e-7*n, the Huynh--Hwang dimension-scaled rule); "matched" drives
            # every solver to the same tight tolerance so wall-clock is
            # comparable at equal accuracy. Sec. 3.1 is precisely that these two
            # need not agree.
            tolv_run = tol_mode == "native" ? 1e-7 * n : matched_tol
            solvers = Any[
                ("SBB-Dual",      (to) -> sbb_dual(G; tol=tolv_run, to=to,
                                              maxit=parse(Int, get(args, "sbb-maxit", "5000")))),
                ("Newton-SIN-BH", (to) -> newton_ncm_globalized(G; tol=tolv_run, to=to,
                                              globalization=:armijo_bh,
                                              max_evds=timing_evd_budget)),
                # --cap-naive-newton (opt-in, disclosed): apply --evd-budget to the
                # naive-Armijo control too. Default stays uncapped, as in the n=100 runs.
                ("Newton-SIN",    (to) -> newton_ncm(G; tol=tolv_run, to=to,
                                              max_evds=(haskey(args, "cap-naive-newton") ||
                                                        "--cap-naive-newton" in ARGS) ?
                                                       timing_evd_budget : typemax(Int))),
                ("AGD-SDAJ-BH",   (to) -> agd_sdaj_ncm(G; tol=tolv_run, to=to,
                                              globalization=:armijo_bh,
                                              max_evds=timing_evd_budget)),
                ("AGD-SDAJ",      (to) -> agd_sdaj_ncm(G; tol=tolv_run, to=to,
                                              globalization=:armijo_naive,
                                              max_evds=timing_evd_budget)),
                ("Dykstra-APM",   (to) -> dykstra_apm(G; tol=tolv_run, to=to,
                                              maxit=dykstra_maxit)),
            ]

            for (sname, f) in solvers
                # --no-warmup (disclosed; intended only for n>=3000 where one
                # solve costs minutes and JIT is negligible by comparison)
                haskey(args, "no-warmup") || "--no-warmup" in ARGS ||
                    (_ = f(TimerOutput()))               # discarded warmup
                GC.gc()
                to = TimerOutput()
                res = nothing
                elapsed = @elapsed begin
                    res = f(to)
                end
                # percentages are taken against the MEASURED solve time, so any
                # uninstrumented work shows up as `other_seconds` instead of
                # silently inflating evd_percent
                ev = evd_seconds(to)
                bb = section_seconds(to, "bb_step")
                cert = section_seconds(to, "certificate/residual")
                resc = section_seconds(to, "bh_rescale_epilogue")
                cg = section_seconds(to, "newton_cg")
                dyk = section_seconds(to, "dykstra_update")
                other = max(elapsed - ev - bb - cert - resc - cg - dyk, 0.0)
                tot = elapsed

                X = res.X
                dist = norm(G .- X)
                err = norm(X .- Xref)
                lmin = minimum(eigvals(Symmetric((X + X') / 2)))
                dpost = maximum(abs.(diag(X) .- 1.0))
                dpre = hasproperty(res, :diag_pre) ? res.diag_pre : dpost
                clamp = hasproperty(res, :clamp_pct) ? res.clamp_pct : NaN
                tolv = hasproperty(res, :tol) ? res.tol : 1e-7 * n

                vals = [name, n, sname, "1e-7*n", tolv, res.updates, res.evds,
                        elapsed, ev, (tot > 0 ? 100ev / tot : NaN), bb, cert,
                        resc, cg, dyk, other, dist, err, lmin, dpre, dpost,
                        res.cert2, res.certinf, clamp, res.exit,
                        getprop(res, :cg_iters_total, 0),
                        getprop(res, :jacobian_vector_products,
                                getprop(res, :cg_iters_total, 0)),
                        getprop(res, :backtracks, 0),
                        getprop(res, :nls_backtracks, 0),
                        getprop(res, :mls_backtracks, 0),
                        getprop(res, :negative_curvature_count, 0),
                        res.updates,
                        ref.cert2,
                        string(VERSION), BLAS.vendor(), BLAS.get_num_threads(),
                        Threads.nthreads(), cpu, string(Sys.KERNEL), gitsha]
                println(io, join(vals, ","))
                flush(io)
                @printf("    %-12s upd=%-5d EVDs=%-5d %7.3fs  EVD %5.1f%%  ||G-X||=%.4f  ||X-X*||=%.2e  lmin=%+.1e  diag=%.1e  clamp=%s  %s\n",
                        sname, res.updates, res.evds, elapsed,
                        (tot > 0 ? 100ev / tot : NaN), dist, err, lmin, dpost,
                        isnan(clamp) ? "--" : @sprintf("%.1f%%", clamp),
                        res.exit)
                flush(stdout)
            end
        end
    end
    println("\nwrote ", outcsv)
end

if abspath(PROGRAM_FILE) == (@__FILE__)
    main()
end
