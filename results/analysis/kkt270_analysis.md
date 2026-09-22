# Paper 2 Sec. 5 - ranking under different conventions

**Sections 2, 3, 4, 5 and 7 below use `cost_to`, an earlier reach rule kept**
**verbatim for provenance (it scores a run 'not reached' on its first**
**sub-target dip even if it later settles below target). It does NOT match**
**the paper's definition (Sec. 3.2) and is superseded by `cost_to_fixed`.**
**Every number those sections' rule affects, and that the paper cites**
**(tab:fwd, tab:cells, tab:n500, tab:thesispert, the accounting-sensitivity**
**numbers of Sec. 5.12), comes instead from the corrected recomputation in**
**the second half of this file (from '## 12' on), not from Sections 2-5/7.**
**Sections 1 and 6 (native exit, feasibility) do not use `cost_to` and are**
**unaffected; tab:feas is read directly from Sec. 6.**

Instances: 270 (n=100). Solvers: Newton-SIN-BH, AGD-SDAJ-BH, AGD-SDAJ, SBB-Dual, Dykstra-APM, Anderson-APM.

## 1. Native stopping rules

Each solver run to its own exit. This is the comparison a paper reporting
"iterations to convergence" would make, and it credits a solver for
stopping early rather than for being accurate.

| solver | median EVDs | min | max | median final err |
|---|---:|---:|---:|---:|
| Newton-SIN-BH | 5 | 4 | 10 | 1.25e-13 |
| AGD-SDAJ-BH | 70 | 27 | 131 | 1.10e-11 |
| AGD-SDAJ | 82 | 34 | 4035 | 1.16e-11 |
| SBB-Dual | 46 | 13 | 218 | 1.74e-11 |
| Dykstra-APM | 102 | 24 | 443 | 1.98e-11 |
| Anderson-APM | 34 | 16 | 147 | 1.57e-11 |

Achieved accuracy differs across solvers at their native exits, so these
costs are NOT comparable; that is what the remaining sections correct for.

## 2. Common forward error ||X-X*||_F <= eps (exact X*)

| eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM | winner | n reached |
|---|---:|---:|---:|---:|---:|---:|---|---|
| 1e-02 | 3 | 6 | 6 | 8 | 15 | 5 | **Newton-SIN-BH** | Newton:270 AGD:270 AGD:270 SBB:270 Dykstra:270 Anderson:265 |
| 1e-04 | 4 | 14 | 14 | 16 | 34 | 11 | **Newton-SIN-BH** | Newton:270 AGD:270 AGD:270 SBB:270 Dykstra:270 Anderson:270 |
| 1e-06 | 4 | 28 | 28 | 24 | 54 | 18 | **Newton-SIN-BH** | Newton:270 AGD:269 AGD:269 SBB:270 Dykstra:270 Anderson:270 |
| 1e-08 | 5 | 43 | 45 | 34 | 74 | 24 | **Newton-SIN-BH** | Newton:270 AGD:217 AGD:202 SBB:270 Dykstra:270 Anderson:270 |
| 1e-10 | 5 | 59 | 70 | 44 | 96 | 32 | **Newton-SIN-BH** | Newton:270 AGD:208 AGD:198 SBB:270 Dykstra:270 Anderson:270 |

## 3. Common dual residual ||grad theta||_2 <= tau

| tau | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM | winner | n reached |
|---|---:|---:|---:|---:|---:|---:|---|---|
| 1e-02 | 2 | 5 | 5 | 7 | 12 | 5 | **Newton-SIN-BH** | Newton:270 AGD:270 AGD:270 SBB:270 Dykstra:270 Anderson:269 |
| 1e-04 | 3 | 13 | 13 | 14 | 30 | 10 | **Newton-SIN-BH** | Newton:270 AGD:270 AGD:270 SBB:270 Dykstra:270 Anderson:270 |
| 1e-06 | 4 | 27 | 27 | 23 | 50 | 17 | **Newton-SIN-BH** | Newton:270 AGD:270 AGD:270 SBB:270 Dykstra:270 Anderson:270 |
| 1e-08 | 5 | 39 | 42 | 32 | 71 | 24 | **Newton-SIN-BH** | Newton:270 AGD:228 AGD:210 SBB:270 Dykstra:270 Anderson:268 |
| 1e-10 | 5 | 57 | 65 | 42 | 92 | 31 | **Newton-SIN-BH** | Newton:270 AGD:219 AGD:199 SBB:270 Dykstra:270 Anderson:270 |

