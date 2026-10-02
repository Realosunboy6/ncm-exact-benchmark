#!/usr/bin/env python3
"""First-dip vs reach-and-hold sensitivity for the NCM ranking study.

Reads one or more ranking-study trajectory CSVs (one row per EVD per solver
per instance; several CSVs are read as one study, so e.g. the Anderson-APM
file joins the tables of the run it extends) and recomputes the forward-error
median-cost orderings under two reach definitions, accepted-only:

  hold: the paper's rule (analyze_ranking.py cost_to_fixed) -- EVDs at the
        first accepted iterate from which the target holds to the end of the
        run (None if the final accepted iterate is above target).
  dip:  EVDs at the first accepted iterate with forward error <= target
        (None if never reached).

Curve format matches analyze_ranking.py: (evds, err_raw_fro, grad_2, accepted).

Usage: python first_dip_check.py results/ranking_kkt270_v2.csv.gz \
           results/ranking_kkt270_anderson.csv.gz
"""
import csv
import gzip
import statistics
import sys
from collections import defaultdict

FWD_EPS = [1e-2, 1e-4, 1e-6, 1e-8, 1e-10]
SOLVER_ORDER = ["Newton-SIN-BH", "AGD-SDAJ-BH", "AGD-SDAJ", "SBB-Dual",
                "Dykstra-APM", "Anderson-APM"]


def load(paths):
    curves = defaultdict(list)
    ns = {}
    for path in paths:
        opener = gzip.open if path.endswith(".gz") else open
        with opener(path, "rt") as f:
            for r in csv.DictReader(f):
                key = (r["instance"], r["solver"])
                curves[key].append((
                    int(r["evds"]),
                    float(r["err_raw_fro"]),
                    float(r["grad_2"]),
                    r["accepted"].strip().lower() == "true",
                ))
                ns[r["instance"]] = int(r["n"])
    return curves, ns


def cost_hold(curve, target, col=1):
    """Accepted-only EVDs at the first accepted iterate from which the target
    holds to the end of the run (paper's rule)."""
    acc = [p for p in curve if p[3]]
    if not acc or acc[-1][col] > target:
        return None
    k = len(acc) - 1
    while k > 0 and acc[k - 1][col] <= target:
        k -= 1
    return acc[k][0]


def cost_dip(curve, target, col=1):
    """Accepted-only EVDs at the first accepted iterate at or below target."""
    for p in curve:
        if p[3] and p[col] <= target:
            return p[0]
    return None


def ordering(costs):
    have = {s: c for s, c in costs.items() if c is not None}
    return [s for s, _ in sorted(have.items(), key=lambda kv: kv[1])]


def main():
    paths = sys.argv[1:]
    if not paths:
        sys.exit("usage: first_dip_check.py <csv[.gz] ...>")
    curves, ns = load(paths)
    instances = sorted({i for i, _ in curves})
    solvers = [s for s in SOLVER_ORDER if any((i, s) in curves for i in instances)]
    print(f"instances: {len(instances)} (n={ns[instances[0]]}), "
          f"solvers: {', '.join(solvers)}")
    for eps in FWD_EPS:
        med_hold, med_dip = {}, {}
        status_diff = cost_diff = 0
        for s in solvers:
            ch, cd = [], []
            for i in instances:
                if (i, s) not in curves:
                    continue
                h = cost_hold(curves[(i, s)], eps)
                d = cost_dip(curves[(i, s)], eps)
                if (h is None) != (d is None):
                    status_diff += 1
                if h is not None and d is not None and h != d:
                    cost_diff += 1
                if h is not None:
                    ch.append(h)
                if d is not None:
                    cd.append(d)
            med_hold[s] = statistics.median(ch) if ch else None
            med_dip[s] = statistics.median(cd) if cd else None
        oh, od = ordering(med_hold), ordering(med_dip)
        print(f"\neps = {eps:g}")
        print("  hold: " + " < ".join(f"{s} {med_hold[s]}" for s in oh))
        print("  dip:  " + " < ".join(f"{s} {med_dip[s]}" for s in od))
        print(f"  ordering identical: {oh == od}; "
              f"changed reached-status: {status_diff}, changed cost: {cost_diff}")


if __name__ == "__main__":
    main()
