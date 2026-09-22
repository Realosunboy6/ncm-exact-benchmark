"""
Parameter sensitivity for Sec. 8's tuning limitation: does the ranking in
Sec. 5 depend on SBB-Dual's step clamp eta or on Anderson-APM's history
length m?

Runs both methods on the 270 released n=100 instances (degen_instances_paired)
at a range of eta / m values, to a common tolerance of 1e-11, and reports the
median accepted-only, reach-and-hold EVDs to forward error 1e-8 against the
exact X*, plus the count of instances on which each method is cheaper than
AGD-SDAJ-BH (the comparison Sec. 5 uses SBB-Dual and Anderson-APM against).
AGD-SDAJ-BH itself is run once, at its published parameters, as the fixed
comparator.

No other change to any solver or to the ranking-study protocol: same
instances, same tolerance, same exact reference, same reach-and-hold rule as
analyze_ranking.py's cost_to_fixed (recomputed here directly from each run's
Traj).

Usage: julia --project=. sensitivity_eta_m.jl [outfile.md]
"""
ENV["NCM_STANDALONE"] = "1"   # no MAT/real-suite dependency needed here
include(joinpath(@__DIR__, "bench_sbb_dual.jl"))

using Statistics

const SUITE_DIR = joinpath(@__DIR__, "degen_instances_paired")
const TOL = 1e-11
const TARGET = 1e-8
const ETAS = [0.001, 0.01, 0.05, 0.1, 0.2]      # 0.01 is the value used in Sec. 5
const MS = [1, 2, 3, 5, 10]                      # 2 is the authors' default, used in Sec. 5

"Accepted-only, reach-and-hold EVDs to `target`, from a finished Traj's rows."
function cost_to_fixed(rows::Vector{NamedTuple}, target::Float64)
    acc = [r for r in rows if r.accepted]
    (isempty(acc) || acc[end].err_raw_fro > target) && return nothing
    k = length(acc)
    while k > 1 && acc[k - 1].err_raw_fro <= target
        k -= 1
    end
    return acc[k].evds
end

function main()
    out = length(ARGS) >= 1 ? ARGS[1] : nothing
    lines = String[]
    emit(s::AbstractString="") = (push!(lines, s); println(s))

    suite = load_suite(SUITE_DIR)
    xstars = load_xstars(SUITE_DIR)
    names = [name for (name, _) in suite]
    Gs = Dict(name => G for (name, G) in suite)

    emit("# Sensitivity of Sec. 5 to SBB-Dual's eta and Anderson-APM's m")
    emit("")
    emit("270 n=100 instances, tolerance 1e-11, target forward error 1e-8, reach-and-hold,")
    emit("accepted-only. AGD-SDAJ-BH run once at its published parameters as the fixed")
    emit("comparator; only eta (SBB-Dual) and m (Anderson-APM) are varied.")
    emit("")

    println(stderr, "running AGD-SDAJ-BH reference on 270 instances...")
    agd = Dict{String,Any}()
    for name in names
        t = Traj(xstars[name])
        agd_sdaj_ncm(Gs[name]; tol=TOL, max_evds=4000, globalization=:armijo_bh, traj=t)
        agd[name] = cost_to_fixed(t.rows, TARGET)
    end
    agd_vals = Float64[v for v in values(agd) if v !== nothing]
    emit("AGD-SDAJ-BH median EVDs to 1e-8: $(median(agd_vals)) ($(length(agd_vals))/270 reached)")
    emit("")

    emit("## SBB-Dual: sweep of eta, clamp interval [eta, 2-eta]")
    emit("")
    emit("| eta | median EVDs (reached/270) | cheaper than AGD-SDAJ-BH (of instances both reached) |")
    emit("|---:|---:|---:|")
    for eta in ETAS
        println(stderr, "SBB-Dual eta=$eta ...")
        costs = Dict{String,Any}()
        for name in names
            t = Traj(xstars[name])
            sbb_dual(Gs[name]; eps=eta, tol=TOL, maxit=20000, traj=t)
            costs[name] = cost_to_fixed(t.rows, TARGET)
        end
        vals = Float64[v for v in values(costs) if v !== nothing]
        both = [name for name in names if costs[name] !== nothing && agd[name] !== nothing]
        cheaper = count(name -> costs[name] < agd[name], both)
        emit("| $eta | $(median(vals)) ($(length(vals))/270) | $cheaper / $(length(both)) |")
    end
    emit("")

    emit("## Anderson-APM: sweep of history length m")
    emit("")
    emit("| m | median EVDs (reached/270) | cheaper than AGD-SDAJ-BH (of instances both reached) |")
    emit("|---:|---:|---:|")
    for m in MS
        println(stderr, "Anderson-APM m=$m ...")
        costs = Dict{String,Any}()
        for name in names
            t = Traj(xstars[name])
            anderson_apm(Gs[name]; m=m, tol=TOL, maxit=2000, traj=t)
            costs[name] = cost_to_fixed(t.rows, TARGET)
        end
        vals = Float64[v for v in values(costs) if v !== nothing]
        both = [name for name in names if costs[name] !== nothing && agd[name] !== nothing]
        cheaper = count(name -> costs[name] < agd[name], both)
        emit("| $m | $(median(vals)) ($(length(vals))/270) | $cheaper / $(length(both)) |")
    end
    emit("")

    if out !== nothing
        open(out, "w") do io
            for l in lines
                println(io, l)
            end
        end
        println(stderr, "wrote $out")
    end
end

main()
