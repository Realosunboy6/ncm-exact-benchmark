"""KKT-controlled NCM instances with a KNOWN EXACT solution.

Construction
------------
Pick X* = U U^T with unit-norm rows, so diag(X*) = 1 and rank(X*) = r. Let Q0
span ker(X*) and set W = Q0 Diag(mu) Q0^T >= 0. Then with

    G  = X* - W + Diag(diag W),      y* = -diag(W)

we get G + Diag(y*) = X* - W, and since X* W = 0 the two ranges are orthogonal
complements, so Pi_{S+}(X* - W) = X* exactly and grad theta(y*) = 0. X* is the
exact nearest correlation matrix -- no approximate reference is required.

mu controls the degeneracy exactly. The eigenvalues of C(y*) = X* - W are the
r positive eigenvalues of X* together with {-mu_j}:

    mu_j >> 0   ->  strictly negative eigenvalue   (gamma)
    mu_j = delta ->  near-degenerate as delta -> 0
    mu_j = 0    ->  exact zero eigenvalue          (beta)

so the beta multiplicity equals #{j : mu_j = 0}. mu is laid out as
(1, ..., 1, delta, ..., delta) with `m` copies of delta, keeping the instance
nontrivial while only m directions approach the nonsmooth boundary.

Screening
---------
Emitted instances must satisfy diag(G) = 1, lambda_min(G) < 0, and |G_ij| <= 1,
so they are correlation-like rather than merely symmetric with unit diagonal.
Rejections are counted and reported, never silently dropped.

Writes `degen_instances/`:
    manifest.tsv    idx, name, n, sha256(G upper), r, m, delta, seed
    G_<idx>.bin     n*n float64
    Xstar_<idx>.bin n*n float64   (exact solution)
    cases.csv       full per-instance record including screening diagnostics
"""
import argparse
import csv
import hashlib
import os

import numpy as np

HERE = os.path.dirname(os.path.abspath(__file__))


def build_instance(n, r, m, delta, seed, mu_bulk=0.1):
    rng = np.random.default_rng(seed)
    U = rng.standard_normal((n, r))
    U /= np.linalg.norm(U, axis=1, keepdims=True)          # unit rows -> diag 1
    Xs = 0.5 * ((U @ U.T) + (U @ U.T).T)

    w, V = np.linalg.eigh(Xs)
    thr = 1e-10 * max(1.0, w.max())
    Q0 = V[:, w <= thr]
    if Q0.shape[1] != n - r:
        return None, None, None, f"kernel dim {Q0.shape[1]} != {n-r}"

    k = Q0.shape[1]
    if m > k:
        return None, None, None, f"m={m} exceeds kernel dim {k}"
    # The bulk level is a free parameter: any mu >= 0 gives an exact KKT point,
    # but mu_bulk = 1 makes |G_ij| exceed 1 at low rank (every r=5 case was
    # rejected), so the family would lose its most rank-deficient corner.
    # mu_bulk = 0.1 keeps all ranks correlation-like and still indefinite.
    mu = np.full(k, mu_bulk)
    mu[k - m:] = delta                                      # m near-zero/zero
    W = Q0 @ np.diag(mu) @ Q0.T
    W = 0.5 * (W + W.T)

    G = Xs - W + np.diag(np.diag(W))
    G = 0.5 * (G + G.T)
    ystar = -np.diag(W)
    return G, Xs, ystar, None


def screen(G, Xs, ystar):
    """Returns (ok, reason, diagnostics)."""
    d = np.abs(np.diag(G) - 1.0).max()
    offmax = np.abs(G - np.diag(np.diag(G))).max()
    lam_G = float(np.linalg.eigvalsh(G)[0])
    C = G + np.diag(ystar)
    lam = np.linalg.eigvalsh(0.5 * (C + C.T))
    # Match the Newton implementation's alpha/beta/gamma partition exactly.
    # A looser ad-hoc threshold misclassifies small but strictly negative
    # eigenvalues as beta at larger n.
    tol = 100 * np.finfo(float).eps * max(1.0, np.abs(lam).max())
    nb = int((np.abs(lam) <= tol).sum())
    Xp_lam = np.maximum(lam, 0.0)
    # exactness of the KKT point, recomputed rather than assumed
    w2, P2 = np.linalg.eigh(0.5 * (C + C.T))
    Xproj = (P2 * np.maximum(w2, 0.0)) @ P2.T
    kkt = float(np.linalg.norm(np.diag(Xproj) - 1.0))
    exact = float(np.linalg.norm(Xproj - Xs, "fro"))
    diag = dict(diag_dev=d, offdiag_absmax=offmax, lambda_min_G=lam_G,
                beta_count=nb, kkt_grad_norm=kkt, exactness_fro=exact,
                pos_count=int((lam > tol).sum()),
                neg_count=int((lam < -tol).sum()))
    if d > 1e-10:
        return False, "diag(G) != 1", diag
    if offmax > 1.0 + 1e-12:
        return False, "|G_ij| > 1", diag
    if lam_G >= 0:
        return False, "G already PSD", diag
    if kkt > 1e-9 or exact > 1e-9:
        return False, "KKT check failed", diag
    return True, "", diag


