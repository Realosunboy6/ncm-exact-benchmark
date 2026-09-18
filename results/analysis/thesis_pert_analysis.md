# Paper 2 Sec. 5 - ranking under different conventions

Instances: 20 (n=550). Solvers: Newton-SIN-BH, AGD-SDAJ-BH, AGD-SDAJ, SBB-Dual, Dykstra-APM, Anderson-APM.

## 1. Native stopping rules

Each solver run to its own exit. This is the comparison a paper reporting
"iterations to convergence" would make, and it credits a solver for
stopping early rather than for being accurate.

| solver | median EVDs | min | max | median final err |
|---|---:|---:|---:|---:|
| Newton-SIN-BH | 6 | 5 | 7 | 3.41e-12 |
| AGD-SDAJ-BH | 30 | 17 | 49 | 5.82e-10 |
| AGD-SDAJ | 36 | 17 | 3000 | 4.96e-10 |
| SBB-Dual | 26 | 11 | 73 | 8.99e-10 |
| Dykstra-APM | 52 | 19 | 153 | 1.36e-09 |
| Anderson-APM | 28 | 13 | 67 | 1.01e-09 |

Achieved accuracy differs across solvers at their native exits, so these
costs are NOT comparable; that is what the remaining sections correct for.

## 2. Common forward error ||X-X*||_F <= eps (exact X*)

| eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM | winner | n reached |
|---|---:|---:|---:|---:|---:|---:|---|---|
| 1e-02 | 4 | 7 | 7 | 6 | 11 | 6 | **Newton-SIN-BH** | Newton:20 AGD:20 AGD:20 SBB:20 Dykstra:20 Anderson:20 |
| 1e-04 | 4 | 12 | 12 | 12 | 22 | 12 | **Newton-SIN-BH** | Newton:20 AGD:20 AGD:20 SBB:20 Dykstra:20 Anderson:20 |
| 1e-06 | 6 | 17 | 18 | 17 | 34 | 18 | **Newton-SIN-BH** | Newton:20 AGD:19 AGD:18 SBB:20 Dykstra:20 Anderson:20 |
| 1e-08 | 6 | 26 | 33 | 23 | 47 | 24 | **Newton-SIN-BH** | Newton:20 AGD:14 AGD:9 SBB:20 Dykstra:20 Anderson:20 |
| 1e-10 | 6 | 28 | 28 | 13 | -- | -- | **Newton-SIN-BH** | Newton:17 AGD:2 AGD:1 SBB:1 Dykstra:0 Anderson:0 |

## 3. Common dual residual ||grad theta||_2 <= tau

| tau | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM | winner | n reached |
|---|---:|---:|---:|---:|---:|---:|---|---|
| 1e-02 | 4 | 7 | 7 | 6 | 10 | 6 | **Newton-SIN-BH** | Newton:20 AGD:20 AGD:20 SBB:20 Dykstra:20 Anderson:20 |
| 1e-04 | 4 | 12 | 12 | 10 | 20 | 12 | **Newton-SIN-BH** | Newton:20 AGD:20 AGD:20 SBB:20 Dykstra:20 Anderson:20 |
| 1e-06 | 6 | 18 | 18 | 17 | 34 | 18 | **Newton-SIN-BH** | Newton:20 AGD:20 AGD:19 SBB:20 Dykstra:20 Anderson:20 |
| 1e-08 | 6 | 24 | 29 | 22 | 46 | 24 | **Newton-SIN-BH** | Newton:20 AGD:13 AGD:9 SBB:20 Dykstra:20 Anderson:20 |
| 1e-10 | 6 | 28 | 28 | 13 | -- | -- | **Newton-SIN-BH** | Newton:18 AGD:2 AGD:1 SBB:1 Dykstra:0 Anderson:0 |

## 4. Accepted-only vs all-trial accounting

Under all-trial accounting a REJECTED line-search trial may be credited with
reaching the target. Rejected trials cost EVDs under both rules; the question
is only whether they earn accuracy credit. Rows shown only where the median
changed.

| eps | solver | accepted-only | all-trial | delta |
|---|---|---:|---:|---:|
| 1e-06 | AGD-SDAJ | 18.0 | 19.0 | +1.0 |
| 1e-08 | AGD-SDAJ-BH | 26.5 | 29.0 | +2.5 |

