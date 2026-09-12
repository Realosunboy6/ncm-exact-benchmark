# Paper 2 Sec. 5 - ranking under different conventions

Instances: 162 (n=500). Solvers: Newton-SIN-BH, AGD-SDAJ-BH, AGD-SDAJ, SBB-Dual, Dykstra-APM.

## 1. Native stopping rules

Each solver run to its own exit. This is the comparison a paper reporting
"iterations to convergence" would make, and it credits a solver for
stopping early rather than for being accurate.

| solver | median EVDs | min | max | median final err |
|---|---:|---:|---:|---:|
| Newton-SIN-BH | 5 | 4 | 15 | 1.22e-12 |
| AGD-SDAJ-BH | 106 | 54 | 240 | 2.60e-11 |
| AGD-SDAJ | 133 | 69 | 4039 | 2.74e-11 |
| SBB-Dual | 272 | 92 | 1075 | 4.77e-11 |
| Dykstra-APM | 550 | 193 | 800 | 4.89e-11 |

Achieved accuracy differs across solvers at their native exits, so these
costs are NOT comparable; that is what the remaining sections correct for.

## 2. Common forward error ||X-X*||_F <= eps (exact X*)

| eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | winner | n reached |
|---|---:|---:|---:|---:|---:|---|---|
| 1e-02 | 3 | 9 | 9 | 44 | 87 | **Newton-SIN-BH** | Newton:162 AGD:162 AGD:162 SBB:162 Dykstra:162 |
| 1e-04 | 4 | 30 | 30 | 97 | 195 | **Newton-SIN-BH** | Newton:162 AGD:162 AGD:162 SBB:162 Dykstra:162 |
| 1e-06 | 4 | 51 | 54 | 152 | 191 | **Newton-SIN-BH** | Newton:162 AGD:141 AGD:138 SBB:162 Dykstra:108 |
| 1e-08 | 5 | 76 | 84 | 208 | 258 | **Newton-SIN-BH** | Newton:162 AGD:126 AGD:124 SBB:162 Dykstra:108 |
| 1e-10 | 5 | 99 | 111 | 261 | 326 | **Newton-SIN-BH** | Newton:162 AGD:118 AGD:100 SBB:158 Dykstra:108 |

## 3. Common dual residual ||grad theta||_2 <= tau

| tau | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | winner | n reached |
|---|---:|---:|---:|---:|---:|---|---|
| 1e-02 | 2 | 9 | 9 | 26 | 51 | **Newton-SIN-BH** | Newton:162 AGD:160 AGD:160 SBB:162 Dykstra:162 |
| 1e-04 | 3 | 23 | 23 | 79 | 158 | **Newton-SIN-BH** | Newton:162 AGD:154 AGD:154 SBB:162 Dykstra:162 |
| 1e-06 | 4 | 47 | 47 | 132 | 226 | **Newton-SIN-BH** | Newton:162 AGD:160 AGD:159 SBB:162 Dykstra:123 |
| 1e-08 | 5 | 70 | 76 | 188 | 238 | **Newton-SIN-BH** | Newton:162 AGD:129 AGD:124 SBB:162 Dykstra:108 |
| 1e-10 | 5 | 91 | 105 | 244 | 305 | **Newton-SIN-BH** | Newton:162 AGD:122 AGD:107 SBB:162 Dykstra:108 |

## 4. Accepted-only vs all-trial accounting

Under all-trial accounting a REJECTED line-search trial may be credited with
reaching the target. Rejected trials cost EVDs under both rules; the question
is only whether they earn accuracy credit. Rows shown only where the median
changed.

| eps | solver | accepted-only | all-trial | delta |
|---|---|---:|---:|---:|
| 1e-04 | AGD-SDAJ-BH | 30.0 | 31.0 | +1.0 |
| 1e-04 | AGD-SDAJ | 30.0 | 31.0 | +1.0 |
| 1e-06 | AGD-SDAJ-BH | 51.0 | 52.0 | +1.0 |
| 1e-06 | AGD-SDAJ | 53.5 | 52.0 | -1.5 |
| 1e-08 | AGD-SDAJ-BH | 75.5 | 74.0 | -1.5 |
| 1e-08 | AGD-SDAJ | 83.5 | 83.0 | -0.5 |
| 1e-10 | AGD-SDAJ-BH | 99.0 | 100.5 | +1.5 |
| 1e-10 | AGD-SDAJ | 111.0 | 118.0 | +7.0 |