## 4. Accepted-only vs all-trial accounting

Under all-trial accounting a REJECTED line-search trial may be credited with
reaching the target. Rejected trials cost EVDs under both rules; the question
is only whether they earn accuracy credit. Rows shown only where the median
changed.

| eps | solver | accepted-only | all-trial | delta |
|---|---|---:|---:|---:|
| 1e-04 | AGD-SDAJ-BH | 14.0 | 13.5 | -0.5 |
| 1e-04 | AGD-SDAJ | 14.0 | 13.5 | -0.5 |
| 1e-08 | AGD-SDAJ-BH | 43.0 | 37.0 | -6.0 |
| 1e-08 | AGD-SDAJ | 45.0 | 42.5 | -2.5 |
| 1e-10 | AGD-SDAJ-BH | 59.0 | 56.0 | -3.0 |

## 5. Did the ranking actually reverse?

Observed **3** distinct orderings across 11 conventions.

| ordering (cheapest first) | conventions producing it |
|---|---|
| Newton-SIN-BH < Anderson-APM < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM | forward 1e-06, forward 1e-08, forward 1e-10, residual 1e-06, residual 1e-08, residual 1e-10, native |
| Newton-SIN-BH < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM | forward 1e-02, forward 1e-04, residual 1e-04 |
| Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < Anderson-APM < SBB-Dual < Dykstra-APM | residual 1e-02 |

**The winner is invariant: Newton-SIN-BH is cheapest under every convention
tested.** The conventions change cost RATIOS, not the ranking at the top.
This must be reported as a null result for winner-reversal, quantifying
the ratio spread instead of claiming a reversal that was not observed.

## 6. What each solver actually returns

Feasibility of the returned iterate. A solver returning a PSD half-iterate
and one returning a unit-diagonal half-iterate are not interchangeable.

| solver | median lambda_min(X) | worst lambda_min | median diag err | worst diag err |
|---|---:|---:|---:|---:|
| Newton-SIN-BH | -3.42e-15 | -1.25e-14 | 8.38e-15 | 5.70e-12 |
| AGD-SDAJ-BH | -3.40e-15 | -1.36e-14 | 2.53e-12 | 7.20e-12 |
| AGD-SDAJ | -3.40e-15 | -1.39e-14 | 2.79e-12 | 4.01e-08 |
| SBB-Dual | -3.42e-15 | -1.49e-14 | 0.00e+00 | 0.00e+00 |
| Dykstra-APM | -3.43e-15 | -1.36e-14 | 1.49e-12 | 9.37e-12 |
| Anderson-APM | -3.45e-15 | -1.36e-14 | 2.12e-12 | 7.50e-12 |

## 7. Ranking by degeneracy cell

Aggregate medians can hide a regime-dependent reversal. The KKT family
controls rank r, near-zero multiplicity m and separation delta exactly so
this can be checked: if any ordering flips, it should flip in the degenerate
corner (small delta, large m), not on average. Target: forward 1e-08.

54 cells, **13** distinct orderings.

