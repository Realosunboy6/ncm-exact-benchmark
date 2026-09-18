"""Generate the data files behind the figures of section 5.

Writes into paper/figures/data/:
  evd_vs_eps.dat     median EVDs to reach and hold forward error eps, n=100,
                     every solver, on a half-decade grid of eps (Figure 1)
  heatmap.dat        per-cell ratio of median EVDs to 1e-8, SBB-Dual over
                     AGD-SDAJ-BH, n=100 (Figure 4, left)
  heatmap_pub.dat    the same for Dykstra-APM over AGD-SDAJ-BH (Figure 4, right)
  crossover.dat      fraction of instances on which SBB-Dual reaches 1e-8 in
                     fewer EVDs than AGD-SDAJ-BH, by rank and test set
  crossover_pub.dat  the same for the two published pairs: Dykstra-APM and
                     Anderson-APM, each against AGD-SDAJ-BH
  per_evd_cost.dat   median microseconds per EVD at matched tolerance, n=100,
                     from the timing runs in results/
  native_accuracy.dat  median forward error, EVDs and time at the native rule

Cost rule as everywhere else: accepted rows only, EVDs at the start of the
final suffix with err_raw_fro <= eps (reach and hold). A run that never reaches
the target counts as infinitely expensive, so it is never the cheaper one.
When several CSVs are read as one study, a later file supersedes an earlier one
for any (instance, solver) it contains.

Usage (from the artifact root, after reproduce.sh has unpacked the results):
  python code/make_figure_data.py results/reproduced paper/figures/data [timing_dir]
"""
import csv
import math
import os
import re
import statistics as st
import sys
from collections import defaultdict

INF = math.inf


def load(paths):
    keys_by_file = []
    for p in paths:
        with open(p) as f:
            keys_by_file.append({(r["instance"], r["solver"]) for r in csv.DictReader(f)})
    acc = defaultdict(list)
    for k, p in enumerate(paths):
        superseded = set().union(*keys_by_file[k + 1:]) if k + 1 < len(paths) else set()
        with open(p) as f:
            for r in csv.DictReader(f):
                key = (r["instance"], r["solver"])
                if key in superseded:
                    continue
                if r["accepted"].strip().lower() == "true":
                    acc[key].append((int(r["evds"]), float(r["err_raw_fro"])))
    for k in acc:
        acc[k].sort()
    return acc


def cost(tr, eps):
    if not tr or tr[-1][1] > eps:
        return INF
    k = len(tr) - 1
    while k > 0 and tr[k - 1][1] <= eps:
        k -= 1
    return tr[k][0]


def rank_of(name):
    return int(re.search(r"-r(\d+)-", name).group(1))


def fmt(x):
    return "nan" if x is None or (isinstance(x, float) and math.isnan(x)) else f"{x:g}"


def evd_vs_eps(acc, out):
    solvers = ["Newton-SIN-BH", "AGD-SDAJ-BH", "AGD-SDAJ", "SBB-Dual", "Dykstra-APM", "Anderson-APM"]
    cols = [s.replace("-", "") for s in solvers]
    inst = sorted({i for i, _ in acc})
    with open(out, "w", newline="\n") as f:
        f.write("eps " + " ".join(cols) + " " + " ".join("reach" + c for c in cols) + "\n")
        for k in range(2, 21):                       # 1e-1 .. 1e-10, half-decade steps
            eps = 10 ** (-k / 2)
            meds, reach = [], []
            for s in solvers:
                v = [c for i in inst if (c := cost(acc[(i, s)], eps)) < INF]
                meds.append(fmt(st.median(v)) if v else "nan")
                reach.append(str(len(v)))
            f.write(f"{eps:.3e} " + " ".join(meds) + " " + " ".join(reach) + "\n")


def heatmap(acc, num, den, out):
    """Rows: (r, m) in order (5,1)..(50,20); columns: delta 0, 1e-10, 1e-8, 1e-6, 1e-4, 1e-2."""
    deltas = ["0", "1e-10", "1e-08", "1e-06", "0.0001", "0.01"]
    rows = [(r, m) for r in (5, 20, 50) for m in (1, 5, 20)]
    inst = sorted({i for i, _ in acc})
    with open(out, "w", newline="\n") as f:
        f.write("x y ratio\n")
        for y, (r, m) in enumerate(rows):
            for x, d in enumerate(deltas):
                I = [i for i in inst if re.match(rf"degen-r{r}-m{m}-d{re.escape(d)}-p\d+$", i)]
                a = st.median(cost(acc[(i, num)], 1e-8) for i in I)
                b = st.median(cost(acc[(i, den)], 1e-8) for i in I)
                f.write(f"{x} {y} {a / b:.4f}\n")
            f.write("\n")                          # scanline break, as pgfplots expects


TIMING_ORDER = ["Newton-SIN-BH", "Newton-SIN", "AGD-SDAJ-BH", "AGD-SDAJ",
                "SBB-Dual", "Dykstra-APM", "Anderson-APM"]


