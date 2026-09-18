# Anderson-accelerated alternating projections for the NCM problem.
#
# A line-for-line transcription of nearcorr_aa.m and nearcorr_new.m by
# N. J. Higham and N. Strabic (github.com/higham/anderson-accel-ncm,
# BSD-2-Clause), the code behind
#   N. J. Higham and N. Strabic, Anderson acceleration of the alternating
#   projections method for computing the nearest correlation matrix,
#   Numer. Algorithms 72 (2016) 1021-1042,
# which follows H. F. Walker's AndAcc.m (least squares by QR factorization with
# updating). Only the default least-squares option 'u' is transcribed, with its
# optional column dropping (DROPTOL, off by default); the paper's experiments
# use it, and the 'n' and 'b' options are not needed here.
#
# The MATLAB control flow is kept: the convergence test comes before the
# update, the history counter mAA is managed exactly as in the original, a new
# column enters the QR factors by modified Gram-Schmidt, the oldest column
# leaves through MATLAB's qrdelete (Givens rotations from planerot), and the
# returned matrix is the input Yin of the final step, not its output.
#
# Two optional hooks let the benchmark harness drive the same arithmetic:
#   stop(Xout, Yout)  replaces the published stopping test
#   onstep(Xout)      is called after every eigendecomposition
# With both left unset the function is the published method.

"MATLAB planerot: returns G with G*[x1; x2] = [r; 0]."
function hs_planerot(x1::Float64, x2::Float64)
    if x2 != 0
        r = hypot(x1, x2)
        return [x1 x2; -x2 x1] ./ r, r
    else
        return [1.0 0.0; 0.0 1.0], x1
    end
end

"MATLAB qrdelete(Q, R, 1) for an economy-size factorization."
function hs_qrdelete_first(Q::Matrix{Float64}, R::Matrix{Float64})
    R = R[:, 2:end]
    Q = copy(Q)
    m, n = size(R)
    for k in 1:min(n, m - 1)
        G, r = hs_planerot(R[k, k], R[k+1, k])
        R[k, k] = r
        R[k+1, k] = 0.0
        if k < n
            R[k:k+1, k+1:n] = G * R[k:k+1, k+1:n]
        end
        Q[:, k:k+1] = Q[:, k:k+1] * G'
    end
    mq, nq = size(Q)
    if mq != nq
        R = R[1:m-1, :]
        Q = Q[:, 1:nq-1]
    end
    return Q, R
end

# LAPACK driver for the symmetric eigendecomposition. :syevr is Julia's default
# and is used for every reported run; :syevd and :syev exist only so the
# validation can show how far iteration counts at tol = n*eps move under a
# change of eigensolver alone.
const HS_EIG = Ref(:syevr)

