# Paper 2 Sec. 5 - ranking under different conventions

Instances: 81 (n=550). Solvers: Newton-SIN-BH, AGD-SDAJ-BH, AGD-SDAJ, SBB-Dual, Dykstra-APM, Anderson-APM.

## 1. Native stopping rules

Each solver run to its own exit. This is the comparison a paper reporting
"iterations to convergence" would make, and it credits a solver for
stopping early rather than for being accurate.

| solver | median EVDs | min | max | median final err |
|---|---:|---:|---:|---:|
| Newton-SIN-BH | 5 | 4 | 13 | 8.34e-13 |
| AGD-SDAJ-BH | 121 | 67 | 270 | 1.91e-11 |
| AGD-SDAJ | 169 | 56 | 4044 | 2.01e-11 |
| SBB-Dual | 155 | 93 | 361 | 3.76e-11 |
| Dykstra-APM | 316 | 193 | 725 | 3.90e-11 |
| Anderson-APM | 85 | 63 | 191 | 2.68e-11 |

Achieved accuracy differs across solvers at their native exits, so these
costs are NOT comparable; that is what the remaining sections correct for.

## 2. Common forward error ||X-X*||_F <= eps (exact X*)

| eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM | winner | n reached |
|---|---:|---:|---:|---:|---:|---:|---|---|
| 1e-02 | 2 | 12 | 12 | 12 | 22 | 6 | **Newton-SIN-BH** | Newton:81 AGD:81 AGD:81 SBB:81 Dykstra:81 Anderson:81 |
| 1e-04 | 3 | 41 | 41 | 42 | 85 | 21 | **Newton-SIN-BH** | Newton:81 AGD:81 AGD:81 SBB:81 Dykstra:81 Anderson:81 |
| 1e-06 | 4 | 60 | 61 | 77 | 156 | 40 | **Newton-SIN-BH** | Newton:81 AGD:67 AGD:61 SBB:81 Dykstra:81 Anderson:81 |
| 1e-08 | 4 | 90 | 96 | 112 | 228 | 64 | **Newton-SIN-BH** | Newton:81 AGD:54 AGD:50 SBB:81 Dykstra:81 Anderson:81 |
| 1e-10 | 4 | 108 | 130 | 148 | 301 | 83 | **Newton-SIN-BH** | Newton:81 AGD:67 AGD:47 SBB:81 Dykstra:81 Anderson:81 |

## 3. Common dual residual ||grad theta||_2 <= tau

| tau | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM | winner | n reached |
|---|---:|---:|---:|---:|---:|---:|---|---|
| 1e-02 | 2 | 4 | 4 | 5 | 8 | 3 | **Newton-SIN-BH** | Newton:81 AGD:81 AGD:81 SBB:81 Dykstra:81 Anderson:81 |
| 1e-04 | 3 | 36 | 36 | 33 | 65 | 16 | **Newton-SIN-BH** | Newton:81 AGD:77 AGD:77 SBB:81 Dykstra:81 Anderson:81 |
| 1e-06 | 3 | 50 | 55 | 66 | 134 | 34 | **Newton-SIN-BH** | Newton:81 AGD:72 AGD:67 SBB:81 Dykstra:81 Anderson:81 |
| 1e-08 | 4 | 76 | 94 | 101 | 206 | 57 | **Newton-SIN-BH** | Newton:81 AGD:58 AGD:54 SBB:81 Dykstra:81 Anderson:81 |
| 1e-10 | 4 | 104 | 134 | 137 | 279 | 78 | **Newton-SIN-BH** | Newton:81 AGD:69 AGD:64 SBB:81 Dykstra:81 Anderson:81 |

## 4. Accepted-only vs all-trial accounting

Under all-trial accounting a REJECTED line-search trial may be credited with
reaching the target. Rejected trials cost EVDs under both rules; the question
is only whether they earn accuracy credit. Rows shown only where the median
changed.

| eps | solver | accepted-only | all-trial | delta |
|---|---|---:|---:|---:|
| 1e-02 | AGD-SDAJ-BH | 12.0 | 5.0 | -7.0 |
| 1e-02 | AGD-SDAJ | 12.0 | 5.0 | -7.0 |
| 1e-04 | AGD-SDAJ-BH | 41.0 | 37.0 | -4.0 |
| 1e-04 | AGD-SDAJ | 41.0 | 37.0 | -4.0 |
| 1e-06 | AGD-SDAJ-BH | 60.0 | 56.0 | -4.0 |
| 1e-06 | AGD-SDAJ | 61.0 | 57.0 | -4.0 |
| 1e-08 | AGD-SDAJ-BH | 90.0 | 81.0 | -9.0 |
| 1e-08 | AGD-SDAJ | 96.0 | 94.5 | -1.5 |
| 1e-10 | AGD-SDAJ-BH | 108.0 | 107.0 | -1.0 |
| 1e-10 | AGD-SDAJ | 130.0 | 126.5 | -3.5 |

## 5. Did the ranking actually reverse?

Observed **3** distinct orderings across 11 conventions.

| ordering (cheapest first) | conventions producing it |
|---|---|
| Newton-SIN-BH < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM | forward 1e-02, forward 1e-04, forward 1e-06, forward 1e-08, forward 1e-10, residual 1e-02, residual 1e-06, residual 1e-08, residual 1e-10 |
| Newton-SIN-BH < Anderson-APM < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM | residual 1e-04 |
| Newton-SIN-BH < Anderson-APM < AGD-SDAJ-BH < SBB-Dual < AGD-SDAJ < Dykstra-APM | native |

**The winner is invariant: Newton-SIN-BH is cheapest under every convention
tested.** The conventions change cost RATIOS, not the ranking at the top.
This must be reported as a null result for winner-reversal, quantifying
the ratio spread instead of claiming a reversal that was not observed.

## 6. What each solver actually returns

Feasibility of the returned iterate. A solver returning a PSD half-iterate
and one returning a unit-diagonal half-iterate are not interchangeable.

| solver | median lambda_min(X) | worst lambda_min | median diag err | worst diag err |
|---|---:|---:|---:|---:|
| Newton-SIN-BH | -7.43e-14 | -1.80e-13 | 2.99e-14 | 3.56e-12 |
| AGD-SDAJ-BH | -6.89e-14 | -1.63e-13 | 3.87e-12 | 7.16e-12 |
| AGD-SDAJ | -6.47e-14 | -1.86e-13 | 3.90e-12 | 5.44e-07 |
| SBB-Dual | -6.61e-14 | -1.75e-13 | 0.00e+00 | 0.00e+00 |
| Dykstra-APM | -7.03e-14 | -1.69e-13 | 5.51e-12 | 9.39e-12 |
| Anderson-APM | -6.62e-14 | -1.87e-13 | 4.29e-12 | 8.15e-12 |

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
| Newton-SIN-BH | converged | 81 |
| AGD-SDAJ-BH | diag_feasible | 25 |
| AGD-SDAJ-BH | diag_feasible_at_xpre | 56 |
| AGD-SDAJ | diag_feasible | 33 |
| AGD-SDAJ | diag_feasible_at_xpre | 38 |
| AGD-SDAJ | evd_budget | 10 |
| SBB-Dual | diag_feasible | 81 |
| Dykstra-APM | diag_feasible | 81 |
| Anderson-APM | diag_feasible | 81 |

## 12. Sections 2 and 7 recomputed with the corrected reach rule

`cost_to` (Secs. 2-7) scores a run 'not reached' if its first sub-eps dip is
not held, even if it later settles below eps. Corrected: cost = EVDs at the
start of the final sub-eps suffix. Sections 9-11 below also use this rule.

| eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM | ordering (cheapest first) |
|---|---:|---:|---:|---:|---:|---:|---|
| 1e-02 | 2.0 (81/81) | 12.0 (81/81) | 12.0 (81/81) | 12.0 (81/81) | 22.0 (81/81) | 6.0 (81/81) | Newton-SIN-BH < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM |
| 1e-04 | 3.0 (81/81) | 41.0 (81/81) | 41.0 (81/81) | 42.0 (81/81) | 85.0 (81/81) | 21.0 (81/81) | Newton-SIN-BH < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM |
| 1e-06 | 4.0 (81/81) | 60.0 (81/81) | 65.0 (79/81) | 77.0 (81/81) | 156.0 (81/81) | 40.0 (81/81) | Newton-SIN-BH < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM |
| 1e-08 | 4.0 (81/81) | 90.0 (81/81) | 99.5 (76/81) | 112.0 (81/81) | 228.0 (81/81) | 64.0 (81/81) | Newton-SIN-BH < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM |
| 1e-10 | 4.0 (81/81) | 113.0 (81/81) | 145.0 (74/81) | 148.0 (81/81) | 301.0 (81/81) | 83.0 (81/81) | Newton-SIN-BH < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM |

## 9-11. Bootstrap sections

Instance names carry no paired-seed structure (real matrices), so no
bootstrap is possible. Per-matrix EVDs to each forward target instead
(`--` = not reached and held; forward error is against the COMPUTED
reference, not an exact X*):

