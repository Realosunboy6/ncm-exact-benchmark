#!/bin/sh
# Anderson-APM on the two test sets it has not yet seen: the perturbed n=550
# equity matrices and the four literature matrices. AGD-SDAJ-BH runs alongside
# as a replay: on these sets the forward error is measured against a computed
# reference, so an identical AGD trajectory shows the reference matched too.
cd "$(dirname "$0")"
export NCM_STANDALONE=1
PANEL="C:/Users/ibrah/Documents/Codex/NCM-research/benchmarks-and-missingness/outputs/thesis-missingness-3type-archived/data/thesis_market_panel"
J="julia --project=. bench_sbb_dual.jl --solvers AGD-SDAJ-BH,Anderson-APM --blas-threads 4"

echo "$(date) export perturbed n=550 suite"
/c/Python314/python.exe -W ignore export_thesis_suite.py --panel "$PANEL" --out thesis_suite > export_thesis_suite.log 2>&1
tail -3 export_thesis_suite.log

echo "$(date) perturbed n=550, 20 matrices"
$J --suite thesis_suite --ranking ranking_thesis_anderson.csv --ranking-tol 1e-9 \
   --max-evds 3000 --sbb-maxit 3000 --apm-maxit 3000 --ref-sbb-maxit 0 > anderson_thesis_run.log 2>&1

echo "$(date) literature matrices, smaller two (cap 500)"
$J --suite real_suite --only "Rocky_Mountain_Region_CORR,cor1399" \
   --ranking ranking_real_anderson_small.csv --ranking-tol 1e-9 \
   --max-evds 500 --apm-maxit 500 --ref-sbb-maxit 0 > anderson_real_small.log 2>&1

echo "$(date) literature matrices, larger two (cap 300)"
$J --suite real_suite --only "cor3120,bccd16" \
   --ranking ranking_real_anderson_large.csv --ranking-tol 1e-9 \
   --max-evds 300 --apm-maxit 300 --ref-sbb-maxit 0 > anderson_real_large.log 2>&1

echo "$(date) ANDERSON REST QUEUE DONE"