## 5. Did the ranking actually reverse?

Observed **5** distinct orderings across 11 conventions.

| ordering (cheapest first) | conventions producing it |
|---|---|
| Newton-SIN-BH < SBB-Dual < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM | forward 1e-02, forward 1e-08, residual 1e-02, native |
| Newton-SIN-BH < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Anderson-APM < Dykstra-APM | forward 1e-04, residual 1e-04, residual 1e-06 |
| Newton-SIN-BH < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ | forward 1e-10, residual 1e-10 |
| Newton-SIN-BH < AGD-SDAJ-BH < SBB-Dual < AGD-SDAJ < Anderson-APM < Dykstra-APM | forward 1e-06 |
| Newton-SIN-BH < SBB-Dual < AGD-SDAJ-BH < Anderson-APM < AGD-SDAJ < Dykstra-APM | residual 1e-08 |

**The winner is invariant: Newton-SIN-BH is cheapest under every convention
tested.** The conventions change cost RATIOS, not the ranking at the top.
This must be reported as a null result for winner-reversal, quantifying
the ratio spread instead of claiming a reversal that was not observed.

## 6. What each solver actually returns

Feasibility of the returned iterate. A solver returning a PSD half-iterate
and one returning a unit-diagonal half-iterate are not interchangeable.

| solver | median lambda_min(X) | worst lambda_min | median diag err | worst diag err |
|---|---:|---:|---:|---:|
| Newton-SIN-BH | -1.52e-14 | -3.68e-14 | 1.04e-12 | 8.43e-10 |
| AGD-SDAJ-BH | -1.30e-14 | -4.28e-14 | 2.06e-10 | 6.02e-10 |
| AGD-SDAJ | -1.22e-14 | -4.14e-14 | 1.70e-10 | 1.73e-08 |
| SBB-Dual | -1.27e-14 | -4.47e-14 | 0.00e+00 | 0.00e+00 |
| Dykstra-APM | -1.62e-14 | -4.17e-14 | 7.26e-10 | 9.67e-10 |
| Anderson-APM | -1.41e-14 | -4.90e-14 | 4.40e-10 | 8.17e-10 |

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
| Newton-SIN-BH | converged | 20 |
| AGD-SDAJ-BH | diag_feasible | 7 |
| AGD-SDAJ-BH | diag_feasible_at_xpre | 13 |
| AGD-SDAJ | diag_feasible | 6 |
| AGD-SDAJ | diag_feasible_at_xpre | 13 |
| AGD-SDAJ | evd_budget | 1 |
| SBB-Dual | diag_feasible | 20 |
| Dykstra-APM | diag_feasible | 20 |
| Anderson-APM | diag_feasible | 20 |

## 12. Sections 2 and 7 recomputed with the corrected reach rule

`cost_to` (Secs. 2-7) scores a run 'not reached' if its first sub-eps dip is
not held, even if it later settles below eps. Corrected: cost = EVDs at the
start of the final sub-eps suffix. Sections 9-11 below also use this rule.

| eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM | ordering (cheapest first) |
|---|---:|---:|---:|---:|---:|---:|---|
| 1e-02 | 3.5 (20/20) | 7.0 (20/20) | 7.0 (20/20) | 5.5 (20/20) | 11.0 (20/20) | 6.5 (20/20) | Newton-SIN-BH < SBB-Dual < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM |
| 1e-04 | 4.5 (20/20) | 12.0 (20/20) | 12.0 (20/20) | 11.5 (20/20) | 22.0 (20/20) | 12.0 (20/20) | Newton-SIN-BH < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Anderson-APM < Dykstra-APM |
| 1e-06 | 5.5 (20/20) | 18.0 (20/20) | 19.0 (20/20) | 17.0 (20/20) | 34.5 (20/20) | 18.5 (20/20) | Newton-SIN-BH < SBB-Dual < AGD-SDAJ-BH < Anderson-APM < AGD-SDAJ < Dykstra-APM |
| 1e-08 | 6.0 (20/20) | 26.0 (20/20) | 30.0 (19/20) | 23.0 (20/20) | 47.0 (20/20) | 24.5 (20/20) | Newton-SIN-BH < SBB-Dual < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM |
| 1e-10 | 6.0 (17/20) | 28.0 (2/20) | 28.0 (1/20) | 13.0 (1/20) | -- (0/20) | -- (0/20) | Newton-SIN-BH < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ |

