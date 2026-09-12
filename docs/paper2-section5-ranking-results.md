# Paper 2 §5 — ranking-reversal study: results

**Run date:** 2026-09-08
**Instances:** 270 paired KKT-controlled instances, n=100, exact `X*` from the construction
(`degen_instances_paired`). Forward error is measured against that exact solution, never
against another solve.
**Solvers (all five verified):** Newton-SIN-BH (cached Jacobian + Borsdorf--Higham
globalization), AGD-SDAJ (Huynh--Hwang 2025, as published), AGD-SDAJ-BH (same, with the
BH correction applied to its Algorithm-1 step), SBB-Dual, Dykstra-APM.
**Common target tolerance:** all solvers run to `1e-11`, with a 4000-EVD budget.
**Artifacts:** `experiments/bench/ranking_kkt270_v2.csv` (trajectories, one row per EVD),
`ranking_kkt270_v2_analysis.md` (generated tables), `analyze_ranking.py`.

> **Correction (2026-09-11) — read before using any number below.** `analyze_ranking.py::cost_to`
> scored a run as never reaching a target if its *first* dip below the target was not held,
> without checking whether a later iterate settled below it for good. That undercounted the
> non-monotone AGD variants only (audit: `ranking_kkt270_v2_cost_to_audit.md`, 234 affected
> cases; corrected tables: `ranking_kkt270_v2_gaps_analysis.md` §12). Corrected values:
> - AGD-SDAJ-BH reaches every target on **270/270**. Forward medians are **45** at 1e-8 and
>   **63.5** at 1e-10 (not 43 and 59 over 217/208). Residual: 42 and 60.
> - Uncorrected AGD-SDAJ: 264/253 forward (medians 50, 72); residual 264/254 (47, 69).
> - Newton-SIN-BH, SBB-Dual and Dykstra-APM are unchanged.
> - **The 2nd/3rd reversal is unchanged at every target.**
> - Per-cell orderings at 1e-8: **7 distinct, not 9**.
> - Accounting: at most **2 EVDs**, and all-trial is now slightly *dearer*. The "−14%" figure
>   in §4 below is **withdrawn**.
> - The §1 caveat that AGD medians are "conditioned on the easier subset" no longer applies
>   to AGD-SDAJ-BH.
>
> The body below keeps the original, uncorrected numbers for the record.

---

## Headline

1. **The winner does not change.** Newton-SIN-BH is cheapest under all 11 stopping-rule
   and accounting conventions tested. This is a **null result for winner-reversal** and
   must be reported as such.
2. **The ranking below the winner does change, and the crossover is the accuracy target.**
   SBB-Dual and AGD-SDAJ swap 2nd/3rd place between loose and tight tolerances.
3. **Across the degeneracy grid the ordering is not stable at all:** 54 cells produce
   **9 distinct orderings**. In 12 cells both AGD variants fall to *last*, below Dykstra.
4. **§4's finite-precision Armijo trap replicates in a second, independently published
   method.** AGD-SDAJ as published stalls on 18/270 instances; the BH correction fixes
   all 18.

---

## 1. The convention-dependent reversal

Median EVDs to reach a common forward error `||X - X*||_F <= eps`:

| eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM |
|---|---:|---:|---:|---:|---:|
| 1e-02 | **3** | 6 | 6 | 8 | 15 |
| 1e-04 | **4** | 14 | 14 | 16 | 34 |
| 1e-06 | **4** | 28 | 28 | *24* | 54 |
| 1e-08 | **5** | 43 | 45 | *34* | 74 |
| 1e-10 | **5** | 59 | 70 | *44* | 96 |

The dual-residual criterion produces the same flip at the same crossover, so this is not
an artifact of which error measure is used.

**Reading.** A paper reporting a loose tolerance ranks AGD-SDAJ above SBB-Dual; a paper
reporting a tight tolerance ranks them the other way. Both are defensible single-number
summaries of the same runs. This is the concrete instance of the paper's thesis, and it is
honest about being a 2nd/3rd-place reversal rather than a change of winner.

