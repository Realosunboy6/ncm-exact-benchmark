# Paper 2 — gaps 1–3: n=500 replication, real matrices, statistics

**Status:** IN PROGRESS (this section written 2026-09-11 ~02:50 CDT, before results).

## Deviations and censoring (recorded at decision time)

### D1. n=500 ranking study runs on a 162-instance subset (3 of 5 seeds per cell)

**Instance generation: the full design was populated, with no change.**
`gen_degeneracy_family.py --n 500 --out degen_instances_n500_paired --max-seed-attempts 200`
(ranks 5,20,50; mult 1,5,20; deltas 1e-2,1e-4,1e-6,1e-8,1e-10,0; 5 paired seeds;
mu_bulk=0.1, same as n=100) emitted all 270 instances in 4.2 min.

Seed acceptance (`degen_instances_n500_paired/seed_screening.csv`); a seed must pass the
whole 18-cell (m, delta) block:

| rank | accepted / candidates | rejection reason |
|---|---:|---|
| 5  | 5 / 7 (71%) | 2 seeds rejected: \|G_ij\| > 1 |
| 20 | 5 / 5 (100%) | — |
| 50 | 5 / 5 (100%) | — |

Among the accepted r=5 instances, max off-diagonal |G_ij| is 0.99987. So r=5 at n=500 is
feasible at mu_bulk=0.1, but it is already at the edge of the |G_ij| <= 1 screen. This is
consistent with Proposition 2.3b (at fixed rank, max |X*_ij| saturates toward 1 as n grows):
it is the first rank to show rejections. The `degen_probe_n500_paired` precedent (r=5 only,
one cell) accepted 5 of 6. Neither mu_bulk nor the rank set was changed.

**Why the ranking run was reduced.** Measured EVD time (Julia `eigen(Symmetric)`, random
symmetric matrix, minimum of repeats):

| n | 1 BLAS thread | 4 threads | 8 | 12 |
|---|---:|---:|---:|---:|
| 500  | 0.069 s | 0.042 s | 0.099 s | 0.154 s |
| 1399 | 1.46 s  | 1.23 s  | 1.27 s  | 1.33 s  |
| 3120 | 14.9 s  | 11.2 s  | 10.4 s  | 10.4 s  |
| 3250 | 16.8 s  | —       | —       | —       |

The ranking pass is untimed (it records EVD counts, not seconds), so it was run with 4 BLAS
threads (the new `--blas-threads` knob). That changes its wall-clock only, never the counts.

The first attempt used the full 270-instance design with default caps. On its first instance,
SBB-Dual alone needed **1075 EVDs** to reach 1e-11 (the n=100 median is about 218). Newton-SIN-BH
took 4, AGD-SDAJ 107 and AGD-SDAJ-BH 79. Dykstra-APM was still running when the attempt was
stopped; it was projected to reach its 2000-iteration cap. That is roughly 3300 EVDs per
instance. Each EVD step (eigen plus reconstruct) costs about 0.07–0.08 s, so one instance takes
about 260 s and the full 270 would take **about 19 h**, against a ~14 h budget for all three gaps.
The attempt was stopped after instance 1; its partial files are kept as
`ranking_n500_aborted_full.{log,csv}` and are not used for results.

**What was kept.** All 54 (r, m, delta) cells, with paired seeds **p0, p1, p2** (the first
three accepted seeds per rank), for 162 instances. The list is in
`n500_subset_p012.txt`. Caps: `--sbb-maxit 1200 --apm-maxit 800`. `--max-evds 4000` and
`--ranking-tol 1e-11` are unchanged. Command:

```
NCM_STANDALONE=1 julia --project=. bench_sbb_dual.jl --suite degen_instances_n500_paired \
  --only "$(cat n500_subset_p012.txt)" --ranking ranking_n500.csv --blas-threads 4 \
  --sbb-maxit 1200 --apm-maxit 800
```

Projected runtime is about 5–6 h. Any SBB-Dual or Dykstra-APM run that exits at `max_iter` is
**censored**. It is reported as not having reached any target it did not reach and hold, and
it is never counted as converged. The forward-error targets are at most 1e-10, and at n=100
they were reached far earlier than the 1e-11 exit (SBB median 44 EVDs to 1e-10, versus about
218 to exit). So the caps are expected to censor mainly the exit, not the targets. This will be
checked from the CSV and reported.

