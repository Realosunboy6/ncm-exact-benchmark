"""Fairness check: does the ranking change if cost is scored on the BH-rescaled
iterate (err_bh_fro) instead of the raw projection (err_raw_fro)?

SBB-Dual applies a Borsdorf-Higham rescaling epilogue before returning X, so it is
scored on a quantity it does not return. Both columns are recorded for every solver.
Usage: python check_scoring_column.py <ranking csv> [...]
"""
import csv
import os
import statistics as st
import sys
from collections import defaultdict

SOLVERS = ["Newton-SIN-BH", "AGD-SDAJ-BH", "AGD-SDAJ", "SBB-Dual", "Dykstra-APM"]
EPS = [1e-2, 1e-4, 1e-6, 1e-8, 1e-10]


def load(path, col):
    rows = defaultdict(list)
    with open(path) as f:
        for r in csv.DictReader(f):
            if r["accepted"] == "true":
                rows[(r["instance"], r["solver"])].append((int(r["evds"]), float(r[col])))
    return rows


def cost(tr, eps):
    if not tr or tr[-1][1] > eps:
        return None
    k = len(tr) - 1
    while k > 0 and tr[k - 1][1] <= eps:
        k -= 1
    return tr[k][0]


for path in sys.argv[1:]:
    print(f"\n=== {os.path.basename(path)}")
    raw, bh = load(path, "err_raw_fro"), load(path, "err_bh_fro")
    inst = sorted({k[0] for k in raw})
    print(f"{len(inst)} instances")
    for eps in EPS:
        line = []
        order = {}
        for col, rows in (("raw", raw), ("bh", bh)):
            med = {}
            for s in SOLVERS:
                v = [c for i in inst if (c := cost(rows[(i, s)], eps)) is not None]
                med[s] = st.median(v) if v else None
            order[col] = [s for s in sorted((s for s in SOLVERS if med[s] is not None), key=lambda s: med[s])]
            line.append(" ".join(f"{s.split('-')[0]}{'BH' if s.endswith('-BH') else ''}={med[s]:g}({sum(1 for i in inst if cost(rows[(i, s)], eps) is not None)})"
                                 for s in SOLVERS if med[s] is not None))
        same = "SAME ORDER" if order["raw"] == order["bh"] else "ORDER CHANGES: raw " + " < ".join(order["raw"]) + " | bh " + " < ".join(order["bh"])
        print(f"  eps={eps:g}\n    raw: {line[0]}\n    bh : {line[1]}\n    -> {same}")
