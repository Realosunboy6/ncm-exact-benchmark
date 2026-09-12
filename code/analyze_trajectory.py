"""Matched-accuracy analysis: EVDs required to reach a given forward error.

Reads trajectory.csv (one row per EVD per solver per instance) and answers
"how much spectral work did each method need to reach error <= eps?" for a grid
of eps, rather than at whichever point a stopping rule happened to fire.

Two honesty features:

* `first_k` is the first EVD at which error <= eps. Because a Newton step is
  atomic, its cost is quantised: one step can take the error from 1e-2 to
  1e-11, so `first_k` is constant across many decades. That plateau is shown
  explicitly (`plateau` column) rather than hidden, because it is exactly what
  makes a single-eps comparison misleading.
* Forward error need not be monotone. `stays` reports whether the error remains
  <= eps for the rest of the run; a method that dips below and comes back out
  has not really reached that accuracy.

Usage: python analyze_trajectory.py [trajectory.csv]
"""
import csv
import sys
from collections import defaultdict

path = sys.argv[1] if len(sys.argv) > 1 else "trajectory.csv"
rows = list(csv.DictReader(open(path)))

curves = defaultdict(list)  # (instance, solver) -> [(evds, err_raw, err_bh, accepted)]
ns = {}
for r in rows:
    k = (r["instance"], r["solver"])
    accepted = r.get("accepted", "true").strip().lower() == "true"
    curves[k].append((int(r["evds"]), float(r["err_raw_fro"]),
                      float(r["err_bh_fro"]), accepted))
    ns[r["instance"]] = int(r["n"])
for k in curves:
    curves[k].sort()

instances = sorted({i for i, _ in curves}, key=lambda s: (ns[s], s))
SOLVERS = ["SBB-Dual", "Newton-SIN", "Newton-SIN-cached", "Dykstra-APM"]
EPS = [1e-2, 1e-3, 1e-4, 1e-5, 1e-6, 1e-7, 1e-8]


def cost_to(curve, eps, col=1):
    """First accepted iterate at error <= eps and whether accepted iterates stay."""
    for idx, pt in enumerate(curve):
        if pt[3] and pt[col] <= eps:
            accepted_tail = [p for p in curve[idx:] if p[3]]
            stays = all(p[col] <= eps for p in accepted_tail)
            return pt[0], stays
    return None, False


print("# Matched-accuracy comparison: EVDs to reach ||X - X*||_F <= eps\n")
print("Raw iterate (no BH epilogue). Rejected Armijo trials count as EVD work "
      "but never receive accuracy credit. `*` = a later accepted iterate rises "
      "back above eps.\n")

for inst in instances:
    print(f"\n## {inst} (n={ns[inst]})\n")
    finals = {s: [p for p in curves[(inst, s)] if p[3]][-1][1]
              for s in SOLVERS if (inst, s) in curves}
    reach = {s: f"{v:.2e}" for s, v in finals.items()}
    print(f"final error reached: " + ", ".join(f"{s} {v}" for s, v in reach.items()))
    print()
    print("| eps | " + " | ".join(SOLVERS) + " | SBB/Newton-cached |")
    print("|---|" + "---:|" * (len(SOLVERS) + 1))
    for eps in EPS:
        cells, costs = [], {}
        for s in SOLVERS:
            if (inst, s) not in curves:
                cells.append("--"); continue
            k, stays = cost_to(curves[(inst, s)], eps)
            if k is None:
                cells.append("n/r")            # not reached in this run
            else:
                if stays:
                    costs[s] = k
                cells.append(f"{k}{'' if stays else '*'}")
        ref = "Newton-SIN-cached" if "Newton-SIN-cached" in costs else "Newton-SIN"
        if "SBB-Dual" in costs and ref in costs:
            ratio = f"{costs['SBB-Dual']/costs[ref]:.2f}x"
        else:
            ratio = "--"
        print(f"| {eps:.0e} | " + " | ".join(cells) + f" | {ratio} |")

    # plateau: how many decades of eps map to the same Newton cost
    plateau_solver = "Newton-SIN-cached" if (inst, "Newton-SIN-cached") in curves else "Newton-SIN"
    nk = [cost_to(curves[(inst, plateau_solver)], e)[0] for e in EPS] \
        if (inst, plateau_solver) in curves else []
    nk = [x for x in nk if x is not None]
    if nk:
        span = len(nk) - len(set(nk)) + 1
        print(f"\nCached Newton cost takes {len(set(nk))} distinct value(s) across "
              f"{len(nk)} reachable tolerance levels.")

print("\n\n# Summary: SBB/Newton EVD ratio at matched error\n")
print("| instance | n | " + " | ".join(f"{e:.0e}" for e in EPS) + " |")
print("|---|---:|" + "---:|" * len(EPS))
allr = defaultdict(list)
for inst in instances:
    cells = []
    for eps in EPS:
        a, astays = cost_to(curves.get((inst, "SBB-Dual"), []), eps)
        b, bstays = cost_to(curves.get((inst, "Newton-SIN-cached"),
                                       curves.get((inst, "Newton-SIN"), [])), eps)
        if a and b and astays and bstays:
            cells.append(f"{a/b:.2f}"); allr[eps].append(a/b)
        else:
            cells.append("--")
    print(f"| {inst} | {ns[inst]} | " + " | ".join(cells) + " |")
print("\n| eps | median SBB/Newton | range |")
print("|---|---:|---|")
for eps in EPS:
    v = sorted(allr[eps])
    if v:
        med = v[len(v)//2] if len(v) % 2 else 0.5*(v[len(v)//2-1]+v[len(v)//2])
        print(f"| {eps:.0e} | {med:.2f}x | {min(v):.2f}--{max(v):.2f}x |")