**Consequences for gap 3.** With 3 seeds per cell instead of 5:
- the per-cell bootstrap at n=500 resamples only 3 values, so it has very little resolving
  power;
- the cluster bootstrap resamples 3 pair-clusters per rank instead of 5.

The n=500 per-cell stability results are therefore **weaker** than those at n=100. An
"unresolved" order at n=500 is weak evidence of a tie, not evidence that one exists.

**Rate update (03:10).** The rate measured on the subset run is about 190 s per instance
(7 instances in 22.5 min, r=5 cells), projecting about 8.6 h for 162 instances. The r=5 cells
are expected to be the slowest: SBB needs about 1070 EVDs there, and Dykstra hits its
800-iteration cap with error about 6e-5. Because of this, the real-matrix ranking budget was
cut (D4). Early censoring counts: 6 Dykstra-APM `max_iter` exits and 1 `evd_budget` exit
(AGD, 4000 EVDs) in the first 7 instances.

### D3. Julia package images blocked on this machine; workaround

On 2026-09-11 an Windows Application Control policy blocked the compiled package-image DLLs
under `~/.julia/compiled/v1.12` (`HDF5_jll`, `OrderedCollections`). As a result neither
`using MAT` nor `using TimerOutputs` loads, and the non-standalone harness path (timing runs,
`--matrices`) cannot start as invoked on 2026-09-08. The system policy was **not** modified.
Workarounds:
- **Timing runs** are launched as `julia --pkgimages=no --project=. ...`. Packages then load
  from non-native caches. That changes package load and JIT behaviour only: the numerical code
  and the `@elapsed` measurement are the same, and the discarded warmup absorbs JIT. Verified:
  TimerOutputs and MAT both load, and `matread` reads Rocky_Mountain (94×94).
- **Real matrices** were exported with `export_real_suite.py` (scipy.io.loadmat, reproducing
  `load_higham_matrix` exactly: column-wise strict-upper unpacking of `x`, symmetrised `A`)
  to `real_suite/` (manifest.tsv + G_<idx>.bin, with no Xstar). They are run with `--suite`
  in NCM_STANDALONE=1 mode for ranking. Sizes and properties from the export:
  Rocky_Mountain n=94 (λmin −4.64e−2, 2 negative eigenvalues); cor1399 n=1399 (λmin −8.45,
  639 negative, max |G_ij| 1.157); bccd16 n=3250 (λmin −25.7, 5 negative); cor3120 n=3120
  (λmin −0.718, 86 negative, max |G_ij| 1.075).

### D5. Analysis bug found in `analyze_ranking.py::cost_to` (affects the n=100 §5 numbers)

`cost_to` is meant to score a target as reached only if it holds for the rest of the run. It
actually returns at the **first** accepted iterate below eps: if that dip is not held, it
reports "not reached" and never looks at later iterates, even when the run later settles
below eps for good. Accelerated methods are non-monotone, so this undercounts AGD.
`audit_cost_to.py` on `ranking_kkt270_v2.csv` (output in `ranking_kkt270_v2_cost_to_audit.md`)
finds 234 affected (instance, solver, eps) cases, all AGD-SDAJ / AGD-SDAJ-BH:

| eps | AGD-SDAJ-BH reached: old → fixed | median old → fixed | AGD-SDAJ reached: old → fixed | median old → fixed |
|---|---|---|---|---|
| 1e-06 | 269 → 270 | 28 → 28 | 269 → 270 | 28 → 28 |
| 1e-08 | 217 → **270** | 43 → **45** | 202 → **264** | 45 → **50** |
| 1e-10 | 208 → **270** | 59 → **63.5** | 198 → **253** | 70 → **72** |

Newton-SIN-BH, SBB-Dual and Dykstra-APM are unchanged, since they are monotone in this metric.
Sections 1–8 of `analyze_ranking.py` are kept verbatim so the earlier outputs reproduce. The
new Sections 9–12 use the corrected rule, and Section 12 recomputes the §5 headline tables
under it.

**Effect on n=100 claims, from Sec. 12 of `ranking_kkt270_v2_gaps_analysis.md` (corrected rule):**
- Aggregate forward-eps ordering: unchanged at every eps. AGD first below Newton at 1e-2 and
  1e-4; SBB-Dual second from 1e-6 on. The 2nd/3rd reversal therefore **stands**.
