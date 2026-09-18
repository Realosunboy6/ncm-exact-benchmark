# Exact test problems and a work–accuracy protocol for benchmarking NCM solvers

Submission artifact. Everything here is self-contained: the paper source, the
generator, the solvers, the analysis scripts, and every result file behind every
table.

**Author:** Oyeyinka E. Ibrahim, Department of Industrial and Systems
Engineering, Northern Illinois University.

The nearest correlation matrix (NCM) problem is

> minimize ½‖X − G‖²_F subject to X ⪰ 0, diag(X) = e.

## Layout

| path | contents |
|---|---|
| `paper/` | LaTeX source and the compiled `main.pdf` |
| `code/` | generator, solvers, analysis scripts, `validation/` checks |
| `code/reproduce.sh` | regenerates every analysis table from the shipped results |
| `data/canonical_n100/` | 12 ready-made instances with exact solutions (2 MB) |
| `data/manifests/` | SHA-256 manifests and screening logs for every instance set |
| `results/` | raw trajectories (gzipped), analysis tables, validation logs |

## Reproducing the tables without running a solver

```sh
sh code/reproduce.sh python3
```

Reads `results/*.csv.gz`, writes `results/reproduced/`, and prints which file
holds which table. Takes about three minutes. Compare with `results/analysis/`.

## Reproducing the instances

The generator is seeded:

```sh
cd code
python gen_degeneracy_family.py --n 100 --out degen_instances_paired
python gen_degeneracy_family.py --n 500 --out degen_instances_n500_paired
python materialize_exact_ystars.py degen_instances_paired
```

It is not bit-reproducible across machines. It takes a basis for a degenerate
eigenspace from LAPACK (`numpy.linalg.eigh`), and which basis LAPACK returns
depends on the build, so on another machine the regenerated instances have the
same parameters and pass the same screening but are not hash-identical to the
ones used in the paper. The manifests in `data/manifests/` and the screening
logs are the authoritative record of those instances. Instance binaries are not
shipped (1 GB at n=500); `data/canonical_n100/` is a 12-instance subset for
smoke tests.

Each instance is `G_<i>.bin`, `Xstar_<i>.bin`, `ystar_<i>.bin`: `n*n` (or `n`)
float64, little-endian, row-major. `cases.csv` records rank, near-zero
multiplicity, separation, seed and screening diagnostics.

## Rerunning a study

```sh
cd code
NCM_STANDALONE=1 julia --project=. bench_sbb_dual.jl \
  --suite degen_instances_paired --ranking ranking_kkt270_v2.csv
python analyze_ranking.py ranking_kkt270_v2.csv kkt270_analysis.md
```

`--solvers`, `--only`, `--max-evds`, `--sbb-maxit`, `--apm-maxit` and
`--blas-threads` restrict or bound a run; `bench_sbb_dual.jl --help` lists them.

## Requirements

- Julia 1.12 or later (`code/Project.toml`, `code/Manifest.toml`)
- Python 3.10 or later with NumPy (pandas for the equity exporters)
- Only for the literature matrices: the Anymatrix `CORRINV` collection
  (<https://github.com/higham/anymatrix>), not redistributed here

## Validation

`code/validation/` checks every solver against published solutions and work
counts: Higham (2002) 3×3; Higham and Strabić (2016) alternating-projections
iteration counts on ten matrices; Borsdorf (2007) Newton iteration counts on
`cor1399` and `cor3120`; Huynh and Hwang (2025) AGD-SDAJ counts on P7/P8/P9.
Logs are in `results/validation/`. Set `NCM_REAL_SUITE` to an exported
real-matrix suite first.

## Data notes

- Forward error on the synthetic and equity-derived KKT families is measured
  against the **exact** solution.
- On the literature matrices no exact solution exists; the reference is a
  high-accuracy Newton solve. Two independent references agree to 1.3e-11
  (`cor3120`) and 8.1e-12 (`bccd16`).
- The two equity panels (550 and 2105 US-traded stocks) are built from vendor
  price data that may not be redistributed; the exporters, the result files and
  the selection rules are included, the raw prices are not.
- `results/*.csv.gz` are gzipped; `reproduce.sh` unpacks them.

## License

MIT for code, manifests and result files; see `LICENSE`. The manuscript text
and figures under `paper/` remain the copyright of the author. The Anymatrix
`CORRINV` matrices and the equity price data are not redistributed and carry
their own terms.
