## n=100 (270 instances)

Median microseconds/EVD per session (session 0 = the canonical,
previously shipped single run; sessions 1-4 = further repeats):

| solver | session 0 | session 1 | session 2 | session 3 | session 4 | spread (max/min - 1) |
|---|---:|---:|---:|---:|---:|---:|
| AGD-SDAJ | 1188 | 2737 | 2260 | 2918 | 4842 | 307% |
| AGD-SDAJ-BH | 1181 | 2704 | 2271 | 2923 | 4789 | 306% |
| Anderson-APM | 1323 | 3051 | 3110 | 3970 | 6443 | 387% |
| Dykstra-APM | 1278 | 3052 | 2486 | 3215 | 5234 | 310% |
| Newton-SIN | 1341 | 2967 | 2665 | 3429 | 5314 | 296% |
| Newton-SIN-BH | 1695 | 3511 | 3403 | 4382 | 6371 | 276% |
| SBB-Dual | 1133 | 2529 | 2284 | 2937 | 4672 | 312% |

EVD-order vs wall-clock-order of the seven variants, per session
(median total EVDs and median total elapsed time to the matched
target; "same" means the two rankings agree exactly):

session 0: SAME
  by EVDs:  Newton-SIN-BH < Newton-SIN < Anderson-APM < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM
  cheapest overall: Newton-SIN-BH by EVDs, Newton-SIN-BH by time (agree); priciest overall: Dykstra-APM by EVDs, Dykstra-APM by time (agree)
session 1: DIFFERENT
  by EVDs:  Newton-SIN-BH < Newton-SIN < Anderson-APM < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM
  by time:  Newton-SIN-BH < Newton-SIN < SBB-Dual < Anderson-APM < AGD-SDAJ-BH < Dykstra-APM < AGD-SDAJ
  cheapest overall: Newton-SIN-BH by EVDs, Newton-SIN-BH by time (agree); priciest overall: Dykstra-APM by EVDs, AGD-SDAJ by time (DISAGREE)
session 2: SAME
  by EVDs:  Newton-SIN-BH < Newton-SIN < Anderson-APM < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM
  cheapest overall: Newton-SIN-BH by EVDs, Newton-SIN-BH by time (agree); priciest overall: Dykstra-APM by EVDs, Dykstra-APM by time (agree)
session 3: DIFFERENT
  by EVDs:  Newton-SIN-BH < Newton-SIN < Anderson-APM < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM
  by time:  Newton-SIN-BH < Newton-SIN < SBB-Dual < Anderson-APM < AGD-SDAJ-BH < Dykstra-APM < AGD-SDAJ
  cheapest overall: Newton-SIN-BH by EVDs, Newton-SIN-BH by time (agree); priciest overall: Dykstra-APM by EVDs, AGD-SDAJ by time (DISAGREE)
session 4: DIFFERENT
  by EVDs:  Newton-SIN-BH < Newton-SIN < Anderson-APM < SBB-Dual < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM
  by time:  Newton-SIN-BH < Newton-SIN < SBB-Dual < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < Dykstra-APM
  cheapest overall: Newton-SIN-BH by EVDs, Newton-SIN-BH by time (agree); priciest overall: Dykstra-APM by EVDs, Dykstra-APM by time (agree)

Full agreement in 2 of 5 sessions. Cheapest overall agrees between the two metrics in 5 of 5 sessions; priciest overall agrees in 3 of 5. Disagreements, where they occur, are not necessarily confined to the middle of the ranking -- check the per-session lines above rather than assuming it.

## n=500 (18-instance timing subset)

Median microseconds/EVD per session (session 0 = the canonical,
previously shipped single run; sessions 1-4 = further repeats):

| solver | session 0 | session 1 | session 2 | session 3 | session 4 | spread (max/min - 1) |
|---|---:|---:|---:|---:|---:|---:|
| AGD-SDAJ | 48128 | 51141 | 223697 | 204203 | 105960 | 365% |
| AGD-SDAJ-BH | 48149 | 51568 | 220755 | 212088 | 105479 | 358% |
| Anderson-APM | 55379 | 59700 | 271046 | 249182 | 131072 | 389% |
| Dykstra-APM | 56471 | 61517 | 255741 | 237304 | 133142 | 353% |
| Newton-SIN | 54663 | 58818 | 250645 | 229818 | 104800 | 359% |
| Newton-SIN-BH | 61787 | 71309 | 288717 | 258399 | 127588 | 367% |
| SBB-Dual | 46632 | 49817 | 218131 | 203731 | 102190 | 368% |

EVD-order vs wall-clock-order of the seven variants, per session
(median total EVDs and median total elapsed time to the matched
target; "same" means the two rankings agree exactly):

session 0: SAME
  by EVDs:  Newton-SIN-BH < Newton-SIN < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM
  cheapest overall: Newton-SIN-BH by EVDs, Newton-SIN-BH by time (agree); priciest overall: Dykstra-APM by EVDs, Dykstra-APM by time (agree)
session 1: SAME
  by EVDs:  Newton-SIN-BH < Newton-SIN < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM
  cheapest overall: Newton-SIN-BH by EVDs, Newton-SIN-BH by time (agree); priciest overall: Dykstra-APM by EVDs, Dykstra-APM by time (agree)
session 2: DIFFERENT
  by EVDs:  Newton-SIN-BH < Newton-SIN < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM
  by time:  Newton-SIN-BH < Newton-SIN < AGD-SDAJ-BH < Anderson-APM < AGD-SDAJ < SBB-Dual < Dykstra-APM
  cheapest overall: Newton-SIN-BH by EVDs, Newton-SIN-BH by time (agree); priciest overall: Dykstra-APM by EVDs, Dykstra-APM by time (agree)
session 3: SAME
  by EVDs:  Newton-SIN-BH < Newton-SIN < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM
  cheapest overall: Newton-SIN-BH by EVDs, Newton-SIN-BH by time (agree); priciest overall: Dykstra-APM by EVDs, Dykstra-APM by time (agree)
session 4: DIFFERENT
  by EVDs:  Newton-SIN-BH < Newton-SIN < Anderson-APM < AGD-SDAJ-BH < AGD-SDAJ < SBB-Dual < Dykstra-APM
  by time:  Newton-SIN-BH < Newton-SIN < AGD-SDAJ-BH < AGD-SDAJ < Anderson-APM < SBB-Dual < Dykstra-APM
  cheapest overall: Newton-SIN-BH by EVDs, Newton-SIN-BH by time (agree); priciest overall: Dykstra-APM by EVDs, Dykstra-APM by time (agree)

Full agreement in 3 of 5 sessions. Cheapest overall agrees between the two metrics in 5 of 5 sessions; priciest overall agrees in 5 of 5. Disagreements, where they occur, are not necessarily confined to the middle of the ranking -- check the per-session lines above rather than assuming it.