- The tight-eps AGD-SDAJ-BH medians become 45 (1e-8) and 63.5 (1e-10) on **270/270**. They
  are not conditioned on a subset. The §5 caveat that "AGD reached only 217/208" was an
  analysis artefact for AGD-SDAJ-BH. For uncorrected AGD-SDAJ it shrinks to 264/253.
- Per-cell orderings at 1e-8: **7** distinct orderings, not **9**; 11 of 54 cells change
  ordering.

### D4. Real-matrix scope reduced (budget)
Real-matrix ranking runs Rocky_Mountain and cor1399 (caps: 500 EVDs per solver) and bccd16
(caps: 100 EVDs per solver, since an EVD step there costs about 13 s). **cor3120 is not run**:
it is the lowest priority, and the n=500 run's 8.6 h (D1) leaves no budget for it.
Real-matrix timing covers Rocky_Mountain and cor1399 at matched 1e-9, with caps of 300
EVDs per solver (a new optional `--sbb-maxit` in the timing path; default 5000 unchanged)
and warmup kept. Commands are in `run_chain.sh`.

### Early real-data observation (smoke test, Rocky_Mountain n=94, matched 1e-9)
A throwaway timing smoke run (`smoke_timing_rocky.csv`; timings not used) showed the naive-Armijo
Newton-SIN control exiting `max_iter` after **100 outer iterations / 3164 EVDs**, with forward
error 1.03e-8 against the reference. Newton-SIN-BH converged in **4 EVDs** (error 1.5e-13).
This is the §4 finite-precision Armijo stall on a real matrix, not a constructed one. It will
be confirmed in the measured run. Because an uncapped stall on cor1399 would cost hours, the
real-matrix timing run uses a new opt-in `--cap-naive-newton` flag, which applies
`--evd-budget 300` to naive Newton-SIN. That run's naive-Newton result is **censored** by
construction. n=500 timing keeps naive Newton uncapped, as at n=100.

## Gap 1 results — n=500 ranking (162 instances, finished 2026-09-11 18:31)

Corrected reach-and-hold rule throughout (§ D5). Median EVDs to reach and hold a common
forward error, with reach counts:

| eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM |
|---|---:|---:|---:|---:|---:|
| 1e-02 | **3** | 9 | 9 | 44 | 87 |
| 1e-04 | **4** | 30 | 30 | 97 | 195 |
| 1e-06 | **4** | 54 | 56 [160] | 152 | 191 [108] |
| 1e-08 | **5** | 79 | 85 [154] | 207.5 | 258 [108] |
| 1e-10 | **5** | 101 | 118 [144] | 261 [158] | 325.5 [108] |

**Verdicts against the n=100 claims.**

| claim (n=100) | n=500 verdict |
|---|---|
| Winner invariant (Newton-SIN-BH cheapest under every convention) | **CONFIRMED** — cheapest at every target, 5 EVDs median |
| 2nd/3rd reversal between SBB-Dual and AGD-SDAJ with the accuracy target | **OVERTURNED** — one ordering at all five targets; AGD-SDAJ-BH cheaper throughout |
| Rank decides which of SBB-Dual / AGD-SDAJ is cheaper (SBB wins at r>=20) | **OVERTURNED as stated; direction survives** — AGD-BH cheaper in 54/54 cells at r=5 and r=20, and 46/54 at r=50. Median SBB/AGD-BH ratio at 1e-8: 6.61x (r=5), 2.71x (r=20), 1.24x (r=50) |
| AGD-SDAJ (as published) stalls; the BH correction removes it | **CONFIRMED** — 21/162 `evd_budget` stalls for the naive variant, 0 for AGD-SDAJ-BH (max 240 EVDs vs 4039) |

**Not a censoring artifact.** SBB-Dual converged on 162/162 (max 1075 EVDs against the
1200 cap) and reached every target except 1e-10 on 4 instances, so its poor showing is
real, not a truncation. Newton-SIN-BH converged on 162/162 (max 15 EVDs). **Dykstra-APM
is censored:** 54/162 exits at the 800-iteration cap, and from 1e-6 down its medians cover
only 108/162, so its n=500 position must be reported as censored.

**Reading.** The ordering below the winner is not a property of the methods; it depends on
the dimension as well as the instance regime. SBB-Dual scales markedly worse than
AGD-SDAJ-BH here: its median cost to 1e-8 rises from 34 EVDs at n=100 to 207.5 at n=500
(6.1x), while AGD-SDAJ-BH rises from 45 to 79 (1.8x). This also bears on Paper 1, whose
comparison section should not claim that SBB-Dual beats the AGD variants at tight tolerance
without the n=100 qualifier.