def timing_figures(native_csv, matched_csv, dst):
    """per_evd_cost.dat (matched tolerance) and native_accuracy.dat (native rule),
    both at n=100, with the medians analyze_timing.py reports."""
    def rows(p):
        d = defaultdict(list)
        with open(p) as f:
            for r in csv.DictReader(f):
                d[r["solver"]].append(r)
        return d
    m, nat = rows(matched_csv), rows(native_csv)
    per = {s: st.median(1e6 * float(r["elapsed_seconds"]) / float(r["total_evds"])
                        for r in m[s] if float(r["total_evds"]) > 0)
           for s in TIMING_ORDER if s in m}
    lo = min(per.values())
    with open(os.path.join(dst, "per_evd_cost.dat"), "w", newline="\n") as f:
        f.write("idx solver name usperevd rel\n")
        for k, s in enumerate(sorted(per, key=per.get), 1):
            f.write(f"{k} {s.replace('-', '')} {s} {per[s]:.0f} {per[s] / lo:.2f}\n")
    with open(os.path.join(dst, "native_accuracy.dat"), "w", newline="\n") as f:
        f.write("idx solver name err evds time\n")
        for k, s in enumerate([s for s in TIMING_ORDER if s in nat], 1):
            rs = nat[s]
            err = st.median(float(r["err_vs_ref_fro"]) for r in rs)
            ev = st.median(float(r["total_evds"]) for r in rs)
            t = st.median(float(r["elapsed_seconds"]) for r in rs)
            f.write(f"{k} {s.replace('-', '')} {s} {err:.2e} {ev:.0f} {t:.3f}\n")


def fraction_cheaper(acc, a, b, eps=1e-8):
    by_rank = defaultdict(list)
    for i in sorted({i for i, _ in acc}):
        if (i, a) in acc and (i, b) in acc:
            by_rank[rank_of(i)].append(cost(acc[(i, a)], eps) < cost(acc[(i, b)], eps))
    return {r: sum(v) / len(v) for r, v in by_rank.items()}


def main():
    src, dst = sys.argv[1], sys.argv[2]
    P = lambda *names: [os.path.join(src, n) for n in names]
    n100 = load(P("ranking_kkt270_v2.csv", "ranking_kkt270_anderson.csv"))
    n500 = load(P("ranking_n500.csv", "ranking_n500_anderson.csv"))
    hr = load(P("ranking_highrank_n500.csv", "ranking_highrank_proj.csv"))
    n550 = load(P("ranking_thesis_kkt.csv", "ranking_thesis_kkt_anderson.csv"))
    n2105 = load(P("ranking_us2105_kkt.csv", "ranking_us2105_kkt_part2.csv",
                   "ranking_us2105_dykstra.csv", "ranking_us2105_anderson.csv"))
    n500all = {**n500, **hr}

    evd_vs_eps(n100, os.path.join(dst, "evd_vs_eps.dat"))
    tdir = sys.argv[3] if len(sys.argv) > 3 else os.path.join(src, os.pardir)   # results/
    timing_figures(os.path.join(tdir, "timing_kkt270_native.csv"),
                   os.path.join(tdir, "timing_kkt270_matched.csv"), dst)
    heatmap(n100, "SBB-Dual", "AGD-SDAJ-BH", os.path.join(dst, "heatmap.dat"))
    heatmap(n100, "Dykstra-APM", "AGD-SDAJ-BH", os.path.join(dst, "heatmap_pub.dat"))

    ranks = [5, 20, 50, 75, 100, 150, 200, 400]
    sets = [("frac100", n100), ("frac500", n500all), ("frac550", n550), ("frac2105", n2105)]
    fr = {k: fraction_cheaper(a, "SBB-Dual", "AGD-SDAJ-BH") for k, a in sets}
    with open(os.path.join(dst, "crossover.dat"), "w", newline="\n") as f:
        f.write("# Fraction of instances on which SBB-Dual reaches forward error 1e-8 in fewer\n"
                "# EVDs than AGD-SDAJ-BH, by solution rank, for each test set.\n"
                "# Generated by code/make_figure_data.py.\n")
        f.write("rank " + " ".join(k for k, _ in sets) + "\n")
        for r in ranks:
            f.write(f"{r} " + " ".join(f"{fr[k][r]:.2f}" if r in fr[k] else "nan" for k, _ in sets) + "\n")

    pub = [("dyk100", fraction_cheaper(n100, "Dykstra-APM", "AGD-SDAJ-BH")),
           ("dyk500", fraction_cheaper(n500all, "Dykstra-APM", "AGD-SDAJ-BH")),
           ("and2105", fraction_cheaper(n2105, "Anderson-APM", "AGD-SDAJ-BH"))]
    with open(os.path.join(dst, "crossover_pub.dat"), "w", newline="\n") as f:
        f.write("# Fraction of instances on which the first method of a published pair reaches\n"
                "# forward error 1e-8 in fewer EVDs than AGD-SDAJ-BH, by solution rank:\n"
                "# Dykstra-APM at n=100 and n=500, Anderson-APM at n=2105.\n"
                "# Generated by code/make_figure_data.py.\n")
        f.write("rank " + " ".join(k for k, _ in pub) + "\n")
        for r in ranks:
            f.write(f"{r} " + " ".join(f"{d[r]:.2f}" if r in d else "nan" for _, d in pub) + "\n")
    print("wrote", dst)


if __name__ == "__main__":
    main()
