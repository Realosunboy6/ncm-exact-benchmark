# Paper 2 Sec. 5 - ranking under different conventions

Instances: 4 (n=94). Solvers: Newton-SIN-BH, AGD-SDAJ-BH, AGD-SDAJ, SBB-Dual, Dykstra-APM.

## 1. Native stopping rules

Each solver run to its own exit. This is the comparison a paper reporting
"iterations to convergence" would make, and it credits a solver for
stopping early rather than for being accurate.

| solver | median EVDs | min | max | median final err |
|---|---:|---:|---:|---:|
| Newton-SIN-BH | 6 | 4 | 7 | 6.51e-10 |
| AGD-SDAJ-BH | 30 | 9 | 69 | 1.10e-09 |
| AGD-SDAJ | 64 | 25 | 323 | 1.12e-09 |
| SBB-Dual | 110 | 6 | 270 | 1.58e-09 |
| Dykstra-APM | 156 | 7 | 430 | 1.71e-09 |

Achieved accuracy differs across solvers at their native exits, so these
costs are NOT comparable; that is what the remaining sections correct for.

## 2. Common forward error ||X-X*||_F <= eps (exact X*)

| eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | winner | n reached |
|---|---:|---:|---:|---:|---:|---|---|
| 1e-02 | 4 | 10 | 10 | 28 | 56 | **Newton-SIN-BH** | Newton:4 AGD:4 AGD:4 SBB:4 Dykstra:4 |
| 1e-04 | 4 | 10 | 10 | 54 | 108 | **Newton-SIN-BH** | Newton:4 AGD:4 AGD:4 SBB:4 Dykstra:4 |
| 1e-06 | 5 | 16 | 32 | 79 | 8 | **Newton-SIN-BH** | Newton:4 AGD:4 AGD:3 SBB:4 Dykstra:3 |
| 1e-08 | 5 | 26 | 40 | 104 | 11 | **Newton-SIN-BH** | Newton:4 AGD:4 AGD:2 SBB:4 Dykstra:3 |
| 1e-10 | 4 | -- | -- | -- | -- | **Newton-SIN-BH** | Newton:2 AGD:0 AGD:0 SBB:0 Dykstra:0 |

## 3. Common dual residual ||grad theta||_2 <= tau

| tau | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | winner | n reached |
|---|---:|---:|---:|---:|---:|---|---|
| 1e-02 | 4 | 4 | 4 | 19 | 36 | **Newton-SIN-BH** | Newton:4 AGD:3 AGD:3 SBB:4 Dykstra:4 |
| 1e-04 | 4 | 10 | 10 | 48 | 96 | **Newton-SIN-BH** | Newton:4 AGD:4 AGD:4 SBB:4 Dykstra:4 |
| 1e-06 | 5 | 16 | 23 | 73 | 8 | **Newton-SIN-BH** | Newton:4 AGD:4 AGD:3 SBB:4 Dykstra:3 |
| 1e-08 | 5 | 12 | 38 | 98 | 11 | **Newton-SIN-BH** | Newton:4 AGD:3 AGD:2 SBB:4 Dykstra:3 |
| 1e-10 | 4 | -- | -- | -- | -- | **Newton-SIN-BH** | Newton:2 AGD:0 AGD:0 SBB:0 Dykstra:0 |

## 4. Accepted-only vs all-trial accounting

Under all-trial accounting a REJECTED line-search trial may be credited with
reaching the target. Rejected trials cost EVDs under both rules; the question
is only whether they earn accuracy credit. Rows shown only where the median
changed.

| eps | solver | accepted-only | all-trial | delta |
|---|---|---:|---:|---:|
| 1e-04 | AGD-SDAJ-BH | 10.5 | 4.0 | -6.5 |
| 1e-04 | AGD-SDAJ | 10.5 | 4.0 | -6.5 |
| 1e-06 | AGD-SDAJ | 32.0 | 31.5 | -0.5 |
| 1e-08 | AGD-SDAJ | 39.5 | 39.0 | -0.5 |

