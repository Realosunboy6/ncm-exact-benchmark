# Paper 2 Sec. 5 - ranking under different conventions

Instances: 270 (n=500). Solvers: Newton-SIN-BH, AGD-SDAJ-BH, AGD-SDAJ, SBB-Dual, Dykstra-APM.

## 1. Native stopping rules

Each solver run to its own exit. This is the comparison a paper reporting
"iterations to convergence" would make, and it credits a solver for
stopping early rather than for being accurate.

| solver | median EVDs | min | max | median final err |
|---|---:|---:|---:|---:|
| Newton-SIN-BH | 5 | 4 | 15 | 1.21e-12 |
| AGD-SDAJ-BH | 107 | 54 | 240 | 2.56e-11 |
| AGD-SDAJ | 131 | 63 | 4039 | 2.73e-11 |
| SBB-Dual | 272 | 92 | 1075 | 4.82e-11 |
| Dykstra-APM | 550 | 193 | 800 | 4.90e-11 |

Achieved accuracy differs across solvers at their native exits, so these
costs are NOT comparable; that is what the remaining sections correct for.

## 2. Common forward error ||X-X*||_F <= eps (exact X*)

| eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | winner | n reached |
|---|---:|---:|---:|---:|---:|---|---|
| 1e-02 | 3 | 9 | 9 | 44 | 87 | **Newton-SIN-BH** | Newton:270 AGD:270 AGD:270 SBB:270 Dykstra:270 |
| 1e-04 | 4 | 30 | 30 | 97 | 195 | **Newton-SIN-BH** | Newton:270 AGD:270 AGD:270 SBB:270 Dykstra:270 |
| 1e-06 | 4 | 51 | 52 | 152 | 191 | **Newton-SIN-BH** | Newton:270 AGD:240 AGD:237 SBB:270 Dykstra:180 |
| 1e-08 | 5 | 76 | 84 | 208 | 258 | **Newton-SIN-BH** | Newton:270 AGD:212 AGD:199 SBB:270 Dykstra:180 |
| 1e-10 | 5 | 101 | 117 | 260 | 326 | **Newton-SIN-BH** | Newton:270 AGD:196 AGD:165 SBB:261 Dykstra:180 |

## 3. Common dual residual ||grad theta||_2 <= tau

| tau | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | winner | n reached |
|---|---:|---:|---:|---:|---:|---|---|
| 1e-02 | 2 | 9 | 9 | 26 | 51 | **Newton-SIN-BH** | Newton:270 AGD:265 AGD:265 SBB:270 Dykstra:270 |
| 1e-04 | 3 | 23 | 23 | 79 | 158 | **Newton-SIN-BH** | Newton:270 AGD:258 AGD:258 SBB:270 Dykstra:270 |
| 1e-06 | 4 | 47 | 47 | 132 | 229 | **Newton-SIN-BH** | Newton:270 AGD:263 AGD:262 SBB:270 Dykstra:205 |
| 1e-08 | 5 | 70 | 75 | 188 | 238 | **Newton-SIN-BH** | Newton:270 AGD:213 AGD:213 SBB:270 Dykstra:180 |
| 1e-10 | 5 | 92 | 105 | 244 | 305 | **Newton-SIN-BH** | Newton:270 AGD:200 AGD:179 SBB:270 Dykstra:180 |

## 4. Accepted-only vs all-trial accounting

Under all-trial accounting a REJECTED line-search trial may be credited with
reaching the target. Rejected trials cost EVDs under both rules; the question
is only whether they earn accuracy credit. Rows shown only where the median
changed.

