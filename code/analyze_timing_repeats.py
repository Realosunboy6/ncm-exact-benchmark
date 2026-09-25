"""Repeat-timing check for Sec. 3.6 (tab:perevd) and the "cost metric does not
change the ranking" claim.

The matched-tolerance timing measurement (tab:perevd, tab:primitive, and the
EVD-vs-wall-clock ranking comparison) previously rested on a single
@elapsed per instance per solver. This script reads that canonical run
together with `code/repeat_timing.sh`'s further repeats of the same
solvers on the same instances, and reports, per solver:

  * the median microseconds/EVD in each session, and the spread across
    sessions (tab:perevd's session-to-session uncertainty);
  * whether the overall EVD-order and wall-clock-order of the seven variants
    (median EVDs and median elapsed time to the matched target) agree in
    each session (the "cost metric does not change the ranking" claim).

`totals()` takes the median over every row for a solver, including any run
that hit its EVD/iteration cap without converging (Newton-SIN's 56/270
naive-Armijo stalls at n=100 are the largest such group; see Sec. 4.2).
Their cost-to-exit is counted as their cost, which is the same convention
tab:perevd and tab:primitive already use, not a new one introduced here.

Usage: python analyze_timing_repeats.py canonical_n100.csv rep_n100_1.csv ... \
           -- canonical_n500.csv rep_n500_1.csv ... [out.md]
(a bare "--" separates the n=100 file list from the n=500 file list; the
last argument is the output path if it does not end in .csv)
"""
import csv
import statistics as st
import sys
from collections import defaultdict

args = sys.argv[1:]
out = args[-1] if args and not args[-1].lower().endswith(".csv") else None
if out is not None:
    args = args[:-1]
sep = args.index("--")
n100_files, n500_files = args[:sep], args[sep + 1:]

L = []


def emit(s=""):
    L.append(s)
    print(s)


def load(path):
    rows = defaultdict(list)
    with open(path) as f:
        for r in csv.DictReader(f):
            rows[r["solver"]].append(r)
    return rows


def per_evd_median(rows):
    vals = [1e6 * float(r["elapsed_seconds"]) / float(r["total_evds"])
            for r in rows if float(r["total_evds"]) > 0]
    return st.median(vals) if vals else float("nan")


def totals(rows):
    return (st.median(float(r["total_evds"]) for r in rows),
            st.median(float(r["elapsed_seconds"]) for r in rows))


def section(label, files):
    emit(f"## {label}")
    emit("")
    runs = [load(f) for f in files]
    solvers = sorted(runs[0].keys())

    emit("Median microseconds/EVD per session (session 0 = the canonical,")
    emit("previously shipped single run; sessions 1-4 = further repeats):")
    emit("")
    emit("| solver | " + " | ".join(f"session {i}" for i in range(len(files)))
         + " | spread (max/min - 1) |")
    emit("|---|" + "---:|" * (len(files) + 1))
    for s in solvers:
        vals = [per_evd_median(r[s]) for r in runs]
        spread = 100 * (max(vals) / min(vals) - 1)
        emit(f"| {s} | " + " | ".join(f"{v:.0f}" for v in vals) +
             f" | {spread:.0f}% |")
    emit("")

    emit("EVD-order vs wall-clock-order of the seven variants, per session")
    emit("(median total EVDs and median total elapsed time to the matched")
    emit("target; \"same\" means the two rankings agree exactly):")
    emit("")
    agree = 0
    cheapest_agree = 0
    priciest_agree = 0
    for i, r in enumerate(runs):
        med_evd, med_time = {}, {}
        for s in solvers:
            e, t = totals(r[s])
            med_evd[s] = e
            med_time[s] = t
        order_evd = sorted(solvers, key=med_evd.get)
        order_time = sorted(solvers, key=med_time.get)
        same = order_evd == order_time
        agree += same
        cheap_ok = order_evd[0] == order_time[0]
        price_ok = order_evd[-1] == order_time[-1]
        cheapest_agree += cheap_ok
        priciest_agree += price_ok
        emit(f"session {i}: {'SAME' if same else 'DIFFERENT'}")
        emit(f"  by EVDs:  {' < '.join(order_evd)}")
        if not same:
            emit(f"  by time:  {' < '.join(order_time)}")
        emit(f"  cheapest overall: {order_evd[0]} by EVDs, {order_time[0]} by "
             f"time ({'agree' if cheap_ok else 'DISAGREE'}); priciest overall: "
             f"{order_evd[-1]} by EVDs, {order_time[-1]} by time "
             f"({'agree' if price_ok else 'DISAGREE'})")
    emit("")
    emit(f"Full agreement in {agree} of {len(runs)} sessions. Cheapest overall "
         f"agrees between the two metrics in {cheapest_agree} of {len(runs)} "
         f"sessions; priciest overall agrees in {priciest_agree} of "
         f"{len(runs)}. Disagreements, where they occur, are not necessarily "
         "confined to the middle of the ranking -- check the per-session lines "
         "above rather than assuming it.")
    emit("")


section("n=100 (270 instances)", n100_files)
section("n=500 (18-instance timing subset)", n500_files)

if out is not None:
    with open(out, "w") as f:
        for l in L:
            f.write(l + "\n")
    print(f"wrote {out}", file=sys.stderr)