| matrix | n | eps | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM |
|---|---:|---|---:|---:|---:|---:|---:|---:|
| thesiskkt-r100-m1-d0-p0 | 550 | 1e-02 | 2 | 13 | 13 | 8 | 15 | 6 |
| thesiskkt-r100-m1-d0-p0 | 550 | 1e-04 | 3 | 53 | 53 | 28 | 56 | 20 |
| thesiskkt-r100-m1-d0-p0 | 550 | 1e-06 | 3 | 65 | 65 | 50 | 102 | 36 |
| thesiskkt-r100-m1-d0-p0 | 550 | 1e-08 | 4 | 84 | 79 | 73 | 150 | 55 |
| thesiskkt-r100-m1-d0-p0 | 550 | 1e-10 | 4 | 125 | 98 | 97 | 200 | 74 |
| thesiskkt-r100-m1-d0-p1 | 550 | 1e-02 | 2 | 21 | 21 | 8 | 15 | 6 |
| thesiskkt-r100-m1-d0-p1 | 550 | 1e-04 | 3 | 74 | 74 | 28 | 56 | 20 |
| thesiskkt-r100-m1-d0-p1 | 550 | 1e-06 | 3 | 83 | 83 | 50 | 102 | 36 |
| thesiskkt-r100-m1-d0-p1 | 550 | 1e-08 | 4 | 102 | 132 | 73 | 150 | 55 |
| thesiskkt-r100-m1-d0-p1 | 550 | 1e-10 | 4 | 120 | 144 | 97 | 200 | 74 |
| thesiskkt-r100-m1-d0-p2 | 550 | 1e-02 | 2 | 13 | 13 | 8 | 15 | 6 |
| thesiskkt-r100-m1-d0-p2 | 550 | 1e-04 | 3 | 49 | 49 | 28 | 56 | 20 |
| thesiskkt-r100-m1-d0-p2 | 550 | 1e-06 | 3 | 68 | 68 | 50 | 102 | 36 |
| thesiskkt-r100-m1-d0-p2 | 550 | 1e-08 | 4 | 77 | 98 | 73 | 150 | 55 |
| thesiskkt-r100-m1-d0-p2 | 550 | 1e-10 | 4 | 112 | 158 | 97 | 200 | 74 |
| thesiskkt-r100-m1-d1e-05-p0 | 550 | 1e-02 | 2 | 13 | 13 | 8 | 15 | 6 |
| thesiskkt-r100-m1-d1e-05-p0 | 550 | 1e-04 | 3 | 44 | 44 | 28 | 56 | 20 |
| thesiskkt-r100-m1-d1e-05-p0 | 550 | 1e-06 | 4 | 56 | 56 | 50 | 102 | 35 |
| thesiskkt-r100-m1-d1e-05-p0 | 550 | 1e-08 | 4 | 93 | 101 | 73 | 150 | 53 |
| thesiskkt-r100-m1-d1e-05-p0 | 550 | 1e-10 | 4 | 137 | 139 | 97 | 200 | 71 |
| thesiskkt-r100-m1-d1e-05-p1 | 550 | 1e-02 | 2 | 20 | 20 | 8 | 15 | 6 |
| thesiskkt-r100-m1-d1e-05-p1 | 550 | 1e-04 | 3 | 54 | 54 | 28 | 56 | 20 |
| thesiskkt-r100-m1-d1e-05-p1 | 550 | 1e-06 | 4 | 66 | 66 | 50 | 102 | 36 |
| thesiskkt-r100-m1-d1e-05-p1 | 550 | 1e-08 | 4 | 96 | 122 | 73 | 150 | 54 |
| thesiskkt-r100-m1-d1e-05-p1 | 550 | 1e-10 | 4 | 109 | 155 | 97 | 200 | 72 |
| thesiskkt-r100-m1-d1e-05-p2 | 550 | 1e-02 | 2 | 13 | 13 | 8 | 15 | 6 |
| thesiskkt-r100-m1-d1e-05-p2 | 550 | 1e-04 | 3 | 45 | 45 | 28 | 56 | 20 |
| thesiskkt-r100-m1-d1e-05-p2 | 550 | 1e-06 | 4 | 64 | 64 | 50 | 102 | 35 |
| thesiskkt-r100-m1-d1e-05-p2 | 550 | 1e-08 | 4 | 87 | 121 | 73 | 150 | 53 |
| thesiskkt-r100-m1-d1e-05-p2 | 550 | 1e-10 | 4 | 93 | 152 | 97 | 200 | 71 |
| thesiskkt-r100-m1-d1e-09-p0 | 550 | 1e-02 | 2 | 13 | 13 | 8 | 15 | 6 |
| thesiskkt-r100-m1-d1e-09-p0 | 550 | 1e-04 | 3 | 54 | 54 | 28 | 56 | 20 |
| thesiskkt-r100-m1-d1e-09-p0 | 550 | 1e-06 | 3 | 64 | 90 | 50 | 102 | 36 |
| thesiskkt-r100-m1-d1e-09-p0 | 550 | 1e-08 | 4 | 85 | -- | 73 | 150 | 55 |
| thesiskkt-r100-m1-d1e-09-p0 | 550 | 1e-10 | 5 | 107 | -- | 97 | 200 | 74 |
| thesiskkt-r100-m1-d1e-09-p1 | 550 | 1e-02 | 2 | 21 | 21 | 8 | 15 | 6 |
| thesiskkt-r100-m1-d1e-09-p1 | 550 | 1e-04 | 3 | 76 | 76 | 28 | 56 | 20 |
| thesiskkt-r100-m1-d1e-09-p1 | 550 | 1e-06 | 3 | 95 | 109 | 50 | 102 | 36 |
| thesiskkt-r100-m1-d1e-09-p1 | 550 | 1e-08 | 4 | 142 | 163 | 73 | 150 | 55 |
| thesiskkt-r100-m1-d1e-09-p1 | 550 | 1e-10 | 5 | 157 | 223 | 97 | 200 | 74 |
| thesiskkt-r100-m1-d1e-09-p2 | 550 | 1e-02 | 2 | 13 | 13 | 8 | 15 | 6 |
| thesiskkt-r100-m1-d1e-09-p2 | 550 | 1e-04 | 3 | 51 | 51 | 28 | 56 | 20 |
| thesiskkt-r100-m1-d1e-09-p2 | 550 | 1e-06 | 3 | 65 | 65 | 50 | 102 | 36 |
| thesiskkt-r100-m1-d1e-09-p2 | 550 | 1e-08 | 4 | 90 | 79 | 73 | 150 | 55 |
| thesiskkt-r100-m1-d1e-09-p2 | 550 | 1e-10 | 5 | 99 | 119 | 97 | 200 | 73 |
| thesiskkt-r100-m20-d0-p0 | 550 | 1e-02 | 2 | 5 | 5 | 7 | 12 | 5 |
| thesiskkt-r100-m20-d0-p0 | 550 | 1e-04 | 3 | 13 | 13 | 23 | 47 | 17 |
| thesiskkt-r100-m20-d0-p0 | 550 | 1e-06 | 4 | 25 | 26 | 44 | 90 | 34 |
| thesiskkt-r100-m20-d0-p0 | 550 | 1e-08 | 4 | 49 | 48 | 66 | 136 | 52 |
| thesiskkt-r100-m20-d0-p0 | 550 | 1e-10 | 5 | 68 | 61 | 89 | 184 | 71 |
| thesiskkt-r100-m20-d0-p1 | 550 | 1e-02 | 2 | 5 | 5 | 7 | 12 | 5 |
| thesiskkt-r100-m20-d0-p1 | 550 | 1e-04 | 3 | 13 | 13 | 23 | 47 | 16 |
| thesiskkt-r100-m20-d0-p1 | 550 | 1e-06 | 4 | 44 | 61 | 44 | 90 | 33 |
| thesiskkt-r100-m20-d0-p1 | 550 | 1e-08 | 4 | 60 | 77 | 67 | 137 | 51 |
| thesiskkt-r100-m20-d0-p1 | 550 | 1e-10 | 5 | 68 | 105 | 90 | 186 | 68 |
| thesiskkt-r100-m20-d0-p2 | 550 | 1e-02 | 2 | 5 | 5 | 7 | 12 | 5 |
| thesiskkt-r100-m20-d0-p2 | 550 | 1e-04 | 3 | 13 | 13 | 23 | 47 | 18 |
| thesiskkt-r100-m20-d0-p2 | 550 | 1e-06 | 4 | 24 | 28 | 44 | 89 | 35 |
| thesiskkt-r100-m20-d0-p2 | 550 | 1e-08 | 4 | 45 | 61 | 65 | 135 | 52 |
| thesiskkt-r100-m20-d0-p2 | 550 | 1e-10 | 5 | 63 | 73 | 88 | 181 | 70 |
| thesiskkt-r100-m20-d1e-05-p0 | 550 | 1e-02 | 2 | 5 | 5 | 7 | 12 | 5 |
| thesiskkt-r100-m20-d1e-05-p0 | 550 | 1e-04 | 3 | 13 | 13 | 23 | 47 | 16 |
| thesiskkt-r100-m20-d1e-05-p0 | 550 | 1e-06 | 4 | 27 | 28 | 45 | 93 | 26 |
| thesiskkt-r100-m20-d1e-05-p0 | 550 | 1e-08 | 4 | 53 | 72 | 69 | 141 | 43 |
| thesiskkt-r100-m20-d1e-05-p0 | 550 | 1e-10 | 5 | 69 | 136 | 92 | 191 | 62 |
| thesiskkt-r100-m20-d1e-05-p1 | 550 | 1e-02 | 2 | 5 | 5 | 7 | 12 | 5 |
| thesiskkt-r100-m20-d1e-05-p1 | 550 | 1e-04 | 3 | 13 | 13 | 23 | 47 | 16 |
| thesiskkt-r100-m20-d1e-05-p1 | 550 | 1e-06 | 4 | 35 | 35 | 45 | 93 | 27 |
| thesiskkt-r100-m20-d1e-05-p1 | 550 | 1e-08 | 4 | 51 | 42 | 69 | 142 | 46 |
| thesiskkt-r100-m20-d1e-05-p1 | 550 | 1e-10 | 5 | 65 | 55 | 93 | 191 | 64 |
| thesiskkt-r100-m20-d1e-05-p2 | 550 | 1e-02 | 2 | 5 | 5 | 7 | 12 | 5 |
| thesiskkt-r100-m20-d1e-05-p2 | 550 | 1e-04 | 3 | 14 | 14 | 24 | 47 | 17 |
| thesiskkt-r100-m20-d1e-05-p2 | 550 | 1e-06 | 4 | 24 | 24 | 45 | 93 | 27 |
| thesiskkt-r100-m20-d1e-05-p2 | 550 | 1e-08 | 4 | 49 | 518 | 68 | 140 | 44 |
| thesiskkt-r100-m20-d1e-05-p2 | 550 | 1e-10 | 5 | 64 | 549 | 92 | 190 | 61 |
| thesiskkt-r100-m20-d1e-09-p0 | 550 | 1e-02 | 2 | 5 | 5 | 7 | 12 | 5 |
| thesiskkt-r100-m20-d1e-09-p0 | 550 | 1e-04 | 3 | 13 | 13 | 23 | 47 | 17 |
| thesiskkt-r100-m20-d1e-09-p0 | 550 | 1e-06 | 4 | 26 | 26 | 44 | 90 | 34 |
| thesiskkt-r100-m20-d1e-09-p0 | 550 | 1e-08 | 4 | 54 | 69 | 66 | 136 | 52 |
| thesiskkt-r100-m20-d1e-09-p0 | 550 | 1e-10 | 6 | 76 | 85 | 90 | 186 | 66 |
| thesiskkt-r100-m20-d1e-09-p1 | 550 | 1e-02 | 2 | 5 | 5 | 7 | 12 | 5 |
| thesiskkt-r100-m20-d1e-09-p1 | 550 | 1e-04 | 3 | 13 | 13 | 23 | 47 | 16 |
| thesiskkt-r100-m20-d1e-09-p1 | 550 | 1e-06 | 4 | 22 | 22 | 44 | 90 | 33 |
| thesiskkt-r100-m20-d1e-09-p1 | 550 | 1e-08 | 4 | 52 | 80 | 67 | 138 | 50 |
| thesiskkt-r100-m20-d1e-09-p1 | 550 | 1e-10 | 5 | 102 | 99 | 91 | 187 | 67 |
| thesiskkt-r100-m20-d1e-09-p2 | 550 | 1e-02 | 2 | 5 | 5 | 7 | 12 | 5 |
| thesiskkt-r100-m20-d1e-09-p2 | 550 | 1e-04 | 3 | 13 | 13 | 23 | 47 | 18 |
| thesiskkt-r100-m20-d1e-09-p2 | 550 | 1e-06 | 4 | 22 | 22 | 44 | 89 | 35 |
| thesiskkt-r100-m20-d1e-09-p2 | 550 | 1e-08 | 4 | 38 | 38 | 65 | 135 | 52 |
| thesiskkt-r100-m20-d1e-09-p2 | 550 | 1e-10 | 6 | 75 | 66 | 89 | 184 | 64 |
| thesiskkt-r100-m5-d0-p0 | 550 | 1e-02 | 2 | 14 | 14 | 8 | 14 | 6 |
| thesiskkt-r100-m5-d0-p0 | 550 | 1e-04 | 3 | 38 | 38 | 26 | 53 | 19 |
| thesiskkt-r100-m5-d0-p0 | 550 | 1e-06 | 4 | 48 | 48 | 48 | 99 | 36 |
| thesiskkt-r100-m5-d0-p0 | 550 | 1e-08 | 4 | 68 | 73 | 72 | 147 | 54 |
| thesiskkt-r100-m5-d0-p0 | 550 | 1e-10 | 4 | 104 | 126 | 95 | 196 | 73 |
| thesiskkt-r100-m5-d0-p1 | 550 | 1e-02 | 2 | 9 | 9 | 8 | 14 | 6 |
| thesiskkt-r100-m5-d0-p1 | 550 | 1e-04 | 3 | 28 | 28 | 27 | 53 | 19 |
| thesiskkt-r100-m5-d0-p1 | 550 | 1e-06 | 4 | 49 | 49 | 49 | 99 | 36 |
| thesiskkt-r100-m5-d0-p1 | 550 | 1e-08 | 4 | 73 | 81 | 72 | 148 | 54 |
| thesiskkt-r100-m5-d0-p1 | 550 | 1e-10 | 4 | 125 | 122 | 96 | 198 | 74 |
| thesiskkt-r100-m5-d0-p2 | 550 | 1e-02 | 2 | 12 | 12 | 8 | 14 | 6 |
| thesiskkt-r100-m5-d0-p2 | 550 | 1e-04 | 3 | 30 | 30 | 27 | 53 | 19 |
| thesiskkt-r100-m5-d0-p2 | 550 | 1e-06 | 4 | 38 | 38 | 48 | 99 | 36 |
| thesiskkt-r100-m5-d0-p2 | 550 | 1e-08 | 4 | 65 | 55 | 72 | 147 | 54 |
| thesiskkt-r100-m5-d0-p2 | 550 | 1e-10 | 4 | 77 | 109 | 96 | 197 | 73 |
| thesiskkt-r100-m5-d1e-05-p0 | 550 | 1e-02 | 2 | 14 | 14 | 8 | 14 | 6 |
| thesiskkt-r100-m5-d1e-05-p0 | 550 | 1e-04 | 3 | 37 | 37 | 27 | 53 | 19 |
| thesiskkt-r100-m5-d1e-05-p0 | 550 | 1e-06 | 4 | 47 | 87 | 49 | 99 | 32 |
| thesiskkt-r100-m5-d1e-05-p0 | 550 | 1e-08 | 4 | 71 | -- | 72 | 148 | 50 |
| thesiskkt-r100-m5-d1e-05-p0 | 550 | 1e-10 | 4 | 80 | -- | 96 | 198 | 68 |
| thesiskkt-r100-m5-d1e-05-p1 | 550 | 1e-02 | 2 | 9 | 9 | 8 | 14 | 6 |
| thesiskkt-r100-m5-d1e-05-p1 | 550 | 1e-04 | 3 | 25 | 25 | 27 | 54 | 19 |
| thesiskkt-r100-m5-d1e-05-p1 | 550 | 1e-06 | 4 | 41 | 44 | 49 | 100 | 32 |
| thesiskkt-r100-m5-d1e-05-p1 | 550 | 1e-08 | 4 | 62 | 57 | 72 | 149 | 49 |
| thesiskkt-r100-m5-d1e-05-p1 | 550 | 1e-10 | 4 | 73 | 72 | 96 | 198 | 67 |
| thesiskkt-r100-m5-d1e-05-p2 | 550 | 1e-02 | 2 | 12 | 12 | 8 | 14 | 6 |
| thesiskkt-r100-m5-d1e-05-p2 | 550 | 1e-04 | 3 | 42 | 42 | 27 | 54 | 19 |
| thesiskkt-r100-m5-d1e-05-p2 | 550 | 1e-06 | 4 | 51 | 52 | 49 | 100 | 35 |
| thesiskkt-r100-m5-d1e-05-p2 | 550 | 1e-08 | 4 | 61 | 79 | 72 | 148 | 53 |
| thesiskkt-r100-m5-d1e-05-p2 | 550 | 1e-10 | 4 | 97 | 106 | 96 | 198 | 71 |
| thesiskkt-r100-m5-d1e-09-p0 | 550 | 1e-02 | 2 | 14 | 14 | 8 | 14 | 6 |
| thesiskkt-r100-m5-d1e-09-p0 | 550 | 1e-04 | 3 | 34 | 34 | 26 | 53 | 19 |
| thesiskkt-r100-m5-d1e-09-p0 | 550 | 1e-06 | 4 | 49 | 66 | 48 | 99 | 36 |
| thesiskkt-r100-m5-d1e-09-p0 | 550 | 1e-08 | 4 | 74 | 77 | 72 | 147 | 54 |
| thesiskkt-r100-m5-d1e-09-p0 | 550 | 1e-10 | 5 | 94 | 93 | 95 | 197 | 73 |
| thesiskkt-r100-m5-d1e-09-p1 | 550 | 1e-02 | 2 | 9 | 9 | 8 | 14 | 6 |
| thesiskkt-r100-m5-d1e-09-p1 | 550 | 1e-04 | 3 | 28 | 28 | 27 | 53 | 19 |
| thesiskkt-r100-m5-d1e-09-p1 | 550 | 1e-06 | 4 | 37 | 37 | 49 | 99 | 36 |
| thesiskkt-r100-m5-d1e-09-p1 | 550 | 1e-08 | 4 | 61 | 97 | 72 | 148 | 54 |
| thesiskkt-r100-m5-d1e-09-p1 | 550 | 1e-10 | 5 | 98 | 112 | 96 | 198 | 73 |
| thesiskkt-r100-m5-d1e-09-p2 | 550 | 1e-02 | 2 | 12 | 12 | 8 | 14 | 6 |
| thesiskkt-r100-m5-d1e-09-p2 | 550 | 1e-04 | 3 | 30 | 30 | 27 | 53 | 19 |
| thesiskkt-r100-m5-d1e-09-p2 | 550 | 1e-06 | 4 | 41 | 42 | 48 | 99 | 36 |
| thesiskkt-r100-m5-d1e-09-p2 | 550 | 1e-08 | 4 | 52 | 94 | 72 | 147 | 54 |
| thesiskkt-r100-m5-d1e-09-p2 | 550 | 1e-10 | 5 | 80 | 120 | 96 | 197 | 72 |
| thesiskkt-r20-m1-d0-p0 | 550 | 1e-02 | 2 | 15 | 15 | 22 | 42 | 7 |
| thesiskkt-r20-m1-d0-p0 | 550 | 1e-04 | 3 | 99 | 99 | 97 | 193 | 38 |
| thesiskkt-r20-m1-d0-p0 | 550 | 1e-06 | 3 | 167 | 264 | 178 | 358 | 85 |
| thesiskkt-r20-m1-d0-p0 | 550 | 1e-08 | 4 | 200 | 300 | 263 | 528 | 133 |
| thesiskkt-r20-m1-d0-p0 | 550 | 1e-10 | 4 | 221 | 384 | 349 | 701 | 178 |
| thesiskkt-r20-m1-d0-p1 | 550 | 1e-02 | 2 | 10 | 10 | 22 | 42 | 8 |
| thesiskkt-r20-m1-d0-p1 | 550 | 1e-04 | 3 | 57 | 57 | 96 | 191 | 35 |
| thesiskkt-r20-m1-d0-p1 | 550 | 1e-06 | 3 | 81 | 98 | 177 | 354 | 74 |
| thesiskkt-r20-m1-d0-p1 | 550 | 1e-08 | 4 | 92 | 126 | 261 | 524 | 115 |
| thesiskkt-r20-m1-d0-p1 | 550 | 1e-10 | 4 | 113 | 165 | 347 | 697 | 149 |
| thesiskkt-r20-m1-d0-p2 | 550 | 1e-02 | 2 | 16 | 16 | 22 | 42 | 8 |
| thesiskkt-r20-m1-d0-p2 | 550 | 1e-04 | 3 | 77 | 77 | 96 | 192 | 33 |
| thesiskkt-r20-m1-d0-p2 | 550 | 1e-06 | 3 | 120 | 165 | 178 | 357 | 68 |
| thesiskkt-r20-m1-d0-p2 | 550 | 1e-08 | 4 | 204 | 241 | 263 | 528 | 107 |
| thesiskkt-r20-m1-d0-p2 | 550 | 1e-10 | 4 | 227 | 286 | 349 | 701 | 140 |
| thesiskkt-r20-m1-d1e-05-p0 | 550 | 1e-02 | 2 | 15 | 15 | 22 | 42 | 7 |
| thesiskkt-r20-m1-d1e-05-p0 | 550 | 1e-04 | 3 | 72 | 72 | 97 | 193 | 38 |
| thesiskkt-r20-m1-d1e-05-p0 | 550 | 1e-06 | 3 | 115 | 118 | 180 | 361 | 76 |
| thesiskkt-r20-m1-d1e-05-p0 | 550 | 1e-08 | 3 | 151 | 140 | 265 | 533 | 116 |
| thesiskkt-r20-m1-d1e-05-p0 | 550 | 1e-10 | 4 | 179 | 237 | 352 | 707 | 151 |
| thesiskkt-r20-m1-d1e-05-p1 | 550 | 1e-02 | 2 | 10 | 10 | 22 | 42 | 8 |
| thesiskkt-r20-m1-d1e-05-p1 | 550 | 1e-04 | 3 | 52 | 52 | 96 | 191 | 35 |
| thesiskkt-r20-m1-d1e-05-p1 | 550 | 1e-06 | 3 | 64 | 64 | 179 | 358 | 50 |
| thesiskkt-r20-m1-d1e-05-p1 | 550 | 1e-08 | 3 | 118 | 202 | 264 | 531 | 74 |
| thesiskkt-r20-m1-d1e-05-p1 | 550 | 1e-10 | 4 | 135 | 228 | 351 | 705 | 103 |
| thesiskkt-r20-m1-d1e-05-p2 | 550 | 1e-02 | 2 | 16 | 16 | 22 | 42 | 8 |
| thesiskkt-r20-m1-d1e-05-p2 | 550 | 1e-04 | 3 | 59 | 59 | 97 | 192 | 33 |
| thesiskkt-r20-m1-d1e-05-p2 | 550 | 1e-06 | 3 | 115 | 138 | 180 | 360 | 58 |
| thesiskkt-r20-m1-d1e-05-p2 | 550 | 1e-08 | 4 | 151 | 220 | 265 | 533 | 90 |
| thesiskkt-r20-m1-d1e-05-p2 | 550 | 1e-10 | 4 | 236 | 262 | 352 | 707 | 122 |
| thesiskkt-r20-m1-d1e-09-p0 | 550 | 1e-02 | 2 | 15 | 15 | 22 | 42 | 7 |
| thesiskkt-r20-m1-d1e-09-p0 | 550 | 1e-04 | 3 | 85 | 85 | 97 | 193 | 38 |
| thesiskkt-r20-m1-d1e-09-p0 | 550 | 1e-06 | 3 | 108 | 113 | 178 | 358 | 85 |
| thesiskkt-r20-m1-d1e-09-p0 | 550 | 1e-08 | 4 | 135 | 154 | 263 | 529 | 133 |
| thesiskkt-r20-m1-d1e-09-p0 | 550 | 1e-10 | 5 | 152 | 187 | 350 | 703 | 172 |
| thesiskkt-r20-m1-d1e-09-p1 | 550 | 1e-02 | 2 | 10 | 10 | 22 | 42 | 8 |
| thesiskkt-r20-m1-d1e-09-p1 | 550 | 1e-04 | 3 | 57 | 57 | 96 | 191 | 35 |
| thesiskkt-r20-m1-d1e-09-p1 | 550 | 1e-06 | 3 | 72 | 72 | 177 | 354 | 74 |
| thesiskkt-r20-m1-d1e-09-p1 | 550 | 1e-08 | 4 | 133 | 203 | 261 | 525 | 115 |
| thesiskkt-r20-m1-d1e-09-p1 | 550 | 1e-10 | 5 | 146 | 223 | 348 | 699 | 144 |
| thesiskkt-r20-m1-d1e-09-p2 | 550 | 1e-02 | 2 | 16 | 16 | 22 | 42 | 8 |
| thesiskkt-r20-m1-d1e-09-p2 | 550 | 1e-04 | 3 | 85 | 85 | 96 | 192 | 33 |
| thesiskkt-r20-m1-d1e-09-p2 | 550 | 1e-06 | 3 | 138 | 140 | 178 | 357 | 68 |
| thesiskkt-r20-m1-d1e-09-p2 | 550 | 1e-08 | 4 | 152 | 208 | 263 | 528 | 107 |
| thesiskkt-r20-m1-d1e-09-p2 | 550 | 1e-10 | 5 | 205 | 271 | 350 | 703 | 143 |
| thesiskkt-r20-m20-d0-p0 | 550 | 1e-02 | 2 | 5 | 5 | 14 | 26 | 6 |
| thesiskkt-r20-m20-d0-p0 | 550 | 1e-04 | 3 | 28 | 28 | 61 | 122 | 29 |
| thesiskkt-r20-m20-d0-p0 | 550 | 1e-06 | 4 | 59 | 58 | 138 | 277 | 76 |
| thesiskkt-r20-m20-d0-p0 | 550 | 1e-08 | 4 | 76 | 79 | 221 | 443 | 112 |
| thesiskkt-r20-m20-d0-p0 | 550 | 1e-10 | 4 | 90 | -- | 305 | 612 | 142 |
| thesiskkt-r20-m20-d0-p1 | 550 | 1e-02 | 2 | 5 | 5 | 14 | 26 | 6 |
| thesiskkt-r20-m20-d0-p1 | 550 | 1e-04 | 3 | 17 | 17 | 60 | 120 | 33 |
| thesiskkt-r20-m20-d0-p1 | 550 | 1e-06 | 4 | 58 | 93 | 134 | 269 | 85 |
| thesiskkt-r20-m20-d0-p1 | 550 | 1e-08 | 4 | 90 | 103 | 215 | 431 | 143 |
| thesiskkt-r20-m20-d0-p1 | 550 | 1e-10 | 5 | 115 | 141 | 297 | 597 | 189 |
| thesiskkt-r20-m20-d0-p2 | 550 | 1e-02 | 2 | 5 | 5 | 14 | 26 | 6 |
| thesiskkt-r20-m20-d0-p2 | 550 | 1e-04 | 3 | 25 | 25 | 62 | 123 | 30 |
| thesiskkt-r20-m20-d0-p2 | 550 | 1e-06 | 4 | 62 | 159 | 136 | 273 | 64 |
| thesiskkt-r20-m20-d0-p2 | 550 | 1e-08 | 4 | 83 | 248 | 216 | 434 | 86 |
| thesiskkt-r20-m20-d0-p2 | 550 | 1e-10 | 4 | 117 | 322 | 297 | 598 | 101 |
| thesiskkt-r20-m20-d1e-05-p0 | 550 | 1e-02 | 2 | 5 | 5 | 14 | 26 | 6 |
| thesiskkt-r20-m20-d1e-05-p0 | 550 | 1e-04 | 3 | 26 | 26 | 62 | 123 | 25 |
| thesiskkt-r20-m20-d1e-05-p0 | 550 | 1e-06 | 4 | 83 | 79 | 145 | 290 | 62 |
| thesiskkt-r20-m20-d1e-05-p0 | 550 | 1e-08 | 4 | 117 | 201 | 230 | 463 | 108 |
| thesiskkt-r20-m20-d1e-05-p0 | 550 | 1e-10 | 4 | 171 | 253 | 317 | 637 | 153 |
| thesiskkt-r20-m20-d1e-05-p1 | 550 | 1e-02 | 2 | 5 | 5 | 14 | 26 | 6 |
| thesiskkt-r20-m20-d1e-05-p1 | 550 | 1e-04 | 3 | 17 | 17 | 61 | 122 | 32 |
| thesiskkt-r20-m20-d1e-05-p1 | 550 | 1e-06 | 4 | 48 | 38 | 143 | 286 | 63 |
| thesiskkt-r20-m20-d1e-05-p1 | 550 | 1e-08 | 4 | 115 | 82 | 228 | 459 | 110 |
| thesiskkt-r20-m20-d1e-05-p1 | 550 | 1e-10 | 4 | 167 | 116 | 315 | 633 | 149 |
| thesiskkt-r20-m20-d1e-05-p2 | 550 | 1e-02 | 2 | 5 | 5 | 14 | 26 | 6 |
| thesiskkt-r20-m20-d1e-05-p2 | 550 | 1e-04 | 3 | 24 | 24 | 63 | 124 | 25 |
| thesiskkt-r20-m20-d1e-05-p2 | 550 | 1e-06 | 4 | 72 | 103 | 144 | 289 | 52 |
| thesiskkt-r20-m20-d1e-05-p2 | 550 | 1e-08 | 4 | 150 | 159 | 229 | 460 | 99 |
| thesiskkt-r20-m20-d1e-05-p2 | 550 | 1e-10 | 4 | 170 | 236 | 315 | 633 | 138 |
| thesiskkt-r20-m20-d1e-09-p0 | 550 | 1e-02 | 2 | 5 | 5 | 14 | 26 | 6 |
| thesiskkt-r20-m20-d1e-09-p0 | 550 | 1e-04 | 3 | 28 | 28 | 61 | 122 | 29 |
| thesiskkt-r20-m20-d1e-09-p0 | 550 | 1e-06 | 4 | 44 | 58 | 138 | 277 | 76 |
| thesiskkt-r20-m20-d1e-09-p0 | 550 | 1e-08 | 4 | 92 | 92 | 221 | 443 | 105 |
| thesiskkt-r20-m20-d1e-09-p0 | 550 | 1e-10 | 5 | 129 | 150 | 307 | 617 | 133 |
| thesiskkt-r20-m20-d1e-09-p1 | 550 | 1e-02 | 2 | 5 | 5 | 14 | 26 | 6 |
| thesiskkt-r20-m20-d1e-09-p1 | 550 | 1e-04 | 3 | 17 | 17 | 60 | 120 | 33 |
| thesiskkt-r20-m20-d1e-09-p1 | 550 | 1e-06 | 4 | 37 | 59 | 134 | 269 | 85 |
| thesiskkt-r20-m20-d1e-09-p1 | 550 | 1e-08 | 4 | 48 | 131 | 215 | 432 | 143 |
| thesiskkt-r20-m20-d1e-09-p1 | 550 | 1e-10 | 5 | 81 | 196 | 301 | 605 | 168 |
| thesiskkt-r20-m20-d1e-09-p2 | 550 | 1e-02 | 2 | 5 | 5 | 14 | 26 | 6 |
| thesiskkt-r20-m20-d1e-09-p2 | 550 | 1e-04 | 3 | 25 | 25 | 62 | 123 | 30 |
| thesiskkt-r20-m20-d1e-09-p2 | 550 | 1e-06 | 4 | 62 | 70 | 136 | 273 | 64 |
| thesiskkt-r20-m20-d1e-09-p2 | 550 | 1e-08 | 4 | 78 | 118 | 216 | 434 | 92 |
| thesiskkt-r20-m20-d1e-09-p2 | 550 | 1e-10 | 5 | 101 | 147 | 301 | 605 | 107 |
| thesiskkt-r20-m5-d0-p0 | 550 | 1e-02 | 2 | 15 | 15 | 19 | 37 | 7 |
| thesiskkt-r20-m5-d0-p0 | 550 | 1e-04 | 3 | 62 | 62 | 85 | 169 | 24 |
| thesiskkt-r20-m5-d0-p0 | 550 | 1e-06 | 3 | 87 | 94 | 165 | 330 | 53 |
| thesiskkt-r20-m5-d0-p0 | 550 | 1e-08 | 4 | 117 | 170 | 249 | 500 | 90 |
| thesiskkt-r20-m5-d0-p0 | 550 | 1e-10 | 4 | 144 | 227 | 334 | 672 | 124 |
| thesiskkt-r20-m5-d0-p1 | 550 | 1e-02 | 2 | 13 | 13 | 19 | 37 | 7 |
| thesiskkt-r20-m5-d0-p1 | 550 | 1e-04 | 3 | 55 | 55 | 84 | 168 | 24 |
| thesiskkt-r20-m5-d0-p1 | 550 | 1e-06 | 3 | 82 | 83 | 163 | 327 | 72 |
| thesiskkt-r20-m5-d0-p1 | 550 | 1e-08 | 4 | 90 | 91 | 247 | 497 | 130 |
| thesiskkt-r20-m5-d0-p1 | 550 | 1e-10 | 4 | 130 | 162 | 333 | 669 | 175 |
| thesiskkt-r20-m5-d0-p2 | 550 | 1e-02 | 2 | 10 | 10 | 19 | 37 | 7 |
| thesiskkt-r20-m5-d0-p2 | 550 | 1e-04 | 3 | 45 | 45 | 84 | 168 | 24 |
| thesiskkt-r20-m5-d0-p2 | 550 | 1e-06 | 3 | 60 | 57 | 162 | 325 | 63 |
| thesiskkt-r20-m5-d0-p2 | 550 | 1e-08 | 4 | 98 | 85 | 245 | 493 | 112 |
| thesiskkt-r20-m5-d0-p2 | 550 | 1e-10 | 4 | 117 | 121 | 330 | 663 | 158 |
| thesiskkt-r20-m5-d1e-05-p0 | 550 | 1e-02 | 2 | 15 | 15 | 19 | 37 | 7 |
| thesiskkt-r20-m5-d1e-05-p0 | 550 | 1e-04 | 3 | 77 | 77 | 85 | 170 | 24 |
| thesiskkt-r20-m5-d1e-05-p0 | 550 | 1e-06 | 4 | 148 | 165 | 169 | 339 | 52 |
| thesiskkt-r20-m5-d1e-05-p0 | 550 | 1e-08 | 4 | 191 | 224 | 255 | 512 | 92 |
| thesiskkt-r20-m5-d1e-05-p0 | 550 | 1e-10 | 4 | 264 | 252 | 341 | 686 | 125 |
| thesiskkt-r20-m5-d1e-05-p1 | 550 | 1e-02 | 2 | 12 | 12 | 19 | 37 | 7 |
| thesiskkt-r20-m5-d1e-05-p1 | 550 | 1e-04 | 3 | 59 | 59 | 85 | 168 | 24 |
| thesiskkt-r20-m5-d1e-05-p1 | 550 | 1e-06 | 4 | 83 | 83 | 168 | 337 | 52 |
| thesiskkt-r20-m5-d1e-05-p1 | 550 | 1e-08 | 4 | 97 | 101 | 254 | 510 | 82 |
| thesiskkt-r20-m5-d1e-05-p1 | 550 | 1e-10 | 4 | 115 | 169 | 340 | 684 | 114 |
| thesiskkt-r20-m5-d1e-05-p2 | 550 | 1e-02 | 2 | 10 | 10 | 19 | 37 | 7 |
| thesiskkt-r20-m5-d1e-05-p2 | 550 | 1e-04 | 3 | 32 | 32 | 85 | 169 | 25 |
| thesiskkt-r20-m5-d1e-05-p2 | 550 | 1e-06 | 4 | 53 | 63 | 168 | 336 | 56 |
| thesiskkt-r20-m5-d1e-05-p2 | 550 | 1e-08 | 4 | 77 | 90 | 253 | 508 | 91 |
| thesiskkt-r20-m5-d1e-05-p2 | 550 | 1e-10 | 4 | 89 | 159 | 339 | 682 | 128 |
| thesiskkt-r20-m5-d1e-09-p0 | 550 | 1e-02 | 2 | 15 | 15 | 19 | 37 | 7 |
| thesiskkt-r20-m5-d1e-09-p0 | 550 | 1e-04 | 3 | 71 | 71 | 85 | 169 | 24 |
| thesiskkt-r20-m5-d1e-09-p0 | 550 | 1e-06 | 3 | 109 | 125 | 165 | 330 | 54 |
| thesiskkt-r20-m5-d1e-09-p0 | 550 | 1e-08 | 4 | 142 | 145 | 249 | 500 | 96 |
| thesiskkt-r20-m5-d1e-09-p0 | 550 | 1e-10 | 5 | 167 | 174 | 336 | 675 | 127 |
| thesiskkt-r20-m5-d1e-09-p1 | 550 | 1e-02 | 2 | 13 | 13 | 19 | 37 | 7 |
| thesiskkt-r20-m5-d1e-09-p1 | 550 | 1e-04 | 3 | 57 | 57 | 84 | 168 | 24 |
| thesiskkt-r20-m5-d1e-09-p1 | 550 | 1e-06 | 3 | 102 | 113 | 163 | 327 | 72 |
| thesiskkt-r20-m5-d1e-09-p1 | 550 | 1e-08 | 4 | 121 | 193 | 248 | 497 | 130 |
| thesiskkt-r20-m5-d1e-09-p1 | 550 | 1e-10 | 5 | 174 | 259 | 334 | 672 | 177 |
| thesiskkt-r20-m5-d1e-09-p2 | 550 | 1e-02 | 2 | 10 | 10 | 19 | 37 | 7 |
| thesiskkt-r20-m5-d1e-09-p2 | 550 | 1e-04 | 3 | 45 | 45 | 84 | 168 | 24 |
| thesiskkt-r20-m5-d1e-09-p2 | 550 | 1e-06 | 3 | 61 | 71 | 162 | 325 | 63 |
| thesiskkt-r20-m5-d1e-09-p2 | 550 | 1e-08 | 4 | 77 | 171 | 246 | 493 | 112 |
| thesiskkt-r20-m5-d1e-09-p2 | 550 | 1e-10 | 5 | 109 | 203 | 332 | 667 | 154 |
| thesiskkt-r50-m1-d0-p0 | 550 | 1e-02 | 2 | 18 | 18 | 13 | 23 | 7 |
| thesiskkt-r50-m1-d0-p0 | 550 | 1e-04 | 3 | 78 | 78 | 45 | 91 | 21 |
| thesiskkt-r50-m1-d0-p0 | 550 | 1e-06 | 3 | 90 | 92 | 81 | 163 | 42 |
| thesiskkt-r50-m1-d0-p0 | 550 | 1e-08 | 4 | 122 | 134 | 116 | 237 | 67 |
| thesiskkt-r50-m1-d0-p0 | 550 | 1e-10 | 4 | 146 | 161 | 152 | 311 | 91 |
| thesiskkt-r50-m1-d0-p1 | 550 | 1e-02 | 2 | 17 | 17 | 13 | 23 | 7 |
| thesiskkt-r50-m1-d0-p1 | 550 | 1e-04 | 3 | 49 | 49 | 45 | 91 | 21 |
| thesiskkt-r50-m1-d0-p1 | 550 | 1e-06 | 3 | 78 | 88 | 81 | 163 | 43 |
| thesiskkt-r50-m1-d0-p1 | 550 | 1e-08 | 4 | 93 | 135 | 116 | 236 | 68 |
| thesiskkt-r50-m1-d0-p1 | 550 | 1e-10 | 4 | 174 | 170 | 152 | 310 | 92 |
| thesiskkt-r50-m1-d0-p2 | 550 | 1e-02 | 2 | 21 | 21 | 13 | 23 | 7 |
| thesiskkt-r50-m1-d0-p2 | 550 | 1e-04 | 3 | 60 | 60 | 45 | 91 | 21 |
| thesiskkt-r50-m1-d0-p2 | 550 | 1e-06 | 3 | 82 | 101 | 80 | 163 | 42 |
| thesiskkt-r50-m1-d0-p2 | 550 | 1e-08 | 4 | 111 | 119 | 116 | 236 | 67 |
| thesiskkt-r50-m1-d0-p2 | 550 | 1e-10 | 4 | 137 | 171 | 152 | 310 | 91 |
| thesiskkt-r50-m1-d1e-05-p0 | 550 | 1e-02 | 2 | 17 | 17 | 13 | 23 | 7 |
| thesiskkt-r50-m1-d1e-05-p0 | 550 | 1e-04 | 3 | 84 | 84 | 45 | 91 | 21 |
| thesiskkt-r50-m1-d1e-05-p0 | 550 | 1e-06 | 3 | 101 | 101 | 81 | 164 | 43 |
| thesiskkt-r50-m1-d1e-05-p0 | 550 | 1e-08 | 4 | 124 | 137 | 117 | 238 | 69 |
| thesiskkt-r50-m1-d1e-05-p0 | 550 | 1e-10 | 4 | 157 | 171 | 153 | 312 | 92 |
| thesiskkt-r50-m1-d1e-05-p1 | 550 | 1e-02 | 2 | 17 | 17 | 13 | 23 | 7 |
| thesiskkt-r50-m1-d1e-05-p1 | 550 | 1e-04 | 3 | 51 | 51 | 45 | 91 | 21 |
| thesiskkt-r50-m1-d1e-05-p1 | 550 | 1e-06 | 4 | 101 | 108 | 81 | 164 | 40 |
| thesiskkt-r50-m1-d1e-05-p1 | 550 | 1e-08 | 4 | 113 | 149 | 117 | 238 | 64 |
| thesiskkt-r50-m1-d1e-05-p1 | 550 | 1e-10 | 4 | 182 | 162 | 153 | 312 | 84 |
| thesiskkt-r50-m1-d1e-05-p2 | 550 | 1e-02 | 2 | 21 | 21 | 13 | 23 | 7 |
| thesiskkt-r50-m1-d1e-05-p2 | 550 | 1e-04 | 3 | 51 | 51 | 45 | 91 | 21 |
| thesiskkt-r50-m1-d1e-05-p2 | 550 | 1e-06 | 3 | 68 | 68 | 81 | 164 | 34 |
| thesiskkt-r50-m1-d1e-05-p2 | 550 | 1e-08 | 4 | 81 | 931 | 117 | 238 | 54 |
| thesiskkt-r50-m1-d1e-05-p2 | 550 | 1e-10 | 4 | 108 | 959 | 153 | 312 | 74 |
| thesiskkt-r50-m1-d1e-09-p0 | 550 | 1e-02 | 2 | 18 | 18 | 13 | 23 | 7 |
| thesiskkt-r50-m1-d1e-09-p0 | 550 | 1e-04 | 3 | 77 | 77 | 45 | 91 | 21 |
| thesiskkt-r50-m1-d1e-09-p0 | 550 | 1e-06 | 3 | 124 | 106 | 81 | 163 | 42 |
| thesiskkt-r50-m1-d1e-09-p0 | 550 | 1e-08 | 4 | 155 | 117 | 116 | 237 | 67 |
| thesiskkt-r50-m1-d1e-09-p0 | 550 | 1e-10 | 5 | 172 | 130 | 153 | 311 | 92 |
| thesiskkt-r50-m1-d1e-09-p1 | 550 | 1e-02 | 2 | 17 | 17 | 13 | 23 | 7 |
| thesiskkt-r50-m1-d1e-09-p1 | 550 | 1e-04 | 3 | 49 | 49 | 45 | 91 | 21 |
| thesiskkt-r50-m1-d1e-09-p1 | 550 | 1e-06 | 3 | 60 | 60 | 81 | 163 | 43 |
| thesiskkt-r50-m1-d1e-09-p1 | 550 | 1e-08 | 4 | 74 | 77 | 116 | 236 | 68 |
| thesiskkt-r50-m1-d1e-09-p1 | 550 | 1e-10 | 5 | 90 | 138 | 153 | 311 | 91 |
| thesiskkt-r50-m1-d1e-09-p2 | 550 | 1e-02 | 2 | 21 | 21 | 13 | 23 | 7 |
| thesiskkt-r50-m1-d1e-09-p2 | 550 | 1e-04 | 3 | 62 | 62 | 45 | 91 | 21 |
| thesiskkt-r50-m1-d1e-09-p2 | 550 | 1e-06 | 3 | 90 | -- | 80 | 163 | 42 |
| thesiskkt-r50-m1-d1e-09-p2 | 550 | 1e-08 | 4 | 123 | -- | 116 | 236 | 67 |
| thesiskkt-r50-m1-d1e-09-p2 | 550 | 1e-10 | 5 | 134 | -- | 152 | 311 | 92 |
| thesiskkt-r50-m20-d0-p0 | 550 | 1e-02 | 2 | 5 | 5 | 10 | 17 | 6 |
| thesiskkt-r50-m20-d0-p0 | 550 | 1e-04 | 3 | 14 | 14 | 35 | 70 | 19 |
| thesiskkt-r50-m20-d0-p0 | 550 | 1e-06 | 4 | 28 | 32 | 68 | 137 | 32 |
| thesiskkt-r50-m20-d0-p0 | 550 | 1e-08 | 4 | 42 | 62 | 102 | 208 | 52 |
| thesiskkt-r50-m20-d0-p0 | 550 | 1e-10 | 5 | 79 | 126 | 137 | 279 | 74 |
| thesiskkt-r50-m20-d0-p1 | 550 | 1e-02 | 2 | 5 | 5 | 10 | 17 | 6 |
| thesiskkt-r50-m20-d0-p1 | 550 | 1e-04 | 3 | 17 | 17 | 35 | 69 | 18 |
| thesiskkt-r50-m20-d0-p1 | 550 | 1e-06 | 4 | 54 | 31 | 66 | 134 | 35 |
| thesiskkt-r50-m20-d0-p1 | 550 | 1e-08 | 4 | 92 | -- | 99 | 202 | 59 |
| thesiskkt-r50-m20-d0-p1 | 550 | 1e-10 | 5 | 104 | -- | 133 | 271 | 80 |
| thesiskkt-r50-m20-d0-p2 | 550 | 1e-02 | 2 | 5 | 5 | 10 | 17 | 6 |
| thesiskkt-r50-m20-d0-p2 | 550 | 1e-04 | 3 | 22 | 22 | 35 | 69 | 18 |
| thesiskkt-r50-m20-d0-p2 | 550 | 1e-06 | 4 | 39 | 39 | 66 | 134 | 32 |
| thesiskkt-r50-m20-d0-p2 | 550 | 1e-08 | 4 | 72 | 63 | 99 | 202 | 51 |
| thesiskkt-r50-m20-d0-p2 | 550 | 1e-10 | 5 | 98 | 111 | 133 | 271 | 74 |
| thesiskkt-r50-m20-d1e-05-p0 | 550 | 1e-02 | 2 | 5 | 5 | 10 | 17 | 6 |
| thesiskkt-r50-m20-d1e-05-p0 | 550 | 1e-04 | 3 | 15 | 15 | 35 | 71 | 18 |
| thesiskkt-r50-m20-d1e-05-p0 | 550 | 1e-06 | 4 | 52 | 76 | 71 | 144 | 33 |
| thesiskkt-r50-m20-d1e-05-p0 | 550 | 1e-08 | 4 | 81 | 108 | 107 | 218 | 50 |
| thesiskkt-r50-m20-d1e-05-p0 | 550 | 1e-10 | 4 | 92 | 132 | 144 | 293 | 68 |
| thesiskkt-r50-m20-d1e-05-p1 | 550 | 1e-02 | 2 | 5 | 5 | 10 | 17 | 6 |
| thesiskkt-r50-m20-d1e-05-p1 | 550 | 1e-04 | 3 | 20 | 20 | 35 | 70 | 18 |
| thesiskkt-r50-m20-d1e-05-p1 | 550 | 1e-06 | 4 | 50 | 67 | 70 | 142 | 35 |
| thesiskkt-r50-m20-d1e-05-p1 | 550 | 1e-08 | 4 | 97 | 883 | 106 | 216 | 54 |
| thesiskkt-r50-m20-d1e-05-p1 | 550 | 1e-10 | 4 | 137 | 939 | 142 | 290 | 75 |
| thesiskkt-r50-m20-d1e-05-p2 | 550 | 1e-02 | 2 | 5 | 5 | 10 | 17 | 6 |
| thesiskkt-r50-m20-d1e-05-p2 | 550 | 1e-04 | 3 | 16 | 16 | 35 | 70 | 18 |
| thesiskkt-r50-m20-d1e-05-p2 | 550 | 1e-06 | 4 | 47 | 49 | 70 | 142 | 33 |
| thesiskkt-r50-m20-d1e-05-p2 | 550 | 1e-08 | 4 | 124 | 72 | 106 | 216 | 50 |
| thesiskkt-r50-m20-d1e-05-p2 | 550 | 1e-10 | 4 | 177 | 117 | 142 | 290 | 68 |
| thesiskkt-r50-m20-d1e-09-p0 | 550 | 1e-02 | 2 | 5 | 5 | 10 | 17 | 6 |
| thesiskkt-r50-m20-d1e-09-p0 | 550 | 1e-04 | 3 | 14 | 14 | 35 | 70 | 19 |
| thesiskkt-r50-m20-d1e-09-p0 | 550 | 1e-06 | 4 | 33 | 33 | 68 | 137 | 32 |
| thesiskkt-r50-m20-d1e-09-p0 | 550 | 1e-08 | 4 | 88 | 130 | 102 | 208 | 51 |
| thesiskkt-r50-m20-d1e-09-p0 | 550 | 1e-10 | 5 | 107 | 147 | 139 | 283 | 63 |
| thesiskkt-r50-m20-d1e-09-p1 | 550 | 1e-02 | 2 | 5 | 5 | 10 | 17 | 6 |
| thesiskkt-r50-m20-d1e-09-p1 | 550 | 1e-04 | 3 | 17 | 17 | 35 | 69 | 18 |
| thesiskkt-r50-m20-d1e-09-p1 | 550 | 1e-06 | 4 | 33 | 37 | 66 | 134 | 35 |
| thesiskkt-r50-m20-d1e-09-p1 | 550 | 1e-08 | 4 | 74 | 61 | 99 | 202 | 58 |
| thesiskkt-r50-m20-d1e-09-p1 | 550 | 1e-10 | 5 | 93 | 76 | 135 | 276 | 80 |
| thesiskkt-r50-m20-d1e-09-p2 | 550 | 1e-02 | 2 | 5 | 5 | 10 | 17 | 6 |
| thesiskkt-r50-m20-d1e-09-p2 | 550 | 1e-04 | 3 | 22 | 22 | 35 | 69 | 18 |
| thesiskkt-r50-m20-d1e-09-p2 | 550 | 1e-06 | 4 | 34 | 46 | 66 | 134 | 32 |
| thesiskkt-r50-m20-d1e-09-p2 | 550 | 1e-08 | 4 | 120 | 66 | 100 | 203 | 49 |
| thesiskkt-r50-m20-d1e-09-p2 | 550 | 1e-10 | 5 | 172 | 102 | 135 | 276 | 68 |
| thesiskkt-r50-m5-d0-p0 | 550 | 1e-02 | 2 | 14 | 14 | 12 | 22 | 7 |
| thesiskkt-r50-m5-d0-p0 | 550 | 1e-04 | 3 | 41 | 41 | 43 | 85 | 22 |
| thesiskkt-r50-m5-d0-p0 | 550 | 1e-06 | 3 | 55 | 56 | 77 | 156 | 44 |
| thesiskkt-r50-m5-d0-p0 | 550 | 1e-08 | 4 | 95 | 95 | 112 | 228 | 70 |
| thesiskkt-r50-m5-d0-p0 | 550 | 1e-10 | 4 | 120 | 127 | 148 | 301 | 94 |
| thesiskkt-r50-m5-d0-p1 | 550 | 1e-02 | 2 | 11 | 11 | 12 | 22 | 7 |
| thesiskkt-r50-m5-d0-p1 | 550 | 1e-04 | 3 | 60 | 60 | 42 | 84 | 22 |
| thesiskkt-r50-m5-d0-p1 | 550 | 1e-06 | 3 | 70 | 71 | 75 | 152 | 43 |
| thesiskkt-r50-m5-d0-p1 | 550 | 1e-08 | 4 | 93 | 109 | 109 | 223 | 67 |
| thesiskkt-r50-m5-d0-p1 | 550 | 1e-10 | 4 | 113 | 132 | 144 | 294 | 90 |
| thesiskkt-r50-m5-d0-p2 | 550 | 1e-02 | 2 | 13 | 13 | 12 | 22 | 7 |
| thesiskkt-r50-m5-d0-p2 | 550 | 1e-04 | 3 | 43 | 43 | 42 | 85 | 22 |
| thesiskkt-r50-m5-d0-p2 | 550 | 1e-06 | 3 | 53 | -- | 76 | 153 | 43 |
| thesiskkt-r50-m5-d0-p2 | 550 | 1e-08 | 4 | 103 | -- | 110 | 224 | 69 |
| thesiskkt-r50-m5-d0-p2 | 550 | 1e-10 | 4 | 136 | -- | 145 | 296 | 92 |
| thesiskkt-r50-m5-d1e-05-p0 | 550 | 1e-02 | 2 | 14 | 14 | 12 | 22 | 7 |
| thesiskkt-r50-m5-d1e-05-p0 | 550 | 1e-04 | 3 | 48 | 48 | 43 | 86 | 23 |
| thesiskkt-r50-m5-d1e-05-p0 | 550 | 1e-06 | 4 | 69 | 71 | 78 | 159 | 35 |
| thesiskkt-r50-m5-d1e-05-p0 | 550 | 1e-08 | 4 | 84 | 94 | 114 | 233 | 58 |
| thesiskkt-r50-m5-d1e-05-p0 | 550 | 1e-10 | 4 | 104 | 114 | 151 | 307 | 83 |
| thesiskkt-r50-m5-d1e-05-p1 | 550 | 1e-02 | 2 | 11 | 11 | 12 | 22 | 7 |
| thesiskkt-r50-m5-d1e-05-p1 | 550 | 1e-04 | 3 | 35 | 35 | 42 | 84 | 22 |
| thesiskkt-r50-m5-d1e-05-p1 | 550 | 1e-06 | 4 | 51 | 54 | 77 | 156 | 35 |
| thesiskkt-r50-m5-d1e-05-p1 | 550 | 1e-08 | 4 | 71 | 70 | 113 | 230 | 59 |
| thesiskkt-r50-m5-d1e-05-p1 | 550 | 1e-10 | 4 | 114 | 110 | 149 | 304 | 82 |
| thesiskkt-r50-m5-d1e-05-p2 | 550 | 1e-02 | 2 | 13 | 13 | 12 | 22 | 7 |
| thesiskkt-r50-m5-d1e-05-p2 | 550 | 1e-04 | 3 | 37 | 37 | 42 | 85 | 22 |
| thesiskkt-r50-m5-d1e-05-p2 | 550 | 1e-06 | 4 | 43 | 43 | 78 | 157 | 35 |
| thesiskkt-r50-m5-d1e-05-p2 | 550 | 1e-08 | 4 | 63 | 75 | 113 | 231 | 57 |
| thesiskkt-r50-m5-d1e-05-p2 | 550 | 1e-10 | 4 | 79 | 146 | 150 | 305 | 82 |
| thesiskkt-r50-m5-d1e-09-p0 | 550 | 1e-02 | 2 | 14 | 14 | 12 | 22 | 7 |
| thesiskkt-r50-m5-d1e-09-p0 | 550 | 1e-04 | 3 | 41 | 41 | 43 | 85 | 22 |
| thesiskkt-r50-m5-d1e-09-p0 | 550 | 1e-06 | 3 | 53 | 59 | 77 | 156 | 44 |
| thesiskkt-r50-m5-d1e-09-p0 | 550 | 1e-08 | 4 | 67 | 80 | 112 | 228 | 69 |
| thesiskkt-r50-m5-d1e-09-p0 | 550 | 1e-10 | 5 | 92 | 114 | 149 | 303 | 91 |
| thesiskkt-r50-m5-d1e-09-p1 | 550 | 1e-02 | 2 | 11 | 11 | 12 | 22 | 7 |
| thesiskkt-r50-m5-d1e-09-p1 | 550 | 1e-04 | 3 | 36 | 36 | 42 | 84 | 22 |
| thesiskkt-r50-m5-d1e-09-p1 | 550 | 1e-06 | 3 | 45 | 45 | 75 | 152 | 43 |
| thesiskkt-r50-m5-d1e-09-p1 | 550 | 1e-08 | 4 | 75 | 87 | 110 | 223 | 67 |
| thesiskkt-r50-m5-d1e-09-p1 | 550 | 1e-10 | 5 | 124 | -- | 146 | 297 | 81 |
| thesiskkt-r50-m5-d1e-09-p2 | 550 | 1e-02 | 2 | 13 | 13 | 12 | 22 | 7 |
| thesiskkt-r50-m5-d1e-09-p2 | 550 | 1e-04 | 3 | 55 | 55 | 42 | 85 | 22 |
| thesiskkt-r50-m5-d1e-09-p2 | 550 | 1e-06 | 3 | 67 | 68 | 76 | 153 | 43 |
| thesiskkt-r50-m5-d1e-09-p2 | 550 | 1e-08 | 4 | 92 | 82 | 110 | 224 | 68 |
| thesiskkt-r50-m5-d1e-09-p2 | 550 | 1e-10 | 5 | 104 | 132 | 146 | 299 | 92 |