| eps | solver | accepted-only | all-trial | delta |
|---|---|---:|---:|---:|
| 1e-04 | AGD-SDAJ-BH | 30.0 | 32.0 | +2.0 |
| 1e-04 | AGD-SDAJ | 30.0 | 32.0 | +2.0 |
| 1e-06 | AGD-SDAJ-BH | 51.0 | 49.5 | -1.5 |
| 1e-06 | AGD-SDAJ | 52.0 | 50.0 | -2.0 |
| 1e-08 | AGD-SDAJ | 84.0 | 83.5 | -0.5 |
| 1e-10 | AGD-SDAJ-BH | 101.0 | 103.0 | +2.0 |
| 1e-10 | AGD-SDAJ | 117.0 | 118.0 | +1.0 |

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
| Newton-SIN-BH | -1.55e-14 | -7.69e-14 | 1.83e-14 | 8.62e-12 |
| AGD-SDAJ-BH | -1.53e-14 | -8.61e-14 | 2.48e-12 | 7.08e-12 |
| AGD-SDAJ | -1.51e-14 | -7.25e-14 | 2.50e-12 | 2.46e-07 |
| SBB-Dual | -1.54e-14 | -7.76e-14 | 0.00e+00 | 0.00e+00 |
| Dykstra-APM | -1.52e-14 | -7.30e-14 | 5.58e-13 | 3.77e-07 |

## 7. Ranking by degeneracy cell

Aggregate medians can hide a regime-dependent reversal. The KKT family
controls rank r, near-zero multiplicity m and separation delta exactly so
this can be checked: if any ordering flips, it should flip in the degenerate
corner (small delta, large m), not on average. Target: forward 1e-08.

54 cells, **6** distinct orderings.

| ordering (cheapest first) | cells | example |
|---|---:|---|
| Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM | 26 | r=20 m=1 d=0 |
| Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual | 16 | r=5 m=1 d=0 |
| Newton-SIN-BH < AGD-SDAJ < AGD-SDAJ-BH < SBB-Dual < Dykstra-APM | 5 | r=20 m=1 d=1e-10 |
| Newton-SIN-BH < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM | 3 | r=50 m=20 d=0 |
| Newton-SIN-BH < AGD-SDAJ < AGD-SDAJ-BH < SBB-Dual | 2 | r=5 m=1 d=0.0001 |
| Newton-SIN-BH < AGD-SDAJ-BH < SBB-Dual < AGD-SDAJ < Dykstra-APM | 2 | r=50 m=20 d=1e-06 |

Orderings DO differ by regime. The cells that differ from the majority
ordering are the paper's exhibit; report them with their (r, m, delta).

## 8. Exit reasons

| solver | exit | count |
|---|---|---:|
| Newton-SIN-BH | converged | 270 |
| AGD-SDAJ-BH | diag_feasible | 182 |
| AGD-SDAJ-BH | diag_feasible_at_xpre | 88 |
| AGD-SDAJ | diag_feasible | 145 |
| AGD-SDAJ | diag_feasible_at_xpre | 94 |
| AGD-SDAJ | evd_budget | 31 |
| SBB-Dual | diag_feasible | 270 |
| Dykstra-APM | diag_feasible | 180 |
| Dykstra-APM | max_iter | 90 |

## 12. Sections 2 and 7 recomputed with the corrected reach rule

`cost_to` (Secs. 2-7) scores a run 'not reached' if its first sub-eps dip is
not held, even if it later settles below eps. Corrected: cost = EVDs at the
start of the final sub-eps suffix. Sections 9-11 below also use this rule.

| eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | ordering (cheapest first) |
|---|---:|---:|---:|---:|---:|---|
| 1e-02 | 3.0 (270/270) | 9.0 (270/270) | 9.0 (270/270) | 44.0 (270/270) | 87.0 (270/270) | Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM |
| 1e-04 | 4.0 (270/270) | 30.0 (270/270) | 30.0 (270/270) | 97.0 (270/270) | 195.0 (270/270) | Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM |
| 1e-06 | 4.0 (270/270) | 53.5 (270/270) | 55.5 (268/270) | 152.0 (270/270) | 191.0 (180/270) | Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM |
| 1e-08 | 5.0 (270/270) | 79.0 (270/270) | 87.0 (259/270) | 207.5 (270/270) | 258.0 (180/270) | Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM |
| 1e-10 | 5.0 (270/270) | 101.5 (270/270) | 119.0 (242/270) | 260.0 (261/270) | 325.5 (180/270) | Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM |

