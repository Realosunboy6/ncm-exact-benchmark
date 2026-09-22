# Attempt to add repeat-timing uncertainty to tab:perevd (not completed)

A referee-style review flagged that tab:perevd's per-EVD ratios (1.04-1.18x
for five of the seven variants) come from one `@elapsed` per instance, and
are smaller than the documented ~4x session-to-session drift, so they carry
no stated uncertainty. This note records an attempt to fix that by repeating
the matched-tolerance timing measurements several times, and why it was not
completed.

## What was tried

`code/repeat_timing.sh` repeats `timing_rerun.sh`'s matched-tolerance steps
(n=100 full suite, n=500 18-instance timing subset) `N` times, writing each
repeat to its own CSV, so the per-EVD spread across repeats can be reported
alongside the single-run numbers already in the paper.

## Why it did not run here

The timing harness needs `NCM_STANDALONE=0` for real timings: its
`NCM_STANDALONE=1` stub replaces `TimerOutputs.@timeit` with a no-op and
short-circuits `MAT`, which is fine for the ranking study (only EVD counts
and forward error matter there) but is NOT a valid substitute for timing --
a spot check here showed it inflates `@elapsed` itself by roughly 2.2x on
SBB-Dual, not only the internal percentage breakdown, presumably from type
instability in the stubbed `to::TimerOutput` argument threaded through the
solvers' hot loops. (One incidental, harmless fix survived this
investigation: `section_seconds` in `bench_sbb_dual.jl` now checks
`hasproperty(to, :inner_timers)` instead of assuming it, so it degrades to
0.0 under the stub instead of throwing.)

With `NCM_STANDALONE=0`, `using MAT` fails on this machine:

```
ERROR: LoadError: InitError: could not load library ".../dlfcn_win32_jll/.../libdl.dll"
An Application Control policy has blocked this file.
```

A `NCM_NO_MAT` mode (load `TimerOutputs` for real timing, stub only
`matread`) was added and then removed again, because `using TimerOutputs`
alone fails the same way, blocked on a different compiled package cache file
(`LaTeXStrings`, one of its dependencies):

```
ERROR: LoadError: Error opening package file .../LaTeXStrings/....dll:
An Application Control policy has blocked this file.
```

This is a Windows Application Control (WDAC/AppLocker-style) policy on this
machine blocking newly compiled Julia package-cache DLLs for at least these
two packages, not a bug in this repository's code, and not something this
session should try to work around (there is no code-level fix for an OS
security policy, and disabling or bypassing it is out of scope). The same
commands succeeded in an earlier session on what should be the same
machine, so the policy or the depot's trust state changed in between; the
`timing_rerun.sh` run that the paper's timing tables come from (commit
`cb6625a`) predates this and is unaffected.

## To finish this later

On a machine where `julia --project=code -e "using TimerOutputs, MAT"`
succeeds, run:

```sh
sh code/repeat_timing.sh 4 results/repeat_timing
```

(4 further repeats; the existing `results/timing_kkt270_matched.csv` and
`results/timing_n500_matched.csv` serve as repeat 1.) Then compute the
per-solver, per-repeat median microseconds/EVD and report the range or
coefficient of variation alongside tab:perevd, and revisit the Sec. 8
sentence that currently just says ratios under about 15% should not be read
as ordered.