## Gap 2 results, part 1 — real matrices (finished 2026-09-11 20:12)

Rocky Mountain (n=94) and cor1399 (n=1399), ranking protocol, target tolerance 1e-9,
caps 500 EVDs per solver. **Forward error here is against a computed reference, not an
exact X\*:** the cor1399 reference solve ended at `max_iter` after 1770 EVDs with
`||grad||_2 = 4.59e-13`, which is accurate enough to serve as a reference but must be
reported as iteration-limited rather than converged.

EVDs to reach and hold a common forward error (corrected reach-and-hold rule):

| matrix | solver | total | 1e-2 | 1e-4 | 1e-6 | 1e-8 | final err |
|---|---|---:|---:|---:|---:|---:|---:|
| Rocky Mountain, n=94 | Newton-SIN-BH | 4 | 2 | 3 | 3 | **4** | 1.49e-13 |
| | **SBB-Dual** | 8 | 2 | 4 | 6 | **7** | 1.53e-10 |
| | Dykstra-APM | 13 | 2 | 5 | 8 | 11 | 2.57e-10 |
| | AGD-SDAJ-BH | 17 | 2 | 4 | 8 | 12 | 3.47e-10 |
| | AGD-SDAJ | 25 | 2 | 4 | 8 | 12 | 3.47e-10 |
| cor1399, n=1399 | Newton-SIN-BH | 7 | 6 | 6 | 7 | **7** | 1.27e-09 |
| | **AGD-SDAJ-BH** | 69 | 29 | 33 | 55 | **66** | 1.98e-09 |
| | AGD-SDAJ | 70 | 29 | 33 | 55 | 67 | 1.90e-09 |
| | SBB-Dual | 212 | 58 | 105 | 152 | 200 | 3.01e-09 |
| | Dykstra-APM | 430 | 116 | 212 | 309 | 406 | 2.57e-09 |

**Verdicts.**

| claim | real-matrix verdict |
|---|---|
| Winner invariant (Newton-SIN-BH cheapest) | **CONFIRMED** on both matrices (4 and 7 EVDs) |
| Order below the winner depends on the regime, including dimension | **CONFIRMED, and on real data** — the two matrices disagree with each other in the predicted direction |

**The key result.** The two real matrices reproduce the dimension dependence found on the
synthetic family, independently of it:
- at **n=94**, SBB-Dual is the cheapest first-order method (7 EVDs to 1e-8, against 12 for
  AGD-SDAJ-BH and 11 for Dykstra-APM) — the n=100 KKT pattern;
- at **n=1399**, SBB-Dual costs 3.0x AGD-SDAJ-BH (200 against 66) — the n=500 KKT pattern.

So the crossover is not an artifact of the constructed family. Two matrices from the
literature, with uncontrolled spectra, show the same reversal with dimension. This is the
strongest available support for the paper's corrected claim that lower-place rankings are
regime-dependent rather than intrinsic to the methods.

**Not yet observed here.** Both AGD variants converge on both matrices, so the finite-precision
Armijo stall does not appear in this ranking pass (the naive-Armijo *Newton* control is not
part of the ranking solver set; the smoke test in D4 showed it stalling on Rocky Mountain at
3164 EVDs against 4 for Newton-SIN-BH, and that will be confirmed in the timing run).

**Still pending:** bccd16 (n=3250, running), cor3120 (not run, D4), and all three timing
stages.

## Gap 1/2 results — timing (chain finished 2026-09-12 07:29)

### n=500 timing, 18 instances, 6 solvers

Matched tolerance 1e-11 (median EVDs / median seconds / median forward error):

| solver | EVDs | time (s) | err vs X* | us/EVD |
|---|---:|---:|---:|---:|
| Newton-SIN-BH | 5 | 1.02 | 3.61e-12 | 208096 |
| Newton-SIN | 9 | 1.83 | 3.57e-12 | 185659 |
| AGD-SDAJ-BH | 106 | 15.88 | 2.16e-11 | 175806 |
| AGD-SDAJ | 118 | 21.83 | 2.65e-11 | 172252 |
| SBB-Dual | 274 | 54.54 | 1.13e-11 | 191514 |
| Dykstra-APM | 553 | 123.90 | 4.00e-11 | 222267 |

