# Paper 2 - timing, primitive work, and cost-metric sensitivity

Single-threaded BLAS, discarded warmup solve, GC before the measured run,
one `@elapsed` around the whole solve (protocol Sec. 3.5). Percentages are
taken against measured elapsed time, so uninstrumented work appears as
`other_seconds` rather than inflating the EVD share.

## 1. Native stopping rules (Sec. 3.1)

18 instances, tolerance rule: 1e-7*n (dimension-scaled).

| solver | median EVDs | median time (s) | median err vs X* | us/EVD | EVD % | CG iters | LS trials |
|---|---:|---:|---:|---:|---:|---:|---:|
| Newton-SIN-BH | 3 | 0.177 | 1.74e-05 | 57590 | 85.6 | 8 | 0 |
| Newton-SIN | 5 | 0.261 | 1.74e-05 | 50584 | 90.5 | 8 | 0 |
| AGD-SDAJ-BH | 26 | 1.144 | 9.62e-05 | 44339 | 98.8 | 0 | 9 |
| AGD-SDAJ | 26 | 1.176 | 9.62e-05 | 44785 | 98.8 | 0 | 9 |
| SBB-Dual | 88 | 3.925 | 4.97e-05 | 45838 | 98.3 | 0 | 0 |
| Dykstra-APM | 178 | 9.796 | 2.41e-04 | 56350 | 86.3 | 0 | 0 |
| Anderson-APM | 19 | 0.963 | 1.36e-04 | 51275 | 82.3 | 0 | 0 |

**Achieved accuracy spans 13.8x across solvers at their native
exits** (best Newton-SIN-BH at 1.74e-05, worst Dykstra-APM at 2.41e-04). Cost comparisons taken at these
exit points are therefore comparisons at different accuracies, which is
the confound Sec. 3.1 exists to name.

## 2. Matched tolerance (Sec. 3.4/3.5)

18 instances, tolerance rule: common 1e-11.

| solver | median EVDs | median time (s) | median err vs X* | us/EVD | EVD % | CG iters | LS trials |
|---|---:|---:|---:|---:|---:|---:|---:|
| Newton-SIN-BH | 5 | 0.309 | 2.13e-12 | 61787 | 72.4 | 24 | 0 |
| Newton-SIN | 9 | 0.499 | 2.13e-12 | 54663 | 82.7 | 26 | 0 |
| AGD-SDAJ-BH | 106 | 5.106 | 2.11e-11 | 48149 | 98.6 | 0 | 38 |
| AGD-SDAJ | 118 | 5.632 | 2.43e-11 | 48128 | 97.3 | 0 | 54 |
| SBB-Dual | 274 | 12.553 | 1.01e-11 | 46632 | 97.5 | 0 | 0 |
| Dykstra-APM | 553 | 31.004 | 4.84e-11 | 56471 | 85.6 | 0 | 0 |
| Anderson-APM | 90 | 5.048 | 3.88e-11 | 55379 | 82.3 | 0 | 0 |

## 3. Is the EVD a fair unit of work?

| solver | microseconds per EVD | relative to cheapest |
|---|---:|---:|
| Newton-SIN-BH | 61787 | 1.32x |
| Newton-SIN | 54663 | 1.17x |
| AGD-SDAJ-BH | 48149 | 1.03x |
| AGD-SDAJ | 48128 | 1.03x |
| SBB-Dual | 46632 | 1.00x |
| Dykstra-APM | 56471 | 1.21x |
| Anderson-APM | 55379 | 1.19x |

Spread: **1.32x** (SBB-Dual cheapest, Newton-SIN-BH dearest).

Per-EVD cost is **not** uniform: counting EVDs systematically favours
whichever method carries the most non-spectral work per decomposition
(Krylov products, line-search bookkeeping). EVD counts must therefore
be reported alongside wall-clock, never instead of it.

## 4. Does the cost metric change the ranking?

- By **EVDs**: Newton-SIN-BH < Newton-SIN < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM
- By **wall-clock**: Newton-SIN-BH < Newton-SIN < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM

**The two metrics agree.** No cost-metric-dependent reversal on this
family; the EVD-count rankings reported in Sec. 5 are not an artifact
of choosing a spectral-work unit.

## 5. Primitive work beyond the EVD (Sec. 3.4)

| solver | median EVDs | CG iterations | line-search trials | accepted outer its |
|---|---:|---:|---:|---:|
| Newton-SIN-BH | 5 | 24 | 0 | 4 |
| Newton-SIN | 9 | 26 | 0 | 4 |
| AGD-SDAJ-BH | 106 | 0 | 38 | 11 |
| AGD-SDAJ | 118 | 0 | 54 | 11 |
| SBB-Dual | 274 | 0 | 0 | 272 |
| Dykstra-APM | 553 | 0 | 0 | 553 |
| Anderson-APM | 90 | 0 | 0 | 90 |

An 'iteration' means a different amount of work in each row: a Newton
outer iteration carries a Krylov solve, a Dykstra iteration is one
projection, an AGD-SDAJ outer iteration contains q inner QN-SDAJ steps
each with its own line search. Reporting iteration counts across these
methods without the primitive breakdown is not a comparison.

## 6. Exit reasons at matched tolerance

| solver | exit | count |
|---|---|---:|
| Newton-SIN-BH | converged | 18 |
| Newton-SIN | converged | 18 |
| AGD-SDAJ-BH | diag_feasible | 13 |
| AGD-SDAJ-BH | diag_feasible_at_xpre | 5 |
| AGD-SDAJ | diag_feasible | 11 |
| AGD-SDAJ | diag_feasible_at_xpre | 5 |
| AGD-SDAJ | evd_budget | 2 |
| SBB-Dual | diag_feasible | 18 |
| Dykstra-APM | diag_feasible | 12 |
| Dykstra-APM | max_iter | 6 |
| Anderson-APM | diag_feasible | 18 |

