#!/bin/sh
# Queued after the n=2105 Anderson run: high-rank n=500 set with the projection methods.
cd "$(dirname "$0")"
until grep -q "^wrote " anderson_us2105_run.log 2>/dev/null; do sleep 60; done
J="julia --project=. bench_sbb_dual.jl --suite degen_highrank_n500 --blas-threads 4 --sbb-maxit 1200 --apm-maxit 800"
export NCM_STANDALONE=1
echo "$(date) step 1: AGD-SDAJ-BH replay"
$J --ranking ranking_highrank_agdcheck.csv --solvers AGD-SDAJ-BH > highrank_agdcheck.log 2>&1
/c/Python314/python.exe - <<'PY' > highrank_bitcheck.txt
import csv
def load(p, s):
    return [(r["instance"], r["evds"], r["err_raw_fro"]) for r in csv.DictReader(open(p)) if r["solver"] == s]
a = load("../results/reproduced/ranking_highrank_n500.csv", "AGD-SDAJ-BH")
b = load("ranking_highrank_agdcheck.csv", "AGD-SDAJ-BH")
print("IDENTICAL" if sorted(a) == sorted(b) else "DIFFERENT", len(a), len(b))
PY
cat highrank_bitcheck.txt
echo "$(date) step 2: Dykstra-APM and Anderson-APM"
$J --ranking ranking_highrank_proj.csv --solvers Dykstra-APM,Anderson-APM > highrank_proj.log 2>&1
if ! grep -q IDENTICAL highrank_bitcheck.txt; then
  echo "$(date) step 3: bits differ, rerunning Newton-SIN-BH and SBB-Dual"
  $J --ranking ranking_highrank_rest.csv --solvers Newton-SIN-BH,SBB-Dual > highrank_rest.log 2>&1
fi
echo "$(date) HIGHRANK QUEUE DONE"
