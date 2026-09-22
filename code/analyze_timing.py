"""Paper 2 Secs. 3.1/3.4/3.5: is the EVD a fair unit of work, and does the cost
metric change the ranking?

Reads the timing CSVs written by bench_sbb_dual.jl (--tol-mode native|matched)
and answers three questions the protocol depends on:

  1. Sec. 3.1  At native stopping rules, do solvers stop at comparable accuracy?
               If not, native-rule cost comparisons are meaningless.
  2. Sec. 3.4  Is "EVDs" a hardware-independent proxy for cost, or does
               seconds-per-EVD differ enough across solvers that counting EVDs
               systematically favours some methods? Newton spends Krylov work
               per outer iteration that never appears in an EVD count.
  3. Sec. 5    Does ranking by wall-clock agree with ranking by EVDs? A
               disagreement is a cost-metric-dependent reversal and is reported
               as such.

Usage: python analyze_timing.py timing_native.csv timing_matched.csv [out.md]
"""
import csv
import statistics
import sys
from collections import defaultdict

args = [a for a in sys.argv[1:]]
outpath = None
if len(args) >= 3:
    outpath = args[2]
native_path = args[0] if args else "timing_kkt270_native.csv"
matched_path = args[1] if len(args) > 1 else "timing_kkt270_matched.csv"

ORDER = ["Newton-SIN-BH", "Newton-SIN", "AGD-SDAJ-BH", "AGD-SDAJ",
         "SBB-Dual", "Dykstra-APM", "Anderson-APM"]

L = []


def emit(line=""):
    L.append(line)
    print(line)


def med(v):
    return statistics.median(v) if v else float("nan")


def hm(x):
    """Median of counts: keep the half-integer, drop a trailing .0."""
    return f"{x:g}"


def load(path):
    rows = defaultdict(list)
    try:
        with open(path) as f:
            for r in csv.DictReader(f):
                rows[r["solver"]].append(r)
    except FileNotFoundError:
        return None
    return rows


def fnum(r, k, default=0.0):
    try:
        return float(r[k])
    except (KeyError, ValueError, TypeError):
        return default


def section(title, rows, tol_label):
    emit(f"## {title}")
    emit("")
    if rows is None:
        emit("*(file not found)*")
        emit("")
        return None
    solvers = [s for s in ORDER if s in rows]
    n_inst = len(rows[solvers[0]]) if solvers else 0
    emit(f"{n_inst} instances, tolerance rule: {tol_label}.")
    emit("")
    emit("| solver | median EVDs | median time (s) | median err vs X* | "
         "us/EVD | EVD % | CG iters | LS trials |")
    emit("|---|---:|---:|---:|---:|---:|---:|---:|")
    stats = {}
    for s in solvers:
        rs = rows[s]
        evds = [fnum(r, "total_evds") for r in rs]
        secs = [fnum(r, "elapsed_seconds") for r in rs]
        errs = [fnum(r, "err_vs_ref_fro") for r in rs]
        evpc = [fnum(r, "evd_percent") for r in rs]
        cg = [fnum(r, "cg_iters_total") for r in rs]
        ls = [fnum(r, "linesearch_trials") for r in rs]
        per = [1e6 * t / e for t, e in zip(secs, evds) if e > 0]
        stats[s] = dict(evds=med(evds), secs=med(secs), err=med(errs),
                        per=med(per), cg=med(cg), ls=med(ls))
        emit(f"| {s} | {hm(med(evds))} | {med(secs):.3f} | {med(errs):.2e} | "
             f"{med(per):.0f} | {med(evpc):.1f} | {hm(med(cg))} | {hm(med(ls))} |")
    emit("")
    return stats


emit("# Paper 2 - timing, primitive work, and cost-metric sensitivity")
emit("")
emit("Single-threaded BLAS, discarded warmup solve, GC before the measured run,")
emit("one `@elapsed` around the whole solve (protocol Sec. 3.5). Percentages are")
emit("taken against measured elapsed time, so uninstrumented work appears as")
emit("`other_seconds` rather than inflating the EVD share.")
emit("")

nat = load(native_path)
mat = load(matched_path)