Per-cell at forward 1e-08, corrected rule: 54 cells, **7** distinct orderings (Sec. 7: 6); cells whose ordering changed: 8.

| ordering (cheapest first) | cells | example |
|---|---:|---|
| Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM | 28 | r=20 m=1 d=0 |
| Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual | 16 | r=5 m=1 d=0 |
| Newton-SIN-BH < AGD-SDAJ-BH < SBB-Dual < AGD-SDAJ < Dykstra-APM | 3 | r=50 m=20 d=0.0001 |
| Newton-SIN-BH < AGD-SDAJ < AGD-SDAJ-BH < SBB-Dual < Dykstra-APM | 2 | r=20 m=5 d=1e-06 |
| Newton-SIN-BH < AGD-SDAJ < AGD-SDAJ-BH < SBB-Dual | 2 | r=5 m=20 d=1e-06 |
| Newton-SIN-BH < SBB-Dual < AGD-SDAJ < AGD-SDAJ-BH < Dykstra-APM | 2 | r=50 m=20 d=1e-08 |
| Newton-SIN-BH < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM | 1 | r=50 m=20 d=0 |

## 9. Cluster-bootstrap CIs on median EVDs to forward target

B=2000, seed=20260911. Resampling unit: the paired seed within rank (all
18 (m, delta) cells of a drawn pair come together), which respects the
pairing of the design. Percentile 95% intervals. Medians are over the
instances that reached and held the target (as in Sec. 2), so they are
conditioned on the reached subset wherever reach < total.

| eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM |
|---|---|---|---|---|---|
| 1e-02 | 3.0 [3.0, 3.0] (270/270) | 9.0 [9.0, 9.0] (270/270) | 9.0 [9.0, 9.0] (270/270) | 44.0 [44.0, 44.0] (270/270) | 87.0 [86.5, 88.0] (270/270) |
| 1e-04 | 4.0 [3.0, 4.0] (270/270) | 30.0 [29.0, 32.0] (270/270) | 30.0 [29.0, 32.0] (270/270) | 97.0 [97.0, 97.0] (270/270) | 195.0 [194.5, 195.5] (270/270) |
| 1e-06 | 4.0 [4.0, 4.0] (270/270) | 53.5 [50.5, 56.0] (270/270) | 55.5 [52.0, 58.0] (268/270) | 152.0 [152.0, 152.0] (270/270) | 191.0 [191.0, 192.0] (180/270) |
| 1e-08 | 5.0 [5.0, 5.0] (270/270) | 79.0 [76.0, 80.0] (270/270) | 87.0 [84.0, 89.0] (259/270) | 207.5 [207.0, 208.0] (270/270) | 258.0 [258.0, 260.0] (180/270) |
| 1e-10 | 5.0 [5.0, 5.0] (270/270) | 101.5 [98.5, 105.0] (270/270) | 119.0 [117.0, 123.0] (242/270) | 260.0 [259.0, 262.0] (261/270) | 325.5 [325.0, 327.5] (180/270) |

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
| 1e-02 | 270 | 0 | 0 | 0 | 35.0 [35.0, 35.0] | 0.000 | 0 | 1.05e-81 | 0 / 270 | 1.05e-81 |
| 1e-04 | 270 | 0 | 0 | 0 | 69.5 [60.5, 71.0] | 0.011 | 0 | 3.46e-75 | 3 / 267 | 3.46e-75 |
| 1e-06 | 270 | 0 | 0 | 0 | 98.0 [93.5, 101.5] | 0.026 | 0 | 2.08e-68 | 7 / 263 | 2.08e-68 |
| 1e-08 | 270 | 0 | 0 | 0 | 129.0 [120.5, 131.0] | 0.056 | 1 | 3.22e-57 | 15 / 254 | 3.22e-57 |
| 1e-10 | 261 | 0 | 9 | 0 | 154.0 [150.0, 160.0] | 0.069 | 1 | 2.94e-51 | 18 / 251 | 1.08e-53 |

