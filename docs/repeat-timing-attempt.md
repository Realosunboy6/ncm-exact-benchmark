# Repeat-timing uncertainty for tab:perevd: completed

A referee-style review flagged that tab:perevd's per-EVD ratios (1.04-1.18x
for five of the seven variants) come from one `@elapsed` per instance, and
are smaller than the documented ~4x session-to-session drift, so they carry
no stated uncertainty. This note records how that was fixed: four further
matched-tolerance timing sessions, and two real problems found and fixed
along the way.

## Result

Four further sessions of `code/repeat_timing.sh` (same instances, same
code, matched tolerance) were run to completion, alongside the existing
canonical session. `code/analyze_timing_repeats.py`, run on all five,
found:

- A given solver's median microseconds/EVD varies by up to a factor of 4.9
  (n=100) / 4.7 (n=500) across the five sessions -- an order of magnitude
  more than the <=1.50x spread *between* solvers within any one session.
- The specific per-solver ratios in tab:perevd are therefore one session's
  draw, not stable constants, except at the extremes: the cheapest solver
  per EVD is always SBB-Dual or an AGD variant, and the dearest is
  Newton-SIN-BH in four of five sessions (Anderson-APM in the fifth).
- The "cost metric does not change the ranking" claim (Sec. 3.6): the
  EVD-order and wall-clock-order of all seven variants agree exactly in
  only 2 of 5 sessions at n=100 and 3 of 5 at n=500. What is robust in
  every session at both dimensions is the position of the two ends
  (Newton-SIN-BH cheapest overall, Dykstra-APM dearest overall); the
  disagreements are confined to the middle four or five solvers, and where
  they occur they are systematic (SBB-Dual overtakes Anderson-APM), not
  random noise.

Sec. 3.6 and the Sec. 8 limitations were rewritten to report this directly,
with concrete numbers in place of the earlier placeholder ("ratios under
about 15%"). Output shipped at `results/analysis/timing_repeats.md`.
Wall-clock cost, from `results/timing_kkt270_matched_rep{1,2,3,4}.csv` and
`results/timing_n500_matched_rep{1,2,3,4}.csv`.

## Two problems found and fixed along the way

**1. The environment blocker resolved on its own.** An earlier attempt on
this machine hit `using MAT` and, separately, `using TimerOutputs` failing
with

```
An Application Control policy has blocked this file.
```

blocking the compiled package caches for MAT's `dlfcn_win32_jll` dependency
and TimerOutputs' `LaTeXStrings` dependency. On retry (a later date), both
loaded cleanly with no code change. This looks like a transient Windows
Application Control (WDAC/AppLocker-style) state, not a permanent
restriction; if it recurs, there is no code-level fix, and it is not
something to try to work around.

**2. A real bug this investigation had introduced.** The first successful
retry showed every timing run's "EVD %" column at a suspicious flat 0.0%.
`section_seconds` in `bench_sbb_dual.jl` had been guarded with
`hasproperty(to, :inner_timers)` (added while chasing problem 1, to stop it
crashing under the unrelated `NCM_STANDALONE` stub). This is not a safe
check for the real `TimerOutputs.TimerOutput`: its actual fields are
`:root`/`:stack`/`:enabled`/`:start_time`/`:start_allocs`/`:measured`, and
`.inner_timers` is exposed only through a custom `getproperty`, which
`hasproperty` does not see (verified directly: `hasproperty(to,
:inner_timers)` is `false`, but `haskey(to.inner_timers, "foo")` works
fine). So the guard silently zeroed the breakdown for every real timing run
since it was added. Fixed with a `try`/`catch` instead (identical behavior
on the real type, still degrades to 0.0 on the stub). This never affected
any number already in the paper -- every shipped timing CSV predates the
bug -- but would have if left in place for the repeat-timing runs, whose
"EVD %" column would otherwise have been silently wrong (not that this
column is what tab:perevd/tab:primitive use -- see below -- but it would
have been a live landmine for the next person who did trust it).

**3. `NCM_STANDALONE=1` is not a valid substitute for real timing,
confirmed again.** A spot check while problem 1 was still blocking real
`TimerOutputs` showed the stub's dummy `TimerOutput` inflates the outer
`@elapsed` itself by roughly 2.2x on SBB-Dual, not only the internal
breakdown it is documented to skip. `repeat_timing.sh` requires
`NCM_STANDALONE=0` and should not be "fixed" to use the stub.
