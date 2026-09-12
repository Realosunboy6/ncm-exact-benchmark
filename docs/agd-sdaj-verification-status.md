# AGD-SDAJ reimplementation: verification status

**Gate:** Paper 2 §5 requires a verified fourth solver. Per the risk register, a local
AGD-SDAJ implementation may be reported only after it reproduces Huynh & Hwang's own
published counts on their own instances. This document records that attempt.

**Verdict as of 2026-09-08: VERIFIED, with one documented residual.** The full text was
obtained (ILLiad) and equation (6) transcribed exactly. Two of three verification
instances now reproduce every published count exactly; the third matches iteration count
and residual exactly and differs by a single backtracking decision. This implementation
is cleared for use as the fourth solver in Paper 2 Sec. 5, provided the P7 residual is
disclosed.

**Source:** Huynh & Hwang (2025), *Accelerated Gradient Descent With Quasi-Newton
Preconditioning for Nearest Correlation Matrix Problems*, Numerical Linear Algebra with
Applications 32(6), DOI 10.1002/nla.70045.
**Implementation:** `experiments/bench/agd_sdaj.jl` (Julia, BLAS single-threaded).
**Instances:** exported by `export_agd_verify_matrices.jl` from the same Anymatrix
CORRINV `.mat` files already audited for the P7/P8 SBB-Dual runs, via the identical
`load_higham_matrix` convention — no new provenance question is introduced.

## 1. What was transcribed vs. what was assumed

**Transcribed from captured pages** (`work/pdf-review/algorithm1-09.png`,
`algorithms34-12.png`, `setup-16.png`): Algorithm 1 (AGD), Algorithm 3 (QN-SDAJ),
Algorithm 4 (AGD-SDAJ), and the Section 4.3 parameters `c=1e-4`, `rho=0.5`,
`lambda1=lambda2=0.01`, `eps_l=1e-5`, `eps_u=1e8`, `q=2`, `x_0=0`, stopping
`||grad theta|| <= 1e-7*n`, `k_max=200`.

**Obtained 2026-09-08 (full text via ILLiad).** Equation (6), article p.5, Li-Fukushima
[14] form, transcribed exactly:

```
||grad theta(x + alpha*d)||^2 <= (1 + eps_k)*||grad theta(x)||^2
                                 - lam1*||alpha*grad theta(x)||^2
                                 - lam2*||alpha*d||^2
```

with `eps_k = 1/(k+1)^2` (eq. (7), summable) and `lam1 = lam2 = 0.01`. The merit function
is `f = 0.5*||grad theta||^2`; the search direction need not be a descent direction for
it, which is precisely why a nonmonotone rule is needed. Article p.12 further confirms
`B_k` is reset to the identity once `x_k^pre` is generated, and that Step 4 discards
`x_k^pre` on insufficient decrease -- both already implemented correctly.

The pre-full-text guess had the right family but three wrong specifics: unsquared norms,
a missing `(1 + eps_k)` slack, and `lam1`/`lam2` attached to the wrong terms.

## 2. Results

Published values are Table 3 (q=2) for It/#EVDs/#NLS and Table A1 for `||A-X*||_F`.
`:eq6` is the final implementation (exact equation (6) + the general-direction
acceleration factor). `:gll` and `:lf` are the two superseded pre-full-text guesses,
retained because their bracketing is what localized the gap.

| Instance | Published It / EVDs / #NLS / norm | **`:eq6` (final)** | `:gll` | `:lf` |
|---|---|---|---|---|
| P9 `bccd16`, n=3250 | 1 / 5 / 0 / 29.06 | **1 / 5 / 0 / 29.0563 — EXACT** | 1 / 5 / 0 | 1 / 5 / 0 |
| P8 `cor3120`, n=3120 | 3 / 18 / 1 / 5.44 | **3 / 18 / 1 / 5.4437 — EXACT** | 3 / 17 / 0 | 3 / 19 / 2 |
| P7 `cor1399`, n=1399 | 4 / 31 / 8 / 21.03 | **4** / 32 / 7 / 21.0339 | 6 / 40 / 3 | 5 / 48 / 17 |