By rank (SBB-Dual vs AGD-SDAJ-BH): median d over 'both' and frac SBB cheaper

| eps | r=5 | r=20 | r=50 |
|---|---|---|---|
| 1e-02 | +96.5 (0.00, n=90) | +35.0 (0.00, n=90) | +13.0 (0.00, n=90) |
| 1e-04 | +283.0 (0.00, n=90) | +69.5 (0.00, n=90) | +14.0 (0.03, n=90) |
| 1e-06 | +471.0 (0.00, n=90) | +98.0 (0.00, n=90) | +13.5 (0.08, n=90) |
| 1e-08 | +669.5 (0.00, n=90) | +129.0 (0.00, n=90) | +13.0 (0.17, n=90) |
| 1e-10 | +859.0 (0.00, n=81) | +158.0 (0.00, n=90) | +11.5 (0.20, n=90) |

### SBB-Dual vs AGD-SDAJ

| eps | both | SBB only | AGD only | neither | median d [95% CI] | frac SBB cheaper (both) | ties | sign test p (both) | SBB wins / losses incl. failures | sign test p (fail-as-loss) |
|---|---:|---:|---:|---:|---|---:|---:|---:|---|---:|
| 1e-02 | 270 | 0 | 0 | 0 | 35.0 [35.0, 35.0] | 0.000 | 0 | 1.05e-81 | 0 / 270 | 1.05e-81 |
| 1e-04 | 270 | 0 | 0 | 0 | 69.5 [60.5, 71.0] | 0.011 | 0 | 3.46e-75 | 3 / 267 | 3.46e-75 |
| 1e-06 | 268 | 2 | 0 | 0 | 96.5 [91.0, 99.0] | 0.037 | 0 | 1.95e-63 | 12 / 258 | 2.70e-61 |
| 1e-08 | 259 | 11 | 0 | 0 | 117.0 [112.0, 119.0] | 0.131 | 1 | 1.75e-35 | 45 / 224 | 9.70e-30 |
| 1e-10 | 234 | 27 | 8 | 1 | 137.5 [129.0, 145.5] | 0.175 | 2 | 2.47e-24 | 68 / 199 | 4.45e-16 |

By rank (SBB-Dual vs AGD-SDAJ): median d over 'both' and frac SBB cheaper

