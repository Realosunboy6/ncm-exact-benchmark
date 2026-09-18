# Median EVDs by rank (16 instances, 6 solvers)

Reach-and-hold rule, accepted rows only. '--' = target not reached.

## forward target 0.0001

| r | n | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM | SBB-Dual < AGD-SDAJ-BH | Anderson-APM < AGD-SDAJ-BH |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 50 | 4 | 4 | 71.5 | 71.5 | 278.5 | 556 | 56.5 | 0/4 | 2/4 |
| 100 | 4 | 4 | 86 | 86 | 189.5 | 378.5 | 93 | 0/4 | 2/4 |
| 200 | 4 | 4 | 73.5 | 73.5 | 103.5 | 206.5 | 65 | 0/4 | 3/4 |
| 400 | 4 | 4 | 58.5 | 58.5 | 46 | 93 | 30 | 3/4 | 4/4 |

## forward target 1e-06

| r | n | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM | SBB-Dual < AGD-SDAJ-BH | Anderson-APM < AGD-SDAJ-BH |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 50 | 4 | 4.5 | 117.5 | 118.5 | 464.5 | -- | 94 | 0/4 | 2/4 |
| 100 | 4 | 4.5 | 100.5 | 108.5 | 315 | 630.5 | 162 | 0/4 | 1/4 |
| 200 | 4 | 5 | 93.5 | 92 | 173 | 347 | 110.5 | 0/4 | 0/4 |
| 400 | 4 | 5 | 79.5 | 76 | 76.5 | 156 | 53 | 2/4 | 4/4 |

## forward target 1e-08

| r | n | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM | SBB-Dual < AGD-SDAJ-BH | Anderson-APM < AGD-SDAJ-BH |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 50 | 4 | 5 | 159.5 | 201.5 | 650 | -- | 147.5 | 0/4 | 3/4 |
| 100 | 4 | 5 | 143 | 179 | 442 | -- | 233 | 0/4 | 1/4 |
| 200 | 4 | 5 | 111 | 116.5 | 244 | 491 | 158.5 | 0/4 | 0/4 |
| 400 | 4 | 5 | 109.5 | 130 | 109 | 222.5 | 78 | 2/4 | 4/4 |

## forward target 1e-10

| r | n | Newton-SIN-BH | AGD-SDAJ-BH | AGD-SDAJ | SBB-Dual | Dykstra-APM | Anderson-APM | SBB-Dual < AGD-SDAJ-BH | Anderson-APM < AGD-SDAJ-BH |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 50 | 4 | 5 | 180.5 | 228 | 835.5 | -- | 195.5 | 0/4 | 3/4 |
| 100 | 4 | 5 | 168.5 | 237.5 | 569.5 | -- | 268.5 | 0/4 | 2/4 |
| 200 | 4 | 5 | 129 | 176 | 316 | 637 | 181 | 0/4 | 0/4 |
| 400 | 4 | 5 | 132.5 | 122 [3] | 141.5 | 289 | 95 | 1/4 | 4/4 |
