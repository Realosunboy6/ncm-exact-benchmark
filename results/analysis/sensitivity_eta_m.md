# Sensitivity of Sec. 5 to SBB-Dual's eta and Anderson-APM's m

270 n=100 instances, tolerance 1e-11, target forward error 1e-8, reach-and-hold,
accepted-only. AGD-SDAJ-BH run once at its published parameters as the fixed
comparator; only eta (SBB-Dual) and m (Anderson-APM) are varied.

AGD-SDAJ-BH median EVDs to 1e-8: 45.0 (270/270 reached)

## SBB-Dual: sweep of eta, clamp interval [eta, 2-eta]

| eta | median EVDs (reached/270) | cheaper than AGD-SDAJ-BH (of instances both reached) |
|---:|---:|---:|
| 0.001 | 33.5 (270/270) | 167 / 270 |
| 0.01 | 34.0 (270/270) | 167 / 270 |
| 0.05 | 34.5 (270/270) | 167 / 270 |
| 0.1 | 36.0 (270/270) | 167 / 270 |
| 0.2 | 38.5 (270/270) | 165 / 270 |

## Anderson-APM: sweep of history length m

| m | median EVDs (reached/270) | cheaper than AGD-SDAJ-BH (of instances both reached) |
|---:|---:|---:|
| 1 | 36.0 (270/270) | 210 / 270 |
| 2 | 24.0 (270/270) | 240 / 270 |
| 3 | 21.5 (270/270) | 258 / 270 |
| 5 | 20.0 (270/270) | 261 / 270 |
| 10 | 19.0 (270/270) | 257 / 270 |

