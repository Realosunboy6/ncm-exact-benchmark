"""KKT instances with an EXACT solution built from the thesis correlation matrix.

The thesis correlation matrix C (550 tickers, 1397 daily returns) is valid and
full rank (lambda_min about 0.019), so it has no kernel and cannot itself be the
solution of a nontrivial KKT instance. Instead we use its rank-r factor model:

    C ~ V_r Lambda_r V_r^T,   U = V_r Lambda_r^{1/2},   rows of U scaled to unit norm,
    X* = U U^T.

X* is a valid correlation matrix of rank exactly r whose eigenvectors come from
the market data. From here the construction is that of gen_degeneracy_family.py:

    W = Q0 Diag(mu) Q0^T,   G = X* - W + Diag(diag W),   y* = -diag(W),

with Q0 spanning ker(X*), so X* is the exact nearest correlation matrix to G.
X* is deterministic for each r; replicates differ only in a random rotation of
the kernel basis Q0, which decides which kernel directions receive the
near-zero values delta. Screening (unit diagonal, |G_ij| <= 1, G indefinite,
KKT exactness) is the same function the synthetic family uses, and rejected
rotations are counted, never silently dropped.

Defaults differ from the synthetic family for a measured reason. On this panel a
rank-5 factor model misses 95 percent of the off-diagonal correlation and drives
some pairs to |X*_ij| = 0.99995, so every r = 5 instance fails |G_ij| <= 1; ranks
are therefore 20, 50, 100 (off-diagonal relative fit 0.59, 0.39, 0.24). With
mu_bulk = 0.1 every rank fails the same screen; mu_bulk = 0.01 passes. The deltas
1e-5 and 1e-9 keep the separation rho = delta / mu_bulk at 1e-3 and 1e-7, on the
synthetic family's grid.

No missing data are involved.

Output (bench_sbb_dual.jl --suite reads G and the exact X* automatically):
    <out>/manifest.tsv, G_<idx>.bin, Xstar_<idx>.bin, cases.csv, seed_screening.csv

Usage:
    python export_thesis_kkt.py --panel <thesis_market_panel dir> --out thesis_kkt
"""
import argparse
import csv
import hashlib
import os

import numpy as np
import pandas as pd

from gen_degeneracy_family import screen


def factor_xstar(C, r):
    w, V = np.linalg.eigh(C)
    top = np.argsort(w)[::-1][:r]
    U = V[:, top] * np.sqrt(w[top])
    U /= np.linalg.norm(U, axis=1, keepdims=True)
    Xs = U @ U.T
    return 0.5 * (Xs + Xs.T)


def build(Xs, r, m, delta, rot_seed, mu_bulk):
    n = Xs.shape[0]
    w, V = np.linalg.eigh(Xs)
    Q0 = V[:, w <= 1e-10 * max(1.0, w.max())]
    k = Q0.shape[1]
    if k != n - r:
        return None, None, f"kernel dim {k} != {n - r}"
    Z = np.random.default_rng(rot_seed).standard_normal((k, k))
    Qr, R = np.linalg.qr(Z)
    Q0 = Q0 @ (Qr * np.sign(np.diag(R)))          # Haar-random basis of ker(X*)
    mu = np.full(k, mu_bulk)
    mu[k - m:] = delta
    W = (Q0 * mu) @ Q0.T
    W = 0.5 * (W + W.T)
    G = Xs - W + np.diag(np.diag(W))
    return 0.5 * (G + G.T), -np.diag(W), None