## 5. Did the ranking actually reverse?

Observed **1** distinct orderings across 11 conventions.

| ordering (cheapest first) | conventions producing it |
|---|---|
| Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM | forward 1e-02, forward 1e-04, forward 1e-06, forward 1e-08, forward 1e-10, residual 1e-02, residual 1e-04, residual 1e-06, residual 1e-08, residual 1e-10, native |

**The winner is invariant: Newton-SIN-BH is cheapest under every convention
tested.** The conventions change cost RATIOS, not the ranking at the top.
This must be reported as a null result for winner-reversal, quantifying
the ratio spread instead of claiming a reversal that was not observed.

## 6. What each solver actually returns

Feasibility of the returned iterate. A solver returning a PSD half-iterate
and one returning a unit-diagonal half-iterate are not interchangeable.

| solver | median lambda_min(X) | worst lambda_min | median diag err | worst diag err |
|---|---:|---:|---:|---:|
| Newton-SIN-BH | -1.54e-14 | -7.69e-14 | 1.79e-14 | 8.62e-12 |
| AGD-SDAJ-BH | -1.51e-14 | -8.61e-14 | 2.63e-12 | 6.47e-12 |
| AGD-SDAJ | -1.50e-14 | -7.25e-14 | 2.62e-12 | 2.46e-07 |
| SBB-Dual | -1.50e-14 | -7.76e-14 | 0.00e+00 | 0.00e+00 |
| Dykstra-APM | -1.52e-14 | -7.30e-14 | 5.60e-13 | 3.77e-07 |

## 7. Ranking by degeneracy cell

Aggregate medians can hide a regime-dependent reversal. The KKT family
controls rank r, near-zero multiplicity m and separation delta exactly so
this can be checked: if any ordering flips, it should flip in the degenerate
corner (small delta, large m), not on average. Target: forward 1e-08.

54 cells, **6** distinct orderings.

| ordering (cheapest first) | cells | example |
|---|---:|---|
| Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM | 22 | r=20 m=1 d=0 |
| Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual | 14 | r=5 m=1 d=0 |
| Newton-SIN-BH < AGD-SDAJ < AGD-SDAJ-BH < SBB-Dual < Dykstra-APM | 10 | r=20 m=1 d=1e-08 |
| Newton-SIN-BH < AGD-SDAJ < AGD-SDAJ-BH < SBB-Dual | 4 | r=5 m=1 d=1e-10 |
| Newton-SIN-BH < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM | 2 | r=50 m=20 d=0 |
| Newton-SIN-BH < AGD-SDAJ-BH < SBB-Dual < AGD-SDAJ < Dykstra-APM | 2 | r=50 m=20 d=1e-08 |

Orderings DO differ by regime. The cells that differ from the majority
ordering are the paper's exhibit; report them with their (r, m, delta).

## 8. Exit reasons

| solver | exit | count |
|---|---|---:|
| Newton-SIN-BH | converged | 162 |
| AGD-SDAJ-BH | diag_feasible | 105 |
| AGD-SDAJ-BH | diag_feasible_at_xpre | 57 |
| AGD-SDAJ | diag_feasible | 88 |
| AGD-SDAJ | diag_feasible_at_xpre | 53 |
| AGD-SDAJ | evd_budget | 21 |
| SBB-Dual | diag_feasible | 162 |
| Dykstra-APM | diag_feasible | 108 |
| Dykstra-APM | max_iter | 54 |

## 12. Sections 2 and 7 recomputed with the corrected reach rule

`cost_to` (Secs. 2-7) scores a run 'not reached' if its first sub-eps dip is
not held, even if it later settles below eps. Corrected: cost = EVDs at the
start of the final sub-eps suffix. Sections 9-11 below also use this rule.

| eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | ordering (cheapest first) |
|---|---:|---:|---:|---:|---:|---|
| 1e-02 | 3.0 (162/162) | 9.0 (162/162) | 9.0 (162/162) | 44.0 (162/162) | 87.0 (162/162) | Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM |
| 1e-04 | 4.0 (162/162) | 30.0 (162/162) | 30.0 (162/162) | 97.0 (162/162) | 195.0 (162/162) | Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM |
| 1e-06 | 4.0 (162/162) | 54.0 (162/162) | 56.0 (160/162) | 152.0 (162/162) | 191.0 (108/162) | Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM |
| 1e-08 | 5.0 (162/162) | 79.0 (162/162) | 85.0 (154/162) | 207.5 (162/162) | 258.0 (108/162) | Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM |
| 1e-10 | 5.0 (162/162) | 101.0 (162/162) | 118.0 (144/162) | 261.0 (158/162) | 325.5 (108/162) | Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM |

Per-cell at forward 1e-08, corrected rule: 54 cells, **7** distinct orderings (Sec. 7: 6); cells whose ordering changed: 12.

| ordering (cheapest first) | cells | example |
|---|---:|---|
| Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM | 24 | r=20 m=1 d=0 |
| Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual | 15 | r=5 m=1 d=0 |
| Newton-SIN-BH < AGD-SDAJ < AGD-SDAJ-BH < SBB-Dual < Dykstra-APM | 6 | r=20 m=1 d=1e-08 |
| Newton-SIN-BH < AGD-SDAJ < AGD-SDAJ-BH < SBB-Dual | 3 | r=5 m=20 d=1e-06 |
| Newton-SIN-BH < AGD-SDAJ-BH < SBB-Dual < AGD-SDAJ < Dykstra-APM | 3 | r=50 m=20 d=0.0001 |
| Newton-SIN-BH < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM | 2 | r=50 m=20 d=0 |
| Newton-SIN-BH < SBB-Dual < AGD-SDAJ < AGD-SDAJ-BH < Dykstra-APM | 1 | r=50 m=20 d=1e-08 |

## 9. Cluster-bootstrap CIs on median EVDs to forward target

B=2000, seed=20260911. Resampling unit: the paired seed within rank (all
18 (m, delta) cells of a drawn pair come together), which respects the
pairing of the design. Percentile 95% intervals. Medians are over the
instances that reached and held the target (as in Sec. 2), so they are
conditioned on the reached subset wherever reach < total.

| eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM |
|---|---|---|---|---|---|
| 1e-02 | 3.0 [3.0, 3.0] (162/162) | 9.0 [9.0, 9.0] (162/162) | 9.0 [9.0, 9.0] (162/162) | 44.0 [44.0, 44.0] (162/162) | 87.0 [86.0, 87.0] (162/162) |
| 1e-04 | 4.0 [3.0, 4.0] (162/162) | 30.0 [29.0, 31.0] (162/162) | 30.0 [29.0, 31.0] (162/162) | 97.0 [96.0, 97.5] (162/162) | 195.0 [193.0, 195.0] (162/162) |
| 1e-06 | 4.0 [4.0, 4.0] (162/162) | 54.0 [48.0, 57.5] (162/162) | 56.0 [52.0, 58.0] (160/162) | 152.0 [151.0, 152.0] (162/162) | 191.0 [191.0, 194.0] (108/162) |
| 1e-08 | 5.0 [5.0, 5.0] (162/162) | 79.0 [76.0, 80.0] (162/162) | 85.0 [83.0, 89.0] (154/162) | 207.5 [206.0, 208.0] (162/162) | 258.0 [257.5, 262.5] (108/162) |
| 1e-10 | 5.0 [5.0, 5.0] (162/162) | 101.0 [97.0, 103.0] (162/162) | 118.0 [114.0, 123.0] (144/162) | 261.0 [259.5, 263.0] (158/162) | 325.5 [325.0, 330.5] (108/162) |

## 10. Paired per-instance comparison: SBB-Dual vs AGD

d = EVDs(SBB-Dual) - EVDs(AGD) on the SAME instance; d < 0 means SBB is
cheaper. 'both' = instances where both reached and held the target; the
median, CI, fraction and sign test use only these. Instances where only one
reached are counted, not dropped: the 'fail-as-loss' sign test counts a
solver that failed while the other reached as the more expensive one.
Ties (d = 0) are excluded from sign tests. CI: cluster bootstrap as Sec. 9.

### SBB-Dual vs AGD-SDAJ-BH

| eps | both | SBB only | AGD only | neither | median d [95% CI] | frac SBB cheaper (both) | ties | sign test p (both) | SBB wins / losses incl. failures | sign test p (fail-as-loss) |
|---|---:|---:|---:|---:|---|---:|---:|---:|---|---:|
| 1e-02 | 162 | 0 | 0 | 0 | 35.0 [35.0, 35.0] | 0.000 | 0 | 3.42e-49 | 0 / 162 | 3.42e-49 |
| 1e-04 | 162 | 0 | 0 | 0 | 69.0 [59.0, 72.0] | 0.000 | 0 | 3.42e-49 | 0 / 162 | 3.42e-49 |
| 1e-06 | 162 | 0 | 0 | 0 | 96.0 [91.0, 100.0] | 0.025 | 0 | 9.70e-42 | 4 / 158 | 9.70e-42 |
| 1e-08 | 162 | 0 | 0 | 0 | 126.0 [116.0, 132.5] | 0.049 | 0 | 3.56e-36 | 8 / 154 | 3.56e-36 |
| 1e-10 | 158 | 0 | 4 | 0 | 157.0 [150.0, 162.0] | 0.057 | 1 | 1.47e-33 | 9 / 152 | 1.16e-34 |

