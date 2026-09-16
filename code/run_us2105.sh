#!/usr/bin/env bash
# Solver experiments on the 2,105-stock US equity panel (Sep 2021 - Sep 2026, 1,253 returns).
# The sample correlation matrix is singular (853 zero eigenvalues).
#  A. perturbed matrix: sigma in {0.005, 0.01, 0.03, 0.1}, 2 draws -> 8 matrices, computed reference
#  B. KKT instances seeded by the data: r in {50, 100, 200, 400}, m in {1, 20}, delta = 0,
#     mu_bulk = 0.1 (passes screening at every rank here), 2 kernel rotations -> 16, exact X*
# Four solvers (Dykstra-APM omitted for cost: at n=2105 one EVD takes ~1.8 s and it is the slowest).
set -u
cd "$(dirname "$0")"
PY=/c/Python314/python.exe
PANEL="C:/Users/ibrah/Documents/Codex/NCM-research/data-us-equities/ncm_input"
SOLVERS="Newton-SIN-BH,AGD-SDAJ-BH,AGD-SDAJ,SBB-Dual"
LOG=us2105_run.log
stamp() { echo "$(date) $*" >> "$LOG"; }

stamp "start"
$PY -W ignore export_thesis_suite.py --panel "$PANEL" --out us2105_pert \
    --sigmas 0.005 0.01 0.03 0.1 --reps 2 --seed-base 20260915 >> "$LOG" 2>&1
stamp "exported perturbed suite exit $?"
$PY -W ignore export_thesis_kkt.py --panel "$PANEL" --out us2105_kkt \
    --ranks 50 100 200 400 --mult 1 20 --deltas 0 --reps 2 --mu-bulk 0.1 >> "$LOG" 2>&1
stamp "exported KKT suite exit $?"

NCM_STANDALONE=1 julia --project=. bench_sbb_dual.jl --suite us2105_pert \
    --ranking ranking_us2105_pert.csv --ranking-tol 1e-9 --solvers "$SOLVERS" \
    --max-evds 800 --sbb-maxit 3000 --ref-sbb-maxit 0 --blas-threads 4 >> "$LOG" 2>&1
stamp "perturbed benchmark exit $?"
NCM_STANDALONE=1 julia --project=. bench_sbb_dual.jl --suite us2105_kkt \
    --ranking ranking_us2105_kkt.csv --solvers "$SOLVERS" \
    --max-evds 800 --sbb-maxit 3000 --blas-threads 4 >> "$LOG" 2>&1
stamp "KKT benchmark exit $?"
stamp "ALL DONE"