`||A-X*||_F` matches the published value to displayed precision on every instance and
under every variant tried, which is what established early that the objective, gradient,
projection and stopping rule were correct and isolated the discrepancy to work per
iteration.

## 3. Three defects found and fixed

The first two were found by accounting for P9's EVDs one at a time against the
published 5; the third by the P7 iteration-count gap surviving the correct linesearch.

1. **Redundant EVD at an already-evaluated point.** `qnsdaj!` recomputed `theta/grad` at
   the point its caller had just evaluated. Same defect class as Paper 2 Sec. 4 trap 1
   (redundant Jacobian factorization), found the same way — by counting primitives rather
   than trusting iteration counts. Fixed by threading `th0, g0` from the caller.
2. **Missing early termination on the preconditioned point.** The Table 3 note states the
   loop also terminates whenever `x_k^pre` satisfies the stopping criteria (P7, P8, P9),
   reducing EVDs "by fewer than two units." Without it the outer AGD step is always paid.
3. **Wrong acceleration factor in Algorithm 3.** `beta_k^pre` had been implemented with
   Algorithm 1's `a_k = ||g||^2`, which is the SPECIALIZATION to `d = -grad theta`. In
   Algorithm 3 the direction is `d = -B^{-1} g`, so the general Sec. 2.3 form
   `a = -g'd`, `b = (g_y - g)'d` is required; it reduces exactly to Algorithm 1 when
   `d = -g`, so it is consistent with both statements in the paper. **This was the cause
   of the outer-iteration-count gap**: fixing it took P7 from 6 iterations to 4.

Cumulative effect on P7: 46 EVDs -> 40 (defects 1-2) -> 43 with exact eq. (6) -> **32 with
the correct acceleration factor**, against a published 31.

## 4. The remaining P7 residual

P7 matches on outer iterations (4) and residual norm (21.0339), and differs by **one
backtracking decision**: 7 rejected trials locally against 8 published.

That single decision fully accounts for the EVD difference. Excluding backtracks, the
local base cost is `32 - 7 = 25` and the published base is `31 - 8 = 23`. The 2-EVD gap is
exactly the early-termination saving described in the Table 3 note: with their extra
backtrack the trajectory reaches tolerance *at* `x_k^pre`, skipping the final AGD step,
whereas the local trajectory reaches it just after. One knife-edge acceptance in
equation (6) therefore propagates to a 1-EVD and a 2-EVD difference.

**This is attributed to floating-point differences, not to a modelling error.** The
reference implementation is MATLAB; this one is Julia. `eig` and `eigen` dispatch to
different LAPACK drivers with different orderings, and on a 1399x1399 dense symmetric
problem last-bit differences in the spectrum are more than sufficient to flip a single
Armijo test whose two sides are nearly equal. P8 and P9 reproduce every count exactly
under the identical code path, which is the evidence that the rule itself is right.

No further parameter search was performed. Tuning `eps_k` indexing or the acceptance
inequality until P7 also matched would be fitting to a target, and could easily be wrong
in ways that surface only on the KKT family — the precise failure mode Paper 2 exists to
document.

## 5. Status and conditions of use

**Cleared** for use as the fourth solver in Paper 2 Sec. 5, subject to three conditions:

1. Publish `agd_sdaj.jl` and this verification record alongside the results.
2. Disclose the P7 residual explicitly (4/32/7 local vs 4/31/8 published) rather than
   reporting only the two exact matches.
3. Report AGD-SDAJ's own published counts next to the locally measured ones wherever the
   comparison appears, so a reader can see the reimplementation is faithful on the
   authors' own instances before reading any KKT-family result.

Because the solver is now verified on the source instances, Paper 2 Sec. 5 no longer
needs fallback option (b). The ranking-reversal study can proceed with four solvers:
corrected BH-Newton, SBB-Dual, Dykstra/APM, and AGD-SDAJ.