| ordering (cheapest first) | cells | example |
|---|---:|---|
| Newton-SIN-BH < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM | 12 | r=5 m=1 d=0 |
| Newton-SIN-BH < SBB-Dual < Anderson-APM < Dykstra-APM < AGD-SDAJ-BH < AGD-SDAJ | 12 | r=20 m=20 d=1e-10 |
| Newton-SIN-BH < Anderson-APM < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM | 8 | r=20 m=1 d=0 |
| Newton-SIN-BH < SBB-Dual < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM | 7 | r=20 m=20 d=0 |
| Newton-SIN-BH < AGD-SDAJ-BH < Anderson-APM < AGD-SDAJ < SBB-Dual < Dykstra-APM | 3 | r=5 m=1 d=0.01 |
| Newton-SIN-BH < Anderson-APM < SBB-Dual < AGD-SDAJ < AGD-SDAJ-BH < Dykstra-APM | 3 | r=20 m=1 d=1e-08 |
| Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < Anderson-APM < SBB-Dual < Dykstra-APM | 2 | r=5 m=1 d=0.0001 |
| Newton-SIN-BH < Anderson-APM < AGD-SDAJ-BH < SBB-Dual < AGD-SDAJ < Dykstra-APM | 2 | r=20 m=1 d=0.0001 |
| Newton-SIN-BH < Anderson-APM < AGD-SDAJ < AGD-SDAJ-BH < SBB-Dual < Dykstra-APM | 1 | r=5 m=1 d=1e-10 |
| Newton-SIN-BH < Anderson-APM < AGD-SDAJ-BH < SBB-Dual < Dykstra-APM | 1 | r=5 m=20 d=0 |
| Newton-SIN-BH < SBB-Dual < Anderson-APM < AGD-SDAJ < AGD-SDAJ-BH < Dykstra-APM | 1 | r=20 m=20 d=1e-06 |
| Newton-SIN-BH < SBB-Dual < Anderson-APM < Dykstra-APM < AGD-SDAJ < AGD-SDAJ-BH | 1 | r=50 m=20 d=0 |
| Newton-SIN-BH < SBB-Dual < Anderson-APM < AGD-SDAJ-BH < Dykstra-APM < AGD-SDAJ | 1 | r=50 m=20 d=0.01 |

Orderings DO differ by regime. The cells that differ from the majority
ordering are the paper's exhibit; report them with their (r, m, delta).

## 8. Exit reasons

| solver | exit | count |
|---|---|---:|
| Newton-SIN-BH | converged | 270 |
| AGD-SDAJ-BH | diag_feasible | 177 |
| AGD-SDAJ-BH | diag_feasible_at_xpre | 93 |
| AGD-SDAJ | diag_feasible | 156 |
| AGD-SDAJ | diag_feasible_at_xpre | 96 |
| AGD-SDAJ | evd_budget | 18 |
| SBB-Dual | diag_feasible | 270 |
| Dykstra-APM | diag_feasible | 270 |
| Anderson-APM | diag_feasible | 270 |

## 12. Sections 2 and 7 recomputed with the corrected reach rule

`cost_to` (Secs. 2-7) scores a run 'not reached' if its first sub-eps dip is
not held, even if it later settles below eps. Corrected: cost = EVDs at the
start of the final sub-eps suffix. Sections 9-11 below also use this rule.

| eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM | ordering (cheapest first) |
|---|---:|---:|---:|---:|---:|---:|---|
| 1e-02 | 3.0 (270/270) | 6.0 (270/270) | 6.0 (270/270) | 8.0 (270/270) | 15.0 (270/270) | 5.0 (270/270) | Newton-SIN-BH < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM |
| 1e-04 | 4.0 (270/270) | 14.0 (270/270) | 14.0 (270/270) | 16.0 (270/270) | 33.5 (270/270) | 11.0 (270/270) | Newton-SIN-BH < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM |
| 1e-06 | 4.0 (270/270) | 28.0 (270/270) | 28.0 (270/270) | 24.5 (270/270) | 53.5 (270/270) | 18.0 (270/270) | Newton-SIN-BH < Anderson-APM < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM |
| 1e-08 | 5.0 (270/270) | 45.0 (270/270) | 50.0 (264/270) | 34.0 (270/270) | 74.5 (270/270) | 24.0 (270/270) | Newton-SIN-BH < Anderson-APM < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM |
| 1e-10 | 5.0 (270/270) | 63.5 (270/270) | 72.0 (253/270) | 43.5 (270/270) | 95.5 (270/270) | 32.0 (270/270) | Newton-SIN-BH < Anderson-APM < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM |

