# Paper 2 - timing, primitive work, and cost-metric sensitivity

Single-threaded BLAS, discarded warmup solve, GC before the measured run,
one `@elapsed` around the whole solve (protocol Sec. 3.5). Percentages are
taken against measured elapsed time, so uninstrumented work appears as
`other_seconds` rather than inflating the EVD share.

## 1. Native stopping rules (Sec. 3.1)

18 instances, tolerance rule: 1e-7*n (dimension-scaled).

| solver | median EVDs | median time (s) | median err vs X* | us/EVD | EVD % | CG iters | LS trials |
|---|---:|---:|---:|---:|---:|---:|---:|
| Newton-SIN-BH | 3 | 0.181 | 1.74e-05 | 58141 | 85.1 | 8 | 0 |
| Newton-SIN | 5 | 0.262 | 1.74e-05 | 51526 | 90.0 | 8 | 0 |
| AGD-SDAJ-BH | 26 | 1.194 | 9.62e-05 | 46000 | 98.7 | 0 | 9 |
| AGD-SDAJ | 26 | 1.251 | 9.62e-05 | 46976 | 98.7 | 0 | 9 |
| SBB-Dual | 88 | 3.943 | 4.97e-05 | 45695 | 97.8 | 0 | 0 |
| Dykstra-APM | 178 | 11.579 | 2.41e-04 | 66065 | 86.7 | 0 | 0 |

**Achieved accuracy spans 13.8x across solvers at their native
exits** (best Newton-SIN-BH at 1.74e-05, worst Dykstra-APM at 2.41e-04). Cost comparisons taken at these
exit points are therefore comparisons at different accuracies, which is
the confound Sec. 3.1 exists to name.

## 2. Matched tolerance (Sec. 3.4/3.5)

18 instances, tolerance rule: common 1e-11.

| solver | median EVDs | median time (s) | median err vs X* | us/EVD | EVD % | CG iters | LS trials |
|---|---:|---:|---:|---:|---:|---:|---:|
| Newton-SIN-BH | 5 | 1.023 | 3.61e-12 | 208096 | 73.9 | 24 | 0 |
| Newton-SIN | 9 | 1.827 | 3.57e-12 | 185659 | 84.4 | 26 | 0 |
| AGD-SDAJ-BH | 106 | 15.879 | 2.16e-11 | 175806 | 98.7 | 0 | 38 |
| AGD-SDAJ | 118 | 21.834 | 2.65e-11 | 172252 | 97.7 | 0 | 54 |
| SBB-Dual | 274 | 54.540 | 1.13e-11 | 191514 | 98.4 | 0 | 0 |
| Dykstra-APM | 553 | 123.903 | 4.00e-11 | 222267 | 88.6 | 0 | 0 |

## 3. Is the EVD a fair unit of work?

| solver | microseconds per EVD | relative to cheapest |
|---|---:|---:|
| Newton-SIN-BH | 208096 | 1.21x |
| Newton-SIN | 185659 | 1.08x |
| AGD-SDAJ-BH | 175806 | 1.02x |
| AGD-SDAJ | 172252 | 1.00x |
| SBB-Dual | 191514 | 1.11x |
| Dykstra-APM | 222267 | 1.29x |

Spread: **1.29x** (AGD-SDAJ cheapest, Dykstra-APM dearest).

Per-EVD cost is **not** uniform: counting EVDs systematically favours
whichever method carries the most non-spectral work per decomposition
(Krylov products, line-search bookkeeping). EVD counts must therefore
be reported alongside wall-clock, never instead of it.

## 4. Does the cost metric change the ranking?

- By **EVDs**: Newton-SIN-BH < Newton-SIN < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM
- By **wall-clock**: Newton-SIN-BH < Newton-SIN < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM

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