## 5. Did the ranking actually reverse?

Observed **3** distinct orderings across 11 conventions.

| ordering (cheapest first) | conventions producing it |
|---|---|
| Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM | forward 1e-02, forward 1e-04, residual 1e-02, residual 1e-04, native |
| Newton-SIN-BH < Dykstra-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual | forward 1e-06, forward 1e-08, residual 1e-06, residual 1e-08 |
| Newton-SIN-BH | forward 1e-10, residual 1e-10 |

**The winner is invariant: Newton-SIN-BH is cheapest under every convention
tested.** The conventions change cost RATIOS, not the ranking at the top.
This must be reported as a null result for winner-reversal, quantifying
the ratio spread instead of claiming a reversal that was not observed.

## 6. What each solver actually returns

Feasibility of the returned iterate. A solver returning a PSD half-iterate
and one returning a unit-diagonal half-iterate are not interchangeable.

| solver | median lambda_min(X) | worst lambda_min | median diag err | worst diag err |
|---|---:|---:|---:|---:|
| Newton-SIN-BH | -6.38e-14 | -1.50e-13 | 7.77e-11 | 4.36e-10 |
| AGD-SDAJ-BH | -6.37e-14 | -1.29e-13 | 2.57e-10 | 4.11e-10 |
| AGD-SDAJ | -5.60e-14 | -1.07e-13 | 2.69e-10 | 6.86e-06 |
| SBB-Dual | -7.01e-14 | -1.66e-13 | 0.00e+00 | 0.00e+00 |
| Dykstra-APM | -5.49e-14 | -1.25e-13 | 4.65e-10 | 2.35e-06 |

## 7. Ranking by degeneracy cell

Aggregate medians can hide a regime-dependent reversal. The KKT family
controls rank r, near-zero multiplicity m and separation delta exactly so
this can be checked: if any ordering flips, it should flip in the degenerate
corner (small delta, large m), not on average. Target: forward 1e-08.

0 cells, **0** distinct orderings.

| ordering (cheapest first) | cells | example |
|---|---:|---|

No cell departs from the global ordering: the ranking is invariant across
the whole degeneracy grid, not merely on average.

## 8. Exit reasons

| solver | exit | count |
|---|---|---:|
| Newton-SIN-BH | converged | 4 |
| AGD-SDAJ-BH | diag_feasible | 2 |
| AGD-SDAJ-BH | diag_feasible_at_xpre | 2 |
| AGD-SDAJ | diag_feasible | 2 |
| AGD-SDAJ | diag_feasible_at_xpre | 1 |
| AGD-SDAJ | evd_budget | 1 |
| SBB-Dual | diag_feasible | 4 |
| Dykstra-APM | diag_feasible | 3 |
| Dykstra-APM | max_iter | 1 |

## 12. Sections 2 and 7 recomputed with the corrected reach rule

`cost_to` (Secs. 2-7) scores a run 'not reached' if its first sub-eps dip is
not held, even if it later settles below eps. Corrected: cost = EVDs at the
start of the final sub-eps suffix. Sections 9-11 below also use this rule.

| eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | ordering (cheapest first) |
|---|---:|---:|---:|---:|---:|---|
| 1e-02 | 4.0 (4/4) | 10.0 (4/4) | 10.0 (4/4) | 28.5 (4/4) | 55.5 (4/4) | Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM |
| 1e-04 | 4.5 (4/4) | 10.5 (4/4) | 10.5 (4/4) | 54.5 (4/4) | 108.5 (4/4) | Newton-SIN-BH < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM |
| 1e-06 | 5.0 (4/4) | 16.5 (4/4) | 32.0 (3/4) | 79.0 (4/4) | 8.0 (3/4) | Newton-SIN-BH < Dykstra-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual |
| 1e-08 | 5.0 (4/4) | 26.5 (4/4) | 56.0 (3/4) | 103.5 (4/4) | 11.0 (3/4) | Newton-SIN-BH < Dykstra-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual |
| 1e-10 | 4.5 (2/4) | -- (0/4) | -- (0/4) | -- (0/4) | -- (0/4) | Newton-SIN-BH |

