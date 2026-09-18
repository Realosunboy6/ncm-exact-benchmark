"""Check a regenerated instance set against the instances used in the paper.

The SHA-256 hashes in data/manifests/ are taken on exact bits, and regenerating
a set reproduces the paper's instances only up to rounding: on the machine that
produced them the regenerated G differ in the last bit (relative difference
below 1e-17) and X* is bit-identical, but every hash fails. On a different
LAPACK build the risk is larger, because the generator takes a basis for a
degenerate eigenspace from numpy.linalg.eigh, and a build may return that
subspace in a rotated basis, which gives a genuinely different G.

This script therefore compares numerical fingerprints instead of hashes: four
invariants of each G, recorded from the original instances to full precision
and compared at a relative tolerance. Last-bit rounding passes; a rotated
basis moves the invariants at order one and fails.

Usage:
  python check_instances.py record <suite_dir> <fingerprints.tsv>
  python check_instances.py check  <suite_dir> <fingerprints.tsv> [--rtol 1e-10]
"""
import csv
import sys

import numpy as np


def fingerprint(G):
    """Four invariants of G that a rotation of the kernel basis would change."""
    ev = np.linalg.eigvalsh(G)
    return (np.linalg.norm(G), float(np.abs(G).sum()), float(ev[0]), float(ev[-1]))


def suite(d):
    with open(f"{d}/manifest.tsv") as f:
        for row in csv.reader(f, delimiter="\t"):
            idx, name, n = row[0], row[1], int(row[2])
            G = np.fromfile(f"{d}/G_{idx}.bin", dtype="<f8").reshape(n, n)
            yield name, n, G


def record(d, out):
    with open(out, "w", newline="\n") as f:
        f.write("name\tn\tfro\tabs_sum\tlambda_min\tlambda_max\n")
        for name, n, G in suite(d):
            f.write(f"{name}\t{n}\t" + "\t".join(f"{v:.17g}" for v in fingerprint(G)) + "\n")
    print(f"recorded fingerprints to {out}")


def check(d, ref, rtol):
    want = {}
    with open(ref) as f:
        for row in csv.DictReader(f, delimiter="\t"):
            want[row["name"]] = tuple(float(row[k]) for k in ("fro", "abs_sum", "lambda_min", "lambda_max"))
    ok = bad = 0
    worst = 0.0
    for name, _, G in suite(d):
        if name not in want:
            print(f"  {name}: not in the reference set")
            bad += 1
            continue
        got = fingerprint(G)
        rel = max(abs(g - w) / max(abs(w), 1e-300) for g, w in zip(got, want[name]))
        worst = max(worst, rel)
        if rel <= rtol:
            ok += 1
        else:
            bad += 1
            print(f"  {name}: MISMATCH, largest relative difference {rel:.2e}")
    print(f"{ok} match, {bad} differ (rtol {rtol:g}); largest relative difference {worst:.2e}")
    return bad == 0


if __name__ == "__main__":
    mode, d, ref = sys.argv[1], sys.argv[2], sys.argv[3]
    rtol = float(sys.argv[sys.argv.index("--rtol") + 1]) if "--rtol" in sys.argv else 1e-10
    if mode == "record":
        record(d, ref)
    else:
        sys.exit(0 if check(d, ref, rtol) else 1)