**Caveat that must be printed with this table.** At `1e-08` and `1e-10` the AGD medians are
computed over the subset that reached and held the target (AGD-SDAJ 202/270 and 198/270;
AGD-SDAJ-BH 217/270 and 208/270), whereas Newton, SBB-Dual and Dykstra reach it on all 270.
The AGD medians are therefore conditioned on the easier subset and are, if anything,
optimistic — the tight-tolerance reversal is understated, not overstated.

## 2. Ranking is regime-dependent

At a fixed target (forward `1e-08`), the 54 (rank, multiplicity, separation) cells produce
**9 distinct orderings**:

| ordering (cheapest first) | cells | example cell |
|---|---:|---|
| Newton < AGD-SDAJ-BH < AGD-SDAJ < SBB < Dykstra | 17 | r=5, m=1, d=0 |
| Newton < SBB < AGD-SDAJ-BH < AGD-SDAJ < Dykstra | 15 | r=20, m=1, d=0 |
| Newton < SBB < Dykstra < AGD-SDAJ-BH < AGD-SDAJ | 12 | r=20, m=20, d=1e-10 |
| Newton < SBB < AGD-SDAJ < AGD-SDAJ-BH < Dykstra | 4 | r=20, m=1, d=1e-08 |
| *(5 further orderings)* | 6 | — |

The 12-cell block matters: in the **degenerate corner** (high near-zero multiplicity, tight
separation) both AGD variants fall below Dykstra/APM to last place, having been *second*
in the low-rank cells. Rank `r` is the dominant covariate — SBB-Dual overtakes AGD at
`r >= 20` — which is exactly the axis the KKT family was built to control, and could not
have been isolated on a collection of real-world matrices with uncontrolled spectra.

## 3. §4's Armijo trap replicates in AGD-SDAJ  `[NEW FINDING]`

AGD-SDAJ as published exhausted the 4000-EVD budget on **18/270** instances. Diagnosis on
`degen-r20-m1-d1e-10-p2`: 3198 rejected `mls_trial` evaluations with `theta` and
`||grad theta||` frozen at exactly `6.0935e-09` / `3.5986e-09`. Algorithm 1 line 5 is the
naive objective-value Armijo test, so once the predicted decrease
`c*alpha*||grad theta||^2 ~ 1.3e-21` falls below `eps(theta) ~ 2e-16`, no step can pass.

Applying the Borsdorf--Higham near-equality test and deciding on the gradient when the
objective difference is unresolvable:

| variant | outer | EVDs | exit | final `\|\|g\|\|` | forward error |
|---|---:|---:|---|---:|---:|
| AGD-SDAJ (as published) | 115 | 4001 | evd_budget | 3.60e-09 | 6.09e-09 |
| AGD-SDAJ-BH | **10** | **67** | converged | 9.40e-12 | 1.82e-11 |

Across the family the correction takes AGD-SDAJ from 252/270 to **270/270** converged and
its worst case from 4035 EVDs to 131 — the same qualitative outcome as the Newton result
in §4 (56/270 stalls eliminated).

**Framing, and it must not be overstated.** This is *not* a defect in Huynh--Hwang's
reported results. Their stopping rule is the dimension-scaled `1e-7*n`, which for these
instances is `1e-5` — six orders of magnitude above the ULP floor where the test fails.
The stall appears only when the method is pushed to a tight common tolerance, which is
precisely what a matched-accuracy comparison requires. The correct claim is:

> The naive objective-value Armijo condition is a recurring defect in the NCM literature
> rather than a property of any single implementation. It is present in both a semismooth
> Newton implementation and in a separately published accelerated-gradient method, is
> invisible under each method's native stopping rule, and is removed in both cases by
> Borsdorf--Higham's modified line search.

This upgrades §4 from "a rediscovery of a known fix in one solver" to an independently
replicated observation across two methods — and it is the strongest argument the paper has
for why the protocol, not just the result, is the contribution.

## 4. Accounting convention