## 9-11. Bootstrap sections

Instance names carry no paired-seed structure (real matrices), so no
bootstrap is possible. Per-matrix EVDs to each forward target instead
(`--` = not reached and held; forward error is against the COMPUTED
reference, not an exact X*):

| matrix | n | eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM |
|---|---:|---|---:|---:|---:|---:|---:|
| Rocky_Mountain_Region_CORR | 94 | 1e-02 | 2 | 2 | 2 | 2 | 2 |
| Rocky_Mountain_Region_CORR | 94 | 1e-04 | 3 | 4 | 4 | 4 | 5 |
| Rocky_Mountain_Region_CORR | 94 | 1e-06 | 3 | 8 | 8 | 6 | 8 |
| Rocky_Mountain_Region_CORR | 94 | 1e-08 | 4 | 12 | 12 | 7 | 11 |
| Rocky_Mountain_Region_CORR | 94 | 1e-10 | 4 | -- | -- | -- | -- |
| bccd16 | 3250 | 1e-02 | 3 | 4 | 4 | 3 | 3 |
| bccd16 | 3250 | 1e-04 | 4 | 4 | 4 | 4 | 4 |
| bccd16 | 3250 | 1e-06 | 4 | 6 | -- | 5 | 5 |
| bccd16 | 3250 | 1e-08 | 4 | 8 | -- | 5 | 6 |
| bccd16 | 3250 | 1e-10 | 5 | -- | -- | -- | -- |
| cor1399 | 1399 | 1e-02 | 6 | 29 | 29 | 58 | 116 |
| cor1399 | 1399 | 1e-04 | 6 | 33 | 33 | 105 | 212 |
| cor1399 | 1399 | 1e-06 | 7 | 55 | 55 | 152 | 309 |
| cor1399 | 1399 | 1e-08 | 7 | 66 | 67 | 200 | 406 |
| cor1399 | 1399 | 1e-10 | -- | -- | -- | -- | -- |
| cor3120 | 3120 | 1e-02 | 5 | 16 | 16 | 54 | 108 |
| cor3120 | 3120 | 1e-04 | 5 | 17 | 17 | 120 | 239 |
| cor3120 | 3120 | 1e-06 | 6 | 25 | 32 | 187 | -- |
| cor3120 | 3120 | 1e-08 | 6 | 41 | 56 | 255 | -- |
| cor3120 | 3120 | 1e-10 | -- | -- | -- | -- | -- |

| matrix | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM |
|---|---|---|---|---|---|
| Rocky_Mountain_Region_CORR | 4 EVDs, converged, err 1.5e-13 | 17 EVDs, diag_feasible, err 3.5e-10 | 25 EVDs, diag_feasible, err 3.5e-10 | 8 EVDs, diag_feasible, err 1.5e-10 | 13 EVDs, diag_feasible, err 2.6e-10 |
| bccd16 | 5 EVDs, converged, err 2.7e-11 | 9 EVDs, diag_feasible_at_xpre, err 8.9e-10 | 323 EVDs, evd_budget, err 3.9e-05 | 6 EVDs, diag_feasible, err 1.2e-10 | 7 EVDs, diag_feasible, err 1.5e-10 |
| cor1399 | 7 EVDs, converged, err 1.3e-09 | 69 EVDs, diag_feasible, err 2.0e-09 | 70 EVDs, diag_feasible, err 1.9e-09 | 212 EVDs, diag_feasible, err 3.0e-09 | 430 EVDs, diag_feasible, err 3.2e-09 |
| cor3120 | 6 EVDs, converged, err 2.3e-09 | 42 EVDs, diag_feasible_at_xpre, err 1.3e-09 | 59 EVDs, diag_feasible_at_xpre, err 2.2e-10 | 270 EVDs, diag_feasible, err 3.4e-09 | 300 EVDs, max_iter, err 1.2e-05 |

