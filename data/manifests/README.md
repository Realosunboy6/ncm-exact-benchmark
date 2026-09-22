# Instance manifests

The instance matrices themselves are not stored in this repository. They are large and
exactly reproducible, so only their manifests and screening logs are kept here.

| set | instances | n | size if materialized |
|---|---:|---:|---:|
| `degen_instances_paired` | 270 | 100 | ~44 MB |
| `degen_instances_n500_paired` | 270 | 500 | ~1.0 GB |
| `real_suite` | 4 | 94–3250 | ~170 MB |
| `degen_highrank_n500` | 135 | 500 | ~0.5 GB |
| `thesis_suite` | 20 | 550 | ~47 MB |
| `thesis_kkt` | 81 | 550 | ~375 MB |
| `us2105_kkt` | 16 | 2105 | ~1.1 GB |

The three equity-derived sets (`thesis_suite`, `thesis_kkt`, `us2105_kkt`) are built
from vendor price data that cannot be redistributed. Their manifests and fingerprints
let a holder of the same data check a rebuilt set with `code/check_instances.py`. The
perturbed equity set at n = 2105 and the bulk-level pilot (`degen_confound_mu*`) are
not manifested here.

## Files

- `fingerprints.tsv` — four numerical invariants of every `G` (Frobenius norm,
  absolute sum, extreme eigenvalues), recorded to full precision. `code/check_instances.py`
  compares a regenerated set with them at a relative tolerance; last-bit rounding passes and
  a rotated eigenbasis fails.
- `manifest.tsv` — one row per instance: index, name, dimension, SHA-256 of the upper
  triangle of `G`. Regenerating the set and comparing this column verifies an exact
  bit-for-bit reproduction.
- `cases.csv` — the full construction record per instance: rank `r`, near-zero
  multiplicity `m`, separation `delta`, seed, pair index, and the screening diagnostics
  (KKT residual, exactness error, `lambda_min(G)`, largest off-diagonal magnitude).
- `seed_screening.csv` — every candidate seed considered, whether its whole
  `(m, delta)` block passed screening, and the reason for any rejection. Rejections are
  recorded, not silently dropped.

## Regenerating

```bash
cd ../../code
python gen_degeneracy_family.py --n 100 --out degen_instances_paired
python gen_degeneracy_family.py --n 500 --out degen_instances_n500_paired
```

The generator draws from NumPy's PCG64 with seeds derived from `n` and the rank, so the
output is deterministic on any platform with the same NumPy version.

## The real matrices

`real_suite` is derived from the Anymatrix `CORRINV` collection
(https://github.com/higham/anymatrix), which is **not** redistributed here. Obtain it
separately, then run `code/export_real_suite.py` to write the binaries this project
reads. `code/export_agd_verify_matrices.jl` does the same for the three matrices used to
verify the AGD-SDAJ reimplementation.
