# Paper 2 - timing, primitive work, and cost-metric sensitivity

Single-threaded BLAS, discarded warmup solve, GC before the measured run,
one `@elapsed` around the whole solve (protocol Sec. 3.5). Percentages are
taken against measured elapsed time, so uninstrumented work appears as
`other_seconds` rather than inflating the EVD share.

## 1. Native stopping rules (Sec. 3.1)

270 instances, tolerance rule: 1e-7*n (dimension-scaled).

| solver | median EVDs | median time (s) | median err vs X* | us/EVD | EVD % | CG iters | LS trials |
|---|---:|---:|---:|---:|---:|---:|---:|
| Newton-SIN-BH | 4 | 0.006 | 5.04e-08 | 1494 | 81.0 | 11 | 0 |
| Newton-SIN | 7 | 0.009 | 5.04e-08 | 1298 | 88.4 | 11 | 0 |
| AGD-SDAJ-BH | 20 | 0.024 | 9.58e-06 | 1107 | 98.6 | 0 | 2 |
| AGD-SDAJ | 20 | 0.024 | 9.58e-06 | 1132 | 98.6 | 0 | 2 |
| SBB-Dual | 18.5 | 0.020 | 7.73e-06 | 1087 | 98.3 | 0 | 0 |
| Dykstra-APM | 40 | 0.045 | 1.93e-05 | 1195 | 93.9 | 0 | 0 |
| Anderson-APM | 13 | 0.016 | 1.37e-05 | 1279 | 84.2 | 0 | 0 |

**Achieved accuracy spans 383.4x across solvers at their native
exits** (best Newton-SIN-BH at 5.04e-08, worst Dykstra-APM at 1.93e-05). Cost comparisons taken at these
exit points are therefore comparisons at different accuracies, which is
the confound Sec. 3.1 exists to name.

## 2. Matched tolerance (Sec. 3.4/3.5)

270 instances, tolerance rule: common 1e-11.

| solver | median EVDs | median time (s) | median err vs X* | us/EVD | EVD % | CG iters | LS trials |
|---|---:|---:|---:|---:|---:|---:|---:|
| Newton-SIN-BH | 5 | 0.009 | 0.00e+00 | 1695 | 73.8 | 24 | 0 |
| Newton-SIN | 11 | 0.017 | 1.72e-13 | 1341 | 85.2 | 29.5 | 0 |
| AGD-SDAJ-BH | 70 | 0.084 | 1.10e-11 | 1181 | 98.8 | 0 | 14 |
| AGD-SDAJ | 81.5 | 0.097 | 1.16e-11 | 1188 | 98.8 | 0 | 25 |
| SBB-Dual | 46.5 | 0.050 | 7.61e-12 | 1133 | 98.6 | 0 | 0 |
| Dykstra-APM | 102.5 | 0.118 | 1.99e-11 | 1278 | 93.5 | 0 | 0 |
| Anderson-APM | 34 | 0.047 | 1.57e-11 | 1323 | 84.2 | 0 | 0 |

## 3. Is the EVD a fair unit of work?

| solver | microseconds per EVD | relative to cheapest |
|---|---:|---:|
| Newton-SIN-BH | 1695 | 1.50x |
| Newton-SIN | 1341 | 1.18x |
| AGD-SDAJ-BH | 1181 | 1.04x |
| AGD-SDAJ | 1188 | 1.05x |
| SBB-Dual | 1133 | 1.00x |
| Dykstra-APM | 1278 | 1.13x |
| Anderson-APM | 1323 | 1.17x |

Spread: **1.50x** (SBB-Dual cheapest, Newton-SIN-BH dearest).

Per-EVD cost is **not** uniform: counting EVDs systematically favours
whichever method carries the most non-spectral work per decomposition
(Krylov products, line-search bookkeeping). EVD counts must therefore
be reported alongside wall-clock, never instead of it.

## 4. Does the cost metric change the ranking?

- By **EVDs**: Newton-SIN-BH < Newton-SIN < Anderson-APM < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM
- By **wall-clock**: Newton-SIN-BH < Newton-SIN < Anderson-APM < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM

**The two metrics agree.** No cost-metric-dependent reversal on this
family; the EVD-count rankings reported in Sec. 5 are not an artifact
of choosing a spectral-work unit.

## 5. Primitive work beyond the EVD (Sec. 3.4)

| solver | median EVDs | CG iterations | line-search trials | accepted outer its |
|---|---:|---:|---:|---:|
| Newton-SIN-BH | 5 | 24 | 0 | 4 |
| Newton-SIN | 11 | 29.5 | 0 | 5 |
| AGD-SDAJ-BH | 70 | 0 | 14 | 9 |
| AGD-SDAJ | 81.5 | 0 | 25 | 10 |
| SBB-Dual | 46.5 | 0 | 0 | 45.5 |
| Dykstra-APM | 102.5 | 0 | 0 | 102.5 |
| Anderson-APM | 34 | 0 | 0 | 34 |

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
| Anderson-APM | diag_feasible | 270 |