| eps | r=5 | r=20 | r=50 |
|---|---|---|---|
| 1e-02 | +96.5 (0.00, n=90) | +35.0 (0.00, n=90) | +13.0 (0.00, n=90) |
| 1e-04 | +283.0 (0.00, n=90) | +69.5 (0.00, n=90) | +14.0 (0.03, n=90) |
| 1e-06 | +464.5 (0.00, n=90) | +96.0 (0.01, n=89) | +13.0 (0.10, n=89) |
| 1e-08 | +653.0 (0.00, n=85) | +118.0 (0.03, n=86) | +7.0 (0.35, n=88) |
| 1e-10 | +832.0 (0.00, n=72) | +142.5 (0.06, n=80) | +5.0 (0.44, n=82) |

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
| r=5 m=1 d=0 | N < Abh < A < S | 0.870 | 5 | N < Abh = A < S |
| r=5 m=1 d=1e-10 | N < Abh < A < S | 0.807 | 5 | N < Abh = A < S |
| r=5 m=1 d=1e-08 | N < Abh < A < S | 0.942 | 5 | N < Abh = A < S |
| r=5 m=1 d=1e-06 | N < Abh < A < S | 0.556 | 5 | N < Abh = A < S |
| r=5 m=1 d=0.0001 | N < Abh < A < S | 0.810 | 5 | N < Abh = A < S |
| r=5 m=1 d=0.01 | N < Abh < A < S | 1.000 | 6 | N < Abh < A < S |
| r=5 m=5 d=0 | N < Abh < A < S | 0.778 | 4 | N < Abh = A = S |
| r=5 m=5 d=1e-10 | N < Abh < A < S | 0.811 | 5 | N < Abh = A < S |
| r=5 m=5 d=1e-08 | N < Abh < A < S | 0.947 | 5 | N < Abh = A < S |
| r=5 m=5 d=1e-06 | N < Abh < A < S | 0.950 | 5 | N < Abh = A < S |
| r=5 m=5 d=0.0001 | N < Abh < A < S | 1.000 | 6 | N < Abh < A < S |
| r=5 m=5 d=0.01 | N < Abh < A < S | 1.000 | 5 | N < Abh = A < S |
| r=5 m=20 d=0 | N < Abh < A < S | 1.000 | 5 | N < Abh < A = S |
| r=5 m=20 d=1e-10 | N < Abh < A < S | 0.946 | 5 | N < Abh = A < S |
| r=5 m=20 d=1e-08 | N < A < Abh < S | 0.760 | 4 | N < A = Abh < S |
| r=5 m=20 d=1e-06 | N < A < Abh < S | 0.269 | 5 | N < A < Abh < S |
| r=5 m=20 d=0.0001 | N < Abh < A < S | 0.742 | 5 | N < Abh = A < S |
| r=5 m=20 d=0.01 | N < Abh < A < S | 0.949 | 4 | N < Abh = A = S |
| r=20 m=1 d=0 | N < Abh < A < S < D | 1.000 | 10 | N < Abh < A < S < D |
| r=20 m=1 d=1e-10 | N < Abh < A < S < D | 0.746 | 9 | N < Abh = A < S < D |
| r=20 m=1 d=1e-08 | N < Abh < A < S < D | 0.746 | 9 | N < Abh = A < S < D |
| r=20 m=1 d=1e-06 | N < Abh < A < S < D | 0.871 | 7 | N < Abh = A = S < D |
| r=20 m=1 d=0.0001 | N < Abh < A < S < D | 0.810 | 9 | N < Abh = A < S < D |
| r=20 m=1 d=0.01 | N < Abh < A < S < D | 0.940 | 9 | N < Abh = A < S < D |
| r=20 m=5 d=0 | N < Abh < A < S < D | 1.000 | 10 | N < Abh < A < S < D |
| r=20 m=5 d=1e-10 | N < Abh < A < S < D | 1.000 | 10 | N < Abh < A < S < D |
| r=20 m=5 d=1e-08 | N < Abh < A < S < D | 0.944 | 9 | N < Abh = A < S < D |
| r=20 m=5 d=1e-06 | N < A < Abh < S < D | 0.874 | 9 | N < A = Abh < S < D |
| r=20 m=5 d=0.0001 | N < Abh < A < S < D | 1.000 | 7 | N < Abh = A = S < D |
| r=20 m=5 d=0.01 | N < Abh < A < S < D | 1.000 | 10 | N < Abh < A < S < D |
| r=20 m=20 d=0 | N < Abh < A < S < D | 0.948 | 9 | N < Abh < A = S < D |
| r=20 m=20 d=1e-10 | N < Abh < A < S < D | 1.000 | 9 | N < Abh = A < S < D |
| r=20 m=20 d=1e-08 | N < Abh < A < S < D | 0.907 | 8 | N < Abh < A = S < D |
| r=20 m=20 d=1e-06 | N < Abh < A < S < D | 0.865 | 9 | N < Abh = A < S < D |
| r=20 m=20 d=0.0001 | N < Abh < A < S < D | 0.797 | 7 | N < Abh = A = S < D |
| r=20 m=20 d=0.01 | N < Abh < A < S < D | 0.884 | 8 | N < Abh = A = S < D |
| r=50 m=1 d=0 | N < Abh < A < S < D | 0.745 | 9 | N < Abh = A < S < D |
| r=50 m=1 d=1e-10 | N < Abh < A < S < D | 0.941 | 8 | N < Abh = A = S < D |
| r=50 m=1 d=1e-08 | N < Abh < A < S < D | 1.000 | 9 | N < Abh = A < S < D |
| r=50 m=1 d=1e-06 | N < A < Abh < S < D | 0.402 | 7 | N < A = Abh < S < D |
| r=50 m=1 d=0.0001 | N < Abh < A < S < D | 0.932 | 9 | N < Abh = A < S < D |
| r=50 m=1 d=0.01 | N < Abh < A < S < D | 0.816 | 9 | N < Abh = A < S < D |
| r=50 m=5 d=0 | N < Abh < A < S < D | 0.473 | 7 | N < Abh = A = S < D |
| r=50 m=5 d=1e-10 | N < Abh < A < S < D | 0.673 | 8 | N < Abh = A = S < D |
| r=50 m=5 d=1e-08 | N < Abh < A < S < D | 0.643 | 6 | N < Abh = A = S < D |
| r=50 m=5 d=1e-06 | N < Abh < S < A < D | 0.689 | 9 | N < Abh < S = A < D |
| r=50 m=5 d=0.0001 | N < Abh < A < S < D | 0.950 | 8 | N < Abh = A = S < D |
| r=50 m=5 d=0.01 | N < Abh < A < S < D | 0.662 | 8 | N < Abh = A = S < D |
| r=50 m=20 d=0 | N < S < Abh < A < D | 0.938 | 8 | N < S = Abh < A < D |
| r=50 m=20 d=1e-10 | N < S < A < Abh < D | 0.353 | 7 | N < S < A = Abh < D |
| r=50 m=20 d=1e-08 | N < S < A < Abh < D | 0.377 | 7 | N < S = A = Abh < D |
| r=50 m=20 d=1e-06 | N < Abh < S < A < D | 0.884 | 8 | N < Abh = S = A < D |
| r=50 m=20 d=0.0001 | N < Abh < S < A < D | 0.934 | 8 | N < Abh < S = A = D |
| r=50 m=20 d=0.01 | N < Abh < A < S < D | 0.751 | 7 | N < Abh = A = S < D |

