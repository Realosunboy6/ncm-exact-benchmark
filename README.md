# Exact test problems and a work–accuracy protocol for benchmarking nearest correlation matrix solvers

Reproduction artifact for the manuscript of the same name.

**Author:** Oyeyinka E. Ibrahim, Department of Industrial and Systems Engineering,
Northern Illinois University.

The nearest correlation matrix (NCM) problem is

> minimize ½‖X − G‖²_F subject to X ⪰ 0, diag(X) = e.

This repository contains a family of NCM instances whose primal and dual solutions are
known in closed form, a measurement protocol built on that family, and the code and
results behind every table and figure in the paper.

## What is here

| path | contents |
|---|---|
| `paper/` | Full LaTeX source and the compiled `main.pdf` |
| `code/` | Instance generator, solvers, experiment driver, analysis scripts |
| `data/manifests/` | SHA-256 manifests and screening logs for every instance set |
| `results/` | Raw trajectory and timing data, plus the generated analysis tables |
| `docs/` | Verification record, run reports, literature audit |

Instance binaries are **not** stored here. They are large (1 GB at n=500) and exactly
reproducible from the seeded generator, so the manifests carry SHA-256 hashes instead.
See `data/manifests/README.md`.

## Requirements

- Julia 1.12 or later (`code/Project.toml`, `code/Manifest.toml`)
- Python 3.10 or later with NumPy
- For the real-matrix runs only: the Anymatrix `CORRINV` collection
  (https://github.com/higham/anymatrix), not redistributed here

## Reproducing the results

**1. Generate the instances.** Deterministic given the seeds in the generator:

```bash
cd code
python gen_degeneracy_family.py --n 100 --out degen_instances_paired
python gen_degeneracy_family.py --n 500 --out degen_instances_n500_paired
python materialize_exact_ystars.py degen_instances_paired
```

Check the SHA-256 column of the emitted `manifest.tsv` against
`data/manifests/<set>/manifest.tsv`. They should agree row for row.

**2. Ranking study** (work–accuracy trajectories, one row per eigendecomposition):

```bash
NCM_STANDALONE=1 julia --project=. bench_sbb_dual.jl \
  --suite degen_instances_paired --ranking ranking_kkt270_v2.csv
```

**3. Timing study** (single-threaded BLAS, discarded warm-up, one `@elapsed` per solve):

```bash
julia --project=. bench_sbb_dual.jl --suite degen_instances_paired \
  --tol-mode native  --out timing_kkt270_native.csv
julia --project=. bench_sbb_dual.jl --suite degen_instances_paired \
  --tol-mode matched --matched-tol 1e-11 --out timing_kkt270_matched.csv
```

**4. Analysis** (regenerates the tables in `results/analysis/`):

```bash
python analyze_ranking.py ranking_kkt270_v2.csv ranking_kkt270_v2_analysis.md
python analyze_timing.py timing_kkt270_native.csv timing_kkt270_matched.csv \
                         timing_kkt270_analysis.md
```

`code/run_chain.sh` runs the n=500 and real-matrix stages in sequence. Timing stages must
not overlap any other CPU-heavy job.

**5. Rebuild the paper:**

```bash
cd paper
pdflatex main && bibtex main && pdflatex main && pdflatex main
```

## Solvers compared

| name | method |
|---|---|
| `Newton-SIN-BH` | Semismooth Newton (Qi–Sun) with cached factorization and the Borsdorf–Higham line search |
| `Newton-SIN` | The same with the naive Armijo test, kept as a control |
| `AGD-SDAJ` | Huynh–Hwang (2025), transcribed from the published text |
| `AGD-SDAJ-BH` | The same with our adaptation of the Borsdorf–Higham safeguard |
| `SBB-Dual` | Clamped spectral (Barzilai–Borwein) gradient on the dual |
| `Dykstra-APM` | Alternating projections with Dykstra's correction |

`docs/agd-sdaj-verification-status.md` records the verification of the AGD-SDAJ
reimplementation against the counts published by its authors, before it was used on any
new instance.

## Data notes

- Forward error on the synthetic family is measured against the **exact** solution.
- On the real matrices no exact solution exists; the reference is a high-accuracy
  Newton solve. The `cor1399` reference stopped at its iteration limit with
  ‖∇θ‖₂ = 4.59 × 10⁻¹³; the `cor3120` and `bccd16` references are capped at 30 EVDs
  and reach 1.58 × 10⁻¹² and 8.07 × 10⁻¹³. Those runs are an external check, not
  measurements of the same quality.
  A second, independent reference for each agrees with the first to about 1e-11.
- The equity-based instances (`export_thesis_kkt.py`, `export_thesis_suite.py`) need the
  author's returns panel (550 US-traded equities, Jan 2020 – Jul 2025), which is not redistributed here; the result
  files `results/ranking_thesis*.csv.gz` are included.
- `code/validation/` checks every solver against published solutions and work counts
  (Higham 2002; Higham–Strabić 2016; Borsdorf 2007; Huynh–Hwang 2025). The logs are in
  `results/validation/`. Set `NCM_REAL_SUITE` to the exported real-matrix suite first.
- `results/*.csv.gz` are gzipped. Decompress with `gunzip -k` before running the
  analysis scripts.

## License

Released under the MIT License; see `LICENSE`. This covers the code, the manifests and
the result files in this repository.

Two things it does not cover. The manuscript text and figures under `paper/` remain the
copyright of the author, and any journal agreement signed later takes precedence for
them. The Anymatrix `CORRINV` matrices are not redistributed here and carry their own
terms.

## Citation

A `CITATION.cff` is included. Add the DOI to it once the artifact is archived
(Zenodo mints one automatically from a GitHub release).