Crediting rejected line-search trials with reaching a target (all-trial accounting) changes
median costs only for the two AGD variants, by up to 6 EVDs at `eps = 1e-08`
(AGD-SDAJ-BH: 43 accepted-only vs 37 all-trial, **-14%**). Newton, SBB-Dual and Dykstra are
unaffected, having few or no rejected trials on this family. The effect is real but small
and never changes an ordering here.

## 5. What each solver returns is not interchangeable

| solver | median `lambda_min(X)` | worst `lambda_min` | median diag err | worst diag err |
|---|---:|---:|---:|---:|
| Newton-SIN-BH | -3.42e-15 | -1.25e-14 | 8.38e-15 | 5.70e-12 |
| AGD-SDAJ-BH | -3.40e-15 | -1.36e-14 | 2.53e-12 | 7.20e-12 |
| AGD-SDAJ | -3.40e-15 | -1.39e-14 | 2.79e-12 | **4.01e-08** |
| SBB-Dual | -3.42e-15 | -1.49e-14 | **0.00e+00** | **0.00e+00** |
| Dykstra-APM | -3.43e-15 | -1.36e-14 | 1.49e-12 | 9.37e-12 |

SBB-Dual returns an exactly unit diagonal because of its BH rescaling epilogue; every other
solver returns a diagonal correct only to its convergence tolerance. Uncorrected AGD-SDAJ's
worst-case diagonal error is 2.5 orders worse than any other solver's, a direct consequence
of the stalls above. All five return `lambda_min` at roundoff, so none is meaningfully more
PSD than another. A user who needs an exactly unit diagonal and a user who needs minimal
distance are not served by the same solver, and a benchmark that reports only cost hides
this.

---

## Consequences for the programme

**For Paper 2.** §5 is now evidenced and can be written. The claim is precise: *the winner
was invariant across every convention tested; the 2nd/3rd ranking reverses with the accuracy
target; and the ordering is unstable across the degeneracy grid (9 orderings over 54 cells).*
No reversal is claimed that was not observed. §4 gains the replication above.

**For Paper 1.** SBB-Dual is now measured against a fourth verified solver and the result is
mixed rather than uniformly negative: it is beaten by Newton everywhere (as already known),
beaten by AGD-SDAJ at loose tolerance, but **beats both AGD variants at tight tolerance and
at rank >= 20**. That is a narrower and more defensible position than "consistently
improves on alternating projections" alone, and it should replace the current §5 wording.
It does not by itself establish a practical niche — the warm-start experiment (§6) is still
the gate for that.

## Open items

- Timing has not been measured for this study; all costs are EVD counts. Wall-clock needs a
  separate single-threaded run under the §3.5 protocol before any time-based claim.
- The tight-tolerance AGD medians are conditioned on the subset that reached (see §1
  caveat). Either report the reach-rate beside every median or restrict the summary table
  to targets all solvers reach on all 270.
- The BH adaptation to AGD-SDAJ's Algorithm-1 step is *our* correction, not the authors';
  it must be published as code and described as an adaptation, with the uncorrected variant
  reported alongside it as done here.
- n=100 only. Whether the r>=20 crossover between SBB-Dual and AGD-SDAJ persists at larger
  n is untested and should not be assumed.

---

# Timing and primitive work (§3.1, §3.4, §3.5)

**Run:** 2026-09-08, same 270 instances, six solvers, single-threaded BLAS, discarded
warmup, GC before the measured solve, one `@elapsed` per solve. Two tolerance regimes:
native (`1e-7*n`) and matched (common `1e-11`). Artifacts:
`timing_kkt270_native.csv`, `timing_kkt270_matched.csv`, `timing_kkt270_analysis.md`,
`analyze_timing.py`.

> **Scope correction (2026-09-12).** The 383x figure below is the spread at **n=100 only**.
> Repeating the same run at n=500 gives a spread of **13.8x** (medians 1.74e-05 for
> Newton-SIN-BH to 2.41e-04 for Dykstra-APM). The cross-solver spread is not a stable
> property of the rule and must not be reported as one. The claim that survives, and is
> stronger, is the absolute degradation with dimension: Newton-SIN-BH exits at 5.04e-08 at
> n=100 and 1.74e-05 at n=500, about 340x worse, because the threshold grows linearly in n.
> See `paper2-gaps123-results.md`.

