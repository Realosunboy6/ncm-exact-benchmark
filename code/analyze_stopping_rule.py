"""Section 6: the dimension-scaled stopping rule, compared across dimensions on
the same instances.

Reads the native-rule timing runs at n=100 and n=500. The n=500 run covers a
subset of 18 instances, each with a counterpart at n=100 under the same label,
so accuracy at the two sizes is compared instance by instance. Reports, per
solver: the paired ratio of forward error at n=500 to that at n=100 (median and
range), the ratio of medians over the matched set and over all instances, and
the exit margin ||grad theta||_2 / threshold; and the spread across solvers of
the median forward error at each size.

Usage: python analyze_stopping_rule.py timing_kkt270_native.csv timing_n500_native.csv
"""
import csv
import statistics as st
import sys


def load(p):
    with open(p) as f:
        return {(r["instance"], r["solver"]): (float(r["err_vs_ref_fro"]),
                                               float(r["certificate_2"]),
                                               float(r["tol_value"]))
                for r in csv.DictReader(f)}


def main():
    a, b = load(sys.argv[1]), load(sys.argv[2])
    common = sorted({i for i, _ in b} & {i for i, _ in a})
    all100 = sorted({i for i, _ in a})
    solvers = sorted({s for _, s in b})
    print(f"instances: n=100 {len(all100)}, n=500 {len({i for i, _ in b})}, common {len(common)}\n")
    print("| solver | paired median ratio | range | ratio of medians, matched | ratio of medians, all n=100 | exit margin n=100 (matched) | exit margin n=500 |")
    print("|---|---:|---|---:|---:|---:|---:|")
    for s in solvers:
        r = sorted(b[(i, s)][0] / a[(i, s)][0] for i in common)
        m100 = st.median(a[(i, s)][0] for i in common)
        m500 = st.median(b[(i, s)][0] for i in common)
        mall = st.median(a[(i, s)][0] for i in all100)
        g100 = st.median(a[(i, s)][1] / a[(i, s)][2] for i in common)
        g500 = st.median(b[(i, s)][1] / b[(i, s)][2] for i in common)
        print(f"| {s} | {st.median(r):.4g} | [{r[0]:.3g}, {r[-1]:.3g}] | {m500 / m100:.4g} | "
              f"{m500 / mall:.4g} | {g100:.3g} | {g500:.3g} |")
    print()
    for lab, d, I in (("n=100, all", a, all100), ("n=100, matched", a, common), ("n=500", b, common)):
        med = {s: st.median(d[(i, s)][0] for i in I) for s in solvers}
        lo, hi = min(med, key=med.get), max(med, key=med.get)
        print(f"spread across solvers, {lab}: {med[hi] / med[lo]:.4g} "
              f"({lo} {med[lo]:.3g} to {hi} {med[hi]:.3g})")


if __name__ == "__main__":
    main()
