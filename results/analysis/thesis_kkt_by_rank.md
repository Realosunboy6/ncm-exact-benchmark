# Median EVDs by rank (81 instances, 6 solvers)

Reach-and-hold rule, accepted rows only. '--' = target not reached.

## forward target 0.0001

| r | n | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM | SBB-Dual < AGD-SDAJ-BH | Anderson-APM < AGD-SDAJ-BH |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 20 | 27 | 3 | 55 | 55 | 85 | 168 | 30 | 1/27 | 19/27 |
| 50 | 27 | 3 | 41 | 41 | 42 | 85 | 21 | 13/27 | 21/27 |
| 100 | 27 | 3 | 30 | 30 | 27 | 53 | 19 | 17/27 | 18/27 |

## forward target 1e-06

| r | n | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM | SBB-Dual < AGD-SDAJ-BH | Anderson-APM < AGD-SDAJ-BH |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 20 | 27 | 3 | 81 | 93 | 165 | 330 | 64 | 0/27 | 16/27 |
| 50 | 27 | 3 | 54 | 60 [25] | 77 | 156 | 40 | 6/27 | 25/27 |
| 100 | 27 | 4 | 47 | 49 | 49 | 99 | 35 | 11/27 | 21/27 |

## forward target 1e-08

| r | n | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM | SBB-Dual < AGD-SDAJ-BH | Anderson-APM < AGD-SDAJ-BH |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 20 | 27 | 4 | 117 | 154 | 249 | 500 | 108 | 0/27 | 15/27 |
| 50 | 27 | 4 | 92 | 94.5 [24] | 112 | 228 | 64 | 6/27 | 25/27 |
| 100 | 27 | 4 | 65 | 79 [25] | 72 | 148 | 53 | 11/27 | 23/27 |

## forward target 1e-10

| r | n | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM | SBB-Dual < AGD-SDAJ-BH | Anderson-APM < AGD-SDAJ-BH |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 20 | 27 | 4 | 144 | 213 [26] | 334 | 672 | 143 | 0/27 | 15/27 |
| 50 | 27 | 4 | 114 | 132 [23] | 148 | 301 | 83 | 6/27 | 25/27 |
| 100 | 27 | 5 | 94 | 112 [25] | 96 | 198 | 71 | 13/27 | 24/27 |
