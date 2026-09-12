# Running the extended experiments on your own laptop

Two experiments, run by you in your own terminal with your own Julia. Everything
happens inside `code/`. Nothing here needs me to be running.

1. **Thesis matrices** — the 550-ticker thesis correlation matrix, perturbed to make it invalid.
2. **Large synthetic sweep** — exact-solution instances up to n = 6000.

Do experiment 1 first: it is small, finishes in hours, and is a good check that the
setup works before committing days of compute to experiment 2.

---

## One-time setup (PowerShell)

```powershell
cd C:\Users\ibrah\Documents\Codex\NCM-research\ncm-exact-benchmark\code
julia --project=. -e "using Pkg; Pkg.instantiate()"
```

**Use `C:\Python314\python.exe`, not `python`.** On this machine `python` points to
the Microsoft Store stub, and `C:\Python314` is the install that has NumPy and pandas.

For every Julia run in the same PowerShell window, set this once:

```powershell
$env:NCM_STANDALONE = "1"
```

**Keep the laptop plugged in with the lid open**, and set Windows Sleep to
"Never" while plugged in. A run that sleeps simply pauses, and an earlier run here lost
five hours that way.

---

## Experiment 1 — thesis matrices (n = 550)

The full-sample correlation matrix of your thesis panel is valid, but only just
(λ_min = 0.019). Each test matrix adds a small random symmetric perturbation to it, which
makes it invalid, and the solvers then repair it. No missing data are involved.

### 1a. Export the matrices

```powershell
$PANEL = "C:\Users\ibrah\Documents\Codex\NCM-research\benchmarks-and-missingness\outputs\thesis-missingness-3type-archived\data\thesis_market_panel"
C:\Python314\python.exe export_thesis_suite.py --panel "$PANEL" --out thesis_suite
```

This writes 4 perturbation sizes × 5 random draws = **20 matrices** (about 50 MB):

| σ | λ_min | negative eigenvalues |
|---:|---:|---:|
| 0.005 | −0.09 | 60 |
| 0.01 | −0.27 | 112 |
| 0.03 | −1.09 | 189 |
| 0.10 | −4.26 | 242 |

At sigma = 0.10 about 60 to 80 of the 302,500 off-diagonal entries exceed 1 and are
clipped back to 1 or -1 (about 0.02 percent); at the smaller sizes none are.

The last line must read **`all matrices are invalid (lambda_min < 0)`**.

### 1b. Run the five solvers

```powershell
julia --project=. bench_sbb_dual.jl --suite thesis_suite `
  --ranking ranking_thesis.csv --ranking-tol 1e-9 `
  --max-evds 3000 --sbb-maxit 3000 --apm-maxit 3000 `
  --ref-sbb-maxit 0 --blas-threads 4
```

No exact solution exists for these matrices, so each first gets a high-accuracy reference
(a few seconds at n = 550). **Expect roughly 1–3 hours** for all 20.

---

## Experiment 2 — large synthetic sweep (up to n = 6000)

### What it costs

The cost is the eigendecomposition, which grows like n³. Measured single-threaded times on
this laptop, and extrapolations from them:

| n | seconds per EVD | disk per instance |
|---:|---:|---:|
| 500 | 0.07 (measured) | 4 MB |
| 1399 | 1.5 (measured) | 31 MB |
| 3250 | 17 (measured) | 170 MB |
| 2000 | ~4 (estimate) | 64 MB |
| 4000 | ~31 (estimate) | 256 MB |
| 6000 | **~106 (estimate)** | **576 MB** |

**Smoke test, n = 1000** (two instances, run from `code/` exactly as below): generation
took 16 s and 31 MB; Newton-SIN-BH needed 5 to 6 EVDs and AGD-SDAJ-BH 126 to 129. The
whole Julia run took 7.6 minutes, but that includes start-up and compilation and ran while
another benchmark was using the CPU, so treat it as an upper bound.

Four BLAS threads cut this by roughly a quarter. Rough work to reach the target at large n:

| solver | EVDs | at n = 6000 |
|---|---:|---|
| Newton-SIN-BH | 5–8 | ~15 min |
| AGD-SDAJ-BH | 100–250 | ~3–6 h |
| SBB-Dual | grows fast with n; will hit any affordable cap | cap × ~80 s |
| Dykstra-APM | grows faster still | cap × ~80 s |

**So at n = 6000, plan on about one instance per night** with three solvers and a cap
of 300, and expect SBB-Dual to stop at the cap. That censoring is a result, not a failure:
it is the scaling the paper reports at n = 500, continued.

### How to run it: in stages, one dimension at a time

Running each dimension separately means an interruption costs at most one stage.

```powershell
# --- n = 2000 : all five solvers are still affordable ---
C:\Python314\python.exe gen_degeneracy_family.py --n 2000 --ranks 20 50 `
  --mult 5 --deltas 1e-6 0 --seeds 2 --max-seed-attempts 20 --out degen_large_n2000
julia --project=. bench_sbb_dual.jl --suite degen_large_n2000 `
  --ranking ranking_large_n2000.csv --blas-threads 4 `
  --max-evds 1500 --sbb-maxit 1500 --apm-maxit 1500

# --- n = 4000 : drop Dykstra-APM, cap the rest ---
C:\Python314\python.exe gen_degeneracy_family.py --n 4000 --ranks 50 `
  --mult 5 --deltas 1e-6 0 --seeds 2 --max-seed-attempts 20 --out degen_large_n4000
julia --project=. bench_sbb_dual.jl --suite degen_large_n4000 `
  --ranking ranking_large_n4000.csv --blas-threads 4 `
  --solvers "Newton-SIN-BH,AGD-SDAJ-BH,SBB-Dual" `
  --max-evds 500 --sbb-maxit 500

# --- n = 6000 : one cell, two seeds, three solvers ---
C:\Python314\python.exe gen_degeneracy_family.py --n 6000 --ranks 50 `
  --mult 5 --deltas 1e-6 --seeds 2 --max-seed-attempts 20 --out degen_large_n6000
julia --project=. bench_sbb_dual.jl --suite degen_large_n6000 `
  --ranking ranking_large_n6000.csv --blas-threads 4 `
  --solvers "Newton-SIN-BH,AGD-SDAJ-BH,SBB-Dual" `
  --max-evds 300 --sbb-maxit 300
```

**To run a single instance** out of a suite, add `--only <instance-name>`; the names are
in `manifest.tsv`. That is also how to finish a suite after an interruption.

Solver names for `--solvers`: `SBB-Dual`, `Newton-SIN-BH`, `AGD-SDAJ`, `AGD-SDAJ-BH`,
`Dykstra-APM`. A misspelt name stops the run immediately with the list of valid names.

### One risk at large n: the rank

At fixed small rank, the largest off-diagonal of X\* approaches 1 as n grows, so small
ranks can fail the |G_ij| ≤ 1 screen. That is why these commands avoid r = 5. If the
generator reports `found only 0 block-valid seeds`, rerun with a larger `--ranks` value
rather than raising `--max-seed-attempts` — each attempt at n = 6000 costs minutes.

---

## Watching a run

Each instance prints `[k/N] name (n=...)`, then one line per solver with its EVD count and
exit reason. `evd_budget` or `max_iter` means the cap was reached: that run is **censored**
and will be reported that way, never as converged.

## When it is done

Leave the `ranking_*.csv` files in `code/` and tell me. I will run `analyze_ranking.py` on
them, check the censoring, and fold the results into the paper.

## Scope note

The thesis panel is used here only as a realistic correlation matrix. Nothing in these
experiments involves missing data or missingness mechanisms; that is the subject of a
separate paper.