## §3.1 quantified: native exits differ by 383x in accuracy

At their own stopping rules, the six solvers stop at wildly different accuracies:

| solver | median EVDs | median time (s) | median err vs X* |
|---|---:|---:|---:|
| Newton-SIN-BH | 4 | 0.023 | **5.04e-08** |
| Newton-SIN | 7 | 0.035 | 5.04e-08 |
| AGD-SDAJ-BH | 20 | 0.085 | 9.58e-06 |
| AGD-SDAJ | 20 | 0.084 | 9.58e-06 |
| SBB-Dual | 18 | 0.088 | 7.73e-06 |
| Dykstra-APM | 40 | 0.222 | **1.93e-05** |

Best-to-worst achieved accuracy spans **383x** under one shared, published stopping rule.
Any cost comparison drawn at these exit points compares different accuracies. This is the
single cleanest number the paper has for why native-rule comparisons are not comparisons.

## §3.4: the EVD is a *nearly* fair unit, and the bias runs against Newton

Microseconds per EVD at matched tolerance:

| solver | us/EVD | relative |
|---|---:|---:|
| Newton-SIN-BH | 6262 | 1.37x |
| Dykstra-APM | 5440 | 1.19x |
| Newton-SIN | 5262 | 1.15x |
| AGD-SDAJ | 4730 | 1.03x |
| AGD-SDAJ-BH | 4689 | 1.02x |
| SBB-Dual | 4584 | 1.00x |

Spread is **1.37x**, and it runs *against* Newton: its EVDs are the most expensive because
each outer iteration also carries a Krylov solve that no EVD count records. So EVD counting
**understates** Newton's true cost. Concretely, Newton-SIN-BH's advantage over SBB-Dual is
9.2x in EVDs (5 vs 46) but 6.3x in wall-clock (0.032 s vs 0.202 s).

The honest statement is therefore narrower than "EVD counts are misleading": on this family
they are a *directionally biased but rank-preserving* proxy, and the bias is small relative
to the 6--20x gaps being measured. Report both; do not report EVDs alone.

## §5 robustness: the cost metric does NOT change the ranking

- By EVDs: `Newton-SIN-BH < Newton-SIN < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM`
- By wall-clock: **identical ordering**

This is an important negative control for §5. The tolerance-dependent and regime-dependent
reversals reported above are properties of the *stopping rule* and the *instance regime*,
**not** artifacts of choosing spectral decompositions as the unit of work. Had the two
metrics disagreed, every EVD-denominated table in the paper would have needed re-basing.

## §3.4: "iteration" is not a common currency

Median primitive work at matched tolerance:

| solver | EVDs | CG iterations | line-search trials | accepted outer its |
|---|---:|---:|---:|---:|
| Newton-SIN-BH | 5 | 24 | 0 | 4 |
| Newton-SIN | 11 | 30 | 0 | 5 |
| AGD-SDAJ-BH | 70 | 0 | 14 | 9 |
| AGD-SDAJ | 82 | 0 | 25 | 10 |
| SBB-Dual | 46 | 0 | 0 | 46 |
| Dykstra-APM | 102 | 0 | 0 | 102 |

Four accepted Newton iterations carry 5 EVDs and 24 Krylov products; 46 SBB-Dual iterations
carry 46 EVDs and nothing else; 9 AGD-SDAJ outer iterations expand into 70 EVDs because each
contains `q=2` inner QN-SDAJ steps with their own line searches. A table of "iterations to
convergence" across these six rows would be comparing four unrelated quantities.

## Independent confirmation of §4

At matched tolerance the naive-Armijo Newton control exits `max_iter` on **56/270**
instances while the BH-globalized variant converges on **270/270** — reproducing the
original §4 stall count exactly, in a separate run, on a separate code path from the
trajectory study. Together with the AGD-SDAJ replication above, §4 now rests on two methods
and two independent runs.