By rank (SBB-Dual vs AGD-SDAJ-BH): median d over 'both' and frac SBB cheaper

| eps | r=5 | r=20 | r=50 |
|---|---|---|---|
| 1e-02 | +95.5 (0.00, n=54) | +35.0 (0.00, n=54) | +13.0 (0.00, n=54) |
| 1e-04 | +283.5 (0.00, n=54) | +69.0 (0.00, n=54) | +17.5 (0.00, n=54) |
| 1e-06 | +477.0 (0.00, n=54) | +96.0 (0.00, n=54) | +13.5 (0.07, n=54) |
| 1e-08 | +673.0 (0.00, n=54) | +126.0 (0.00, n=54) | +13.5 (0.15, n=54) |
| 1e-10 | +858.5 (0.00, n=50) | +158.0 (0.00, n=54) | +13.0 (0.17, n=54) |

### SBB-Dual vs AGD-SDAJ

| eps | both | SBB only | AGD only | neither | median d [95% CI] | frac SBB cheaper (both) | ties | sign test p (both) | SBB wins / losses incl. failures | sign test p (fail-as-loss) |
|---|---:|---:|---:|---:|---|---:|---:|---:|---|---:|
| 1e-02 | 162 | 0 | 0 | 0 | 35.0 [35.0, 35.0] | 0.000 | 0 | 3.42e-49 | 0 / 162 | 3.42e-49 |
| 1e-04 | 162 | 0 | 0 | 0 | 69.0 [59.0, 72.0] | 0.000 | 0 | 3.42e-49 | 0 / 162 | 3.42e-49 |
| 1e-06 | 160 | 2 | 0 | 0 | 95.0 [91.0, 97.0] | 0.037 | 0 | 3.02e-38 | 8 / 154 | 3.56e-36 |
| 1e-08 | 154 | 8 | 0 | 0 | 116.0 [110.0, 119.0] | 0.130 | 1 | 1.14e-21 | 28 / 133 | 1.44e-17 |
| 1e-10 | 141 | 17 | 3 | 1 | 135.0 [120.0, 148.0] | 0.177 | 2 | 8.91e-15 | 42 / 117 | 2.22e-09 |

By rank (SBB-Dual vs AGD-SDAJ): median d over 'both' and frac SBB cheaper

| eps | r=5 | r=20 | r=50 |
|---|---|---|---|
| 1e-02 | +95.5 (0.00, n=54) | +35.0 (0.00, n=54) | +13.0 (0.00, n=54) |
| 1e-04 | +283.5 (0.00, n=54) | +69.0 (0.00, n=54) | +17.5 (0.00, n=54) |
| 1e-06 | +469.0 (0.00, n=54) | +95.0 (0.00, n=53) | +11.0 (0.11, n=53) |
| 1e-08 | +639.5 (0.00, n=50) | +117.0 (0.02, n=51) | +7.0 (0.36, n=53) |
| 1e-10 | +831.0 (0.00, n=45) | +139.0 (0.07, n=46) | +4.0 (0.44, n=50) |

## 11. Per-cell ordering stability (target forward 1e-08)

Each (r, m, delta) cell has 5 paired seeds. Its 5 instances are resampled
with replacement (B=2000); the ordering is recomputed exactly as in Sec. 7
(median over instances that reached; a solver reaching on none is omitted).
'reproduce' = fraction of resamples giving the observed Sec. 7 ordering.
A pairwise order is RESOLVED only if the 95% bootstrap CI of the median
paired difference excludes 0; for these paired differences a solver that
failed to reach the target on an instance is given cost +inf (so failing is
worse than any finite cost; inf-inf counts as a tie). Unresolved adjacent
pairs in the observed ordering are shown as '='.