Per-cell at forward 1e-08, corrected rule: 54 cells, **10** distinct orderings (Sec. 7: 13); cells whose ordering changed: 15.

| ordering (cheapest first) | cells | r=5 | r=20 | r=50 | example |
|---|---:|---:|---:|---:|---|
| Newton-SIN-BH < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM | 16 | 15 | 1 | 0 | r=20 m=1 d=1e-10 |
| Newton-SIN-BH < SBB-Dual < Anderson-APM < Dykstra-APM < AGD-SDAJ-BH < AGD-SDAJ | 13 | 0 | 2 | 11 | r=20 m=20 d=1e-08 |
| Newton-SIN-BH < Anderson-APM < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM | 12 | 0 | 12 | 0 | r=20 m=1 d=0 |
| Newton-SIN-BH < SBB-Dual < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM | 7 | 0 | 1 | 6 | r=20 m=20 d=1e-06 |
| Newton-SIN-BH < Anderson-APM < AGD-SDAJ-BH < SBB-Dual < AGD-SDAJ < Dykstra-APM | 1 | 0 | 1 | 0 | r=20 m=1 d=0.0001 |
| Newton-SIN-BH < SBB-Dual < Anderson-APM < AGD-SDAJ-BH < Dykstra-APM < AGD-SDAJ | 1 | 0 | 1 | 0 | r=20 m=20 d=0 |
| Newton-SIN-BH < AGD-SDAJ < AGD-SDAJ-BH < Anderson-APM < SBB-Dual < Dykstra-APM | 1 | 1 | 0 | 0 | r=5 m=1 d=0.0001 |
| Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < Anderson-APM < SBB-Dual < Dykstra-APM | 1 | 1 | 0 | 0 | r=5 m=1 d=0.01 |
| Newton-SIN-BH < AGD-SDAJ-BH < Anderson-APM < AGD-SDAJ < SBB-Dual < Dykstra-APM | 1 | 1 | 0 | 0 | r=5 m=5 d=0 |
| Newton-SIN-BH < SBB-Dual < Anderson-APM < Dykstra-APM < AGD-SDAJ < AGD-SDAJ-BH | 1 | 0 | 0 | 1 | r=50 m=20 d=0.01 |

Accounting (Sec. 4) recomputed with the corrected reach rule. Rows shown only where the median changed.

| eps | solver | accepted-only | all-trial | delta |
|---|---|---:|---:|---:|
| 1e-04 | AGD-SDAJ-BH | 14.0 | 15.0 | +1.0 |
| 1e-04 | AGD-SDAJ | 14.0 | 15.0 | +1.0 |
| 1e-08 | AGD-SDAJ-BH | 45.0 | 46.5 | +1.5 |
| 1e-08 | AGD-SDAJ | 50.0 | 52.0 | +2.0 |
| 1e-10 | AGD-SDAJ-BH | 63.5 | 65.5 | +2.0 |
| 1e-10 | AGD-SDAJ | 72.0 | 74.0 | +2.0 |

## 9. Cluster-bootstrap CIs on median EVDs to forward target

B=2000, seed=20260911. Resampling unit: the paired seed within rank (all
18 (m, delta) cells of a drawn pair come together), which respects the
pairing of the design. Percentile 95% intervals. Medians are over the
instances that reached and held the target (as in Sec. 2), so they are
conditioned on the reached subset wherever reach < total.

| eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM |
|---|---|---|---|---|---|---|
| 1e-02 | 3.0 [3.0, 3.0] (270/270) | 6.0 [6.0, 6.5] (270/270) | 6.0 [6.0, 6.5] (270/270) | 8.0 [8.0, 8.0] (270/270) | 15.0 [15.0, 15.0] (270/270) | 5.0 [5.0, 5.0] (270/270) |
| 1e-04 | 4.0 [3.0, 4.0] (270/270) | 14.0 [13.0, 15.0] (270/270) | 14.0 [13.0, 15.0] (270/270) | 16.0 [15.5, 16.0] (270/270) | 33.5 [33.5, 33.5] (270/270) | 11.0 [11.0, 11.0] (270/270) |
| 1e-06 | 4.0 [4.0, 4.0] (270/270) | 28.0 [27.0, 29.0] (270/270) | 28.0 [27.0, 29.0] (270/270) | 24.5 [24.5, 24.5] (270/270) | 53.5 [53.5, 53.5] (270/270) | 18.0 [17.0, 18.5] (270/270) |
| 1e-08 | 5.0 [5.0, 5.0] (270/270) | 45.0 [42.0, 48.5] (270/270) | 50.0 [46.0, 52.0] (264/270) | 34.0 [34.0, 34.0] (270/270) | 74.5 [74.5, 74.5] (270/270) | 24.0 [24.0, 26.0] (270/270) |
| 1e-10 | 5.0 [5.0, 5.0] (270/270) | 63.5 [62.0, 66.0] (270/270) | 72.0 [70.0, 75.0] (253/270) | 43.5 [43.0, 43.5] (270/270) | 95.5 [95.5, 95.5] (270/270) | 32.0 [30.0, 34.0] (270/270) |

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
| 1e-02 | 270 | 0 | 0 | 0 | 2.0 [1.0, 2.0] | 0.404 | 10 | 1.09e-02 | 109 / 151 | 1.09e-02 |
| 1e-04 | 270 | 0 | 0 | 0 | 1.5 [-1.0, 2.0] | 0.485 | 3 | 8.07e-01 | 131 / 136 | 8.07e-01 |
| 1e-06 | 270 | 0 | 0 | 0 | -4.0 [-5.0, -4.0] | 0.541 | 3 | 1.42e-01 | 146 / 121 | 1.42e-01 |
| 1e-08 | 270 | 0 | 0 | 0 | -11.0 [-13.5, -9.0] | 0.619 | 0 | 1.18e-04 | 167 / 103 | 1.18e-04 |
| 1e-10 | 270 | 0 | 0 | 0 | -19.0 [-22.0, -17.0] | 0.656 | 0 | 3.57e-07 | 177 / 93 | 3.57e-07 |

By rank (SBB-Dual vs AGD-SDAJ-BH): median d over 'both' and frac SBB cheaper

| eps | r=5 | r=20 | r=50 |
|---|---|---|---|
| 1e-02 | +13.5 (0.00, n=90) | +2.0 (0.28, n=90) | -1.0 (0.93, n=90) |
| 1e-04 | +34.0 (0.00, n=90) | +1.5 (0.46, n=90) | -2.0 (1.00, n=90) |
| 1e-06 | +58.0 (0.00, n=90) | -5.0 (0.62, n=90) | -10.0 (1.00, n=90) |
| 1e-08 | +80.0 (0.00, n=90) | -16.0 (0.86, n=90) | -17.0 (1.00, n=90) |
| 1e-10 | +97.5 (0.00, n=90) | -25.5 (0.97, n=90) | -26.0 (1.00, n=90) |

### SBB-Dual vs AGD-SDAJ

| eps | both | SBB only | AGD only | neither | median d [95% CI] | frac SBB cheaper (both) | ties | sign test p (both) | SBB wins / losses incl. failures | sign test p (fail-as-loss) |
|---|---:|---:|---:|---:|---|---:|---:|---:|---|---:|
| 1e-02 | 270 | 0 | 0 | 0 | 2.0 [1.0, 2.0] | 0.404 | 10 | 1.09e-02 | 109 / 151 | 1.09e-02 |
| 1e-04 | 270 | 0 | 0 | 0 | 1.5 [-1.0, 2.0] | 0.485 | 3 | 8.07e-01 | 131 / 136 | 8.07e-01 |
| 1e-06 | 270 | 0 | 0 | 0 | -4.0 [-5.0, -4.0] | 0.541 | 3 | 1.42e-01 | 146 / 121 | 1.42e-01 |
| 1e-08 | 264 | 6 | 0 | 0 | -14.0 [-15.0, -12.0] | 0.640 | 2 | 3.09e-06 | 175 / 93 | 6.19e-07 |
| 1e-10 | 253 | 17 | 0 | 0 | -26.0 [-28.0, -24.0] | 0.688 | 0 | 2.24e-09 | 191 / 79 | 7.16e-12 |

