"""Median EVDs by solution rank, for the equity-derived KKT families.

Produces the by-rank tables of the paper (equity n=550 and n=2105): median
EVDs to reach and hold a forward-error target, per rank, per solver, with the
number of instances on which one named solver is cheaper than another.

Cost rule, as everywhere else: accepted rows only, EVDs at the start of the
final suffix with err_raw_fro <= eps (reach and hold). A solver that never
reaches the target is reported as '--' and excluded from the pairwise counts.

Usage:
  python analyze_by_rank.py out.md file1.csv [file2.csv ...] [pairA:pairB ...]

Example:
  python analyze_by_rank.py t.md ranking_thesis_kkt.csv ranking_thesis_kkt_anderson.csv \\
      SBB-Dual:AGD-SDAJ-BH Anderson-APM:AGD-SDAJ-BH
"""
import csv
import re
import statistics as st
import sys
from collections import defaultdict

SOLVER_ORDER = ["Newton-SIN-BH", "AGD-SDAJ-BH", "AGD-SDAJ", "SBB-Dual",
                "Dykstra-APM", "Anderson-APM"]
EPS = [1e-4, 1e-6, 1e-8, 1e-10]


def load(paths):
    rows = defaultdict(list)
    for p in paths:
        with open(p) as f:
            for r in csv.DictReader(f):
                if r["accepted"].strip().lower() == "true":
                    rows[(r["instance"], r["solver"])].append(
                        (int(r["evds"]), float(r["err_raw_fro"])))
    for k in rows:
        rows[k].sort()
    return rows


def cost(tr, eps):
    if not tr or tr[-1][1] > eps:
        return None
    k = len(tr) - 1
    while k > 0 and tr[k - 1][1] <= eps:
        k -= 1
    return tr[k][0]


def main():
    args = sys.argv[1:]
    files = [a for a in args if a.lower().endswith(".csv")]
    outpath = next(a for a in args if a.lower().endswith(".md"))
    pairs = [tuple(a.split(":")) for a in args
             if ":" in a and not a.lower().endswith((".csv", ".md"))]
    rows = load(files)
    inst = sorted({i for i, _ in rows})
    solvers = [s for s in SOLVER_ORDER if any((i, s) in rows for i in inst)]
    ranks = sorted({int(re.search(r"-r(\d+)-", i).group(1)) for i in inst})

    out = []

    def emit(line=""):
        out.append(line)
        print(line)

    emit(f"# Median EVDs by rank ({len(inst)} instances, {len(solvers)} solvers)")
    emit()
    emit("Reach-and-hold rule, accepted rows only. '--' = target not reached.")
    for eps in EPS:
        emit()
        emit(f"## forward target {eps:g}")
        emit()
        head = "| r | n | " + " | ".join(solvers)
        for a, b in pairs:
            head += f" | {a} < {b}"
        emit(head + " |")
        emit("|---:|---:|" + "---:|" * (len(solvers) + len(pairs)))
        for r in ranks:
            I = [i for i in inst if int(re.search(r"-r(\d+)-", i).group(1)) == r]
            cells = []
            for s in solvers:
                v = [c for i in I if (c := cost(rows[(i, s)], eps)) is not None]
                cells.append("--" if not v else
                             f"{st.median(v):g}" + ("" if len(v) == len(I) else f" [{len(v)}]"))
            for a, b in pairs:
                d = [x - y for i in I
                     if (x := cost(rows[(i, a)], eps)) is not None
                     and (y := cost(rows[(i, b)], eps)) is not None]
                cells.append("--" if not d else f"{sum(x < 0 for x in d)}/{len(d)}")
            emit(f"| {r} | {len(I)} | " + " | ".join(cells) + " |")
    with open(outpath, "w") as f:
        f.write("\n".join(out) + "\n")


if __name__ == "__main__":
    main()