N=Newton-SIN-BH, Abh=AGD-SDAJ-BH, A=AGD-SDAJ, S=SBB-Dual, D=Dykstra-APM.

- Observed distinct orderings (Sec. 7): **7** over 54 cells.
- Median reproduce fraction across cells: **0.879**; cells with reproduce >= 0.5: 49; >= 0.8: 36.
- Cells whose full 5-solver ordering is resolved (all adjacent pairs): **7**; all 10 pairs resolved: 4.
- Distinct observed orderings realised by at least one fully-resolved cell: **3** of 7.
- Distinct tie-aware orderings: **17**.

| tie-aware ordering | cells |
|---|---:|
| N < Abh = A < S | 11 |
| N < Abh = A < S < D | 11 |
| N < Abh = A = S < D | 11 |
| N < Abh < A < S < D | 4 |
| N < Abh < A < S | 2 |
| N < Abh = A = S | 2 |
| N < A = Abh < S < D | 2 |
| N < Abh < A = S < D | 2 |
| N < Abh < A = S | 1 |
| N < A = Abh < S | 1 |
| N < A < Abh < S | 1 |
| N < Abh < S = A < D | 1 |
| N < S = Abh < A < D | 1 |
| N < S < A = Abh < D | 1 |
| N < S = A = Abh < D | 1 |
| N < Abh = S = A < D | 1 |
| N < Abh < S = A = D | 1 |

Resolved status of the pairwise orders the narrative relies on (cells where
the pair is resolved in each direction / unresolved):

| pair | first cheaper (resolved) | second cheaper (resolved) | unresolved |
|---|---:|---:|---:|
| SBB-Dual vs AGD-SDAJ-BH | 0 | 47 | 7 |
| SBB-Dual vs AGD-SDAJ | 1 | 29 | 24 |
| AGD-SDAJ-BH vs Dykstra-APM | 36 | 0 | 18 |
| AGD-SDAJ vs Dykstra-APM | 28 | 0 | 26 |
| AGD-SDAJ-BH vs AGD-SDAJ | 14 | 0 | 40 |
| Newton-SIN-BH vs SBB-Dual | 54 | 0 | 0 |