| cell (r,m,d) | observed ordering | reproduce | resolved pairs /10 | tie-aware ordering |
|---|---|---:|---:|---|
| r=5 m=1 d=0 | N < Abh < A < S | 1.000 | 6 | N < Abh < A < S |
| r=5 m=1 d=1e-10 | N < Abh < A < S | 0.747 | 5 | N < Abh = A < S |
| r=5 m=1 d=1e-08 | N < Abh < A < S | 0.742 | 5 | N < Abh = A < S |
| r=5 m=1 d=1e-06 | N < Abh < A < S | 0.735 | 5 | N < Abh = A < S |
| r=5 m=1 d=0.0001 | N < Abh < A < S | 1.000 | 6 | N < Abh < A < S |
| r=5 m=1 d=0.01 | N < Abh < A < S | 1.000 | 6 | N < Abh < A < S |
| r=5 m=5 d=0 | N < A < Abh < S | 0.854 | 4 | N < A = Abh < S |
| r=5 m=5 d=1e-10 | N < Abh < A < S | 1.000 | 6 | N < Abh < A < S |
| r=5 m=5 d=1e-08 | N < Abh < A < S | 1.000 | 6 | N < Abh < A < S |
| r=5 m=5 d=1e-06 | N < Abh < A < S | 1.000 | 6 | N < Abh < A < S |
| r=5 m=5 d=0.0001 | N < Abh < A < S | 1.000 | 6 | N < Abh < A < S |
| r=5 m=5 d=0.01 | N < Abh < A < S | 1.000 | 5 | N < Abh = A < S |
| r=5 m=20 d=0 | N < Abh < A < S | 1.000 | 6 | N < Abh < A < S |
| r=5 m=20 d=1e-10 | N < Abh < A < S | 0.745 | 5 | N < Abh = A < S |
| r=5 m=20 d=1e-08 | N < A < Abh < S | 0.613 | 4 | N < A = Abh < S |
| r=5 m=20 d=1e-06 | N < A < Abh < S | 0.337 | 5 | N < A < Abh < S |
| r=5 m=20 d=0.0001 | N < Abh < A < S | 0.744 | 5 | N < Abh = A < S |
| r=5 m=20 d=0.01 | N < Abh < A < S | 0.967 | 5 | N < Abh < A = S |
| r=20 m=1 d=0 | N < Abh < A < S < D | 1.000 | 10 | N < Abh < A < S < D |
| r=20 m=1 d=1e-10 | N < Abh < A < S < D | 1.000 | 10 | N < Abh < A < S < D |
| r=20 m=1 d=1e-08 | N < A < Abh < S < D | 0.472 | 9 | N < A = Abh < S < D |
| r=20 m=1 d=1e-06 | N < Abh < A < S < D | 0.605 | 8 | N < Abh < A = S < D |
| r=20 m=1 d=0.0001 | N < Abh < A < S < D | 0.742 | 9 | N < Abh = A < S < D |
| r=20 m=1 d=0.01 | N < Abh < A < S < D | 0.738 | 9 | N < Abh = A < S < D |
| r=20 m=5 d=0 | N < Abh < A < S < D | 1.000 | 10 | N < Abh < A < S < D |
| r=20 m=5 d=1e-10 | N < Abh < A < S < D | 1.000 | 10 | N < Abh < A < S < D |
| r=20 m=5 d=1e-08 | N < Abh < A < S < D | 1.000 | 10 | N < Abh < A < S < D |
| r=20 m=5 d=1e-06 | N < A < Abh < S < D | 0.733 | 9 | N < A = Abh < S < D |
| r=20 m=5 d=0.0001 | N < Abh < A < S < D | 0.963 | 7 | N < Abh = A = S < D |
| r=20 m=5 d=0.01 | N < Abh < A < S < D | 1.000 | 10 | N < Abh < A < S < D |
| r=20 m=20 d=0 | N < Abh < A < S < D | 1.000 | 10 | N < Abh < A < S < D |
| r=20 m=20 d=1e-10 | N < Abh < A < S < D | 1.000 | 9 | N < Abh = A < S < D |
| r=20 m=20 d=1e-08 | N < A < Abh < S < D | 0.320 | 8 | N < A < Abh < S < D |
| r=20 m=20 d=1e-06 | N < Abh < A < S < D | 1.000 | 9 | N < Abh = A < S < D |
| r=20 m=20 d=0.0001 | N < Abh < A < S < D | 1.000 | 10 | N < Abh < A < S < D |
| r=20 m=20 d=0.01 | N < Abh < A < S < D | 0.741 | 9 | N < Abh = A < S < D |
| r=50 m=1 d=0 | N < Abh < A < S < D | 1.000 | 10 | N < Abh < A < S < D |
| r=50 m=1 d=1e-10 | N < Abh < A < S < D | 0.740 | 9 | N < Abh < A = S < D |
| r=50 m=1 d=1e-08 | N < Abh < A < S < D | 1.000 | 9 | N < Abh = A < S < D |
| r=50 m=1 d=1e-06 | N < A < Abh < S < D | 0.456 | 7 | N < A = Abh < S < D |
| r=50 m=1 d=0.0001 | N < Abh < A < S < D | 0.731 | 9 | N < Abh = A < S < D |
| r=50 m=1 d=0.01 | N < A < Abh < S < D | 0.473 | 9 | N < A = Abh < S < D |
| r=50 m=5 d=0 | N < Abh < S < A < D | 0.732 | 8 | N < Abh < S = A < D |
| r=50 m=5 d=1e-10 | N < A < Abh < S < D | 0.466 | 9 | N < A = Abh < S < D |
| r=50 m=5 d=1e-08 | N < Abh < A < S < D | 1.000 | 9 | N < Abh = A < S < D |
| r=50 m=5 d=1e-06 | N < Abh < A < S < D | 0.727 | 9 | N < Abh < A = S < D |
| r=50 m=5 d=0.0001 | N < Abh < A < S < D | 0.732 | 9 | N < Abh < A = S < D |
| r=50 m=5 d=0.01 | N < Abh < A < S < D | 0.737 | 8 | N < Abh = A = S < D |
| r=50 m=20 d=0 | N < S < Abh < A < D | 1.000 | 10 | N < S < Abh < A < D |
| r=50 m=20 d=1e-10 | N < S < Abh < A < D | 0.500 | 8 | N < S = Abh < A = D |
| r=50 m=20 d=1e-08 | N < S < A < Abh < D | 0.481 | 7 | N < S = A = Abh < D |
| r=50 m=20 d=1e-06 | N < Abh < S < A < D | 0.746 | 9 | N < Abh < S = A < D |
| r=50 m=20 d=0.0001 | N < Abh < S < A < D | 1.000 | 9 | N < Abh < S < A = D |
| r=50 m=20 d=0.01 | N < Abh < A < S < D | 0.485 | 7 | N < Abh = A = S < D |