By rank (SBB-Dual vs AGD-SDAJ): median d over 'both' and frac SBB cheaper

| eps | r=5 | r=20 | r=50 |
|---|---|---|---|
| 1e-02 | +13.5 (0.00, n=90) | +2.0 (0.28, n=90) | -1.0 (0.93, n=90) |
| 1e-04 | +34.0 (0.00, n=90) | +1.5 (0.46, n=90) | -2.0 (1.00, n=90) |
| 1e-06 | +58.0 (0.00, n=90) | -5.0 (0.62, n=90) | -10.0 (1.00, n=90) |
| 1e-08 | +75.0 (0.01, n=88) | -20.0 (0.91, n=87) | -18.0 (1.00, n=89) |
| 1e-10 | +85.0 (0.05, n=83) | -38.5 (1.00, n=82) | -30.0 (1.00, n=88) |

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
| r=5 m=1 d=0 | N < AA < Abh < A < S < D | 0.879 | 13 | N < AA = Abh < A < S < D |
| r=5 m=1 d=1e-10 | N < AA < Abh < A < S < D | 0.880 | 12 | N < AA = Abh = A < S < D |
| r=5 m=1 d=1e-08 | N < AA < Abh < A < S < D | 0.823 | 12 | N < AA = Abh = A < S < D |
| r=5 m=1 d=1e-06 | N < AA < Abh < A < S < D | 0.838 | 12 | N < AA = Abh = A < S < D |
| r=5 m=1 d=0.0001 | N < A < Abh < AA < S < D | 0.261 | 12 | N < A = Abh = AA < S < D |
| r=5 m=1 d=0.01 | N < Abh < A < AA < S < D | 0.603 | 13 | N < Abh < A = AA < S < D |
| r=5 m=5 d=0 | N < Abh < AA < A < S < D | 0.358 | 13 | N < Abh = AA = A < S < D |
| r=5 m=5 d=1e-10 | N < AA < Abh < A < S < D | 0.615 | 12 | N < AA = Abh = A < S < D |
| r=5 m=5 d=1e-08 | N < AA < Abh < A < S < D | 0.686 | 12 | N < AA = Abh = A < S < D |
| r=5 m=5 d=1e-06 | N < AA < Abh < A < S < D | 0.872 | 13 | N < AA = Abh = A < S < D |
| r=5 m=5 d=0.0001 | N < AA < Abh < A < S < D | 0.940 | 12 | N < AA = Abh = A < S < D |
| r=5 m=5 d=0.01 | N < AA < Abh < A < S < D | 0.885 | 13 | N < AA = Abh = A < S < D |
| r=5 m=20 d=0 | N < AA < Abh < A < S < D | 0.750 | 10 | N < AA = Abh = A = S < D |
| r=5 m=20 d=1e-10 | N < AA < Abh < A < S < D | 0.946 | 12 | N < AA = Abh = A < S < D |
| r=5 m=20 d=1e-08 | N < AA < Abh < A < S < D | 0.884 | 12 | N < AA = Abh = A < S < D |
| r=5 m=20 d=1e-06 | N < AA < Abh < A < S < D | 0.871 | 11 | N < AA = Abh < A = S < D |
| r=5 m=20 d=0.0001 | N < AA < Abh < A < S < D | 0.684 | 12 | N < AA = Abh = A < S < D |
| r=5 m=20 d=0.01 | N < AA < Abh < A < S < D | 0.825 | 12 | N < AA = Abh = A < S < D |
| r=20 m=1 d=0 | N < AA < S < Abh < A < D | 0.943 | 13 | N < AA < S = Abh = A < D |
| r=20 m=1 d=1e-10 | N < AA < Abh < A < S < D | 0.499 | 12 | N < AA < Abh = A = S < D |
| r=20 m=1 d=1e-08 | N < AA < S < Abh < A < D | 0.950 | 12 | N < AA < S = Abh = A < D |
| r=20 m=1 d=1e-06 | N < AA < S < Abh < A < D | 0.688 | 12 | N < AA < S = Abh = A < D |
| r=20 m=1 d=0.0001 | N < AA < Abh < S < A < D | 0.623 | 12 | N < AA < Abh = S = A < D |
| r=20 m=1 d=0.01 | N < AA < S < Abh < A < D | 0.686 | 11 | N < AA < S = Abh = A = D |
| r=20 m=5 d=0 | N < AA < S < Abh < A < D | 1.000 | 14 | N < AA < S < Abh = A < D |
| r=20 m=5 d=1e-10 | N < AA < S < Abh < A < D | 1.000 | 14 | N < AA < S < Abh = A < D |
| r=20 m=5 d=1e-08 | N < AA < S < Abh < A < D | 1.000 | 14 | N < AA < S < Abh = A < D |
| r=20 m=5 d=1e-06 | N < AA < S < Abh < A < D | 0.651 | 13 | N < AA < S < Abh = A = D |
| r=20 m=5 d=0.0001 | N < AA < S < Abh < A < D | 0.948 | 14 | N < AA < S < Abh < A = D |
| r=20 m=5 d=0.01 | N < AA < S < Abh < A < D | 0.672 | 12 | N < AA < S = Abh = A < D |
| r=20 m=20 d=0 | N < S < AA < Abh < D < A | 0.418 | 12 | N < S < AA < Abh = D = A |
| r=20 m=20 d=1e-10 | N < S < AA < D < Abh < A | 0.673 | 12 | N < S < AA < D = Abh = A |
| r=20 m=20 d=1e-08 | N < S < AA < D < Abh < A | 0.823 | 12 | N < S < AA < D = Abh = A |
| r=20 m=20 d=1e-06 | N < S < AA < Abh < A < D | 0.387 | 11 | N < S = AA < Abh = A = D |
| r=20 m=20 d=0.0001 | N < AA < S < Abh < A < D | 1.000 | 14 | N < AA < S < Abh = A < D |
| r=20 m=20 d=0.01 | N < AA < S < Abh < A < D | 0.911 | 13 | N < AA < S < Abh = A = D |
| r=50 m=1 d=0 | N < S < AA < Abh < A < D | 0.683 | 12 | N < S < AA < Abh = A = D |
| r=50 m=1 d=1e-10 | N < S < AA < Abh < A < D | 0.675 | 12 | N < S < AA < Abh = A = D |
| r=50 m=1 d=1e-08 | N < S < AA < Abh < A < D | 0.933 | 12 | N < S < AA < Abh = A = D |
| r=50 m=1 d=1e-06 | N < S < AA < Abh < A < D | 1.000 | 12 | N < S < AA < Abh = A = D |
| r=50 m=1 d=0.0001 | N < S < AA < Abh < A < D | 1.000 | 14 | N < S < AA < Abh = A < D |
| r=50 m=1 d=0.01 | N < S < AA < Abh < A < D | 0.681 | 12 | N < S < AA < Abh = A = D |
| r=50 m=5 d=0 | N < S < AA < D < Abh < A | 0.811 | 13 | N < S = AA < D < Abh = A |
| r=50 m=5 d=1e-10 | N < S < AA < D < Abh < A | 0.817 | 13 | N < S = AA < D < Abh = A |
| r=50 m=5 d=1e-08 | N < S < AA < D < Abh < A | 0.934 | 13 | N < S = AA < D < Abh = A |
| r=50 m=5 d=1e-06 | N < S < AA < D < Abh < A | 0.895 | 11 | N < S = AA < D = Abh = A |
| r=50 m=5 d=0.0001 | N < S < AA < D < Abh < A | 0.999 | 14 | N < S < AA < D < Abh = A |
| r=50 m=5 d=0.01 | N < S < AA < D < Abh < A | 0.679 | 11 | N < S = AA < D = Abh = A |
| r=50 m=20 d=0 | N < S < AA < D < Abh < A | 1.000 | 14 | N < S < AA < D < Abh = A |
| r=50 m=20 d=1e-10 | N < S < AA < D < Abh < A | 1.000 | 14 | N < S < AA < D < Abh = A |
| r=50 m=20 d=1e-08 | N < S < AA < D < Abh < A | 1.000 | 14 | N < S < AA < D < Abh = A |
| r=50 m=20 d=1e-06 | N < S < AA < D < Abh < A | 1.000 | 14 | N < S < AA < D < Abh = A |
| r=50 m=20 d=0.0001 | N < S < AA < D < Abh < A | 0.948 | 13 | N < S = AA < D < Abh = A |
| r=50 m=20 d=0.01 | N < S < AA < D < A < Abh | 0.344 | 13 | N < S < AA < D < A = Abh |