def screen_seed_block(n, r, mult, deltas, seed, mu_bulk):
    """A paired seed is valid only when its entire (m, delta) block is valid."""
    for m in mult:
        for delta in deltas:
            G, Xs, ys, err = build_instance(
                n, r, m, delta, seed, mu_bulk=mu_bulk
            )
            if err:
                return False, m, delta, err
            ok, why, _ = screen(G, Xs, ys)
            if not ok:
                return False, m, delta, why
    return True, None, None, ""


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--n", type=int, default=100)
    ap.add_argument("--ranks", type=int, nargs="+", default=[5, 20, 50])
    ap.add_argument("--mult", type=int, nargs="+", default=[1, 5, 20])
    ap.add_argument("--deltas", type=float, nargs="+",
                    default=[1e-2, 1e-4, 1e-6, 1e-8, 1e-10, 0.0])
    ap.add_argument("--seeds", type=int, default=5)
    ap.add_argument("--max-seed-attempts", type=int, default=10000)
    ap.add_argument("--mu-bulk", type=float, default=0.1)
    ap.add_argument("--out", default=os.path.join(HERE, "degen_instances"))
    a = ap.parse_args()

    os.makedirs(a.out, exist_ok=True)
    rows, man = [], []
    idx = 0
    seed_screening = []
    paired_seeds = {}

    # Pre-screen once per rank, then reuse the same accepted draws over every
    # (m, delta) cell. This makes the separation sweep paired within seed and
    # prevents cell-specific rejection from unbalancing the phase diagram.
    for r in a.ranks:
        accepted = []
        candidate = 0
        while len(accepted) < a.seeds and candidate < a.max_seed_attempts:
            seed = 100000 * a.n + 1000 * r + candidate
            ok, failed_m, failed_delta, reason = screen_seed_block(
                a.n, r, a.mult, a.deltas, seed, a.mu_bulk
            )
            seed_screening.append(dict(
                rank=r, candidate_seed=seed, accepted=ok,
                failed_m="" if failed_m is None else failed_m,
                failed_delta="" if failed_delta is None else failed_delta,
                reason=reason,
            ))
            if ok:
                accepted.append(seed)
            candidate += 1
        if len(accepted) != a.seeds:
            raise RuntimeError(
                f"rank {r}: found only {len(accepted)} block-valid seeds after "
                f"{candidate} attempts"
            )
        paired_seeds[r] = accepted

    for r in a.ranks:
        for m in a.mult:
            for delta in a.deltas:
                for pair_id, seed in enumerate(paired_seeds[r]):
                    G, Xs, ys, err = build_instance(a.n, r, m, delta, seed,
                                                    mu_bulk=a.mu_bulk)
                    if err:
                        raise RuntimeError(
                            f"pre-screened seed failed on rebuild: r={r}, m={m}, "
                            f"delta={delta}, seed={seed}: {err}"
                        )
                    ok, why, dg = screen(G, Xs, ys)
                    if not ok:
                        raise RuntimeError(
                            f"pre-screened seed failed on rebuild: r={r}, m={m}, "
                            f"delta={delta}, seed={seed}: {why}"
                        )
                    name = f"degen-r{r}-m{m}-d{delta:g}-p{pair_id}"
                    G.astype("<f8").tofile(os.path.join(a.out, f"G_{idx}.bin"))
                    Xs.astype("<f8").tofile(os.path.join(a.out, f"Xstar_{idx}.bin"))
                    h = hashlib.sha256(np.ascontiguousarray(
                        G[np.triu_indices(a.n)], dtype="<f8").tobytes()).hexdigest()[:32]
                    man.append(f"{idx}\t{name}\t{a.n}\t{h}")
                    rows.append(dict(idx=idx, name=name, n=a.n, rank=r,
                                     near_zero_mult=m, delta=delta, seed=seed,
                                     pair_id=pair_id,
                                     mu_bulk=a.mu_bulk,
                                     separation=delta / a.mu_bulk,
                                     sha256_G=h, **dg))
                    idx += 1

    with open(os.path.join(a.out, "manifest.tsv"), "w") as f:
        f.write("\n".join(man) + "\n")
    with open(os.path.join(a.out, "cases.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader(); w.writerows(rows)
    with open(os.path.join(a.out, "seed_screening.csv"), "w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(seed_screening[0].keys()))
        w.writeheader(); w.writerows(seed_screening)

    print(f"emitted {len(rows)} instances to {a.out}")
    for r in a.ranks:
        sr = [x for x in seed_screening if x["rank"] == r]
        print(f"rank {r}: accepted {a.seeds}/{len(sr)} candidate seeds "
              f"({a.seeds/len(sr):.1%}); paired seeds={paired_seeds[r]}")
    import collections
    bc = collections.Counter(x["beta_count"] for x in rows)
    print("beta multiplicity distribution:", dict(sorted(bc.items())))
    print(f"worst KKT residual   : {max(x['kkt_grad_norm'] for x in rows):.2e}")
    print(f"worst exactness      : {max(x['exactness_fro'] for x in rows):.2e}")
    print(f"lambda_min(G) range  : {min(x['lambda_min_G'] for x in rows):.3e} .. "
          f"{max(x['lambda_min_G'] for x in rows):.3e}")


if __name__ == "__main__":
    main()
