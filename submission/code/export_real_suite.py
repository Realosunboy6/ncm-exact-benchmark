"""Export the CORRINV real matrices to a --suite directory (manifest.tsv + G_<idx>.bin).

Needed because Julia's MAT.jl cannot load on this machine (HDF5_jll DLL blocked by an
Application Control policy, 2026-09-11). Reproduces bench_sbb_dual.jl::load_higham_matrix
exactly: packed unit-triangular `x` filled column by column into the strict upper triangle
(treshape(x,1)), then A + triu(A,1)'; full `A` is symmetrised as (A + A')/2.
No Xstar files are written: these matrices have no exact solution.
"""
import hashlib
import os
import sys

import numpy as np
import scipy.io as sio

SRC = r"C:\Users\ibrah\Documents\Codex\NCM-research\benchmarks-and-missingness\work\p7-p8-sbb\source-matrices"
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "real_suite")
NAMES = ["Rocky_Mountain_Region_CORR", "cor1399", "bccd16", "cor3120"]


def load(path):
    v = sio.loadmat(path)
    if "x" not in v:
        A = np.asarray(v["A"], dtype=float)
        return 0.5 * (A + A.T)
    x = np.asarray(v["x"], dtype=float).ravel()
    m = x.size
    n = int(round((1 + np.sqrt(1 + 8 * m)) / 2))
    assert n * (n - 1) // 2 == m
    A = np.eye(n)
    off = 0
    for col in range(1, n):
        A[:col, col] = x[off:off + col]
        off += col
    assert off == m
    A += np.triu(A, 1).T
    return A


os.makedirs(OUT, exist_ok=True)
man = []
for idx, nm in enumerate(NAMES):
    G = load(os.path.join(SRC, nm + ".mat"))
    n = G.shape[0]
    # Julia reads column-major; G is symmetric so byte order of the layout is moot,
    # but write Fortran order to be exact.
    np.asfortranarray(G).astype("<f8").ravel(order="F").tofile(os.path.join(OUT, f"G_{idx}.bin"))
    h = hashlib.sha256(np.ascontiguousarray(G[np.triu_indices(n)], dtype="<f8").tobytes()).hexdigest()[:32]
    man.append(f"{idx}\t{nm}\t{n}\t{h}")
    lam = np.linalg.eigvalsh(G)
    print(f"{nm}: n={n} diagdev={np.abs(np.diag(G)-1).max():.2e} "
          f"offmax={np.abs(G-np.diag(np.diag(G))).max():.4f} lam_min={lam[0]:.4e} "
          f"#neg={int((lam<0).sum())}", flush=True)
with open(os.path.join(OUT, "manifest.tsv"), "w") as f:
    f.write("\n".join(man) + "\n")
print("wrote", OUT)