N=Newton-SIN-BH, Abh=AGD-SDAJ-BH, A=AGD-SDAJ, S=SBB-Dual, D=Dykstra-APM.

- Observed distinct orderings (Sec. 7): **10** over 54 cells.
- Median reproduce fraction across cells: **0.854**; cells with reproduce >= 0.5: 48; >= 0.8: 33.
- Cells whose full 5-solver ordering is resolved (all adjacent pairs): **0**; all 10 pairs resolved: 1.
- Distinct observed orderings realised by at least one fully-resolved cell: **0** of 10.
- Distinct tie-aware orderings: **23**.

| tie-aware ordering | cells |
|---|---:|
| N < AA = Abh = A < S < D | 12 |
| N < S < AA < Abh = A = D | 5 |
| N < S < AA < D < Abh = A | 5 |
| N < AA < S = Abh = A < D | 4 |
| N < AA < S < Abh = A < D | 4 |
| N < S = AA < D < Abh = A | 4 |
| N < AA < S < Abh = A = D | 2 |
| N < S < AA < D = Abh = A | 2 |
| N < S = AA < D = Abh = A | 2 |
| N < AA = Abh < A < S < D | 1 |
| N < A = Abh = AA < S < D | 1 |
| N < Abh < A = AA < S < D | 1 |
| N < Abh = AA = A < S < D | 1 |
| N < AA = Abh = A = S < D | 1 |
| N < AA = Abh < A = S < D | 1 |
| N < AA < Abh = A = S < D | 1 |
| N < AA < Abh = S = A < D | 1 |
| N < AA < S = Abh = A = D | 1 |
| N < AA < S < Abh < A = D | 1 |
| N < S < AA < Abh = D = A | 1 |
| N < S = AA < Abh = A = D | 1 |
| N < S < AA < Abh = A < D | 1 |
| N < S < AA < D < A = Abh | 1 |

Resolved status of the pairwise orders the narrative relies on (cells where
the pair is resolved in each direction / unresolved):

| pair | first cheaper (resolved) | second cheaper (resolved) | unresolved |
|---|---:|---:|---:|
| SBB-Dual vs AGD-SDAJ-BH | 29 | 18 | 7 |
| SBB-Dual vs AGD-SDAJ | 30 | 16 | 8 |
| AGD-SDAJ-BH vs Dykstra-APM | 33 | 9 | 12 |
| AGD-SDAJ vs Dykstra-APM | 27 | 10 | 17 |
| AGD-SDAJ-BH vs AGD-SDAJ | 5 | 0 | 49 |
| Newton-SIN-BH vs SBB-Dual | 54 | 0 | 0 |

