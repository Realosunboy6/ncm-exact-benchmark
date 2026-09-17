"""US equity panel at n=2105: solver costs by rank (KKT, exact X*) and by sigma (perturbed).

Cost rule: accepted rows only, EVDs at the start of the final suffix with
err_raw_fro <= eps (reach and hold). Usage: python analyze_us2105.py
"""
import csv
import re
import statistics as st
import sys
from collections import defaultdict

SOLVERS = ["Newton-SIN-BH", "AGD-SDAJ-BH", "AGD-SDAJ", "SBB-Dual", "Dykstra-APM", "Anderson-APM"]


def load(paths):
    """Later files supersede earlier ones for the instances they contain."""
    later = set()
    for p in paths[1:]:
        later |= {(r["instance"], r["solver"]) for r in csv.DictReader(open(p))}
    rows = defaultdict(list)
    for k, p in enumerate(paths):
        for r in csv.DictReader(open(p)):
            if k == 0 and (r["instance"], r["solver"]) in later:
                continue
            if r["accepted"] == "true":
                rows[(r["instance"], r["solver"])].append((int(r["evds"]), float(r["err_raw_fro"])))
    return rows


def cost(tr, eps):
    if not tr or tr[-1][1] > eps:
        return None
    k = len(tr) - 1
    while k > 0 and tr[k - 1][1] <= eps:
        k -= 1
    return tr[k][0]


def table(rows, key_of, keys, label):
    inst = sorted({k[0] for k in rows})
    for eps in (1e-4, 1e-6, 1e-8, 1e-10):
        print(f"\n{label}, eps={eps:g}: median EVDs (reached/total); SBB-Dual vs AGD-SDAJ-BH")
        for key in keys:
            I = [i for i in inst if key_of(i) == key]
            if not I:
                continue
            cells = []
            for s in SOLVERS:
                v = [c for i in I if (c := cost(rows[(i, s)], eps)) is not None]
                cells.append(f"{s}={st.median(v):g}({len(v)}/{len(I)})" if v else f"{s}=--")
            d = [cost(rows[(i, "SBB-Dual")], eps) - cost(rows[(i, "AGD-SDAJ-BH")], eps) for i in I
                 if None not in (cost(rows[(i, "SBB-Dual")], eps), cost(rows[(i, "AGD-SDAJ-BH")], eps))]
            extra = f" | SBB cheaper {sum(x < 0 for x in d)}/{len(d)}, median diff {st.median(d):+g}" if d else ""
            print(f"  {key!s:>6}  " + "  ".join(cells) + extra)
    print("\nexit reasons at the cap (evd_budget / max_iter):")
    for i in inst:
        for s in SOLVERS:
            tr = rows[(i, s)]
            if tr and tr[-1][1] > 1e-9:
                print(f"  {i} {s}: {tr[-1][0]} EVDs, final error {tr[-1][1]:.2e}")


if __name__ == "__main__":
    # optional: directory holding ranking_us2105_*.csv (default: current directory)
    d = sys.argv[1] if len(sys.argv) > 1 else "."
    kkt = load([f"{d}/ranking_us2105_kkt.csv", f"{d}/ranking_us2105_kkt_part2.csv",
                f"{d}/ranking_us2105_dykstra.csv", f"{d}/ranking_us2105_anderson.csv"])
    table(kkt, lambda i: int(re.search(r"-r(\d+)-", i).group(1)), [50, 100, 200, 400], "KKT instances (exact X*)")
    pert = load([f"{d}/ranking_us2105_pert.csv"])
    table(pert, lambda i: re.search(r"-s([\d.]+)-", i).group(1), ["0.005", "0.01", "0.03", "0.1"],
          "perturbed matrix (computed reference)")
