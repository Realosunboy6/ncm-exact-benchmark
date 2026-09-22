"""Does rank or the size of the violation drive SBB-Dual vs AGD-SDAJ-BH?

Synthetic n=500 instances, r in {100,150}, m in {1,20}, rho = delta/mu_bulk in
{1e-3, 0}, 3 paired seeds, at two bulk levels mu_bulk in {0.1, 0.01}. Seeds
(hence X*) are identical across the two bulk levels, so each pair of instances
differs only in the size of W.

Cost rule: accepted rows only, EVDs at the start of the final suffix with
err_raw_fro <= eps (reach and hold). This is the source of the "pilot of 48
instances" paragraph of Sec. 5.10.

Usage: python analyze_confound.py <results_dir> [instances_dir]
  results_dir    holds ranking_confound_mu0.1.csv and ranking_confound_mu0.01.csv
                 (unpacked from results/*.csv.gz by reproduce.sh)
  instances_dir  optional; holds degen_confound_mu0.1/cases.csv and
                 degen_confound_mu0.01/cases.csv (the raw instances, not
                 shipped -- see data/manifests/README.md). Without it, the
                 lambda_min(G) column is omitted; every other number is
                 unaffected, since it comes only from the ranking CSVs.
"""
import csv
import os
import re
import statistics as st
import sys
from collections import defaultdict

import numpy as np

RESULTS_DIR = sys.argv[1] if len(sys.argv) > 1 else "."
INSTANCES_DIR = sys.argv[2] if len(sys.argv) > 2 else None
SUITES = {0.1: "degen_confound_mu0.1", 0.01: "degen_confound_mu0.01"}
SOLVERS = ["Newton-SIN-BH", "AGD-SDAJ-BH", "SBB-Dual"]
EPS = [1e-4, 1e-8, 1e-10]


def costs(path):
    rows = defaultdict(list)
    with open(path) as f:
        for r in csv.DictReader(f):
            if r["accepted"] == "true":
                rows[(r["instance"], r["solver"])].append((int(r["evds"]), float(r["err_raw_fro"])))
    out = {}
    for key, tr in rows.items():
        for eps in EPS:
            if tr[-1][1] > eps:
                out[key + (eps,)] = None
                continue
            k = len(tr) - 1
            while k > 0 and tr[k - 1][1] <= eps:
                k -= 1
            out[key + (eps,)] = tr[k][0]
    return out


def lam_min(suite):
    """Raw instances are not shipped (see data/manifests/README.md); returns
    {} if unavailable, in which case the caller prints 'n/a' instead."""
    if INSTANCES_DIR is None:
        return {}
    path = os.path.join(INSTANCES_DIR, suite, "cases.csv")
    if not os.path.isfile(path):
        return {}
    d = {}
    with open(path) as f:
        for r in csv.DictReader(f):
            d[r["name"]] = float(r["lambda_min_G"])
    return d


have_lm = INSTANCES_DIR is not None
print("median EVDs (reached) | SBB cheaper than AGD-BH / n | median d = SBB - AGD-BH"
      + (" | mean lambda_min(G)" if have_lm else " (lambda_min(G) unavailable: raw instances not shipped)"))
paired = defaultdict(dict)
for mu, suite in SUITES.items():
    c = costs(os.path.join(RESULTS_DIR, f"ranking_confound_mu{mu}.csv"))
    lm = lam_min(suite)
    names = sorted({k[0] for k in c})
    for eps in EPS:
        print(f"\nmu_bulk={mu}  eps={eps:g}")
        groups = defaultdict(list)
        for nm in names:
            r = int(re.search(r"-r(\d+)-", nm).group(1)); m = int(re.search(r"-m(\d+)-", nm).group(1))
            groups[(r, m)].append(nm); groups[(r, "all")].append(nm)
        for key in sorted(groups, key=lambda k: (k[0], str(k[1]))):
            g = groups[key]
            med = []
            for s in SOLVERS:
                v = [c[(nm, s, eps)] for nm in g if c.get((nm, s, eps)) is not None]
                med.append(f"{s.split('-')[0]}={st.median(v):g}({len(v)})" if v else f"{s}=--")
            d = [c[(nm, "SBB-Dual", eps)] - c[(nm, "AGD-SDAJ-BH", eps)] for nm in g
                 if None not in (c.get((nm, "SBB-Dual", eps)), c.get((nm, "AGD-SDAJ-BH", eps)))]
            sb = sum(x < 0 for x in d)
            lam_str = f" | lam_min {np.mean([lm[nm] for nm in g]):.2e}" if lm else ""
            print(f"  r={key[0]} m={key[1]!s:3s} " + " ".join(med) +
                  f" | SBB cheaper {sb}/{len(d)} | median d {st.median(d):+g}" + lam_str)
            if key[1] != "all":
                for nm in g:
                    if (nm, "SBB-Dual", eps) in c:
                        paired[(eps, key)][(mu, nm)] = c[(nm, "SBB-Dual", eps)], c[(nm, "AGD-SDAJ-BH", eps)]

print("\nSame X*, bulk level 0.1 vs 0.01: change in d = SBB - AGD-BH (paired by instance name)")
for (eps, key), v in sorted(paired.items(), key=lambda kv: (kv[0][0], kv[0][1])):
    names = {nm for (_, nm) in v}
    diffs = []
    for nm in names:
        a, b = v.get((0.1, nm)), v.get((0.01, nm))
        if a and b and None not in a + b:
            diffs.append(((a[0] - a[1]), (b[0] - b[1])))
    if diffs:
        print(f"  eps={eps:g} r={key[0]} m={key[1]}: median d at mu=0.1 {st.median(x for x, _ in diffs):+g}, "
              f"at mu=0.01 {st.median(y for _, y in diffs):+g}  (n={len(diffs)})")