N=Newton-SIN-BH, Abh=AGD-SDAJ-BH, A=AGD-SDAJ, S=SBB-Dual, D=Dykstra-APM.

- Observed distinct orderings (Sec. 7): **7** over 54 cells.
- Median reproduce fraction across cells: **0.800**; cells with reproduce >= 0.5: 46; >= 0.8: 27.
- Cells whose full 5-solver ordering is resolved (all adjacent pairs): **20**; all 10 pairs resolved: 10.
- Distinct observed orderings realised by at least one fully-resolved cell: **5** of 7.
- Distinct tie-aware orderings: **16**.

| tie-aware ordering | cells |
|---|---:|
| N < Abh < A < S < D | 9 |
| N < Abh < A < S | 8 |
| N < Abh = A < S < D | 8 |
| N < Abh = A < S | 6 |
| N < A = Abh < S < D | 5 |
| N < Abh < A = S < D | 4 |
| N < Abh = A = S < D | 3 |
| N < A = Abh < S | 2 |
| N < Abh < S = A < D | 2 |
| N < A < Abh < S | 1 |
| N < Abh < A = S | 1 |
| N < A < Abh < S < D | 1 |
| N < S < Abh < A < D | 1 |
| N < S = Abh < A = D | 1 |
| N < S = A = Abh < D | 1 |
| N < Abh < S < A = D | 1 |

Resolved status of the pairwise orders the narrative relies on (cells where
the pair is resolved in each direction / unresolved):

| pair | first cheaper (resolved) | second cheaper (resolved) | unresolved |
|---|---:|---:|---:|
| SBB-Dual vs AGD-SDAJ-BH | 1 | 50 | 3 |
| SBB-Dual vs AGD-SDAJ | 3 | 35 | 16 |
| AGD-SDAJ-BH vs Dykstra-APM | 36 | 0 | 18 |
| AGD-SDAJ vs Dykstra-APM | 30 | 0 | 24 |
| AGD-SDAJ-BH vs AGD-SDAJ | 28 | 0 | 26 |
| Newton-SIN-BH vs SBB-Dual | 54 | 0 | 0 |