| matrix | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM |
|---|---|---|---|---|---|---|
| thesiskkt-r100-m1-d0-p0 | 4 EVDs, converged, err 8.9e-13 | 128 EVDs, diag_feasible, err 1.2e-11 | 126 EVDs, diag_feasible, err 2.2e-11 | 103 EVDs, diag_feasible, err 2.9e-11 | 212 EVDs, diag_feasible, err 3.2e-11 | 77 EVDs, diag_feasible, err 2.1e-11 |
| thesiskkt-r100-m1-d0-p1 | 4 EVDs, converged, err 8.8e-13 | 134 EVDs, diag_feasible_at_xpre, err 1.3e-11 | 151 EVDs, diag_feasible, err 1.7e-11 | 103 EVDs, diag_feasible, err 2.8e-11 | 212 EVDs, diag_feasible, err 3.1e-11 | 77 EVDs, diag_feasible, err 2.4e-11 |
| thesiskkt-r100-m1-d0-p2 | 4 EVDs, converged, err 1.3e-12 | 117 EVDs, diag_feasible_at_xpre, err 1.6e-11 | 162 EVDs, diag_feasible, err 8.7e-12 | 103 EVDs, diag_feasible, err 2.9e-11 | 212 EVDs, diag_feasible, err 3.2e-11 | 77 EVDs, diag_feasible, err 1.7e-11 |
| thesiskkt-r100-m1-d1e-05-p0 | 4 EVDs, converged, err 1.4e-12 | 166 EVDs, diag_feasible_at_xpre, err 1.8e-11 | 151 EVDs, diag_feasible, err 1.8e-11 | 103 EVDs, diag_feasible, err 2.9e-11 | 212 EVDs, diag_feasible, err 3.2e-11 | 76 EVDs, diag_feasible, err 2.8e-11 |
| thesiskkt-r100-m1-d1e-05-p1 | 4 EVDs, converged, err 1.9e-12 | 116 EVDs, diag_feasible_at_xpre, err 5.7e-12 | 174 EVDs, diag_feasible, err 1.7e-11 | 103 EVDs, diag_feasible, err 2.9e-11 | 212 EVDs, diag_feasible, err 3.2e-11 | 76 EVDs, diag_feasible, err 2.4e-11 |
| thesiskkt-r100-m1-d1e-05-p2 | 4 EVDs, converged, err 1.3e-12 | 104 EVDs, diag_feasible_at_xpre, err 1.5e-11 | 155 EVDs, diag_feasible_at_xpre, err 1.2e-11 | 103 EVDs, diag_feasible, err 2.9e-11 | 212 EVDs, diag_feasible, err 3.2e-11 | 74 EVDs, diag_feasible, err 2.5e-11 |
| thesiskkt-r100-m1-d1e-09-p0 | 5 EVDs, converged, err 9.2e-13 | 114 EVDs, diag_feasible, err 1.6e-11 | 4038 EVDs, evd_budget, err 5.9e-08 | 103 EVDs, diag_feasible, err 2.9e-11 | 212 EVDs, diag_feasible, err 3.2e-11 | 77 EVDs, diag_feasible, err 2.5e-11 |
| thesiskkt-r100-m1-d1e-09-p1 | 5 EVDs, converged, err 6.1e-13 | 171 EVDs, diag_feasible, err 1.9e-11 | 258 EVDs, diag_feasible, err 1.9e-11 | 103 EVDs, diag_feasible, err 2.9e-11 | 212 EVDs, diag_feasible, err 3.2e-11 | 77 EVDs, diag_feasible, err 2.4e-11 |
| thesiskkt-r100-m1-d1e-09-p2 | 5 EVDs, converged, err 8.3e-13 | 103 EVDs, diag_feasible_at_xpre, err 1.0e-11 | 123 EVDs, diag_feasible_at_xpre, err 5.6e-12 | 103 EVDs, diag_feasible, err 2.9e-11 | 212 EVDs, diag_feasible, err 3.2e-11 | 77 EVDs, diag_feasible, err 2.1e-11 |
| thesiskkt-r100-m20-d0-p0 | 5 EVDs, converged, err 7.1e-13 | 71 EVDs, diag_feasible_at_xpre, err 1.8e-11 | 70 EVDs, diag_feasible, err 1.4e-11 | 95 EVDs, diag_feasible, err 2.8e-11 | 196 EVDs, diag_feasible, err 3.1e-11 | 74 EVDs, diag_feasible, err 2.4e-11 |
| thesiskkt-r100-m20-d0-p1 | 5 EVDs, converged, err 9.2e-13 | 71 EVDs, diag_feasible, err 8.7e-12 | 4011 EVDs, evd_budget, err 2.7e-11 | 96 EVDs, diag_feasible, err 2.9e-11 | 198 EVDs, diag_feasible, err 3.1e-11 | 71 EVDs, diag_feasible, err 3.0e-11 |
| thesiskkt-r100-m20-d0-p2 | 5 EVDs, converged, err 6.7e-13 | 67 EVDs, diag_feasible_at_xpre, err 1.3e-11 | 101 EVDs, diag_feasible, err 1.7e-11 | 93 EVDs, diag_feasible, err 3.1e-11 | 193 EVDs, diag_feasible, err 3.1e-11 | 74 EVDs, diag_feasible, err 2.2e-11 |
| thesiskkt-r100-m20-d1e-05-p0 | 5 EVDs, converged, err 5.2e-13 | 74 EVDs, diag_feasible_at_xpre, err 1.4e-11 | 137 EVDs, diag_feasible_at_xpre, err 1.5e-11 | 98 EVDs, diag_feasible, err 3.0e-11 | 202 EVDs, diag_feasible, err 3.3e-11 | 65 EVDs, diag_feasible, err 2.8e-11 |
| thesiskkt-r100-m20-d1e-05-p1 | 5 EVDs, converged, err 3.7e-13 | 72 EVDs, diag_feasible_at_xpre, err 7.6e-12 | 56 EVDs, diag_feasible_at_xpre, err 8.8e-12 | 98 EVDs, diag_feasible, err 3.2e-11 | 203 EVDs, diag_feasible, err 3.2e-11 | 68 EVDs, diag_feasible, err 2.1e-11 |
| thesiskkt-r100-m20-d1e-05-p2 | 5 EVDs, converged, err 6.2e-13 | 67 EVDs, diag_feasible, err 1.6e-11 | 550 EVDs, diag_feasible_at_xpre, err 1.4e-11 | 98 EVDs, diag_feasible, err 2.8e-11 | 202 EVDs, diag_feasible, err 3.1e-11 | 63 EVDs, diag_feasible, err 2.1e-11 |
| thesiskkt-r100-m20-d1e-09-p0 | 6 EVDs, converged, err 7.9e-13 | 79 EVDs, diag_feasible, err 1.2e-11 | 95 EVDs, diag_feasible_at_xpre, err 1.2e-11 | 96 EVDs, diag_feasible, err 2.9e-11 | 198 EVDs, diag_feasible, err 3.1e-11 | 70 EVDs, diag_feasible, err 2.5e-11 |
| thesiskkt-r100-m20-d1e-09-p1 | 5 EVDs, converged, err 6.8e-13 | 107 EVDs, diag_feasible, err 1.8e-11 | 106 EVDs, diag_feasible_at_xpre, err 3.2e-12 | 96 EVDs, diag_feasible, err 3.4e-11 | 199 EVDs, diag_feasible, err 3.3e-11 | 71 EVDs, diag_feasible, err 2.6e-11 |
| thesiskkt-r100-m20-d1e-09-p2 | 6 EVDs, converged, err 6.2e-13 | 80 EVDs, diag_feasible_at_xpre, err 1.6e-11 | 83 EVDs, diag_feasible_at_xpre, err 1.4e-11 | 95 EVDs, diag_feasible, err 2.8e-11 | 196 EVDs, diag_feasible, err 3.1e-11 | 67 EVDs, diag_feasible, err 1.2e-11 |
| thesiskkt-r100-m5-d0-p0 | 5 EVDs, converged, err 1.7e-12 | 115 EVDs, diag_feasible_at_xpre, err 1.2e-11 | 4017 EVDs, evd_budget, err 7.3e-11 | 101 EVDs, diag_feasible, err 3.0e-11 | 208 EVDs, diag_feasible, err 3.3e-11 | 77 EVDs, diag_feasible, err 1.6e-11 |
| thesiskkt-r100-m5-d0-p1 | 4 EVDs, converged, err 2.6e-11 | 128 EVDs, diag_feasible, err 1.5e-11 | 161 EVDs, diag_feasible_at_xpre, err 1.4e-11 | 101 EVDs, diag_feasible, err 3.4e-11 | 209 EVDs, diag_feasible, err 3.3e-11 | 76 EVDs, diag_feasible, err 2.5e-11 |
| thesiskkt-r100-m5-d0-p2 | 5 EVDs, converged, err 1.9e-12 | 82 EVDs, diag_feasible_at_xpre, err 1.7e-11 | 113 EVDs, diag_feasible, err 6.8e-12 | 101 EVDs, diag_feasible, err 3.2e-11 | 209 EVDs, diag_feasible, err 3.2e-11 | 76 EVDs, diag_feasible, err 2.7e-11 |
| thesiskkt-r100-m5-d1e-05-p0 | 5 EVDs, converged, err 8.7e-13 | 93 EVDs, diag_feasible, err 1.1e-11 | 4027 EVDs, evd_budget, err 4.6e-08 | 102 EVDs, diag_feasible, err 2.8e-11 | 210 EVDs, diag_feasible, err 3.1e-11 | 71 EVDs, diag_feasible, err 1.8e-11 |
| thesiskkt-r100-m5-d1e-05-p1 | 4 EVDs, converged, err 1.7e-11 | 77 EVDs, diag_feasible, err 1.1e-11 | 76 EVDs, diag_feasible_at_xpre, err 7.0e-12 | 102 EVDs, diag_feasible, err 3.0e-11 | 210 EVDs, diag_feasible, err 3.3e-11 | 70 EVDs, diag_feasible, err 1.7e-11 |
| thesiskkt-r100-m5-d1e-05-p2 | 4 EVDs, converged, err 1.8e-11 | 109 EVDs, diag_feasible, err 7.3e-12 | 4015 EVDs, evd_budget, err 3.6e-11 | 102 EVDs, diag_feasible, err 2.9e-11 | 210 EVDs, diag_feasible, err 3.2e-11 | 75 EVDs, diag_feasible, err 2.1e-11 |
| thesiskkt-r100-m5-d1e-09-p0 | 5 EVDs, converged, err 8.3e-13 | 99 EVDs, diag_feasible_at_xpre, err 2.1e-11 | 110 EVDs, diag_feasible, err 1.7e-11 | 101 EVDs, diag_feasible, err 3.1e-11 | 209 EVDs, diag_feasible, err 3.1e-11 | 75 EVDs, diag_feasible, err 2.5e-11 |
| thesiskkt-r100-m5-d1e-09-p1 | 5 EVDs, converged, err 8.7e-13 | 101 EVDs, diag_feasible_at_xpre, err 1.3e-11 | 126 EVDs, diag_feasible_at_xpre, err 8.2e-12 | 102 EVDs, diag_feasible, err 2.8e-11 | 210 EVDs, diag_feasible, err 3.1e-11 | 77 EVDs, diag_feasible, err 2.4e-11 |
| thesiskkt-r100-m5-d1e-09-p2 | 5 EVDs, converged, err 6.9e-13 | 85 EVDs, diag_feasible_at_xpre, err 1.1e-11 | 127 EVDs, diag_feasible, err 1.4e-11 | 101 EVDs, diag_feasible, err 3.3e-11 | 209 EVDs, diag_feasible, err 3.3e-11 | 76 EVDs, diag_feasible, err 2.2e-11 |
| thesiskkt-r20-m1-d0-p0 | 4 EVDs, converged, err 2.7e-13 | 222 EVDs, diag_feasible_at_xpre, err 3.8e-11 | 388 EVDs, diag_feasible, err 4.5e-11 | 358 EVDs, diag_feasible, err 6.0e-11 | 719 EVDs, diag_feasible, err 6.2e-11 | 181 EVDs, diag_feasible, err 3.0e-11 |
| thesiskkt-r20-m1-d0-p1 | 4 EVDs, converged, err 4.3e-13 | 116 EVDs, diag_feasible_at_xpre, err 1.9e-11 | 172 EVDs, diag_feasible, err 2.4e-11 | 356 EVDs, diag_feasible, err 6.0e-11 | 715 EVDs, diag_feasible, err 6.2e-11 | 149 EVDs, diag_feasible, err 4.0e-11 |
| thesiskkt-r20-m1-d0-p2 | 4 EVDs, converged, err 2.5e-13 | 234 EVDs, diag_feasible_at_xpre, err 3.0e-11 | 290 EVDs, diag_feasible_at_xpre, err 4.1e-11 | 358 EVDs, diag_feasible, err 6.0e-11 | 719 EVDs, diag_feasible, err 6.1e-11 | 142 EVDs, diag_feasible, err 4.9e-11 |
| thesiskkt-r20-m1-d1e-05-p0 | 4 EVDs, converged, err 3.9e-13 | 187 EVDs, diag_feasible, err 2.7e-11 | 251 EVDs, diag_feasible_at_xpre, err 4.6e-11 | 361 EVDs, diag_feasible, err 5.9e-11 | 725 EVDs, diag_feasible, err 6.1e-11 | 153 EVDs, diag_feasible, err 4.4e-11 |
| thesiskkt-r20-m1-d1e-05-p1 | 4 EVDs, converged, err 2.7e-13 | 141 EVDs, diag_feasible, err 2.3e-11 | 229 EVDs, diag_feasible_at_xpre, err 2.9e-11 | 360 EVDs, diag_feasible, err 5.9e-11 | 723 EVDs, diag_feasible, err 6.1e-11 | 105 EVDs, diag_feasible, err 4.4e-11 |
| thesiskkt-r20-m1-d1e-05-p2 | 4 EVDs, converged, err 2.9e-13 | 249 EVDs, diag_feasible_at_xpre, err 1.2e-11 | 264 EVDs, diag_feasible_at_xpre, err 4.1e-11 | 361 EVDs, diag_feasible, err 5.9e-11 | 725 EVDs, diag_feasible, err 6.1e-11 | 124 EVDs, diag_feasible, err 5.1e-11 |
| thesiskkt-r20-m1-d1e-09-p0 | 5 EVDs, converged, err 3.3e-13 | 161 EVDs, diag_feasible_at_xpre, err 2.2e-11 | 191 EVDs, diag_feasible, err 3.6e-11 | 359 EVDs, diag_feasible, err 5.9e-11 | 721 EVDs, diag_feasible, err 6.1e-11 | 177 EVDs, diag_feasible, err 5.4e-11 |
| thesiskkt-r20-m1-d1e-09-p1 | 5 EVDs, converged, err 3.5e-13 | 148 EVDs, diag_feasible_at_xpre, err 2.4e-11 | 238 EVDs, diag_feasible_at_xpre, err 2.3e-11 | 357 EVDs, diag_feasible, err 6.0e-11 | 717 EVDs, diag_feasible, err 6.2e-11 | 146 EVDs, diag_feasible, err 1.7e-11 |
| thesiskkt-r20-m1-d1e-09-p2 | 5 EVDs, converged, err 3.7e-13 | 208 EVDs, diag_feasible, err 3.0e-11 | 284 EVDs, diag_feasible, err 2.8e-11 | 359 EVDs, diag_feasible, err 5.9e-11 | 721 EVDs, diag_feasible, err 6.1e-11 | 149 EVDs, diag_feasible, err 5.3e-11 |
| thesiskkt-r20-m20-d0-p0 | 5 EVDs, converged, err 1.2e-11 | 96 EVDs, diag_feasible_at_xpre, err 3.6e-11 | 4027 EVDs, evd_budget, err 2.3e-10 | 314 EVDs, diag_feasible, err 5.8e-11 | 630 EVDs, diag_feasible, err 6.1e-11 | 143 EVDs, diag_feasible, err 3.4e-11 |
| thesiskkt-r20-m20-d0-p1 | 5 EVDs, converged, err 7.1e-12 | 125 EVDs, diag_feasible_at_xpre, err 3.2e-11 | 145 EVDs, diag_feasible_at_xpre, err 3.6e-11 | 306 EVDs, diag_feasible, err 5.9e-11 | 615 EVDs, diag_feasible, err 6.0e-11 | 191 EVDs, diag_feasible, err 4.0e-11 |
| thesiskkt-r20-m20-d0-p2 | 13 EVDs, converged, err 8.4e-12 | 135 EVDs, diag_feasible_at_xpre, err 3.0e-11 | 327 EVDs, diag_feasible_at_xpre, err 2.6e-11 | 306 EVDs, diag_feasible, err 6.0e-11 | 616 EVDs, diag_feasible, err 6.0e-11 | 103 EVDs, diag_feasible, err 4.9e-11 |
| thesiskkt-r20-m20-d1e-05-p0 | 4 EVDs, converged, err 2.5e-11 | 177 EVDs, diag_feasible_at_xpre, err 1.7e-11 | 255 EVDs, diag_feasible, err 2.2e-11 | 326 EVDs, diag_feasible, err 6.0e-11 | 655 EVDs, diag_feasible, err 6.2e-11 | 155 EVDs, diag_feasible, err 2.9e-11 |
| thesiskkt-r20-m20-d1e-05-p1 | 4 EVDs, converged, err 2.7e-11 | 172 EVDs, diag_feasible_at_xpre, err 3.2e-11 | 123 EVDs, diag_feasible_at_xpre, err 3.6e-11 | 324 EVDs, diag_feasible, err 6.0e-11 | 651 EVDs, diag_feasible, err 6.2e-11 | 151 EVDs, diag_feasible, err 3.8e-11 |
| thesiskkt-r20-m20-d1e-05-p2 | 4 EVDs, converged, err 2.4e-11 | 176 EVDs, diag_feasible_at_xpre, err 3.3e-11 | 244 EVDs, diag_feasible, err 2.7e-11 | 324 EVDs, diag_feasible, err 6.0e-11 | 652 EVDs, diag_feasible, err 6.0e-11 | 142 EVDs, diag_feasible, err 4.4e-11 |
| thesiskkt-r20-m20-d1e-09-p0 | 5 EVDs, converged, err 6.6e-13 | 141 EVDs, diag_feasible_at_xpre, err 4.0e-11 | 154 EVDs, diag_feasible_at_xpre, err 1.2e-11 | 316 EVDs, diag_feasible, err 6.0e-11 | 635 EVDs, diag_feasible, err 6.1e-11 | 135 EVDs, diag_feasible, err 2.4e-11 |
| thesiskkt-r20-m20-d1e-09-p1 | 5 EVDs, converged, err 4.6e-13 | 83 EVDs, diag_feasible, err 1.8e-11 | 214 EVDs, diag_feasible, err 4.0e-11 | 310 EVDs, diag_feasible, err 6.0e-11 | 623 EVDs, diag_feasible, err 6.1e-11 | 170 EVDs, diag_feasible, err 4.1e-11 |
| thesiskkt-r20-m20-d1e-09-p2 | 5 EVDs, converged, err 7.2e-13 | 113 EVDs, diag_feasible, err 3.7e-11 | 156 EVDs, diag_feasible_at_xpre, err 3.9e-11 | 310 EVDs, diag_feasible, err 6.0e-11 | 623 EVDs, diag_feasible, err 6.2e-11 | 111 EVDs, diag_feasible, err 5.5e-11 |
| thesiskkt-r20-m5-d0-p0 | 4 EVDs, converged, err 4.2e-13 | 147 EVDs, diag_feasible_at_xpre, err 1.7e-11 | 229 EVDs, diag_feasible, err 2.0e-11 | 343 EVDs, diag_feasible, err 6.1e-11 | 690 EVDs, diag_feasible, err 6.1e-11 | 127 EVDs, diag_feasible, err 5.1e-11 |
| thesiskkt-r20-m5-d0-p1 | 4 EVDs, converged, err 6.8e-13 | 134 EVDs, diag_feasible_at_xpre, err 2.6e-11 | 164 EVDs, diag_feasible, err 2.6e-11 | 342 EVDs, diag_feasible, err 5.9e-11 | 687 EVDs, diag_feasible, err 6.0e-11 | 177 EVDs, diag_feasible, err 3.5e-11 |
| thesiskkt-r20-m5-d0-p2 | 4 EVDs, converged, err 5.5e-13 | 122 EVDs, diag_feasible_at_xpre, err 1.5e-11 | 130 EVDs, diag_feasible, err 2.5e-11 | 339 EVDs, diag_feasible, err 5.9e-11 | 681 EVDs, diag_feasible, err 6.0e-11 | 162 EVDs, diag_feasible, err 4.6e-11 |
| thesiskkt-r20-m5-d1e-05-p0 | 4 EVDs, converged, err 2.6e-12 | 270 EVDs, diag_feasible, err 2.4e-11 | 256 EVDs, diag_feasible_at_xpre, err 2.8e-11 | 350 EVDs, diag_feasible, err 6.2e-11 | 704 EVDs, diag_feasible, err 6.2e-11 | 129 EVDs, diag_feasible, err 4.8e-11 |
| thesiskkt-r20-m5-d1e-05-p1 | 4 EVDs, converged, err 1.6e-12 | 121 EVDs, diag_feasible_at_xpre, err 3.7e-11 | 178 EVDs, diag_feasible, err 2.0e-11 | 349 EVDs, diag_feasible, err 6.1e-11 | 702 EVDs, diag_feasible, err 6.2e-11 | 115 EVDs, diag_feasible, err 4.4e-11 |
| thesiskkt-r20-m5-d1e-05-p2 | 4 EVDs, converged, err 1.5e-12 | 91 EVDs, diag_feasible, err 2.4e-11 | 161 EVDs, diag_feasible, err 2.3e-11 | 348 EVDs, diag_feasible, err 6.1e-11 | 700 EVDs, diag_feasible, err 6.1e-11 | 129 EVDs, diag_feasible, err 5.2e-11 |
| thesiskkt-r20-m5-d1e-09-p0 | 5 EVDs, converged, err 3.9e-13 | 186 EVDs, diag_feasible_at_xpre, err 3.2e-11 | 180 EVDs, diag_feasible_at_xpre, err 1.3e-11 | 345 EVDs, diag_feasible, err 6.0e-11 | 693 EVDs, diag_feasible, err 6.2e-11 | 129 EVDs, diag_feasible, err 1.7e-11 |
| thesiskkt-r20-m5-d1e-09-p1 | 5 EVDs, converged, err 4.2e-13 | 180 EVDs, diag_feasible_at_xpre, err 3.0e-11 | 263 EVDs, diag_feasible, err 3.4e-11 | 343 EVDs, diag_feasible, err 6.1e-11 | 690 EVDs, diag_feasible, err 6.1e-11 | 182 EVDs, diag_feasible, err 5.3e-11 |
| thesiskkt-r20-m5-d1e-09-p2 | 5 EVDs, converged, err 3.1e-13 | 130 EVDs, diag_feasible, err 3.1e-11 | 205 EVDs, diag_feasible_at_xpre, err 2.5e-11 | 341 EVDs, diag_feasible, err 6.0e-11 | 685 EVDs, diag_feasible, err 6.1e-11 | 155 EVDs, diag_feasible, err 4.8e-11 |
| thesiskkt-r50-m1-d0-p0 | 4 EVDs, converged, err 6.5e-13 | 151 EVDs, diag_feasible_at_xpre, err 2.0e-11 | 172 EVDs, diag_feasible_at_xpre, err 1.3e-11 | 160 EVDs, diag_feasible, err 3.6e-11 | 325 EVDs, diag_feasible, err 4.0e-11 | 93 EVDs, diag_feasible, err 1.3e-11 |
| thesiskkt-r50-m1-d0-p1 | 4 EVDs, converged, err 6.4e-13 | 202 EVDs, diag_feasible_at_xpre, err 1.1e-11 | 179 EVDs, diag_feasible, err 1.0e-11 | 159 EVDs, diag_feasible, err 4.0e-11 | 325 EVDs, diag_feasible, err 3.9e-11 | 94 EVDs, diag_feasible, err 1.8e-11 |
| thesiskkt-r50-m1-d0-p2 | 4 EVDs, converged, err 1.1e-12 | 142 EVDs, diag_feasible_at_xpre, err 2.1e-11 | 183 EVDs, diag_feasible_at_xpre, err 7.8e-12 | 159 EVDs, diag_feasible, err 3.9e-11 | 325 EVDs, diag_feasible, err 3.9e-11 | 93 EVDs, diag_feasible, err 2.1e-11 |
| thesiskkt-r50-m1-d1e-05-p0 | 4 EVDs, converged, err 8.6e-13 | 158 EVDs, diag_feasible_at_xpre, err 2.3e-11 | 174 EVDs, diag_feasible_at_xpre, err 1.9e-11 | 160 EVDs, diag_feasible, err 4.0e-11 | 327 EVDs, diag_feasible, err 4.0e-11 | 97 EVDs, diag_feasible, err 3.9e-11 |
| thesiskkt-r50-m1-d1e-05-p1 | 4 EVDs, converged, err 1.2e-12 | 196 EVDs, diag_feasible_at_xpre, err 1.2e-11 | 175 EVDs, diag_feasible, err 2.2e-11 | 160 EVDs, diag_feasible, err 4.0e-11 | 327 EVDs, diag_feasible, err 3.9e-11 | 89 EVDs, diag_feasible, err 3.8e-11 |
| thesiskkt-r50-m1-d1e-05-p2 | 4 EVDs, converged, err 7.6e-13 | 114 EVDs, diag_feasible_at_xpre, err 1.5e-11 | 977 EVDs, diag_feasible, err 1.6e-11 | 160 EVDs, diag_feasible, err 4.0e-11 | 327 EVDs, diag_feasible, err 3.9e-11 | 77 EVDs, diag_feasible, err 3.3e-11 |
| thesiskkt-r50-m1-d1e-09-p0 | 5 EVDs, converged, err 1.2e-12 | 206 EVDs, diag_feasible_at_xpre, err 2.2e-11 | 137 EVDs, diag_feasible_at_xpre, err 1.8e-11 | 160 EVDs, diag_feasible, err 3.7e-11 | 326 EVDs, diag_feasible, err 3.9e-11 | 94 EVDs, diag_feasible, err 2.1e-11 |
| thesiskkt-r50-m1-d1e-09-p1 | 5 EVDs, converged, err 6.2e-13 | 96 EVDs, diag_feasible, err 2.0e-11 | 145 EVDs, diag_feasible, err 2.0e-11 | 160 EVDs, diag_feasible, err 3.7e-11 | 326 EVDs, diag_feasible, err 3.9e-11 | 93 EVDs, diag_feasible, err 2.1e-11 |
| thesiskkt-r50-m1-d1e-09-p2 | 5 EVDs, converged, err 1.4e-12 | 148 EVDs, diag_feasible_at_xpre, err 1.9e-11 | 4044 EVDs, evd_budget, err 1.8e-06 | 160 EVDs, diag_feasible, err 3.6e-11 | 325 EVDs, diag_feasible, err 4.0e-11 | 93 EVDs, diag_feasible, err 3.1e-11 |
| thesiskkt-r50-m20-d0-p0 | 5 EVDs, converged, err 1.9e-12 | 80 EVDs, diag_feasible_at_xpre, err 2.4e-11 | 144 EVDs, diag_feasible, err 2.5e-11 | 144 EVDs, diag_feasible, err 3.7e-11 | 294 EVDs, diag_feasible, err 3.8e-11 | 76 EVDs, diag_feasible, err 2.9e-11 |
| thesiskkt-r50-m20-d0-p1 | 5 EVDs, converged, err 2.0e-12 | 109 EVDs, diag_feasible_at_xpre, err 2.3e-11 | 4017 EVDs, evd_budget, err 4.7e-07 | 140 EVDs, diag_feasible, err 3.5e-11 | 285 EVDs, diag_feasible, err 3.9e-11 | 82 EVDs, diag_feasible, err 2.2e-11 |
| thesiskkt-r50-m20-d0-p2 | 5 EVDs, converged, err 2.1e-12 | 105 EVDs, diag_feasible, err 2.0e-11 | 114 EVDs, diag_feasible_at_xpre, err 2.1e-11 | 140 EVDs, diag_feasible, err 3.5e-11 | 285 EVDs, diag_feasible, err 3.8e-11 | 76 EVDs, diag_feasible, err 3.3e-11 |
| thesiskkt-r50-m20-d1e-05-p0 | 5 EVDs, converged, err 5.1e-13 | 108 EVDs, diag_feasible_at_xpre, err 9.9e-12 | 155 EVDs, diag_feasible, err 9.1e-12 | 151 EVDs, diag_feasible, err 3.7e-11 | 307 EVDs, diag_feasible, err 4.0e-11 | 71 EVDs, diag_feasible, err 3.3e-11 |
| thesiskkt-r50-m20-d1e-05-p1 | 5 EVDs, converged, err 7.1e-13 | 140 EVDs, diag_feasible, err 1.9e-11 | 953 EVDs, diag_feasible, err 2.0e-11 | 149 EVDs, diag_feasible, err 3.9e-11 | 305 EVDs, diag_feasible, err 3.8e-11 | 77 EVDs, diag_feasible, err 2.2e-11 |
| thesiskkt-r50-m20-d1e-05-p2 | 5 EVDs, converged, err 5.0e-13 | 192 EVDs, diag_feasible_at_xpre, err 2.0e-11 | 169 EVDs, diag_feasible_at_xpre, err 2.3e-11 | 149 EVDs, diag_feasible, err 3.9e-11 | 305 EVDs, diag_feasible, err 3.8e-11 | 71 EVDs, diag_feasible, err 3.3e-11 |
| thesiskkt-r50-m20-d1e-09-p0 | 5 EVDs, converged, err 1.1e-12 | 114 EVDs, diag_feasible_at_xpre, err 1.9e-11 | 154 EVDs, diag_feasible_at_xpre, err 8.4e-12 | 146 EVDs, diag_feasible, err 3.7e-11 | 297 EVDs, diag_feasible, err 4.0e-11 | 66 EVDs, diag_feasible, err 2.2e-11 |
| thesiskkt-r50-m20-d1e-09-p1 | 5 EVDs, converged, err 6.3e-13 | 99 EVDs, diag_feasible_at_xpre, err 6.7e-12 | 79 EVDs, diag_feasible_at_xpre, err 1.9e-11 | 142 EVDs, diag_feasible, err 3.9e-11 | 290 EVDs, diag_feasible, err 4.0e-11 | 82 EVDs, diag_feasible, err 2.5e-11 |
| thesiskkt-r50-m20-d1e-09-p2 | 5 EVDs, converged, err 5.4e-13 | 179 EVDs, diag_feasible, err 1.8e-11 | 105 EVDs, diag_feasible_at_xpre, err 1.8e-11 | 142 EVDs, diag_feasible, err 3.9e-11 | 290 EVDs, diag_feasible, err 4.0e-11 | 72 EVDs, diag_feasible, err 3.0e-11 |
| thesiskkt-r50-m5-d0-p0 | 4 EVDs, converged, err 2.6e-12 | 124 EVDs, diag_feasible_at_xpre, err 2.1e-11 | 159 EVDs, diag_feasible_at_xpre, err 3.3e-12 | 155 EVDs, diag_feasible, err 3.8e-11 | 316 EVDs, diag_feasible, err 3.9e-11 | 97 EVDs, diag_feasible, err 2.8e-11 |
| thesiskkt-r50-m5-d0-p1 | 4 EVDs, converged, err 4.9e-12 | 127 EVDs, diag_feasible, err 2.0e-11 | 147 EVDs, diag_feasible_at_xpre, err 1.0e-11 | 151 EVDs, diag_feasible, err 3.9e-11 | 309 EVDs, diag_feasible, err 3.8e-11 | 93 EVDs, diag_feasible, err 2.5e-11 |
| thesiskkt-r50-m5-d0-p2 | 4 EVDs, converged, err 4.2e-12 | 141 EVDs, diag_feasible_at_xpre, err 2.6e-11 | 4033 EVDs, evd_budget, err 1.1e-06 | 152 EVDs, diag_feasible, err 3.7e-11 | 310 EVDs, diag_feasible, err 3.9e-11 | 96 EVDs, diag_feasible, err 2.6e-11 |
| thesiskkt-r50-m5-d1e-05-p0 | 4 EVDs, converged, err 5.5e-12 | 109 EVDs, diag_feasible_at_xpre, err 2.1e-11 | 174 EVDs, diag_feasible_at_xpre, err 3.6e-12 | 158 EVDs, diag_feasible, err 3.8e-11 | 322 EVDs, diag_feasible, err 3.9e-11 | 85 EVDs, diag_feasible, err 3.0e-11 |
| thesiskkt-r50-m5-d1e-05-p1 | 4 EVDs, converged, err 9.6e-12 | 115 EVDs, diag_feasible_at_xpre, err 1.9e-11 | 118 EVDs, diag_feasible, err 2.1e-11 | 156 EVDs, diag_feasible, err 4.0e-11 | 319 EVDs, diag_feasible, err 3.9e-11 | 85 EVDs, diag_feasible, err 3.0e-11 |
| thesiskkt-r50-m5-d1e-05-p2 | 4 EVDs, converged, err 1.1e-11 | 90 EVDs, diag_feasible_at_xpre, err 1.8e-11 | 150 EVDs, diag_feasible_at_xpre, err 1.8e-11 | 157 EVDs, diag_feasible, err 3.7e-11 | 320 EVDs, diag_feasible, err 3.9e-11 | 85 EVDs, diag_feasible, err 2.1e-11 |
| thesiskkt-r50-m5-d1e-09-p0 | 5 EVDs, converged, err 5.9e-13 | 109 EVDs, diag_feasible_at_xpre, err 2.0e-11 | 119 EVDs, diag_feasible, err 1.3e-11 | 156 EVDs, diag_feasible, err 3.7e-11 | 318 EVDs, diag_feasible, err 3.9e-11 | 93 EVDs, diag_feasible, err 2.7e-11 |
| thesiskkt-r50-m5-d1e-09-p1 | 5 EVDs, converged, err 9.6e-13 | 142 EVDs, diag_feasible, err 2.3e-11 | 4000 EVDs, evd_budget, err 3.3e-09 | 153 EVDs, diag_feasible, err 3.7e-11 | 312 EVDs, diag_feasible, err 3.9e-11 | 84 EVDs, diag_feasible, err 2.4e-11 |
| thesiskkt-r50-m5-d1e-09-p2 | 5 EVDs, converged, err 5.0e-13 | 113 EVDs, diag_feasible_at_xpre, err 2.1e-11 | 136 EVDs, diag_feasible_at_xpre, err 1.6e-11 | 153 EVDs, diag_feasible, err 4.0e-11 | 313 EVDs, diag_feasible, err 4.0e-11 | 93 EVDs, diag_feasible, err 3.1e-11 |