def main():
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--panel", required=True, help="directory holding returns_clean.csv")
    ap.add_argument("--out", default="thesis_kkt")
    ap.add_argument("--ranks", type=int, nargs="+", default=[20, 50, 100])
    ap.add_argument("--mult", type=int, nargs="+", default=[1, 5, 20])
    ap.add_argument("--deltas", type=float, nargs="+", default=[1e-5, 1e-9, 0.0])
    ap.add_argument("--reps", type=int, default=3, help="kernel rotations per rank")
    ap.add_argument("--mu-bulk", type=float, default=0.01)
    ap.add_argument("--max-attempts", type=int, default=50)
    a = ap.parse_args()

    X = pd.read_csv(os.path.join(a.panel, "returns_clean.csv"),
                    index_col=0, parse_dates=True).to_numpy(dtype=float)
    if np.isnan(X).any():
        raise SystemExit("the panel has missing values; this exporter expects a complete panel")
    C = np.corrcoef(X, rowvar=False)
    C = 0.5 * (C + C.T)
    np.fill_diagonal(C, 1.0)
    n = C.shape[0]
    print(f"panel: {X.shape[0]} dates x {n} assets; lambda_min(C) = {np.linalg.eigvalsh(C)[0]:+.4f}")

    os.makedirs(a.out, exist_ok=True)
    man, rows, screening = [], [], []
    idx = 0
    for r in a.ranks:
        Xs = factor_xstar(C, r)
        off = ~np.eye(n, dtype=bool)
        fit = np.linalg.norm((Xs - C)[off]) / np.linalg.norm(C[off])
        print(f"rank {r}: off-diagonal ||X* - C||_F / ||C||_F = {fit:.3f}, max offdiag |X*| = "
              f"{np.abs(Xs - np.eye(n)).max():.4f}")
        accepted, attempt = [], 0
        while len(accepted) < a.reps and attempt < a.max_attempts:
            seed = 20260913 + 1000 * r + attempt
            ok, why = True, ""
            for m in a.mult:
                for delta in a.deltas:
                    G, ys, err = build(Xs, r, m, delta, seed, a.mu_bulk)
                    if err:
                        ok, why = False, err
                    else:
                        good, why, _ = screen(G, Xs, ys)
                        ok = good
                    if not ok:
                        break
                if not ok:
                    break
            screening.append(dict(rank=r, rotation_seed=seed, accepted=ok, reason=why))
            if ok:
                accepted.append(seed)
            attempt += 1
        if len(accepted) < a.reps:
            raise SystemExit(f"rank {r}: only {len(accepted)} valid rotations in "
                             f"{attempt} attempts; try a smaller --mu-bulk")
        for m in a.mult:
            for delta in a.deltas:
                for rep, seed in enumerate(accepted):
                    G, ys, _ = build(Xs, r, m, delta, seed, a.mu_bulk)
                    _, _, dg = screen(G, Xs, ys)
                    name = f"thesiskkt-r{r}-m{m}-d{delta:g}-p{rep}"
                    G.astype("<f8").tofile(os.path.join(a.out, f"G_{idx}.bin"))
                    Xs.astype("<f8").tofile(os.path.join(a.out, f"Xstar_{idx}.bin"))
                    h = hashlib.sha256(np.ascontiguousarray(
                        G[np.triu_indices(n)], dtype="<f8").tobytes()).hexdigest()[:32]
                    man.append(f"{idx}\t{name}\t{n}\t{h}")
                    rows.append(dict(idx=idx, name=name, n=n, rank=r, near_zero_mult=m,
                                     delta=delta, rotation_seed=seed, pair_id=rep,
                                     mu_bulk=a.mu_bulk, factor_fit_rel=fit,
                                     sha256_G=h, **dg))
                    idx += 1

    with open(os.path.join(a.out, "manifest.tsv"), "w") as f:
        f.write("\n".join(man) + "\n")
    for fname, data in (("cases.csv", rows), ("seed_screening.csv", screening)):
        with open(os.path.join(a.out, fname), "w", newline="") as f:
            w = csv.DictWriter(f, fieldnames=list(data[0].keys()))
            w.writeheader()
            w.writerows(data)
    print(f"wrote {len(rows)} instances to {a.out}")
    print(f"worst KKT residual : {max(x['kkt_grad_norm'] for x in rows):.2e}")
    print(f"worst exactness    : {max(x['exactness_fro'] for x in rows):.2e}")
    print(f"lambda_min(G) range: {min(x['lambda_min_G'] for x in rows):.3e} .. "
          f"{max(x['lambda_min_G'] for x in rows):.3e}")
    print(f"max |G_ij| (offdiag): {max(x['offdiag_absmax'] for x in rows):.5f}")


if __name__ == "__main__":
    main()
