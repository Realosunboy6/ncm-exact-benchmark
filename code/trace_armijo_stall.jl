"""
Trace the naive-Armijo Newton stall of Sec. 4.2 to shipped, reproducible
numbers. Runs Newton-SIN (the naive Armijo control, `newton_ncm` with
cached=false) on the 270 released n=100 instances at tol=1e-11, uncapped in
EVDs, exactly the configuration `code/bench_sbb_dual.jl`'s timing harness
uses by default for Newton-SIN -- this is the run whose 56/270 max_iter
stall count matches `results/timing_kkt270_matched.csv`, and whose total
backtrack count (151,471) matches that file's own `linesearch_trials` sum
and the solver's own internal `backtracks` counter exactly (asserted below).

History: an earlier version of the paper cited 55,402 backtracks, an AUC of
0.934 for a "ULP-margin" predictor, and 2,181 "affected" iterations for this
same claim. No script or log producing those numbers was found in results/
or docs/. This script is a fresh, from-scratch computation, not a
reconstruction aimed at reproducing them, and it does not: the verified
backtrack total here is 151,471, not 55,402 (Sec. 4.2 was corrected to
match). Two natural readings of "affected iteration" were tried:
  (a) full-Newton-step (trial == 1, before any backtracking) rejections that
      would, if accepted, have reduced BOTH the gradient norm and the exact
      forward error -- this population is reported in the paper. Every
      single one of the 5,677 such rejections satisfies the criterion, which
      leaves no negative class and so no AUC is defined on it.
  (b) the same criterion applied to every rejected trial, including those
      reached only after backtracking -- 115,211 of 151,471 (76%) satisfy
      it, and a ULP-margin predictor scores only 0.526 AUC on this
      population (see below), little better than chance.
Neither reading reproduces an AUC near 0.934, under the most natural
definition of the ULP margin
(|theta - theta_t + predicted_decrease| / (u*(1+|theta|+|theta_t|))). The
paper no longer cites an AUC for this claim; it reports (a)'s clean result
(zero exceptions) and (b)'s two counts instead.

Usage: julia --project=. trace_armijo_stall.jl [outfile.md]
"""
ENV["NCM_STANDALONE"] = "1"   # no timing needed, just outcomes; avoids MAT/TimerOutputs
include(joinpath(@__DIR__, "bench_sbb_dual.jl"))

using Statistics

const SUITE_DIR = joinpath(@__DIR__, "degen_instances_paired")
const TOL = 1e-11
const U = eps(Float64) / 2

"Mann-Whitney AUC: P(score of a random positive > score of a random negative),
ties counted as one half. O(n log n)."
function auc(scores_pos::Vector{Float64}, scores_neg::Vector{Float64})
    (isempty(scores_pos) || isempty(scores_neg)) && return NaN
    n1 = length(scores_pos); n2 = length(scores_neg)
    all_scores = vcat(scores_pos, scores_neg)
    order = sortperm(all_scores)
    ranks = Vector{Float64}(undef, length(all_scores))
    i = 1
    while i <= length(order)
        j = i
        while j < length(order) && all_scores[order[j+1]] == all_scores[order[i]]
            j += 1
        end
        r = (i + j) / 2
        for k in i:j
            ranks[order[k]] = r
        end
        i = j + 1
    end
    rank_sum_pos = sum(ranks[1:n1])
    Uu = rank_sum_pos - n1 * (n1 + 1) / 2
    return Uu / (n1 * n2)
end

function main()
    out = length(ARGS) >= 1 ? ARGS[1] : nothing
    lines = String[]
    emit(s::AbstractString="") = (push!(lines, s); println(s))

    suite = load_suite(SUITE_DIR)
    xstars = load_xstars(SUITE_DIR)

    total_backtracks = 0
    total_backtracks_crosscheck = 0
    n_stalled = 0
    affected = 0
    affected_stalled = 0; full_step_rejections_stalled = 0
    full_step_rejections = 0
    margin_affected = Float64[]
    margin_not_affected = Float64[]
    # secondary population: EVERY rejected trial (any trial number), not only
    # the full step, in case the affected/not-affected split is only
    # non-degenerate once backtracked trials are included
    all_affected = 0
    margin_all_affected = Float64[]
    margin_all_not_affected = Float64[]

    for (name, G) in suite
        Xref = xstars[name]
        trial_log = NamedTuple[]
        traj = Traj(Xref)
        res = newton_ncm(G; tol=TOL, maxit=100, max_evds=typemax(Int),
                          cached=false, traj=traj, trial_log=trial_log)
        stalled = res.exit == "max_iter"
        stalled && (n_stalled += 1)
        total_backtracks_crosscheck += res.backtracks

        for r in trial_log
            r.accepted && continue
            total_backtracks += 1
            margin = abs(r.theta - r.theta_t + r.predicted_decrease) /
                     (U * (1 + abs(r.theta) + abs(r.theta_t)))
            is_affected = (r.grad2_trial < r.grad2_before) && (r.err_trial < r.err_before)
            if is_affected
                all_affected += 1
                push!(margin_all_affected, margin)
            else
                push!(margin_all_not_affected, margin)
            end
            r.trial == 1 || continue
            full_step_rejections += 1
            stalled && (full_step_rejections_stalled += 1)
            if is_affected
                affected += 1
                stalled && (affected_stalled += 1)
                push!(margin_affected, margin)
            else
                push!(margin_not_affected, margin)
            end
        end
    end

    @assert total_backtracks_crosscheck == total_backtracks "trial_log backtrack count disagrees with the solver's own count"

    emit("# Sec. 4.2 naive-Armijo Newton stall, traced")
    emit("")
    emit("270 n=100 instances, Newton-SIN (naive Armijo, cached=false), tol=1e-11, uncapped EVDs.")
    emit("")
    emit("Stalled instances (exit = max_iter): $n_stalled / 270")
    emit("Total backtracks (all outer iterations, all instances): $total_backtracks")
    emit("  (cross-checked against the solver's own `backtracks` return value: match)")
    emit("Full-step (trial 1) rejections: $full_step_rejections")
    emit("Affected iterations (full-step rejection that would have reduced both")
    emit("  the gradient norm and the exact forward error): $affected")
    emit("  of which on stalled instances only: $affected_stalled / $full_step_rejections_stalled full-step rejections")
    emit("  on non-stalled instances: $(affected - affected_stalled) / $(full_step_rejections - full_step_rejections_stalled)")
    emit("")
    a = auc(margin_affected, margin_not_affected)
    emit("ULP-margin predictor (defined in the script docstring), evaluated on the")
    emit("$full_step_rejections full-step rejections ($affected affected, $(full_step_rejections - affected) not):")
    emit("AUC = $(round(a, digits=3))")
    emit("")
    emit("Same predictor over EVERY rejected trial (any trial number), all $total_backtracks:")
    emit("  $all_affected affected, $(total_backtracks - all_affected) not affected")
    a_all = auc(margin_all_affected, margin_all_not_affected)
    emit("  AUC = $(round(a_all, digits=3))")
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
