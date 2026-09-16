# Paper 2 - timing, primitive work, and cost-metric sensitivity

Single-threaded BLAS, discarded warmup solve, GC before the measured run,
one `@elapsed` around the whole solve (protocol Sec. 3.5). Percentages are
taken against measured elapsed time, so uninstrumented work appears as
`other_seconds` rather than inflating the EVD share.

## 1. Native stopping rules (Sec. 3.1)

270 instances, tolerance rule: 1e-7*n (dimension-scaled).

| solver | median EVDs | median time (s) | median err vs X* | us/EVD | EVD % | CG iters | LS trials |
|---|---:|---:|---:|---:|---:|---:|---:|
| Newton-SIN-BH | 4 | 0.023 | 5.04e-08 | 5854 | 78.9 | 11 | 0 |
| Newton-SIN | 7 | 0.035 | 5.04e-08 | 5062 | 86.5 | 11 | 0 |
| AGD-SDAJ-BH | 20 | 0.085 | 9.58e-06 | 4613 | 98.7 | 0 | 2 |
| AGD-SDAJ | 20 | 0.084 | 9.58e-06 | 4581 | 98.7 | 0 | 2 |
| SBB-Dual | 18 | 0.088 | 7.73e-06 | 4563 | 98.2 | 0 | 0 |
| Dykstra-APM | 40 | 0.222 | 1.93e-05 | 5299 | 92.6 | 0 | 0 |

**Achieved accuracy spans 383.4x across solvers at their native
exits** (best Newton-SIN-BH at 5.04e-08, worst Dykstra-APM at 1.93e-05). Cost comparisons taken at these
exit points are therefore comparisons at different accuracies, which is
the confound Sec. 3.1 exists to name.

## 2. Matched tolerance (Sec. 3.4/3.5)

270 instances, tolerance rule: common 1e-11.

| solver | median EVDs | median time (s) | median err vs X* | us/EVD | EVD % | CG iters | LS trials |
|---|---:|---:|---:|---:|---:|---:|---:|
| Newton-SIN-BH | 5 | 0.032 | 2.25e-13 | 6262 | 69.1 | 24 | 0 |
| Newton-SIN | 11 | 0.061 | 3.36e-13 | 5262 | 82.2 | 30 | 0 |
| AGD-SDAJ-BH | 70 | 0.330 | 1.13e-11 | 4689 | 98.6 | 0 | 14 |
| AGD-SDAJ | 82 | 0.387 | 1.20e-11 | 4730 | 98.7 | 0 | 25 |
| SBB-Dual | 46 | 0.202 | 7.77e-12 | 4584 | 98.4 | 0 | 0 |
| Dykstra-APM | 102 | 0.556 | 1.90e-11 | 5440 | 90.7 | 0 | 0 |

## 3. Is the EVD a fair unit of work?

| solver | microseconds per EVD | relative to cheapest |
|---|---:|---:|
| Newton-SIN-BH | 6262 | 1.37x |
| Newton-SIN | 5262 | 1.15x |
| AGD-SDAJ-BH | 4689 | 1.02x |
| AGD-SDAJ | 4730 | 1.03x |
| SBB-Dual | 4584 | 1.00x |
| Dykstra-APM | 5440 | 1.19x |

Spread: **1.37x** (SBB-Dual cheapest, Newton-SIN-BH dearest).

Per-EVD cost is **not** uniform: counting EVDs systematically favours
whichever method carries the most non-spectral work per decomposition
(Krylov products, line-search bookkeeping). EVD counts must therefore
be reported alongside wall-clock, never instead of it.

## 4. Does the cost metric change the ranking?

- By **EVDs**: Newton-SIN-BH < Newton-SIN < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM
- By **wall-clock**: Newton-SIN-BH < Newton-SIN < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM

**The two metrics agree.** No cost-metric-dependent reversal on this
family; the EVD-count rankings reported in Sec. 5 are not an artifact
of choosing a spectral-work unit.

## 5. Primitive work beyond the EVD (Sec. 3.4)

| solver | median EVDs | CG iterations | line-search trials | accepted outer its |
|---|---:|---:|---:|---:|
| Newton-SIN-BH | 5 | 24 | 0 | 4 |
| Newton-SIN | 11 | 30 | 0 | 5 |
| AGD-SDAJ-BH | 70 | 0 | 14 | 9 |
| AGD-SDAJ | 82 | 0 | 25 | 10 |
| SBB-Dual | 46 | 0 | 0 | 46 |
| Dykstra-APM | 102 | 0 | 0 | 102 |

An 'iteration' means a different amount of work in each row: a Newton
outer iteration carries a Krylov solve, a Dykstra iteration is one
projection, an AGD-SDAJ outer iteration contains q inner QN-SDAJ steps
each with its own line search. Reporting iteration counts across these
methods without the primitive breakdown is not a comparison.

## 6. Exit reasons at matched tolerance

| solver | exit | count |
|---|---|---:|
| Newton-SIN-BH | converged | 270 |
| Newton-SIN | converged | 214 |
| Newton-SIN | max_iter | 56 |
| AGD-SDAJ-BH | diag_feasible | 177 |
| AGD-SDAJ-BH | diag_feasible_at_xpre | 93 |
| AGD-SDAJ | diag_feasible | 156 |
| AGD-SDAJ | diag_feasible_at_xpre | 96 |
| AGD-SDAJ | evd_budget | 18 |
| SBB-Dual | diag_feasible | 270 |
| Dykstra-APM | diag_feasible | 270 |