s_nat = section("1. Native stopping rules (Sec. 3.1)", nat, "1e-7*n (dimension-scaled)")
if s_nat:
    errs = {k: v["err"] for k, v in s_nat.items()}
    lo, hi = min(errs.values()), max(errs.values())
    emit(f"**Achieved accuracy spans {hi/lo:.1f}x across solvers at their native")
    emit("exits** (best "
         f"{min(errs, key=errs.get)} at {lo:.2e}, worst "
         f"{max(errs, key=errs.get)} at {hi:.2e}). Cost comparisons taken at these")
    emit("exit points are therefore comparisons at different accuracies, which is")
    emit("the confound Sec. 3.1 exists to name.")
    emit("")

s_mat = section("2. Matched tolerance (Sec. 3.4/3.5)", mat, "common 1e-11")


def rank_by(stats, key):
    return [s for s, _ in sorted(stats.items(), key=lambda kv: kv[1][key])]


if s_mat:
    emit("## 3. Is the EVD a fair unit of work?")
    emit("")
    per = {k: v["per"] for k, v in s_mat.items()}
    lo_s, hi_s = min(per, key=per.get), max(per, key=per.get)
    emit("| solver | microseconds per EVD | relative to cheapest |")
    emit("|---|---:|---:|")
    for s in [x for x in ORDER if x in per]:
        emit(f"| {s} | {per[s]:.0f} | {per[s]/per[lo_s]:.2f}x |")
    emit("")
    spread = per[hi_s] / per[lo_s]
    emit(f"Spread: **{spread:.2f}x** ({lo_s} cheapest, {hi_s} dearest).")
    emit("")
    if spread < 1.25:
        emit("Per-EVD cost is nearly uniform across solvers, so EVD counts are a")
        emit("defensible hardware-independent proxy for wall-clock on this family.")
    else:
        emit("Per-EVD cost is **not** uniform: counting EVDs systematically favours")
        emit("whichever method carries the most non-spectral work per decomposition")
        emit("(Krylov products, line-search bookkeeping). EVD counts must therefore")
        emit("be reported alongside wall-clock, never instead of it.")
    emit("")

    emit("## 4. Does the cost metric change the ranking?")
    emit("")
    by_evd = rank_by(s_mat, "evds")
    by_time = rank_by(s_mat, "secs")
    emit(f"- By **EVDs**: {' < '.join(by_evd)}")
    emit(f"- By **wall-clock**: {' < '.join(by_time)}")
    emit("")
    if by_evd == by_time:
        emit("**The two metrics agree.** No cost-metric-dependent reversal on this")
        emit("family; the EVD-count rankings reported in Sec. 5 are not an artifact")
        emit("of choosing a spectral-work unit.")
    else:
        swaps = [(a, b) for a, b in zip(by_evd, by_time) if a != b]
        emit("**The two metrics disagree** - a cost-metric-dependent reversal.")
        emit(f"First position where they differ: {swaps[0][0]} (by EVDs) vs "
             f"{swaps[0][1]} (by time).")
        emit("Report both metrics; a paper quoting only one is quoting a choice.")
    emit("")

    emit("## 5. Primitive work beyond the EVD (Sec. 3.4)")
    emit("")
    emit("| solver | median EVDs | CG iterations | line-search trials | accepted outer its |")
    emit("|---|---:|---:|---:|---:|")
    for s in [x for x in ORDER if x in mat]:
        rs = mat[s]
        emit(f"| {s} | {hm(med([fnum(r,'total_evds') for r in rs]))} | "
             f"{hm(med([fnum(r,'cg_iters_total') for r in rs]))} | "
             f"{hm(med([fnum(r,'linesearch_trials') for r in rs]))} | "
             f"{hm(med([fnum(r,'accepted_outer_iterations') for r in rs]))} |")
    emit("")
    emit("An 'iteration' means a different amount of work in each row: a Newton")
    emit("outer iteration carries a Krylov solve, a Dykstra iteration is one")
    emit("projection, an AGD-SDAJ outer iteration contains q inner QN-SDAJ steps")
    emit("each with its own line search. Reporting iteration counts across these")
    emit("methods without the primitive breakdown is not a comparison.")
    emit("")

    emit("## 6. Exit reasons at matched tolerance")
    emit("")
    emit("| solver | exit | count |")
    emit("|---|---|---:|")
    for s in [x for x in ORDER if x in mat]:
        ec = defaultdict(int)
        for r in mat[s]:
            ec[r["exit"]] += 1
        for e, c in sorted(ec.items(), key=lambda kv: -kv[1]):
            emit(f"| {s} | {e} | {c} |")
    emit("")

if outpath:
    with open(outpath, "w", encoding="utf-8") as f:
        f.write("\n".join(L) + "\n")
    print(f"\nwrote {outpath}")
