# Censoring audit: ranking_kkt270_v2.csv

270 instances.

| solver | runs | exits | censored (cap) | max EVDs |
|---|---:|---|---:|---:|
| AGD-SDAJ | 270 | diag_feasible:156, diag_feasible_at_xpre:96, evd_budget:18 | 18 | 4035 |
| AGD-SDAJ-BH | 270 | diag_feasible:177, diag_feasible_at_xpre:93 | 0 | 131 |
| Dykstra-APM | 270 | diag_feasible:270 | 0 | 443 |
| Newton-SIN-BH | 270 | converged:270 | 0 | 10 |
| SBB-Dual | 270 | diag_feasible:270 | 0 | 218 |

Censored runs: how many still reached and held each forward target before the cap

| solver | censored | 1e-02 | 1e-04 | 1e-06 | 1e-08 | 1e-10 |
|---|---:|---:|---:|---:|---:|---:|
| AGD-SDAJ | 18 | 18 | 18 | 18 | 10 | 1 |

Censored instances (solver: instance, exit, EVDs, final accepted err):

- AGD-SDAJ: degen-r20-m1-d0.0001-p1, evd_budget, 4025 EVDs, err 8.62e-11
- AGD-SDAJ: degen-r20-m1-d0.01-p2, evd_budget, 4013 EVDs, err 3.04e-08
- AGD-SDAJ: degen-r20-m1-d1e-10-p2, evd_budget, 4001 EVDs, err 6.09e-09
- AGD-SDAJ: degen-r20-m1-d1e-10-p4, evd_budget, 4022 EVDs, err 4.18e-10
- AGD-SDAJ: degen-r20-m20-d0.01-p3, evd_budget, 4035 EVDs, err 8.02e-08
- AGD-SDAJ: degen-r20-m20-d0.01-p4, evd_budget, 4018 EVDs, err 1.18e-09
- AGD-SDAJ: degen-r20-m5-d1e-06-p3, evd_budget, 4026 EVDs, err 1.20e-07
- AGD-SDAJ: degen-r20-m5-d1e-10-p0, evd_budget, 4014 EVDs, err 2.00e-10
- AGD-SDAJ: degen-r20-m5-d1e-10-p3, evd_budget, 4024 EVDs, err 3.32e-10
- AGD-SDAJ: degen-r5-m1-d1e-06-p2, evd_budget, 4027 EVDs, err 4.65e-09
- AGD-SDAJ: degen-r5-m1-d1e-10-p3, evd_budget, 4026 EVDs, err 6.52e-09
- AGD-SDAJ: degen-r5-m20-d0-p3, evd_budget, 4016 EVDs, err 9.33e-08
- AGD-SDAJ: degen-r5-m20-d0.0001-p2, evd_budget, 4011 EVDs, err 4.99e-10
- AGD-SDAJ: degen-r5-m20-d1e-06-p1, evd_budget, 4013 EVDs, err 2.61e-07
- AGD-SDAJ: degen-r5-m5-d0.0001-p0, evd_budget, 4008 EVDs, err 6.43e-10
- AGD-SDAJ: degen-r5-m5-d0.01-p3, evd_budget, 4000 EVDs, err 1.63e-10
- AGD-SDAJ: degen-r50-m1-d1e-06-p1, evd_budget, 4015 EVDs, err 6.57e-10
- AGD-SDAJ: degen-r50-m5-d0.0001-p2, evd_budget, 4013 EVDs, err 3.47e-08
