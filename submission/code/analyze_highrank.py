"""High-rank n=500 study: SBB-Dual vs AGD-SDAJ-BH by rank, with a seed bootstrap.

Cost rule: accepted rows only, EVDs at the start of the final suffix with
err_raw_fro <= eps (reach and hold). Usage: python analyze_highrank.py [csv]
"""
import csv
import random
import re
import statistics as st
import sys
from collections import defaultdict

path = sys.argv[1] if len(sys.argv) > 1 else "ranking_highrank_n500.csv"
rows = defaultdict(list)
with open(path) as f:
    for r in csv.DictReader(f):
        if r["accepted"] == "true":
            rows[(r["instance"], r["solver"])].append((int(r["evds"]), float(r["err_raw_fro"])))


def cost(tr, eps):
    if tr[-1][1] > eps:
        return None
    k = len(tr) - 1
    while k > 0 and tr[k - 1][1] <= eps:
        k -= 1
    return tr[k][0]


inst = sorted({k[0] for k in rows})
ranks = sorted({int(re.search(r"-r(\d+)-", i).group(1)) for i in inst})
random.seed(20260914)
for eps in (1e-4, 1e-6, 1e-8, 1e-10):
    print(f"\neps={eps:g}")
    for r in ranks:
        I = [i for i in inst if f"-r{r}-" in i]
        med = {s: st.median([c for i in I if (c := cost(rows[(i, s)], eps)) is not None])
               for s in ("Newton-SIN-BH", "AGD-SDAJ-BH", "SBB-Dual")}
        d = {i: cost(rows[(i, "SBB-Dual")], eps) - cost(rows[(i, "AGD-SDAJ-BH")], eps) for i in I
             if None not in (cost(rows[(i, "SBB-Dual")], eps), cost(rows[(i, "AGD-SDAJ-BH")], eps))}
        seeds = sorted({re.search(r"-p(\d+)$", i).group(1) for i in I})
        boot = sorted(st.median([v for p in [random.choice(seeds) for _ in seeds]
                                 for i, v in d.items() if i.endswith("-p" + p)]) for _ in range(2000))
        bym = {m: st.median([v for i, v in d.items() if f"-m{m}-" in i]) for m in (1, 5, 20)}
        print(f"  r={r:3d} Newton={med['Newton-SIN-BH']:g} AGD-BH={med['AGD-SDAJ-BH']:g} SBB={med['SBB-Dual']:g}"
              f" | SBB cheaper {sum(v < 0 for v in d.values())}/{len(d)} ties {sum(v == 0 for v in d.values())}"
              f" | median d {st.median(d.values()):+g} 95% [{boot[50]:+g},{boot[1949]:+g}] | by m {bym}")
best = all(cost(rows[(i, "Newton-SIN-BH")], e) is not None and
           all(cost(rows[(i, s)], e) is None or cost(rows[(i, "Newton-SIN-BH")], e) < cost(rows[(i, s)], e)
               for s in ("AGD-SDAJ-BH", "SBB-Dual"))
           for i in inst for e in (1e-4, 1e-6, 1e-8, 1e-10))
print(f"\nNewton-SIN-BH strictly cheapest on every instance and target: {best} ({len(inst)} instances)")