"proj_spd: nearest positive semidefinite matrix with smallest eigenvalue >= delta."
function hs_proj_spd(A::Matrix{Float64}, delta::Float64, to::TimerOutput)
    local X
    @timeit to "spectral_projection/eigen" begin
        if HS_EIG[] === :syevr
            F = eigen(Symmetric(A)); w = F.values; V = F.vectors
        elseif HS_EIG[] === :syevd
            w, V = LAPACK.syevd!('V', 'U', copy(A))
        else
            w, V = LAPACK.syev!('V', 'U', copy(A))
        end
        X = V * Diagonal(max.(w, delta)) * V'
    end
    return (X + X') / 2
end

"proj_pattern: unit diagonal, or the entries of A where pattern is true."
function hs_proj_pattern(A::Matrix{Float64}, X::Matrix{Float64}, pattern)
    Y = copy(X)
    if pattern === nothing
        for i in axes(Y, 1)
            Y[i, i] = 1.0
        end
    else
        Y[pattern] = A[pattern]
    end
    return Y
end

"ap_step: one alternating-projections step in fixed-point form."
function hs_ap_step(A, Yin, Sin, pattern, delta, to)
    R = Yin - Sin
    Xout = hs_proj_spd(R, delta, to)
    Sout = Xout - R
    Yout = hs_proj_pattern(A, Xout, pattern)
    return Xout, Yout, Sout
end

"nearcorr_new.m: unaccelerated alternating projections. Returns (Y, iter)."
function hs_nearcorr_new(A::Matrix{Float64}; pattern=nothing, delta::Float64=0.0,
                         tol::Union{Nothing,Float64}=nothing, itmax::Int=100)
    A == A' || error("The input matrix must by symmetric.")
    τ = tol === nothing ? size(A, 1) * eps(Float64) : tol
    Y = copy(A); iter = 0; rel = Inf; dS = zeros(size(A)); to = TimerOutput()
    while rel > τ
        X, Y, dS = hs_ap_step(A, Y, dS, pattern, delta, to)
        rel = norm(Y - X) / norm(Y)
        iter += 1
        iter > itmax && error("Stopped after $itmax its. Try increasing ITMAX.")
    end
    return Y, iter
end

"""
nearcorr_aa.m: alternating projections with Anderson acceleration.
Returns (X, iter, converged, rel, Xout).
"""
function nearcorr_aa(A::Matrix{Float64}; pattern=nothing, mMax::Int=2, itmax::Int=100,
                     delta::Float64=0.0, tol::Union{Nothing,Float64}=nothing,
                     droptol::Float64=0.0, AAstart::Int=1, stop=nothing, onstep=nothing,
                     to::TimerOutput=TimerOutput())
    A == A' || error("The input matrix must by symmetric.")
    n = size(A, 1)
    τ = tol === nothing ? n * eps(Float64) : tol
    N = n * n

    DG = zeros(2N, 0)            # g-value differences
    mAA = 0                      # number of stored residuals
    Q = zeros(2N, 0); R = zeros(0, 0)
    f_old = Float64[]; g_old = Float64[]
    df = Float64[]

    Yin = copy(A)
    Sin = zeros(n, n)
    Xout = copy(A)
    iter = 0; rel = Inf; converged = false

    for it in 1:itmax
        iter = it
        Xout, Yout, Sout = hs_ap_step(A, Yin, Sin, pattern, delta, to)
        onstep === nothing || onstep(Xout)

        x = vcat(vec(Yin), vec(Sin))
        gval = vcat(vec(Yout), vec(Sout))
        fval = gval - x

        rel = norm(Yout - Xout) / norm(Yout)
        done = stop === nothing ? rel < τ : stop(Xout, Yout)
        if done
            converged = true
            break
        end

        if mMax == 0 || it < AAstart
            x = gval
        else
            if it > AAstart
                df = fval - f_old
                if mAA < mMax
                    DG = hcat(DG, gval - g_old)
                else
                    DG = hcat(DG[:, 2:end], gval - g_old)
                end
                mAA += 1
            end
            f_old = fval
            g_old = gval

            if mAA == 0
                x = gval
            else
                if mAA == 1
                    R = fill(norm(df), 1, 1)
                    Q = reshape(df ./ R[1, 1], :, 1)
                else
                    if mAA > mMax
                        Q, R = hs_qrdelete_first(Q, R)
                        mAA -= 1
                        if size(R, 1) != size(R, 2)
                            Q = Q[:, 1:mAA-1]
                            R = R[1:mAA-1, :]
                        end
                    end
                    Rn = zeros(mAA, mAA)
                    Rn[1:mAA-1, 1:mAA-1] = R
                    for j in 1:mAA-1
                        Rn[j, mAA] = dot(Q[:, j], df)
                        df = df - Rn[j, mAA] * Q[:, j]
                    end
                    Rn[mAA, mAA] = norm(df)
                    Q = hcat(Q, df ./ Rn[mAA, mAA])
                    R = Rn
                end

                if droptol > 0
                    # Drop residuals to improve conditioning if necessary.
                    condDF = cond(R)
                    while condDF > droptol && mAA > 1
                        Q, R = hs_qrdelete_first(Q, R)
                        DG = DG[:, 2:mAA]
                        mAA -= 1
                        if size(R, 1) != size(R, 2)
                            Q = Q[:, 1:mAA]
                            R = R[1:mAA, :]
                        end
                        condDF = cond(R)
                    end
                end

                # A zero diagonal in R means the newest difference is exactly
                # dependent on the stored ones (it happens at the rounding
                # floor). MATLAB's R\b then warns and returns Inf/NaN, and the
                # run fails at ITMAX; we stop at once with the same outcome.
                if any(iszero, diag(R))
                    stop === nothing && error("Least-squares breakdown at iteration $it.")
                    return (X=Yin, iter=iter, converged=false, breakdown=true, rel=rel, Xout=Xout)
                end
                gamma = UpperTriangular(R) \ (Q' * fval)
                x = gval - DG * gamma
            end
        end

        Yin = reshape(x[1:N], n, n)
        Sin = reshape(x[N+1:2N], n, n)
    end

    if !converged && stop === nothing
        error("Stopped after $itmax its. Try increasing ITMAX.")
    end
    return (X=Yin, iter=iter, converged=converged, breakdown=false, rel=rel, Xout=Xout)
end

"""
Benchmark form, scored like dykstra_apm: every eigendecomposition records the
positive semidefinite half-iterate, and the run stops when that iterate has
||diag(X) - e||_2 <= tol. History length m = 2 is the published default.
"""
function anderson_apm(G::Matrix{Float64}; tol::Union{Nothing,Float64}=nothing,
                      maxit::Int=5000, m::Int=2, to::TimerOutput=TimerOutput(),
                      traj=nothing)
    n = size(G, 1)
    τ = tol === nothing ? 1e-7 * n : tol
    evds = Ref(0)
    Xlast = Ref(copy(G))
    onstep = X -> begin
        evds[] += 1
        Xlast[] = X
        snap!(traj, X, diag(X) .- 1.0)
    end
    stop = (X, Y) -> norm(diag(X) .- 1.0) <= τ
    r = nearcorr_aa(G; mMax=m, itmax=maxit, stop=stop, onstep=onstep, to=to)
    X = Xlast[]
    g = diag(X) .- 1.0
    return (X=X, updates=r.iter, evds=evds[],
            exit=r.converged ? "diag_feasible" : r.breakdown ? "ls_breakdown" : "max_iter",
            cert=g, cert2=norm(g), certinf=maximum(abs.(g)))
end

"""
Timing form of `anderson_apm`, for the wall-clock study only.

`nearcorr_aa` above is written for fidelity to the MATLAB original: every
iteration it concatenates vectors of length 2n^2, copies the history matrix to
drop a column, and reallocates the QR factors. Timed as it stands, Anderson-APM
would be charged for that transcription style rather than for the method, while
the other solvers update in place. This version performs the same arithmetic in
the same order on preallocated buffers: the history is shifted in place, the
oldest column leaves through Givens rotations applied in place (the operation
MATLAB's qrdelete performs), and products go through `mul!`. Its iterates agree
with `anderson_apm` to rounding (validation/check_anderson_fast.jl), and the work
outside the eigendecomposition is timed as "anderson_update", as the Dykstra
update is timed as "dykstra_update".
"""
function anderson_apm_fast(G::Matrix{Float64}; tol::Union{Nothing,Float64}=nothing,
                           maxit::Int=5000, m::Int=2, to::TimerOutput=TimerOutput(),
                           traj=nothing)
    n = size(G, 1); N = n * n; L = 2N
    τ = tol === nothing ? 1e-7 * n : tol
    x = zeros(L); g = zeros(L); f = zeros(L)
    f_old = zeros(L); g_old = zeros(L); df = zeros(L); tmp = zeros(L)
    DG = zeros(L, m); Q = zeros(L, m); R = zeros(m, m)
    gam = zeros(m); qf = zeros(m)
    copyto!(x, 1, vec(G), 1, N)                  # Yin = G, Sin = 0
    Rm = similar(G)
    Xout = copy(G)
    mAA = 0; evds = 0; its = 0; exitreason = "max_iter"
    for it in 1:maxit
        @timeit to "anderson_update" begin
            @inbounds for k in 1:N               # R = Yin - Sin
                Rm[k] = x[k] - x[N+k]
            end
        end
        Xout = hs_proj_spd(Rm, 0.0, to)          # one EVD, timed inside
        evds += 1
        snap!(traj, Xout, diag(Xout) .- 1.0)
        if norm(diag(Xout) .- 1.0) <= τ
            its = it; exitreason = "diag_feasible"; break
        end
        breakdown = false
        @timeit to "anderson_update" begin
            # g = [vec(Yout); vec(Sout)], Yout = Xout with unit diagonal, Sout = Xout - R
            @inbounds for k in 1:N
                g[k] = Xout[k]
                g[N+k] = Xout[k] - Rm[k]
            end
            @inbounds for i in 1:n
                g[(i-1)*n+i] = 1.0
            end
            f .= g .- x
            if it > 1                            # AAstart = 1
                df .= f .- f_old
                if mAA < m
                    DG[:, mAA+1] .= g .- g_old
                else
                    for j in 1:m-1
                        copyto!(view(DG, :, j), view(DG, :, j+1))
                    end
                    DG[:, m] .= g .- g_old
                end
                mAA += 1
            end
            copyto!(f_old, f); copyto!(g_old, g)
            if mAA == 0
                copyto!(x, g)
            else
                if mAA == 1
                    R[1, 1] = norm(df)
                    Q[:, 1] .= df ./ R[1, 1]
                else
                    if mAA > m                   # qrdelete(Q, R, 1), in place
                        k = m
                        for c in 1:k-1           # R(:,1) = []
                            for r in 1:k
                                R[r, c] = R[r, c+1]
                            end
                        end
                        for j in 1:k-1           # restore triangularity by Givens
                            x1 = R[j, j]; x2 = R[j+1, j]
                            if x2 != 0
                                # the same 2x2 products as hs_qrdelete_first, so
                                # the rounding is identical, not just equivalent
                                rr = hypot(x1, x2)
                                Gm = [x1 x2; -x2 x1] ./ rr
                                R[j, j] = rr; R[j+1, j] = 0.0
                                if j < k - 1
                                    R[j:j+1, j+1:k-1] = Gm * R[j:j+1, j+1:k-1]
                                end
                                Q[:, j:j+1] = Q[:, j:j+1] * Gm'
                            end
                        end
                        mAA -= 1
                        for r in 1:m, c in 1:m   # drop the last row and column
                            (r > mAA - 1 || c > mAA - 1) && (R[r, c] = 0.0)
                        end
                    end
                    for j in 1:mAA-1             # modified Gram-Schmidt
                        R[j, mAA] = dot(view(Q, :, j), df)
                        df .-= R[j, mAA] .* view(Q, :, j)
                    end
                    for c in 1:mAA-1
                        R[mAA, c] = 0.0
                    end
                    R[mAA, mAA] = norm(df)
                    Q[:, mAA] .= df ./ R[mAA, mAA]
                end
                if any(iszero, (R[j, j] for j in 1:mAA))
                    breakdown = true
                else
                    # m x m copies, so the solve takes the same LAPACK path as
                    # the transcription's R\(Q'*f); the O(n^2) work stays in place
                    Qv = view(Q, :, 1:mAA)
                    mul!(view(qf, 1:mAA), Qv', f)
                    gv = UpperTriangular(R[1:mAA, 1:mAA]) \ qf[1:mAA]
                    mul!(tmp, view(DG, :, 1:mAA), gv)
                    x .= g .- tmp
                end
            end
        end
        its = it
        if breakdown
            exitreason = "ls_breakdown"; break
        end
    end
    gd = diag(Xout) .- 1.0
    return (X=Xout, updates=its, evds=evds, exit=exitreason,
            cert=gd, cert2=norm(gd), certinf=maximum(abs.(gd)))
end
