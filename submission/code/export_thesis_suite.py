"""Export perturbed thesis correlation matrices as NCM test problems.

Source: the 550-ticker thesis equity panel (1397 daily log returns, no missing
values). Its full-sample correlation matrix C is a valid correlation matrix,
but only just: lambda_min(C) is about 0.019.

Each test matrix is

    G = clip(C + sigma * E, -1, 1),   diag(G) = 1,

where E is a symmetric matrix with independent standard-normal entries above the
diagonal and zero diagonal. This makes G an invalid correlation matrix in a way
that involves no missing data and no model of how data go missing; it follows
the construction of test problem P12 in Huynh and Hwang (2025), a sample
correlation matrix plus a small symmetric perturbation.

Calibration on this panel (one draw per sigma):

    sigma    lambda_min(G)   negative eigenvalues
    0.005        -0.09               60
    0.01         -0.27              112
    0.03         -1.09              189
    0.10         -4.26              242

At sigma = 0.10 about 28 to 40 of the 150,975 off-diagonal pairs exceed 1 in
magnitude and are clipped, about 0.02 percent; at the smaller sizes none are.

No exact solution exists for these matrices; the benchmark harness computes a
high-accuracy reference for each, as it does for the other real matrices.

Output (the format bench_sbb_dual.jl --suite reads):
    <out>/manifest.tsv   index, name, n, SHA-256 of the upper triangle of G
    <out>/G_<index>.bin  n*n float64
    <out>/cases.csv      sigma, seed and spectral diagnostics

Usage:
    python export_thesis_suite.py --panel <thesis_market_panel dir> --out thesis_suite
"""
import argparse
import csv
import hashlib
import os

import numpy as np
import pandas as pd


def upper_sha(g):
    n = g.shape[0]
    tri = np.ascontiguousarray(g[np.triu_indices(n)], dtype="<f8")
    return hashlib.sha256(tri.tobytes()).hexdigest()[:32]


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--panel", required=True,
                    help="directory holding returns_clean.csv")
    ap.add_argument("--out", default="thesis_suite")
    ap.add_argument("--sigmas", type=float, nargs="+",
                    default=[0.005, 0.01, 0.03, 0.10])
    ap.add_argument("--reps", type=int, default=5,
                    help="independent perturbations per sigma")
    ap.add_argument("--seed-base", type=int, default=20260912)
    a = ap.parse_args()

    returns = pd.read_csv(os.path.join(a.panel, "returns_clean.csv"),
                          index_col=0, parse_dates=True)
    X = returns.to_numpy(dtype=float)
    if np.isnan(X).any():
        raise SystemExit("the panel has missing values; this exporter expects a complete panel")
    C = np.corrcoef(X, rowvar=False)
    C = 0.5 * (C + C.T)
    np.fill_diagonal(C, 1.0)
    n = C.shape[0]
    lam_c = float(np.linalg.eigvalsh(C)[0])
    print(f"panel: {X.shape[0]} dates x {n} assets; lambda_min(C) = {lam_c:+.4f}")

    os.makedirs(a.out, exist_ok=True)
    manifest, cases = [], []
    idx = 0
    for si, sigma in enumerate(a.sigmas):
        for rep in range(a.reps):
            seed = a.seed_base + 1000 * si + rep
            rng = np.random.default_rng(seed)
            E = rng.standard_normal((n, n))
            E = (E + E.T) / np.sqrt(2.0)
            np.fill_diagonal(E, 0.0)
            G = C + sigma * E
            clipped = int(np.count_nonzero(np.abs(G[np.triu_indices(n, 1)]) > 1.0))  # pairs
            G = np.clip(G, -1.0, 1.0)
            np.fill_diagonal(G, 1.0)
            ev = np.linalg.eigvalsh(G)
            name = f"thesis-s{sigma:g}-r{rep}"
            G.astype("<f8").tofile(os.path.join(a.out, f"G_{idx}.bin"))
            manifest.append(f"{idx}\t{name}\t{n}\t{upper_sha(G)}")
            cases.append(dict(idx=idx, name=name, n=n, sigma=sigma, replicate=rep,
                              seed=seed, lambda_min_C=lam_c,
                              lambda_min_G=float(ev[0]),
                              negative_eigenvalues=int((ev < 0).sum()),
                              clipped_entries=clipped,
                              perturbation_fro=float(np.linalg.norm(G - C))))
            print(f"  {name:22s} lambda_min={ev[0]:+.4f}  negative={int((ev < 0).sum()):3d}  "
                  f"clipped={clipped}")
            idx += 1

    with open(os.path.join(a.out, "manifest.tsv"), "w") as f:
        f.write("\n".join(manifest) + "\n")
    with open(os.path.join(a.out, "cases.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(cases[0].keys()))
        w.writeheader()
        w.writerows(cases)
    bad = [c["name"] for c in cases if c["lambda_min_G"] >= 0]
    print(f"wrote {len(cases)} matrices to {a.out}")
    print("all matrices are invalid (lambda_min < 0)" if not bad
          else f"WARNING: still valid, raise sigma: {bad}")


if __name__ == "__main__":
    main()
