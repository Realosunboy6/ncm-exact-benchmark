# Paper 2 Sec. 5 - ranking under different conventions

Instances: 270 (n=100). Solvers: Newton-SIN-BH, AGD-SDAJ-BH, AGD-SDAJ, SBB-Dual, Dykstra-APM.

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

Achieved accuracy differs across solvers at their native exits, so these
costs are NOT comparable; that is what the remaining sections correct for.

## 2. Common forward error ||X-X*||_F <= eps (exact X*)

| eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | winner | n reached |
|---|---:|---:|---:|---:|---:|---|---|
| 1e-02 | 3 | 6 | 6 | 8 | 15 | **Newton-SIN-BH** | Newton:270 AGD:270 AGD:270 SBB:270 Dykstra:270 |
| 1e-04 | 4 | 14 | 14 | 16 | 34 | **Newton-SIN-BH** | Newton:270 AGD:270 AGD:270 SBB:270 Dykstra:270 |
| 1e-06 | 4 | 28 | 28 | 24 | 54 | **Newton-SIN-BH** | Newton:270 AGD:269 AGD:269 SBB:270 Dykstra:270 |
| 1e-08 | 5 | 43 | 45 | 34 | 74 | **Newton-SIN-BH** | Newton:270 AGD:217 AGD:202 SBB:270 Dykstra:270 |
| 1e-10 | 5 | 59 | 70 | 44 | 96 | **Newton-SIN-BH** | Newton:270 AGD:208 AGD:198 SBB:270 Dykstra:270 |

## 3. Common dual residual ||grad theta||_2 <= tau

| tau | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | winner | n reached |
|---|---:|---:|---:|---:|---:|---|---|
| 1e-02 | 2 | 5 | 5 | 7 | 12 | **Newton-SIN-BH** | Newton:270 AGD:270 AGD:270 SBB:270 Dykstra:270 |
| 1e-04 | 3 | 13 | 13 | 14 | 30 | **Newton-SIN-BH** | Newton:270 AGD:270 AGD:270 SBB:270 Dykstra:270 |
| 1e-06 | 4 | 27 | 27 | 23 | 50 | **Newton-SIN-BH** | Newton:270 AGD:270 AGD:270 SBB:270 Dykstra:270 |
| 1e-08 | 5 | 39 | 42 | 32 | 71 | **Newton-SIN-BH** | Newton:270 AGD:228 AGD:210 SBB:270 Dykstra:270 |
| 1e-10 | 5 | 57 | 65 | 42 | 92 | **Newton-SIN-BH** | Newton:270 AGD:219 AGD:199 SBB:270 Dykstra:270 |

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

Observed **2** distinct orderings across 11 conventions.

| ordering (cheapest first) | conventions producing it |
|---|---|
| Newton-SIN-BH < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM | forward 1e-06, forward 1e-08, forward 1e-10, residual 1e-06, residual 1e-08, residual 1e-10, native |
| Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM | forward 1e-02, forward 1e-04, residual 1e-02, residual 1e-04 |

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

## 7. Ranking by degeneracy cell

Aggregate medians can hide a regime-dependent reversal. The KKT family
controls rank r, near-zero multiplicity m and separation delta exactly so
this can be checked: if any ordering flips, it should flip in the degenerate
corner (small delta, large m), not on average. Target: forward 1e-08.

54 cells, **9** distinct orderings.

| ordering (cheapest first) | cells | example |
|---|---:|---|
| Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM | 17 | r=5 m=1 d=0 |
| Newton-SIN-BH < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM | 15 | r=20 m=1 d=0 |
| Newton-SIN-BH < SBB-Dual < Dykstra-APM < AGD-SDAJ-BH < AGD-SDAJ | 12 | r=20 m=20 d=1e-10 |
| Newton-SIN-BH < SBB-Dual < AGD-SDAJ < AGD-SDAJ-BH < Dykstra-APM | 4 | r=20 m=1 d=1e-08 |
| Newton-SIN-BH < AGD-SDAJ-BH < SBB-Dual < AGD-SDAJ < Dykstra-APM | 2 | r=20 m=1 d=0.0001 |
| Newton-SIN-BH < AGD-SDAJ < AGD-SDAJ-BH < SBB-Dual < Dykstra-APM | 1 | r=5 m=1 d=1e-10 |
| Newton-SIN-BH < AGD-SDAJ-BH < SBB-Dual < Dykstra-APM | 1 | r=5 m=20 d=0 |
| Newton-SIN-BH < SBB-Dual < Dykstra-APM < AGD-SDAJ < AGD-SDAJ-BH | 1 | r=50 m=20 d=0 |
| Newton-SIN-BH < SBB-Dual < AGD-SDAJ-BH < Dykstra-APM < AGD-SDAJ | 1 | r=50 m=20 d=0.01 |

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
