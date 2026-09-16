# Instance manifests

The instance matrices themselves are not stored in this repository. They are large and
exactly reproducible, so only their manifests and screening logs are kept here.

| set | instances | n | size if materialized |
|---|---:|---:|---:|
| `degen_instances_paired` | 270 | 100 | ~44 MB |
| `degen_instances_n500_paired` | 270 | 500 | ~1.0 GB |
| `real_suite` | 4 | 94–3250 | ~170 MB |

## Files

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
