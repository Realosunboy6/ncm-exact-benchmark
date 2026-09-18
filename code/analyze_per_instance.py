"""One row per instance and solver: the literature-matrix table.

For each instance and solver: EVDs to reach and hold a forward-error target,
total EVDs at the solver's own exit, the forward error there, and the exit
reason. Cost rule as everywhere else: accepted rows only, EVDs at the start of
the final suffix with err_raw_fro <= eps. Several CSVs are read as one study;
a later file supersedes an earlier one for any (instance, solver) it contains.

Usage:
  python analyze_per_instance.py out.md file1.csv [file2.csv ...] [--eps 1e-8]
"""
import csv
import sys
from collections import defaultdict

SOLVER_ORDER = ["Newton-SIN-BH", "AGD-SDAJ-BH", "AGD-SDAJ", "SBB-Dual",
                "Dykstra-APM", "Anderson-APM"]


def main():
    args = sys.argv[1:]
    eps = 1e-8
    if "--eps" in args:
        k = args.index("--eps")
        eps = float(args[k + 1])
        del args[k:k + 2]
    outpath = next(a for a in args if a.lower().endswith(".md"))
    files = [a for a in args if a.lower().endswith(".csv")]

    later = defaultdict(set)          # file index -> keys it contains
    for k, p in enumerate(files):
        with open(p) as f:
            later[k] = {(r["instance"], r["solver"]) for r in csv.DictReader(f)}
    acc, last = defaultdict(list), {}
    for k, p in enumerate(files):
        superseded = set().union(*(later[j] for j in range(k + 1, len(files))))
        with open(p) as f:
            for r in csv.DictReader(f):
                key = (r["instance"], r["solver"])
                if key in superseded:
                    continue
                if r["accepted"].strip().lower() == "true":
                    acc[key].append((int(r["evds"]), float(r["err_raw_fro"])))
                last[key] = (int(r["evds"]), float(r["err_raw_fro"]), r["solver_exit"])

    def cost(tr):
        tr = sorted(tr)
        if not tr or tr[-1][1] > eps:
            return None
        k = len(tr) - 1
        while k > 0 and tr[k - 1][1] <= eps:
            k -= 1
        return tr[k][0]

    out = [f"# Per-instance costs, forward target {eps:g}", "",
           "| instance | solver | EVDs to target | total EVDs | final error | exit |",
           "|---|---|---:|---:|---:|---|"]
    for i in sorted({k[0] for k in last}):
        rows = []
        for s in SOLVER_ORDER:
            if (i, s) not in last:
                continue
            c = cost(acc[(i, s)])
            tot, err, ex = last[(i, s)]
            rows.append((c if c is not None else float("inf"), s, c, tot, err, ex))
        for _, s, c, tot, err, ex in sorted(rows):
            out.append(f"| {i} | {s} | {'--' if c is None else c} | {tot} | {err:.2e} | {ex} |")
    text = "\n".join(out) + "\n"
    print(text)
    with open(outpath, "w") as f:
        f.write(text)


if __name__ == "__main__":
    main()