## 9-11. Bootstrap sections

Instance names carry no paired-seed structure (real matrices), so no
bootstrap is possible. Per-matrix EVDs to each forward target instead
(`--` = not reached and held; forward error is against the COMPUTED
reference, not an exact X*):

| matrix | n | eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| thesis-s0.005-r0 | 550 | 1e-02 | 3 | 4 | 4 | 3 | 3 | 3 |
| thesis-s0.005-r0 | 550 | 1e-04 | 4 | 8 | 8 | 5 | 8 | 6 |
| thesis-s0.005-r0 | 550 | 1e-06 | 4 | 12 | 12 | 8 | 13 | 9 |
| thesis-s0.005-r0 | 550 | 1e-08 | 5 | 21 | 26 | 11 | 18 | 12 |
| thesis-s0.005-r0 | 550 | 1e-10 | 5 | -- | -- | 13 | -- | -- |
| thesis-s0.005-r1 | 550 | 1e-02 | 3 | 4 | 4 | 3 | 3 | 3 |
| thesis-s0.005-r1 | 550 | 1e-04 | 4 | 8 | 8 | 5 | 8 | 6 |
| thesis-s0.005-r1 | 550 | 1e-06 | 4 | 12 | 12 | 8 | 13 | 9 |
| thesis-s0.005-r1 | 550 | 1e-08 | 5 | 20 | 21 | 10 | 18 | 12 |
| thesis-s0.005-r1 | 550 | 1e-10 | 5 | -- | -- | -- | -- | -- |
| thesis-s0.005-r2 | 550 | 1e-02 | 3 | 4 | 4 | 3 | 3 | 3 |
| thesis-s0.005-r2 | 550 | 1e-04 | 3 | 7 | 7 | 5 | 7 | 6 |
| thesis-s0.005-r2 | 550 | 1e-06 | 4 | 12 | 17 | 8 | 12 | 8 |
| thesis-s0.005-r2 | 550 | 1e-08 | 5 | 15 | 24 | 10 | 17 | 11 |
| thesis-s0.005-r2 | 550 | 1e-10 | 5 | -- | -- | -- | -- | -- |
| thesis-s0.005-r3 | 550 | 1e-02 | 3 | 4 | 4 | 3 | 3 | 3 |
| thesis-s0.005-r3 | 550 | 1e-04 | 4 | 7 | 7 | 5 | 8 | 6 |
| thesis-s0.005-r3 | 550 | 1e-06 | 4 | 14 | 23 | 8 | 13 | 8 |
| thesis-s0.005-r3 | 550 | 1e-08 | 5 | 24 | 30 | 10 | 17 | 11 |
| thesis-s0.005-r3 | 550 | 1e-10 | 5 | -- | -- | -- | -- | -- |
| thesis-s0.005-r4 | 550 | 1e-02 | 3 | 4 | 4 | 3 | 3 | 3 |
| thesis-s0.005-r4 | 550 | 1e-04 | 4 | 7 | 7 | 5 | 8 | 6 |
| thesis-s0.005-r4 | 550 | 1e-06 | 4 | 10 | 10 | 8 | 12 | 8 |
| thesis-s0.005-r4 | 550 | 1e-08 | 5 | 15 | 15 | 10 | 17 | 11 |
| thesis-s0.005-r4 | 550 | 1e-10 | 5 | -- | -- | -- | -- | -- |
| thesis-s0.01-r0 | 550 | 1e-02 | 3 | 4 | 4 | 4 | 7 | 5 |
| thesis-s0.01-r0 | 550 | 1e-04 | 4 | 10 | 10 | 9 | 15 | 9 |
| thesis-s0.01-r0 | 550 | 1e-06 | 5 | 16 | 16 | 13 | 25 | 14 |
| thesis-s0.01-r0 | 550 | 1e-08 | 6 | 20 | 99 | 17 | 34 | 19 |
| thesis-s0.01-r0 | 550 | 1e-10 | 6 | 28 | -- | -- | -- | -- |
| thesis-s0.01-r1 | 550 | 1e-02 | 3 | 4 | 4 | 4 | 6 | 5 |
| thesis-s0.01-r1 | 550 | 1e-04 | 4 | 10 | 10 | 8 | 13 | 8 |
| thesis-s0.01-r1 | 550 | 1e-06 | 5 | 17 | 17 | 11 | 21 | 13 |
| thesis-s0.01-r1 | 550 | 1e-08 | 5 | 33 | 30 | 15 | 29 | 17 |
| thesis-s0.01-r1 | 550 | 1e-10 | -- | -- | -- | -- | -- | -- |
| thesis-s0.01-r2 | 550 | 1e-02 | 3 | 4 | 4 | 4 | 6 | 5 |
| thesis-s0.01-r2 | 550 | 1e-04 | 4 | 10 | 10 | 8 | 14 | 9 |
| thesis-s0.01-r2 | 550 | 1e-06 | 5 | 16 | 16 | 12 | 22 | 13 |
| thesis-s0.01-r2 | 550 | 1e-08 | 5 | 20 | 30 | 16 | 30 | 18 |
| thesis-s0.01-r2 | 550 | 1e-10 | 6 | -- | -- | -- | -- | -- |
| thesis-s0.01-r3 | 550 | 1e-02 | 3 | 4 | 4 | 4 | 6 | 5 |
| thesis-s0.01-r3 | 550 | 1e-04 | 4 | 10 | 10 | 8 | 14 | 9 |
| thesis-s0.01-r3 | 550 | 1e-06 | 5 | 16 | 16 | 11 | 22 | 13 |
| thesis-s0.01-r3 | 550 | 1e-08 | 5 | 20 | 38 | 15 | 30 | 18 |
| thesis-s0.01-r3 | 550 | 1e-10 | 6 | -- | -- | -- | -- | -- |
| thesis-s0.01-r4 | 550 | 1e-02 | 3 | 4 | 4 | 4 | 6 | 5 |
| thesis-s0.01-r4 | 550 | 1e-04 | 4 | 10 | 10 | 8 | 13 | 8 |
| thesis-s0.01-r4 | 550 | 1e-06 | 5 | 15 | 15 | 11 | 21 | 13 |
| thesis-s0.01-r4 | 550 | 1e-08 | 5 | 20 | 20 | 15 | 29 | 17 |
| thesis-s0.01-r4 | 550 | 1e-10 | -- | -- | -- | -- | -- | -- |
| thesis-s0.03-r0 | 550 | 1e-02 | 4 | 10 | 10 | 8 | 15 | 8 |
| thesis-s0.03-r0 | 550 | 1e-04 | 5 | 14 | 14 | 14 | 30 | 15 |
| thesis-s0.03-r0 | 550 | 1e-06 | 6 | 19 | 19 | 22 | 45 | 23 |
| thesis-s0.03-r0 | 550 | 1e-08 | 6 | 31 | 33 | 29 | 61 | 31 |
| thesis-s0.03-r0 | 550 | 1e-10 | 6 | -- | -- | -- | -- | -- |
| thesis-s0.03-r1 | 550 | 1e-02 | 4 | 10 | 10 | 7 | 15 | 8 |
| thesis-s0.03-r1 | 550 | 1e-04 | 5 | 15 | 15 | 14 | 29 | 15 |
| thesis-s0.03-r1 | 550 | 1e-06 | 6 | 23 | 23 | 21 | 44 | 23 |
| thesis-s0.03-r1 | 550 | 1e-08 | 6 | 29 | 29 | 29 | 60 | 31 |
| thesis-s0.03-r1 | 550 | 1e-10 | 6 | -- | -- | -- | -- | -- |
| thesis-s0.03-r2 | 550 | 1e-02 | 4 | 10 | 10 | 7 | 15 | 8 |
| thesis-s0.03-r2 | 550 | 1e-04 | 5 | 16 | 16 | 14 | 29 | 15 |
| thesis-s0.03-r2 | 550 | 1e-06 | 6 | 20 | 20 | 22 | 44 | 23 |
| thesis-s0.03-r2 | 550 | 1e-08 | 6 | 30 | 33 | 29 | 60 | 31 |
| thesis-s0.03-r2 | 550 | 1e-10 | 6 | -- | -- | -- | -- | -- |
| thesis-s0.03-r3 | 550 | 1e-02 | 4 | 10 | 10 | 8 | 15 | 9 |
| thesis-s0.03-r3 | 550 | 1e-04 | 5 | 15 | 15 | 15 | 31 | 16 |
| thesis-s0.03-r3 | 550 | 1e-06 | 6 | 19 | 19 | 23 | 48 | 24 |
| thesis-s0.03-r3 | 550 | 1e-08 | 6 | 24 | 24 | 32 | 65 | 32 |
| thesis-s0.03-r3 | 550 | 1e-10 | -- | 28 | 28 | -- | -- | -- |
| thesis-s0.03-r4 | 550 | 1e-02 | 4 | 10 | 10 | 8 | 15 | 8 |
| thesis-s0.03-r4 | 550 | 1e-04 | 5 | 14 | 14 | 14 | 30 | 15 |
| thesis-s0.03-r4 | 550 | 1e-06 | 6 | 19 | 19 | 22 | 45 | 23 |
| thesis-s0.03-r4 | 550 | 1e-08 | 6 | 28 | 28 | 29 | 60 | 30 |
| thesis-s0.03-r4 | 550 | 1e-10 | 6 | -- | -- | -- | -- | -- |
| thesis-s0.1-r0 | 550 | 1e-02 | 5 | 11 | 11 | 17 | 35 | 16 |
| thesis-s0.1-r0 | 550 | 1e-04 | 6 | 19 | 19 | 33 | 69 | 31 |
| thesis-s0.1-r0 | 550 | 1e-06 | 7 | 25 | 28 | 50 | 105 | 46 |
| thesis-s0.1-r0 | 550 | 1e-08 | 7 | 36 | 40 | 67 | 141 | 61 |
| thesis-s0.1-r0 | 550 | 1e-10 | 7 | -- | -- | -- | -- | -- |
| thesis-s0.1-r1 | 550 | 1e-02 | 5 | 11 | 11 | 17 | 35 | 16 |
| thesis-s0.1-r1 | 550 | 1e-04 | 6 | 19 | 19 | 32 | 67 | 28 |
| thesis-s0.1-r1 | 550 | 1e-06 | 7 | 27 | 27 | 47 | 99 | 41 |
| thesis-s0.1-r1 | 550 | 1e-08 | 7 | 43 | 45 | 63 | 133 | 54 |
| thesis-s0.1-r1 | 550 | 1e-10 | 7 | -- | -- | -- | -- | -- |
| thesis-s0.1-r2 | 550 | 1e-02 | 5 | 11 | 11 | 17 | 35 | 16 |
| thesis-s0.1-r2 | 550 | 1e-04 | 6 | 18 | 18 | 33 | 68 | 30 |
| thesis-s0.1-r2 | 550 | 1e-06 | 7 | 25 | 25 | 49 | 103 | 44 |
| thesis-s0.1-r2 | 550 | 1e-08 | 7 | 36 | 40 | 67 | 140 | 59 |
| thesis-s0.1-r2 | 550 | 1e-10 | 7 | -- | -- | -- | -- | -- |
| thesis-s0.1-r3 | 550 | 1e-02 | 5 | 17 | 17 | 17 | 35 | 16 |
| thesis-s0.1-r3 | 550 | 1e-04 | 6 | 25 | 25 | 32 | 67 | 30 |
| thesis-s0.1-r3 | 550 | 1e-06 | 7 | 32 | 39 | 49 | 102 | 45 |
| thesis-s0.1-r3 | 550 | 1e-08 | 7 | 38 | 47 | 65 | 137 | 60 |
| thesis-s0.1-r3 | 550 | 1e-10 | 7 | -- | -- | -- | -- | -- |
| thesis-s0.1-r4 | 550 | 1e-02 | 5 | 13 | 13 | 17 | 35 | 16 |
| thesis-s0.1-r4 | 550 | 1e-04 | 6 | 19 | 19 | 33 | 69 | 30 |
| thesis-s0.1-r4 | 550 | 1e-06 | 7 | 31 | 58 | 50 | 104 | 44 |
| thesis-s0.1-r4 | 550 | 1e-08 | 7 | 39 | -- | 67 | 140 | 59 |
| thesis-s0.1-r4 | 550 | 1e-10 | 7 | -- | -- | -- | -- | -- |

