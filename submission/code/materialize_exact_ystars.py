"""Materialize exact y* vectors for the existing paired degeneracy suite.

No solver is run. Each case is rebuilt from its registered design parameters,
and G and X* must match the stored binaries bit-for-bit before y* is written.

Usage: python materialize_exact_ystars.py [suite directory]
       (default: degen_instances_paired next to this script)
"""

import sys
from pathlib import Path

import numpy as np
import pandas as pd

from gen_degeneracy_family import build_instance


HERE = Path(__file__).resolve().parent
SUITE = Path(sys.argv[1]) if len(sys.argv) > 1 else HERE / "degen_instances_paired"


def main() -> None:
    cases = pd.read_csv(SUITE / "cases.csv")
    written = 0
    for row in cases.itertuples(index=False):
        g, xstar, ystar, err = build_instance(
            int(row.n),
            int(row.rank),
            int(row.near_zero_mult),
            float(row.delta),
            int(row.seed),
            mu_bulk=float(row.mu_bulk),
        )
        if err:
            raise RuntimeError(f"{row.name}: {err}")
        stored_g = np.fromfile(SUITE / f"G_{int(row.idx)}.bin", dtype="<f8")
        stored_x = np.fromfile(
            SUITE / f"Xstar_{int(row.idx)}.bin", dtype="<f8"
        )
        if not np.array_equal(stored_g, np.asarray(g, dtype="<f8").ravel()):
            raise RuntimeError(f"{row.name}: regenerated G is not bit-identical")
        if not np.array_equal(
            stored_x, np.asarray(xstar, dtype="<f8").ravel()
        ):
            raise RuntimeError(
                f"{row.name}: regenerated Xstar is not bit-identical"
            )
        np.asarray(ystar, dtype="<f8").tofile(
            SUITE / f"ystar_{int(row.idx)}.bin"
        )
        written += 1
    print(f"verified and wrote {written} exact ystar vectors")


if __name__ == "__main__":
    main()