**Ranking by wall-clock equals ranking by EVDs at n=500 as well** — the negative control
of §3.4 holds at a second dimension. Per-EVD spread is 1.29x (1.37x at n=100), and at
n=500 the dearest per EVD is Dykstra-APM rather than Newton.

### The 383x native-rule spread is n=100-specific  `[WEAKENED]`

Under the dimension-scaled rule at n=500 (threshold 5e-5):

| solver | EVDs | time (s) | err at exit |
|---|---:|---:|---:|
| Newton-SIN-BH | 3 | 0.18 | 1.74e-05 |
| AGD-SDAJ-BH | 26 | 1.19 | 9.62e-05 |
| SBB-Dual | 88 | 3.94 | 4.97e-05 |
| Dykstra-APM | 178 | 11.58 | 2.41e-04 |

The cross-solver spread falls from **383x at n=100 to 13.8x at n=500**. The paper must
therefore not present 383x as a property of the rule; it is the spread at one dimension.
What *does* strengthen is the absolute claim: the accuracy the rule delivers degrades
sharply with n — Newton-SIN-BH exits at 5.04e-08 at n=100 but at 1.74e-05 at n=500, about
340x worse, because the threshold grows linearly with n. Report both.

### Real-matrix timing (matched 1e-9; Rocky Mountain n=94, cor1399 n=1399)

| instance | solver | EVDs | time (s) | err vs ref | exit |
|---|---|---:|---:|---:|---|
| Rocky Mountain | Newton-SIN-BH | 4 | 0.009 | 1.49e-13 | converged |
| | SBB-Dual | 8 | 0.011 | 2.35e-10 | converged |
| | Dykstra-APM | 13 | 0.023 | 2.57e-10 | converged |
| | AGD-SDAJ-BH | 17 | 0.023 | 3.47e-10 | converged |
| | AGD-SDAJ | 25 | 0.036 | 3.47e-10 | converged |
| | **Newton-SIN (naive)** | **300** | 0.489 | **1.03e-08** | **EVD budget (stalled)** |
| cor1399 | Newton-SIN-BH | 7 | 7.00 | 1.27e-09 | converged |
| | Newton-SIN | 13 | 11.05 | 1.27e-09 | converged |
| | AGD-SDAJ-BH | 91 | 65.00 | 6.92e-10 | converged |
| | AGD-SDAJ | 136 | 100.04 | 2.29e-09 | converged |
| | SBB-Dual | 212 | 152.69 | 1.89e-09 | converged |
| | Dykstra-APM | 300 | 288.90 | 1.49e-06 | max_iter (censored) |

**The finite-precision Armijo stall occurs on a real matrix.**  `[CONFIRMED, NEW]`
On Rocky Mountain the naive-Armijo Newton control exhausts its 300-EVD cap at forward
error 1.03e-08, while the same solver with the Borsdorf--Higham line search converges in
**4 EVDs** to 1.49e-13 — a 75x cost difference and five orders of accuracy, from a line
search detail alone. Until now the stall had only been shown on the constructed family.
It does not occur on cor1399 (naive Newton converges in 13 EVDs), so it is
matrix-dependent rather than universal. Note the cap here is the opt-in
`--cap-naive-newton` budget, so this run is censored by construction; the uncapped smoke
test reached 3164 EVDs.

**Timing caveats.** Real-matrix timing was run at matched tolerance only, so there is no
native-rule spread on real data; that PENDING in §6 cannot be filled from this chain.
Dykstra-APM is censored on cor1399.

### D6. bccd16 withdrawn (2026-09-12 00:42)
bccd16 (n=3250) was started at 20:12 and stopped after 4h having written **zero** solver
rows: it was still inside the reference solve, which drives Newton to 1e-13 and is not
covered by the `--max-evds` cap applied to the benchmarked solvers. At about 17 s per EVD
this was projected to run many further hours and was blocking the three timing stages.
It is reported as attempted and withdrawn for cost, not as a result. cor3120 was not run
(D4). The real-matrix set is therefore n = 94 and n = 1399. This is itself an instance of
the paper's argument: at large n an exact or high-accuracy reference is expensive, which
is precisely why the synthetic family with a closed-form X* is useful.

### D2. n=500 timing subset (planned)
Timing at n=500 will use 18 instances: seed p0 × all (r, m) × delta ∈ {1e-2, 0}
(`n500_timing_subset.txt`), with `--dykstra-maxit 800`, matched 1e-11 then native, run
sequentially with nothing else running.