| matrix | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM |
|---|---|---|---|---|---|---|
| thesis-s0.005-r0 | 5 EVDs, converged, err 7.8e-13 | 25 EVDs, diag_feasible, err 1.5e-10 | 30 EVDs, diag_feasible_at_xpre, err 6.6e-10 | 13 EVDs, diag_feasible, err 2.0e-11 | 21 EVDs, diag_feasible, err 5.3e-10 | 13 EVDs, diag_feasible, err 1.0e-09 |
| thesis-s0.005-r1 | 5 EVDs, converged, err 7.8e-13 | 23 EVDs, diag_feasible_at_xpre, err 1.2e-10 | 24 EVDs, diag_feasible_at_xpre, err 1.2e-10 | 12 EVDs, diag_feasible, err 8.6e-10 | 20 EVDs, diag_feasible, err 1.0e-09 | 13 EVDs, diag_feasible, err 5.9e-10 |
| thesis-s0.005-r2 | 5 EVDs, converged, err 8.0e-13 | 20 EVDs, diag_feasible, err 1.1e-09 | 36 EVDs, diag_feasible, err 3.0e-10 | 11 EVDs, diag_feasible, err 9.4e-10 | 19 EVDs, diag_feasible, err 5.9e-10 | 13 EVDs, diag_feasible, err 2.5e-10 |
| thesis-s0.005-r3 | 5 EVDs, converged, err 1.1e-12 | 27 EVDs, diag_feasible_at_xpre, err 6.2e-10 | 32 EVDs, diag_feasible_at_xpre, err 6.2e-10 | 11 EVDs, diag_feasible, err 9.4e-10 | 20 EVDs, diag_feasible, err 5.2e-10 | 13 EVDs, diag_feasible, err 3.7e-10 |
| thesis-s0.005-r4 | 5 EVDs, converged, err 7.9e-13 | 17 EVDs, diag_feasible_at_xpre, err 4.5e-10 | 17 EVDs, diag_feasible_at_xpre, err 4.5e-10 | 11 EVDs, diag_feasible, err 8.5e-10 | 19 EVDs, diag_feasible, err 6.8e-10 | 13 EVDs, diag_feasible, err 2.6e-10 |
| thesis-s0.01-r0 | 6 EVDs, converged, err 1.1e-12 | 29 EVDs, diag_feasible_at_xpre, err 8.5e-11 | 107 EVDs, diag_feasible_at_xpre, err 8.5e-10 | 20 EVDs, diag_feasible, err 4.6e-10 | 38 EVDs, diag_feasible, err 1.4e-09 | 21 EVDs, diag_feasible, err 1.3e-09 |
| thesis-s0.01-r1 | 5 EVDs, converged, err 1.2e-09 | 36 EVDs, diag_feasible_at_xpre, err 1.5e-10 | 36 EVDs, diag_feasible, err 1.8e-10 | 16 EVDs, diag_feasible, err 1.1e-09 | 32 EVDs, diag_feasible, err 1.4e-09 | 19 EVDs, diag_feasible, err 1.0e-09 |
| thesis-s0.01-r2 | 6 EVDs, converged, err 1.6e-12 | 29 EVDs, diag_feasible, err 9.0e-10 | 34 EVDs, diag_feasible, err 9.0e-10 | 17 EVDs, diag_feasible, err 3.9e-10 | 34 EVDs, diag_feasible, err 1.1e-09 | 20 EVDs, diag_feasible, err 6.9e-10 |
| thesis-s0.01-r3 | 6 EVDs, converged, err 1.0e-12 | 23 EVDs, diag_feasible_at_xpre, err 6.2e-10 | 42 EVDs, diag_feasible_at_xpre, err 2.0e-10 | 17 EVDs, diag_feasible, err 2.3e-10 | 34 EVDs, diag_feasible, err 7.9e-10 | 20 EVDs, diag_feasible, err 5.9e-10 |
| thesis-s0.01-r4 | 5 EVDs, converged, err 9.9e-10 | 23 EVDs, diag_feasible_at_xpre, err 3.4e-10 | 23 EVDs, diag_feasible_at_xpre, err 3.4e-10 | 16 EVDs, diag_feasible, err 6.4e-10 | 32 EVDs, diag_feasible, err 1.2e-09 | 19 EVDs, diag_feasible, err 7.5e-10 |
| thesis-s0.03-r0 | 6 EVDs, converged, err 2.4e-11 | 35 EVDs, diag_feasible_at_xpre, err 1.4e-10 | 37 EVDs, diag_feasible_at_xpre, err 1.4e-10 | 33 EVDs, diag_feasible, err 7.6e-10 | 67 EVDs, diag_feasible, err 1.3e-09 | 34 EVDs, diag_feasible, err 9.6e-10 |
| thesis-s0.03-r1 | 6 EVDs, converged, err 3.3e-11 | 30 EVDs, diag_feasible_at_xpre, err 4.0e-10 | 30 EVDs, diag_feasible_at_xpre, err 4.0e-10 | 32 EVDs, diag_feasible, err 1.1e-09 | 66 EVDs, diag_feasible, err 1.6e-09 | 34 EVDs, diag_feasible, err 1.0e-09 |
| thesis-s0.03-r2 | 6 EVDs, converged, err 4.4e-11 | 35 EVDs, diag_feasible, err 6.7e-10 | 44 EVDs, diag_feasible, err 6.7e-10 | 33 EVDs, diag_feasible, err 7.5e-10 | 67 EVDs, diag_feasible, err 1.4e-09 | 34 EVDs, diag_feasible, err 1.0e-09 |
| thesis-s0.03-r3 | 6 EVDs, converged, err 1.7e-10 | 29 EVDs, diag_feasible_at_xpre, err 7.0e-11 | 29 EVDs, diag_feasible_at_xpre, err 7.0e-11 | 35 EVDs, diag_feasible, err 1.2e-09 | 72 EVDs, diag_feasible, err 1.6e-09 | 35 EVDs, diag_feasible, err 1.6e-09 |
| thesis-s0.03-r4 | 6 EVDs, converged, err 2.3e-11 | 31 EVDs, diag_feasible, err 7.4e-10 | 31 EVDs, diag_feasible, err 7.4e-10 | 33 EVDs, diag_feasible, err 6.6e-10 | 66 EVDs, diag_feasible, err 1.7e-09 | 34 EVDs, diag_feasible, err 9.5e-10 |
| thesis-s0.1-r0 | 7 EVDs, converged, err 7.2e-12 | 39 EVDs, diag_feasible_at_xpre, err 1.0e-09 | 45 EVDs, diag_feasible, err 1.0e-09 | 73 EVDs, diag_feasible, err 2.0e-09 | 153 EVDs, diag_feasible, err 2.3e-09 | 67 EVDs, diag_feasible, err 1.7e-09 |
| thesis-s0.1-r1 | 7 EVDs, converged, err 2.8e-12 | 49 EVDs, diag_feasible, err 6.5e-10 | 49 EVDs, diag_feasible_at_xpre, err 1.9e-10 | 68 EVDs, diag_feasible, err 1.8e-09 | 143 EVDs, diag_feasible, err 2.2e-09 | 59 EVDs, diag_feasible, err 1.7e-09 |
| thesis-s0.1-r2 | 7 EVDs, converged, err 3.9e-12 | 39 EVDs, diag_feasible_at_xpre, err 1.0e-09 | 43 EVDs, diag_feasible_at_xpre, err 1.0e-09 | 72 EVDs, diag_feasible, err 2.2e-09 | 152 EVDs, diag_feasible, err 2.2e-09 | 64 EVDs, diag_feasible, err 2.0e-09 |
| thesis-s0.1-r3 | 7 EVDs, converged, err 3.0e-12 | 42 EVDs, diag_feasible_at_xpre, err 5.4e-10 | 51 EVDs, diag_feasible_at_xpre, err 5.5e-10 | 71 EVDs, diag_feasible, err 1.8e-09 | 149 EVDs, diag_feasible, err 2.1e-09 | 65 EVDs, diag_feasible, err 1.9e-09 |
| thesis-s0.1-r4 | 7 EVDs, converged, err 4.7e-12 | 43 EVDs, diag_feasible, err 1.1e-09 | 3000 EVDs, evd_budget, err 3.6e-08 | 72 EVDs, diag_feasible, err 2.0e-09 | 152 EVDs, diag_feasible, err 2.0e-09 | 64 EVDs, diag_feasible, err 1.9e-09 |

